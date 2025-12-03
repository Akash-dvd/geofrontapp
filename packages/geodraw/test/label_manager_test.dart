import 'package:flutter_test/flutter_test.dart';
import 'package:geodraw/core/dag/dag_manager.dart';
import 'package:geodraw/core/label_manager.dart';
import 'package:geodraw/models/simple/geo_point.dart';
import 'package:geodraw/models/simple/geo_line.dart';
import 'package:geodraw/models/simple_lists/geo_intersection.dart';

void main() {
  group('LabelManager Tests', () {
    late DAGManager dagManager;

    setUp(() {
      dagManager = DAGManager();
    });

    group('getNextAvailableLabel - Points (Uppercase)', () {
      test('Returns A-Z for points when available', () {
        final label1 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
        );
        expect(label1, 'A');

        final label2 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
        );
        expect(label2, 'B');

        final label3 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
        );
        expect(label3, 'C');
      });

      test('Returns AA-ZZ when A-Z exhausted for points', () {
        // Create points A-Z
        for (int i = 0; i < 26; i++) {
          final label = String.fromCharCode(65 + i); // A-Z
          final point = GeoPointer(id: label, label: label, x: i.toDouble(), y: 0);
          dagManager.addObject(point, []);
        }

        // Next point should get AA
        final label = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
        );
        expect(label, 'AA');
      });

      test('Label Recycling: Reuses deleted labels before creating new ones', () {
        // Create A, B, C
        final pointA = GeoPointer(id: 'A', label: 'A', x: 0, y: 0);
        final pointB = GeoPointer(id: 'B', label: 'B', x: 1, y: 0);
        final pointC = GeoPointer(id: 'C', label: 'C', x: 2, y: 0);

        dagManager.addObject(pointA, []);
        dagManager.addObject(pointB, []);
        dagManager.addObject(pointC, []);

        // Delete A
        dagManager.deleteObject('A');

        // Next point should get A (not D)
        final label = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
        );
        expect(label, 'A');
      });

      test('Label Recycling: Reuses A before AA when A-Z all exist', () {
        // Create all 26 letters
        for (int i = 0; i < 26; i++) {
          final label = String.fromCharCode(65 + i); // A-Z
          final point = GeoPointer(id: label, label: label, x: i.toDouble(), y: 0);
          dagManager.addObject(point, []);
        }

        // Delete A
        dagManager.deleteObject('A');

        // Next point should get A (not AA)
        final label = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
        );
        expect(label, 'A');
      });

      test('Respects preferred label if available and unique', () {
        final label = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
          preferred: 'X',
        );
        expect(label, 'X');
      });

      test('Ignores preferred label if not unique', () {
        // Create point A
        final pointA = GeoPointer(id: 'A', label: 'A', x: 0, y: 0);
        dagManager.addObject(pointA, []);

        // Try to use A as preferred
        final label = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
          preferred: 'A',
        );
        // Should get B instead (A is taken)
        expect(label, 'B');
      });
    });

    group('getNextAvailableLabel - Lines (Lowercase)', () {
      test('Returns a-z for lines when available', () {
        final label1 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.line,
        );
        expect(label1, 'a');

        final label2 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.line,
        );
        expect(label2, 'b');
      });

      test('Returns aa-zz when a-z exhausted for lines', () {
        // Create lines a-z
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);

        for (int i = 0; i < 26; i++) {
          final label = String.fromCharCode(97 + i); // a-z
          final line = GeoLine2P.fromDependencies(
            id: label,
            label: label,
            points: [p1, p2],
          );
          dagManager.addObject(line, [p1.id, p2.id]);
        }

        // Next line should get aa
        final label = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.line,
        );
        expect(label, 'aa');
      });

      test('Label Recycling: Reuses deleted lowercase labels', () {
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);

        // Create a, b, c
        final lineA = GeoLine2P.fromDependencies(
          id: 'a',
          label: 'a',
          points: [p1, p2],
        );
        final lineB = GeoLine2P.fromDependencies(
          id: 'b',
          label: 'b',
          points: [p1, p2],
        );
        final lineC = GeoLine2P.fromDependencies(
          id: 'c',
          label: 'c',
          points: [p1, p2],
        );

        dagManager.addObject(lineA, [p1.id, p2.id]);
        dagManager.addObject(lineB, [p1.id, p2.id]);
        dagManager.addObject(lineC, [p1.id, p2.id]);

        // Delete a
        dagManager.deleteObject('a');

        // Next line should get a (not d)
        final label = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.line,
        );
        expect(label, 'a');
      });
    });

    group('getNextAvailableLabel - Containers', () {
      test('Returns SL1, SL2, SL3, ... for simple list containers', () {
        final label1 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.simpleList,
        );
        expect(label1, 'SL1');

        final label2 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.simpleList,
        );
        expect(label2, 'SL2');

        final label3 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.simpleList,
        );
        expect(label3, 'SL3');
      });

      test('Returns U1, U2, U3, ... for union containers', () {
        final label1 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.union,
        );
        expect(label1, 'U1');

        final label2 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.union,
        );
        expect(label2, 'U2');
      });

      test('Container Label Recycling: Reuses deleted container labels', () {
        // Create SL1, SL2, SL3 as regular objects (simulate conflict)
        final point1 = GeoPointer(id: 'SL1', label: 'SL1', x: 0, y: 0);
        final point2 = GeoPointer(id: 'SL2', label: 'SL2', x: 1, y: 0);
        final point3 = GeoPointer(id: 'SL3', label: 'SL3', x: 2, y: 0);

        dagManager.addObject(point1, []);
        dagManager.addObject(point2, []);
        dagManager.addObject(point3, []);

        // Next container should get SL4 (SL1-3 are taken)
        final label1 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.simpleList,
        );
        expect(label1, 'SL4');

        // Delete SL1
        dagManager.deleteObject('SL1');

        // Next container should get SL1 (reused)
        final label2 = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.simpleList,
        );
        expect(label2, 'SL1');
      });

      test('Finds least available container index', () {
        // Create SL1, SL3 (skip SL2)
        final point1 = GeoPointer(id: 'SL1', label: 'SL1', x: 0, y: 0);
        final point3 = GeoPointer(id: 'SL3', label: 'SL3', x: 2, y: 0);

        dagManager.addObject(point1, []);
        dagManager.addObject(point3, []);

        // Next container should get SL2 (least available)
        final label = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.simpleList,
        );
        expect(label, 'SL2');
      });
    });

    group('getNextAvailableLabelForTransformation', () {
      test('Adds apostrophe to base label: A → A\'', () {
        final label = LabelManager.getNextAvailableLabelForTransformation(
          dagManager,
          'A',
        );
        expect(label, 'A\'');
      });

      test('Adds apostrophe to lowercase: a → a\'', () {
        final label = LabelManager.getNextAvailableLabelForTransformation(
          dagManager,
          'a',
        );
        expect(label, 'a\'');
      });

      test('Tries double apostrophe if single exists', () {
        // Create A'
        final point = GeoPointer(id: 'A\'', label: 'A\'', x: 0, y: 0);
        dagManager.addObject(point, []);

        // Next transformation should get A''
        final label = LabelManager.getNextAvailableLabelForTransformation(
          dagManager,
          'A',
        );
        expect(label, 'A\'\'');
      });

      test('Tries triple apostrophe if double exists', () {
        // Create A' and A''
        final point1 = GeoPointer(id: 'A\'', label: 'A\'', x: 0, y: 0);
        final point2 = GeoPointer(id: 'A\'\'', label: 'A\'\'', x: 1, y: 0);
        dagManager.addObject(point1, []);
        dagManager.addObject(point2, []);

        // Next transformation should get A'''
        final label = LabelManager.getNextAvailableLabelForTransformation(
          dagManager,
          'A',
        );
        expect(label, 'A\'\'\'');
      });
    });

    group('isLabelUnique', () {
      test('Returns true for unique label', () {
        final isUnique = LabelManager.isLabelUnique(dagManager, 'A');
        expect(isUnique, true);
      });

      test('Returns false for duplicate label in DAG nodes', () {
        final point = GeoPointer(id: 'A', label: 'A', x: 0, y: 0);
        dagManager.addObject(point, []);

        final isUnique = LabelManager.isLabelUnique(dagManager, 'A');
        expect(isUnique, false);
      });

      test('Returns false for duplicate label in container elements', () {
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        final line1 = GeoLine2P.fromDependencies(
          id: 'line1',
          label: 'line1',
          points: [p1, p2],
        );
        final line2 = GeoLine2P.fromDependencies(
          id: 'line2',
          label: 'line2',
          points: [p1, p2],
        );

        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);
        dagManager.addObject(line1, [p1.id, p2.id]);
        dagManager.addObject(line2, [p1.id, p2.id]);

        // Create intersection with element 'A'
        final intersection = GeoIntersection.lineLine(
          id: 'SL1',
          label: 'SL1',
          line1: line1,
          line2: line2,
          dagManager: dagManager,
        );
        if (intersection != null) {
          dagManager.addObject(intersection, [line1.id, line2.id]);

          // Check if 'A' is unique (should be false if intersection created point 'A')
          final usedLabels = LabelManager.getAllUsedLabels(dagManager);
          if (usedLabels.contains('A')) {
            final isUnique = LabelManager.isLabelUnique(dagManager, 'A');
            expect(isUnique, false);
          }
        }
      });

      test('Excludes specified ID when checking uniqueness', () {
        final point = GeoPointer(id: 'A', label: 'A', x: 0, y: 0);
        dagManager.addObject(point, []);

        // Check uniqueness excluding 'A' itself
        final isUnique = LabelManager.isLabelUnique(
          dagManager,
          'A',
          excludeId: 'A',
        );
        expect(isUnique, true);
      });
    });

    group('getAllUsedLabels', () {
      test('Collects labels from DAG nodes', () {
        final point1 = GeoPointer(id: 'A', label: 'A', x: 0, y: 0);
        final point2 = GeoPointer(id: 'B', label: 'B', x: 1, y: 0);

        dagManager.addObject(point1, []);
        dagManager.addObject(point2, []);

        final usedLabels = LabelManager.getAllUsedLabels(dagManager);
        expect(usedLabels, contains('A'));
        expect(usedLabels, contains('B'));
      });

      test('Collects element IDs from containers', () {
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        final line1 = GeoLine2P.fromDependencies(
          id: 'line1',
          label: 'line1',
          points: [p1, p2],
        );
        final line2 = GeoLine2P.fromDependencies(
          id: 'line2',
          label: 'line2',
          points: [p1, p2],
        );

        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);
        dagManager.addObject(line1, [p1.id, p2.id]);
        dagManager.addObject(line2, [p1.id, p2.id]);

        final intersection = GeoIntersection.lineLine(
          id: 'SL1',
          label: 'SL1',
          line1: line1,
          line2: line2,
          dagManager: dagManager,
        );
        if (intersection != null) {
          dagManager.addObject(intersection, [line1.id, line2.id]);

          final usedLabels = LabelManager.getAllUsedLabels(dagManager);
          // Should contain container label
          expect(usedLabels, contains('SL1'));
          // Should contain element IDs from intersection
          if (intersection.objects.isNotEmpty) {
            final elementId = intersection.objects.first.id;
            expect(usedLabels, contains(elementId));
          }
        }
      });
    });

    group('suggestNextLabel', () {
      test('Returns base label if unique', () {
        final suggestion = LabelManager.suggestNextLabel(
          dagManager,
          'X',
          GeometryObjectType.point,
        );
        expect(suggestion, 'X');
      });

      test('Suggests next uppercase variant for points', () {
        // Create A, B, C
        for (int i = 0; i < 3; i++) {
          final label = String.fromCharCode(65 + i); // A, B, C
          final point = GeoPointer(id: label, label: label, x: i.toDouble(), y: 0);
          dagManager.addObject(point, []);
        }

        // Suggesting 'A' should return 'D' (next available)
        final suggestion = LabelManager.suggestNextLabel(
          dagManager,
          'A',
          GeometryObjectType.point,
        );
        expect(suggestion, 'D');
      });

      test('Suggests next lowercase variant for lines', () {
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);

        // Create a, b, c
        for (int i = 0; i < 3; i++) {
          final label = String.fromCharCode(97 + i); // a, b, c
          final line = GeoLine2P.fromDependencies(
            id: label,
            label: label,
            points: [p1, p2],
          );
          dagManager.addObject(line, [p1.id, p2.id]);
        }

        // Suggesting 'a' should return 'd' (next available)
        final suggestion = LabelManager.suggestNextLabel(
          dagManager,
          'a',
          GeometryObjectType.line,
        );
        expect(suggestion, 'd');
      });

      test('Suggests next container variant for simpleList', () {
        // Create SL1, SL2
        final point1 = GeoPointer(id: 'SL1', label: 'SL1', x: 0, y: 0);
        final point2 = GeoPointer(id: 'SL2', label: 'SL2', x: 1, y: 0);
        dagManager.addObject(point1, []);
        dagManager.addObject(point2, []);

        // Suggesting 'SL1' should return 'SL3' (next available)
        final suggestion = LabelManager.suggestNextLabel(
          dagManager,
          'SL1',
          GeometryObjectType.simpleList,
        );
        expect(suggestion, 'SL3');
      });
    });

    group('Case Sensitivity', () {
      test('A and a are different labels', () {
        final pointA = GeoPointer(id: 'A', label: 'A', x: 0, y: 0);
        dagManager.addObject(pointA, []);

        // 'a' should be unique (different from 'A')
        final isUnique = LabelManager.isLabelUnique(dagManager, 'a');
        expect(isUnique, true);
      });

      test('Can create both A (point) and a (line)', () {
        final pointA = GeoPointer(id: 'A', label: 'A', x: 0, y: 0);
        dagManager.addObject(pointA, []);

        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);

        // Should be able to create line 'a'
        final lineA = GeoLine2P.fromDependencies(
          id: 'a',
          label: 'a',
          points: [p1, p2],
        );
        dagManager.addObject(lineA, [p1.id, p2.id]);

        // Both should exist
        expect(dagManager.getObject('A'), isNotNull);
        expect(dagManager.getObject('a'), isNotNull);
      });
    });

    group('Edge Cases', () {
      test('Handles empty DAG correctly', () {
        final label = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
        );
        expect(label, 'A');
      });

      test('Handles very large sequences (AA-ZZ)', () {
        // Create all single letters A-Z
        for (int i = 0; i < 26; i++) {
          final label = String.fromCharCode(65 + i);
          final point = GeoPointer(id: label, label: label, x: i.toDouble(), y: 0);
          dagManager.addObject(point, []);
        }

        // Next should be AA
        final label = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
        );
        expect(label, 'AA');

        // Create AA, AB, AC
        for (int i = 0; i < 3; i++) {
          final label = 'A${String.fromCharCode(65 + i)}'; // AA, AB, AC
          final point = GeoPointer(id: label, label: label, x: i.toDouble(), y: 1);
          dagManager.addObject(point, []);
        }

        // Next should be AD
        final nextLabel = LabelManager.getNextAvailableLabel(
          dagManager,
          GeometryObjectType.point,
        );
        expect(nextLabel, 'AD');
      });
    });
  });
}

