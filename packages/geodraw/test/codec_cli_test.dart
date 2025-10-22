import 'package:flutter_test/flutter_test.dart';
import 'package:geodraw/geodraw.dart';

void main() {
  group('Codec Tests', () {
    test('Encoder encodes DAG to JSON', () {
      final dag = DAGManager();
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 10, y: 20);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 30, y: 40);

      dag.addObject(p1, []);
      dag.addObject(p2, []);

      final codec = GeoDrawCodec();
      final json = codec.encode(dag);

      expect(json['type'], 'construction');
      expect(json['version'], '1.0');
      expect(json['objects'], isA<List>());
      expect(json['objects'].length, 2);
    });

    test('Encoder includes object properties', () {
      final dag = DAGManager();
      final point = GeoPointer(id: 'p1', label: 'A', x: 10, y: 20);
      dag.addObject(point, []);

      final codec = GeoDrawCodec();
      final json = codec.encode(dag);
      final obj = json['objects'][0];

      expect(obj['id'], 'p1');
      expect(obj['type'], 'GeoPointer');
      expect(obj['label'], 'A');
      expect(obj['properties']['x'], 10);
      expect(obj['properties']['y'], 20);
    });

    test('Decoder decodes JSON to DAG', () {
      final originalDag = DAGManager();
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 10, y: 20);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 30, y: 40);

      originalDag.addObject(p1, []);
      originalDag.addObject(p2, []);

      final codec = GeoDrawCodec();
      final json = codec.encode(originalDag);
      final decodedDag = codec.decode(json);

      expect(decodedDag.nodeCount, 2);

      final decodedP1 = decodedDag.getObject('p1') as GeoPointer?;
      expect(decodedP1, isNotNull);
      expect(decodedP1!.label, 'A');
      expect(decodedP1.x, 10);
      expect(decodedP1.y, 20);
    });

    test('Round-trip encoding preserves construction', () {
      final dag = DAGManager();
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 10, y: 10);

      dag.addObject(p1, []);
      dag.addObject(p2, []);

      final line = GeoLine2P.fromPoints(id: 'l1', label: 'AB', p1: p1, p2: p2);
      dag.addObject(line, ['p1', 'p2']);

      final codec = GeoDrawCodec();
      final jsonString = codec.encodeToJson(dag);
      final restoredDag = codec.decodeFromJson(jsonString);

      expect(restoredDag.nodeCount, 3);
      expect(restoredDag.getObject('p1'), isNotNull);
      expect(restoredDag.getObject('p2'), isNotNull);
      expect(restoredDag.getObject('l1'), isNotNull);
    });

    test('Encoder handles circles correctly', () {
      final dag = DAGManager();
      final center = GeoPointer(id: 'c1', label: 'C', x: 0, y: 0);
      final point = GeoPointer(id: 'p1', label: 'P', x: 5, y: 0);

      dag.addObject(center, []);
      dag.addObject(point, []);

      final circle = GeoCircle2P.fromPoints(
        id: 'circ1',
        label: 'Circle',
        center: center,
        pointOnCircle: point,
      );
      dag.addObject(circle, ['c1', 'p1']);

      final codec = GeoDrawCodec();
      final json = codec.encode(dag);
      final circleJson = json['objects'][2];

      expect(circleJson['type'], 'GeoCircle2P');
      expect(circleJson['properties']['radius'], 5.0);
    });
  });

  group('CLI Parser Tests', () {
    test('Parser parses simple command', () {
      final parser = CommandParser();
      final command = parser.parse('point(10, 20)');

      expect(command, isNotNull);
      expect(command.name, 'point');
      expect(command.arguments.length, 2);
      expect(command.arguments[0], 10);
      expect(command.arguments[1], 20);
    });

    test('Parser parses command with string arguments', () {
      final parser = CommandParser();
      final command = parser.parse('line(A, B)');

      expect(command, isNotNull);
      expect(command.name, 'line');
      expect(command.arguments.length, 2);
      expect(command.arguments[0], 'A');
      expect(command.arguments[1], 'B');
    });

    test('Parser parses command with mixed arguments', () {
      final parser = CommandParser();
      final command = parser.parse('circle(center, 10)');

      expect(command, isNotNull);
      expect(command.name, 'circle');
      expect(command.arguments.length, 2);
      expect(command.arguments[0], 'center');
      expect(command.arguments[1], 10);
    });

    test('Parser handles empty input', () {
      final parser = CommandParser();
      final command = parser.parse('');

      expect(command, isNull);
    });

    test('Parser validates command', () {
      final parser = CommandParser();
      final command = parser.parse('point(10, 20)');

      expect(parser.validate(command), isTrue);
    });
  });

  group('CLI Executor Tests', () {
    test('Executor creates point from command', () async {
      final dag = DAGManager();
      final executor = CommandExecutor(dagManager: dag);
      final parser = CommandParser();

      final command = parser.parse('point(10, 20, A)');
      final result = await executor.execute(command);

      expect(result.success, isTrue);
      expect(dag.nodeCount, 1);

      final point = dag.nodes.values.first.object as GeoPointer;
      expect(point.label, 'A');
      expect(point.x, 10);
      expect(point.y, 20);
    });

    test('Executor creates line from command', () async {
      final dag = DAGManager();
      final executor = CommandExecutor(dagManager: dag);
      final parser = CommandParser();

      // Create two points first
      await executor.execute(parser.parse('point(0, 0, A)'));
      await executor.execute(parser.parse('point(10, 10, B)'));

      // Create line
      final lineCommand = parser.parse('line(A, B)');
      final result = await executor.execute(lineCommand);

      expect(result.success, isTrue);
      expect(dag.nodeCount, 3);
    });

    test('Executor creates circle from command', () async {
      final dag = DAGManager();
      final executor = CommandExecutor(dagManager: dag);
      final parser = CommandParser();

      // Create center point
      await executor.execute(parser.parse('point(0, 0, C)'));

      // Create circle with radius
      final circleCommand = parser.parse('circle(C, 5)');
      final result = await executor.execute(circleCommand);

      expect(result.success, isTrue);
      expect(dag.nodeCount, 2); // center + circle
    });

    test('Executor creates midpoint from command', () async {
      final dag = DAGManager();
      final executor = CommandExecutor(dagManager: dag);
      final parser = CommandParser();

      // Create two points
      await executor.execute(parser.parse('point(0, 0, A)'));
      await executor.execute(parser.parse('point(10, 10, B)'));

      // Create midpoint
      final midCommand = parser.parse('midpoint(A, B)');
      final result = await executor.execute(midCommand);

      expect(result.success, isTrue);
      expect(dag.nodeCount, 3);

      final midpoint = result.data as GeoMidpoint;
      expect(midpoint.x, 5);
      expect(midpoint.y, 5);
    });

    test('Executor handles errors gracefully', () async {
      final dag = DAGManager();
      final executor = CommandExecutor(dagManager: dag);
      final parser = CommandParser();

      // Try to create line with non-existent points
      final command = parser.parse('line(X, Y)');
      final result = await executor.execute(command);

      expect(result.success, isFalse);
      expect(result.message, contains('not found'));
    });

    test('Executor clear command works', () async {
      final dag = DAGManager();
      final executor = CommandExecutor(dagManager: dag);
      final parser = CommandParser();

      // Create some objects
      await executor.execute(parser.parse('point(0, 0)'));
      await executor.execute(parser.parse('point(10, 10)'));

      expect(dag.nodeCount, 2);

      // Clear
      final clearResult = await executor.execute(parser.parse('clear'));

      expect(clearResult.success, isTrue);
      expect(dag.nodeCount, 0);
    });

    test('Executor list command works', () async {
      final dag = DAGManager();
      final executor = CommandExecutor(dagManager: dag);
      final parser = CommandParser();

      await executor.execute(parser.parse('point(0, 0, A)'));
      await executor.execute(parser.parse('point(10, 10, B)'));

      final listResult = await executor.execute(parser.parse('list'));

      expect(listResult.success, isTrue);
      expect(listResult.message, contains('2'));
    });
  });

  group('Command History Tests', () {
    test('History records commands', () {
      final history = CommandHistory();
      final result = ExecutionResult.successful(message: 'OK');

      history.add('point(10, 20)', result);

      expect(history.length, 1);
      expect(history.isEmpty, isFalse);
    });

    test('History navigates backward and forward', () {
      final history = CommandHistory();
      final result = ExecutionResult.successful(message: 'OK');

      history.add('point(10, 20)', result);
      history.add('point(30, 40)', result);
      history.add('line(A, B)', result);

      // After adding 3 items, current index is at 2 (the last item)
      // previous() decrements and returns that item
      final prev1 = history.previous();
      expect(prev1, 'point(30, 40)'); // Now at index 1

      final prev2 = history.previous();
      expect(prev2, 'point(10, 20)'); // Now at index 0

      final next = history.next();
      expect(next, 'point(30, 40)'); // Back to index 1
    });

    test('History limits size', () {
      final history = CommandHistory();
      final result = ExecutionResult.successful(message: 'OK');

      // Add more than max
      for (int i = 0; i < 150; i++) {
        history.add('command$i', result);
      }

      expect(history.length, 100);
    });

    test('History tracks successful and failed commands', () {
      final history = CommandHistory();

      history.add('point(10, 20)', ExecutionResult.successful(message: 'OK'));
      history.add('bad', ExecutionResult.error('Error'));
      history.add('circle(A, 5)', ExecutionResult.successful(message: 'OK'));

      expect(history.successfulCommands.length, 2);
      expect(history.failedCommands.length, 1);
    });

    test('History clear works', () {
      final history = CommandHistory();
      final result = ExecutionResult.successful(message: 'OK');

      history.add('point(10, 20)', result);
      history.add('point(30, 40)', result);

      expect(history.length, 2);

      history.clear();

      expect(history.length, 0);
      expect(history.isEmpty, isTrue);
    });
  });

  group('Tool Manager Tests', () {
    test('ToolManager initializes with select tool', () {
      final dag = DAGManager();
      final toolManager = ToolManager(dagManager: dag);

      expect(toolManager.activeToolType, ToolType.select);
    });

    test('ToolManager switches tools', () {
      final dag = DAGManager();
      final toolManager = ToolManager(dagManager: dag);

      toolManager.selectTool(ToolType.point);

      expect(toolManager.activeToolType, ToolType.point);
      expect(toolManager.activeTool, isNotNull);
      expect(toolManager.activeTool, isA<PointTool>());
    });

    test('ToolManager provides tool metadata', () {
      final dag = DAGManager();
      final toolManager = ToolManager(dagManager: dag);

      final metadata = toolManager.getToolMetadata(ToolType.point);

      expect(metadata.name, 'Point');
      expect(metadata.tooltip, isNotEmpty);
    });

    test('ToolManager lists available tools', () {
      final dag = DAGManager();
      final toolManager = ToolManager(dagManager: dag);

      final tools = toolManager.availableTools;

      expect(tools, contains(ToolType.point));
      expect(tools, contains(ToolType.line));
      expect(tools, contains(ToolType.circle));
    });

    test('ToolManager checks tool availability', () {
      final dag = DAGManager();
      final toolManager = ToolManager(dagManager: dag);

      expect(toolManager.isToolAvailable(ToolType.point), isTrue);
      expect(toolManager.isToolAvailable(ToolType.line), isTrue);
    });
  });
}
