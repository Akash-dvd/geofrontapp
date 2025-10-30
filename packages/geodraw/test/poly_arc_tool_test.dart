import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geodraw/core/command/command_history.dart';
import 'package:geodraw/core/dag/dag_manager.dart';
import 'package:geodraw/models/complex/geo_shapes_list.dart';
import 'package:geodraw/models/simple/geo_point.dart';
import 'package:geodraw/tools/tool.dart';
import 'package:geodraw/tools/tool_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCommands() => pumpEventQueue();

  group('Poly-arc tool', () {
    late DAGManager dagManager;
    late CommandHistory history;
    late ToolManager manager;
    GeoPolyArc? capturedPolyArc;
    final createdPointIds = <String>[];
    late List<String> states;

    setUp(() {
      dagManager = DAGManager();
      history = CommandHistory();
      capturedPolyArc = null;
      createdPointIds.clear();
      states = <String>[];

      manager = ToolManager(
        dagManager: dagManager,
        commandHistory: history,
        onObjectCreated: (object, dependencies) {
          if (object is GeoPolyArc) {
            capturedPolyArc = object;
          }
          if (object is GeoPoint) {
            createdPointIds.add(object.id);
          }
        },
        onToolStateChanged: states.add,
      );

      manager.selectTool(ToolType.polyArc);
    });

    test('creates initial arc after three selections', () async {
      await _tap(manager, const Offset(0, 0));
      await _tap(manager, const Offset(50, 60));
      await _tap(manager, const Offset(100, 0));
      await pumpCommands();

      expect(history.failedCommands, isEmpty, reason: states.join(' -> '));
      expect(capturedPolyArc, isNotNull, reason: states.join(' -> '));
      final polyArcId = capturedPolyArc!.id;
      expect(
        history.successfulCommands.map((r) => r.entry.canonicalName),
        contains('polyarc'),
      );

      final stored = dagManager.getObject(polyArcId);
      expect(stored, isA<GeoPolyArc>());
      final polyArc = stored as GeoPolyArc;
      expect(polyArc.dependencies.length, 3);
      expect(polyArc.elements.length, 1);
    });

    test('extends poly-arc with each additional point pair', () async {
      await _tap(manager, const Offset(0, 0));
      await _tap(manager, const Offset(50, 60));
      await _tap(manager, const Offset(100, 0));
      await pumpCommands();

      final initial = capturedPolyArc;
      expect(history.failedCommands, isEmpty, reason: states.join(' -> '));
      expect(initial, isNotNull, reason: 'Initial poly-arc should be created');
      final polyArcId = initial!.id;

      await _tap(manager, const Offset(150, -60));
      await pumpCommands();
      await _tap(manager, const Offset(200, 0));
      await pumpCommands();
      expect(history.failedCommands, isEmpty, reason: states.join(' -> '));

      final updated = dagManager.getObject(polyArcId);
      expect(updated, isA<GeoPolyArc>());
      final polyArc = updated as GeoPolyArc;
      expect(polyArc.dependencies.length, 5);
      expect(polyArc.elements.length, 2);

      expect(history.successfulCommands.length, 2);
      final names = history.successfulCommands.map(
        (record) => record.entry.canonicalName,
      );
      expect(names, containsAll(<String>['polyarc', 'extendpolyarc']));
    });
  });
}

Future<void> _tap(ToolManager manager, Offset position) async {
  manager.handleInput(PointerDownEvent(position: position));
  await pumpEventQueue();
}
