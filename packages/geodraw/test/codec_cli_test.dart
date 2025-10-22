import 'package:flutter_test/flutter_test.dart';
import 'package:geodraw/geodraw.dart';

void main() {
  group('GeoDrawCodec', () {
    test('encodes and decodes simple constructions', () {
      final dag = DAGManager();
      final a = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final b = GeoPointer(id: 'p2', label: 'B', x: 3, y: 4);

      dag.addObject(a, []);
      dag.addObject(b, []);

      final circle = GeoCircle2P.fromPoints(
        id: 'c1',
        label: 'CircleAB',
        center: a,
        pointOnCircle: b,
      );
      dag.addObject(circle, [a.id, b.id]);

      final codec = GeoDrawCodec();
      final encoded = codec.encode(dag);

      expect(encoded['objects'], hasLength(3));
      expect(encoded['objects'][0]['type'], 'GeoPointer');

      final restored = codec.decode(encoded);
      expect(restored.nodeCount, equals(dag.nodeCount));
      expect(restored.getObject('c1'), isA<GeoCircle2P>());
    });

    test('round trip preserves labels', () {
      final dag = DAGManager();
      dag.addObject(GeoPointer(id: 'p1', label: 'A', x: 1, y: 2), []);

      final codec = GeoDrawCodec();
      final json = codec.encodeToJson(dag);
      final restored = codec.decodeFromJson(json);

      final restoredPoint = restored.getObject('p1') as GeoPointer?;
      expect(restoredPoint, isNotNull);
      expect(restoredPoint!.label, equals('A'));
    });
  });

  group('CommandParser', () {
    late DAGManager dag;
    late CommandParser parser;

    setUp(() {
      dag = DAGManager();
      parser = CommandParser(dag);
    });

    test('parses command with optional label', () {
      final a = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final b = GeoPointer(id: 'p2', label: 'B', x: 5, y: 0);
      dag.addObject(a, []);
      dag.addObject(b, []);

      final parsed = parser.parse('line(A, B, AB)');

      expect(parsed.canonicalName, equals('line'));
      expect(parsed.arguments[0], same(a));
      expect(parsed.arguments[1], same(b));
      expect(parsed.arguments[2], equals('AB'));
    });

    test('parseAndExecute creates geometry objects', () async {
      final result = await parser.parseAndExecute('point(1, 2, P)');

      expect(result.success, isTrue);
      expect(dag.nodeCount, equals(1));

      final point = dag.getObject(result.objectId!) as GeoPointer?;
      expect(point, isNotNull);
      expect(point!.label, equals('P'));
    });

    test('throws for unknown commands', () {
      expect(() => parser.parse('unknown()'), throwsA(isA<CommandParserException>()));
    });
  });

  group('UnifiedCLIExecutor', () {
    test('executes dependent commands in sequence', () async {
      final dag = DAGManager();
      final executor = UnifiedCLIExecutor(dagManager: dag);

      expect((await executor.executeString('point(0, 0, A)')).success, isTrue);
      expect((await executor.executeString('point(4, 0, B)')).success, isTrue);
      expect((await executor.executeString('point(0, 3, C)')).success, isTrue);

      final circleResult = await executor.executeString('circle3(A, B, C, circumcircle)');
      expect(circleResult.success, isTrue);
      expect(dag.nodeCount, equals(4));

      final missingDependency = await executor.executeString('line(A, Z, AZ)');
      expect(missingDependency.success, isFalse);
    });
  });

  group('CommandHistory', () {
    test('records and navigates history entries', () {
      final history = CommandHistory();
      final success = ExecutionResult.successful(message: 'ok');
      final failure = ExecutionResult.error('oops');

      history.add('point(0, 0, A)', success);
      history.add('line(A, B, L)', failure);

      expect(history.length, equals(2));
      expect(history.successfulCommands, hasLength(1));
      expect(history.failedCommands, hasLength(1));

      final previous = history.previous();
      expect(previous, isNotNull);
      final next = history.next();
      expect(next, isNotNull);
    });
  });
}
