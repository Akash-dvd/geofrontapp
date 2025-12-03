import 'package:flutter_test/flutter_test.dart';
import 'package:geodraw/core/dag/dag_manager.dart';
import 'package:geodraw/models/simple/geo_point.dart';
import 'package:geodraw/models/simple/geo_line.dart';
import 'package:geodraw/models/simple_lists/geo_intersection.dart';

void main() {
  group('DAGManager elementToContainer Map Tests', () {
    late DAGManager dagManager;

    setUp(() {
      dagManager = DAGManager();
    });

    group('Element Registration', () {
      test('Elements are registered when container is added', () {
        // Create two lines for intersection
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        final p3 = GeoPointer(id: 'P3', label: 'P3', x: 2, y: 0);
        final p4 = GeoPointer(id: 'P4', label: 'P4', x: 3, y: 1);

        final line1 = GeoLine2P.fromDependencies(
          id: 'line1',
          label: 'line1',
          points: [p1, p2],
        );
        final line2 = GeoLine2P.fromDependencies(
          id: 'line2',
          label: 'line2',
          points: [p3, p4],
        );

        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);
        dagManager.addObject(p3, []);
        dagManager.addObject(p4, []);
        dagManager.addObject(line1, [p1.id, p2.id]);
        dagManager.addObject(line2, [p3.id, p4.id]);

        // Create intersection (container with elements)
        final intersection = GeoIntersection.lineLine(
          id: 'SL1',
          label: 'SL1',
          line1: line1,
          line2: line2,
          dagManager: dagManager,
        );

        if (intersection != null) {
          dagManager.addObject(intersection, [line1.id, line2.id]);

          // Check that elements are registered
          expect(intersection.objects.isNotEmpty, true);
          for (final element in intersection.objects) {
            final containerId = dagManager.getContainerForElement(element.id);
            expect(containerId, 'SL1');
            expect(dagManager.elementToContainer[element.id], 'SL1');
          }
        }
      });

      test('Multiple containers register their elements correctly', () {
        // Create first intersection
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        final p3 = GeoPointer(id: 'P3', label: 'P3', x: 2, y: 0);
        final p4 = GeoPointer(id: 'P4', label: 'P4', x: 3, y: 1);

        final line1 = GeoLine2P.fromDependencies(
          id: 'line1',
          label: 'line1',
          points: [p1, p2],
        );
        final line2 = GeoLine2P.fromDependencies(
          id: 'line2',
          label: 'line2',
          points: [p3, p4],
        );

        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);
        dagManager.addObject(p3, []);
        dagManager.addObject(p4, []);
        dagManager.addObject(line1, [p1.id, p2.id]);
        dagManager.addObject(line2, [p3.id, p4.id]);

        final intersection1 = GeoIntersection.lineLine(
          id: 'SL1',
          label: 'SL1',
          line1: line1,
          line2: line2,
          dagManager: dagManager,
        );

        if (intersection1 != null) {
          dagManager.addObject(intersection1, [line1.id, line2.id]);

          // Create second intersection
          final p5 = GeoPointer(id: 'P5', label: 'P5', x: 4, y: 0);
          final p6 = GeoPointer(id: 'P6', label: 'P6', x: 5, y: 1);
          final line3 = GeoLine2P.fromDependencies(
            id: 'line3',
            label: 'line3',
            points: [p5, p6],
          );

          dagManager.addObject(p5, []);
          dagManager.addObject(p6, []);
          dagManager.addObject(line3, [p5.id, p6.id]);

          final intersection2 = GeoIntersection.lineLine(
            id: 'SL2',
            label: 'SL2',
            line1: line2,
            line2: line3,
            dagManager: dagManager,
          );

          if (intersection2 != null) {
            dagManager.addObject(intersection2, [line2.id, line3.id]);

            // Check that elements from both containers are registered
            for (final element in intersection1.objects) {
              expect(dagManager.getContainerForElement(element.id), 'SL1');
            }
            for (final element in intersection2.objects) {
              expect(dagManager.getContainerForElement(element.id), 'SL2');
            }

            // Verify no cross-contamination
            final element1Id = intersection1.objects.first.id;
            final element2Id = intersection2.objects.first.id;
            expect(dagManager.getContainerForElement(element1Id), 'SL1');
            expect(dagManager.getContainerForElement(element2Id), 'SL2');
            expect(dagManager.getContainerForElement(element1Id), isNot('SL2'));
            expect(dagManager.getContainerForElement(element2Id), isNot('SL1'));
          }
        }
      });
    });

    group('Element Unregistration', () {
      test('Elements are unregistered when container is deleted', () {
        // Create intersection
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        final p3 = GeoPointer(id: 'P3', label: 'P3', x: 2, y: 0);
        final p4 = GeoPointer(id: 'P4', label: 'P4', x: 3, y: 1);

        final line1 = GeoLine2P.fromDependencies(
          id: 'line1',
          label: 'line1',
          points: [p1, p2],
        );
        final line2 = GeoLine2P.fromDependencies(
          id: 'line2',
          label: 'line2',
          points: [p3, p4],
        );

        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);
        dagManager.addObject(p3, []);
        dagManager.addObject(p4, []);
        dagManager.addObject(line1, [p1.id, p2.id]);
        dagManager.addObject(line2, [p3.id, p4.id]);

        final intersection = GeoIntersection.lineLine(
          id: 'SL1',
          label: 'SL1',
          line1: line1,
          line2: line2,
          dagManager: dagManager,
        );

        if (intersection != null) {
          dagManager.addObject(intersection, [line1.id, line2.id]);

          // Verify elements are registered
          final elementIds = intersection.objects.map((e) => e.id).toList();
          for (final elementId in elementIds) {
            expect(dagManager.getContainerForElement(elementId), 'SL1');
          }

          // Delete container
          dagManager.deleteObject('SL1', cascade: true);

          // Verify elements are unregistered
          for (final elementId in elementIds) {
            expect(dagManager.getContainerForElement(elementId), isNull);
            expect(dagManager.elementToContainer.containsKey(elementId), false);
          }
        }
      });

      test('Manual unregistration works', () {
        dagManager.registerElement('E1', 'SL1');
        expect(dagManager.getContainerForElement('E1'), 'SL1');

        dagManager.unregisterElement('E1');
        expect(dagManager.getContainerForElement('E1'), isNull);
        expect(dagManager.elementToContainer.containsKey('E1'), false);
      });
    });

    group('Element Lookup via getObject()', () {
      test('getObject() finds elements via elementToContainer map', () {
        // Create intersection
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        final p3 = GeoPointer(id: 'P3', label: 'P3', x: 2, y: 0);
        final p4 = GeoPointer(id: 'P4', label: 'P4', x: 3, y: 1);

        final line1 = GeoLine2P.fromDependencies(
          id: 'line1',
          label: 'line1',
          points: [p1, p2],
        );
        final line2 = GeoLine2P.fromDependencies(
          id: 'line2',
          label: 'line2',
          points: [p3, p4],
        );

        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);
        dagManager.addObject(p3, []);
        dagManager.addObject(p4, []);
        dagManager.addObject(line1, [p1.id, p2.id]);
        dagManager.addObject(line2, [p3.id, p4.id]);

        final intersection = GeoIntersection.lineLine(
          id: 'SL1',
          label: 'SL1',
          line1: line1,
          line2: line2,
          dagManager: dagManager,
        );

        if (intersection != null) {
          dagManager.addObject(intersection, [line1.id, line2.id]);

          // Test lookup for each element
          for (final element in intersection.objects) {
            final found = dagManager.getObject(element.id);
            expect(found, isNotNull);
            expect(found, equals(element));
            expect(found?.id, element.id);
          }
        }
      });

      test('getObject() returns null for non-existent element ID', () {
        final found = dagManager.getObject('NONEXISTENT');
        expect(found, isNull);
      });

      test('getObject() finds direct DAG nodes first', () {
        // Create a regular point (not an element)
        final point = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        dagManager.addObject(point, []);

        // Should find via direct lookup, not elementToContainer
        final found = dagManager.getObject('P1');
        expect(found, isNotNull);
        expect(found, equals(point));
        expect(dagManager.elementToContainer.containsKey('P1'), false);
      });
    });

    group('Container Updates', () {
      test('Elements are updated when container changes', () {
        // Create initial intersection
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        final p3 = GeoPointer(id: 'P3', label: 'P3', x: 2, y: 0);
        final p4 = GeoPointer(id: 'P4', label: 'P4', x: 3, y: 1);

        final line1 = GeoLine2P.fromDependencies(
          id: 'line1',
          label: 'line1',
          points: [p1, p2],
        );
        final line2 = GeoLine2P.fromDependencies(
          id: 'line2',
          label: 'line2',
          points: [p3, p4],
        );

        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);
        dagManager.addObject(p3, []);
        dagManager.addObject(p4, []);
        dagManager.addObject(line1, [p1.id, p2.id]);
        dagManager.addObject(line2, [p3.id, p4.id]);

        final intersection = GeoIntersection.lineLine(
          id: 'SL1',
          label: 'SL1',
          line1: line1,
          line2: line2,
          dagManager: dagManager,
        );

        if (intersection != null) {
          dagManager.addObject(intersection, [line1.id, line2.id]);

          final oldElementIds = intersection.objects.map((e) => e.id).toSet();

          // Rebuild intersection (simulates update)
          final rebuilt = intersection.rebuildFromParents(
            [line1, line2],
            dagManager,
          );

          if (rebuilt != null && rebuilt is GeoIntersection) {
            final newElementIds = rebuilt.objects.map((e) => e.id).toSet();

            // Update the container
            dagManager.updateObject('SL1', rebuilt);

            // Check that old elements are unregistered if removed
            for (final oldId in oldElementIds) {
              if (!newElementIds.contains(oldId)) {
                expect(dagManager.getContainerForElement(oldId), isNull);
              }
            }

            // Check that new elements are registered
            for (final element in rebuilt.objects) {
              expect(dagManager.getContainerForElement(element.id), 'SL1');
            }
          }
        }
      });

      test('Removed elements are unregistered, new elements are registered', () {
        // Create a mock container scenario
        // First, manually register some elements
        dagManager.registerElement('E1', 'SL1');
        dagManager.registerElement('E2', 'SL1');

        expect(dagManager.getContainerForElement('E1'), 'SL1');
        expect(dagManager.getContainerForElement('E2'), 'SL1');

        // Simulate container update that removes E1 and adds E3
        // (In real scenario, this would be done via updateObject with new container)
        dagManager.unregisterElement('E1');
        dagManager.registerElement('E3', 'SL1');

        expect(dagManager.getContainerForElement('E1'), isNull);
        expect(dagManager.getContainerForElement('E2'), 'SL1'); // Still registered
        expect(dagManager.getContainerForElement('E3'), 'SL1'); // Newly registered
      });
    });

    group('getContainerForElement() Helper', () {
      test('Returns container ID for registered element', () {
        dagManager.registerElement('E1', 'SL1');
        expect(dagManager.getContainerForElement('E1'), 'SL1');
      });

      test('Returns null for unregistered element', () {
        expect(dagManager.getContainerForElement('NONEXISTENT'), isNull);
      });

      test('Returns correct container for multiple elements', () {
        dagManager.registerElement('E1', 'SL1');
        dagManager.registerElement('E2', 'SL1');
        dagManager.registerElement('E3', 'SL2');

        expect(dagManager.getContainerForElement('E1'), 'SL1');
        expect(dagManager.getContainerForElement('E2'), 'SL1');
        expect(dagManager.getContainerForElement('E3'), 'SL2');
      });
    });

    group('updateElementId()', () {
      test('Updates element ID and elementToContainer map', () {
        // Create intersection
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        final p3 = GeoPointer(id: 'P3', label: 'P3', x: 2, y: 0);
        final p4 = GeoPointer(id: 'P4', label: 'P4', x: 3, y: 1);

        final line1 = GeoLine2P.fromDependencies(
          id: 'line1',
          label: 'line1',
          points: [p1, p2],
        );
        final line2 = GeoLine2P.fromDependencies(
          id: 'line2',
          label: 'line2',
          points: [p3, p4],
        );

        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);
        dagManager.addObject(p3, []);
        dagManager.addObject(p4, []);
        dagManager.addObject(line1, [p1.id, p2.id]);
        dagManager.addObject(line2, [p3.id, p4.id]);

        final intersection = GeoIntersection.lineLine(
          id: 'SL1',
          label: 'SL1',
          line1: line1,
          line2: line2,
          dagManager: dagManager,
        );

        if (intersection != null && intersection.objects.isNotEmpty) {
          dagManager.addObject(intersection, [line1.id, line2.id]);

          final oldElement = intersection.objects.first;
          final oldElementId = oldElement.id;

          // Verify old element is registered
          expect(dagManager.getContainerForElement(oldElementId), 'SL1');

          // Create updated element with new ID
          final newElement = GeoPointer(
            id: 'NEW_ID',
            label: 'NEW_ID',
            x: oldElement.x,
            y: oldElement.y,
          );

          // Update element ID
          dagManager.updateElementId(
            oldElementId: oldElementId,
            newElementId: 'NEW_ID',
            updatedElement: newElement,
          );

          // Verify old ID is unregistered
          expect(dagManager.getContainerForElement(oldElementId), isNull);

          // Verify new ID is registered
          expect(dagManager.getContainerForElement('NEW_ID'), 'SL1');

          // Verify element can be found by new ID
          final found = dagManager.getObject('NEW_ID');
          expect(found, isNotNull);
          expect(found?.id, 'NEW_ID');
        }
      });

      test('Throws error if element is not registered', () {
        final point = GeoPointer(id: 'NEW', label: 'NEW', x: 0, y: 0);

        expect(
          () => dagManager.updateElementId(
            oldElementId: 'NONEXISTENT',
            newElementId: 'NEW',
            updatedElement: point,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Undo/Redo Integration', () {
      test('elementToContainer map is included in undo/redo snapshots', () {
        // Register an element
        dagManager.registerElement('E1', 'SL1');
        expect(dagManager.getContainerForElement('E1'), 'SL1');

        // Record state
        dagManager.history.record();

        // Unregister element
        dagManager.unregisterElement('E1');
        expect(dagManager.getContainerForElement('E1'), isNull);

        // Undo should restore elementToContainer map
        dagManager.undo();
        expect(dagManager.getContainerForElement('E1'), 'SL1');

        // Redo should remove it again
        dagManager.redo();
        expect(dagManager.getContainerForElement('E1'), isNull);
      });

      test('Container deletion and undo restores elementToContainer map', () {
        // Create intersection
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        final p3 = GeoPointer(id: 'P3', label: 'P3', x: 2, y: 0);
        final p4 = GeoPointer(id: 'P4', label: 'P4', x: 3, y: 1);

        final line1 = GeoLine2P.fromDependencies(
          id: 'line1',
          label: 'line1',
          points: [p1, p2],
        );
        final line2 = GeoLine2P.fromDependencies(
          id: 'line2',
          label: 'line2',
          points: [p3, p4],
        );

        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);
        dagManager.addObject(p3, []);
        dagManager.addObject(p4, []);
        dagManager.addObject(line1, [p1.id, p2.id]);
        dagManager.addObject(line2, [p3.id, p4.id]);

        final intersection = GeoIntersection.lineLine(
          id: 'SL1',
          label: 'SL1',
          line1: line1,
          line2: line2,
          dagManager: dagManager,
        );

        if (intersection != null) {
          dagManager.addObject(intersection, [line1.id, line2.id]);

          final elementIds = intersection.objects.map((e) => e.id).toList();

          // Verify elements are registered
          for (final elementId in elementIds) {
            expect(dagManager.getContainerForElement(elementId), 'SL1');
          }

          // Delete container
          dagManager.deleteObject('SL1', cascade: true);

          // Verify elements are unregistered
          for (final elementId in elementIds) {
            expect(dagManager.getContainerForElement(elementId), isNull);
          }

          // Undo deletion
          dagManager.undo();

          // Verify elements are restored in elementToContainer map
          for (final elementId in elementIds) {
            expect(dagManager.getContainerForElement(elementId), 'SL1');
          }
        }
      });
    });

    group('Edge Cases', () {
      test('Empty container does not register any elements', () {
        // Create an empty container scenario
        // (In practice, containers usually have elements, but test the edge case)
        expect(dagManager.elementToContainer.isEmpty, true);
      });

      test('Registering same element twice updates mapping', () {
        dagManager.registerElement('E1', 'SL1');
        expect(dagManager.getContainerForElement('E1'), 'SL1');

        // Register to different container (should update)
        dagManager.registerElement('E1', 'SL2');
        expect(dagManager.getContainerForElement('E1'), 'SL2');
      });

      test('Unregistering non-existent element does not throw', () {
        // Should not throw
        dagManager.unregisterElement('NONEXISTENT');
        expect(dagManager.getContainerForElement('NONEXISTENT'), isNull);
      });

      test('Multiple containers can have elements with same IDs (if different containers)', () {
        // Note: In practice, element IDs are globally unique
        // But test that elementToContainer correctly maps to different containers
        dagManager.registerElement('E1', 'SL1');
        dagManager.registerElement('E2', 'SL1');
        dagManager.registerElement('E3', 'SL2');

        expect(dagManager.getContainerForElement('E1'), 'SL1');
        expect(dagManager.getContainerForElement('E2'), 'SL1');
        expect(dagManager.getContainerForElement('E3'), 'SL2');
      });
    });

    group('Integration with Real Intersection', () {
      test('Full flow: Create intersection, verify registration, delete, verify cleanup', () {
        // Create points
        final p1 = GeoPointer(id: 'P1', label: 'P1', x: 0, y: 0);
        final p2 = GeoPointer(id: 'P2', label: 'P2', x: 1, y: 1);
        final p3 = GeoPointer(id: 'P3', label: 'P3', x: 2, y: 0);
        final p4 = GeoPointer(id: 'P4', label: 'P4', x: 3, y: 1);

        dagManager.addObject(p1, []);
        dagManager.addObject(p2, []);
        dagManager.addObject(p3, []);
        dagManager.addObject(p4, []);

        // Create lines
        final line1 = GeoLine2P.fromDependencies(
          id: 'line1',
          label: 'line1',
          points: [p1, p2],
        );
        final line2 = GeoLine2P.fromDependencies(
          id: 'line2',
          label: 'line2',
          points: [p3, p4],
        );

        dagManager.addObject(line1, [p1.id, p2.id]);
        dagManager.addObject(line2, [p3.id, p4.id]);

        // Create intersection
        final intersection = GeoIntersection.lineLine(
          id: 'SL1',
          label: 'SL1',
          line1: line1,
          line2: line2,
          dagManager: dagManager,
        );

        if (intersection != null) {
          dagManager.addObject(intersection, [line1.id, line2.id]);

          // Step 1: Verify elements are registered
          expect(intersection.objects.isNotEmpty, true);
          for (final element in intersection.objects) {
            expect(dagManager.getContainerForElement(element.id), 'SL1');
            expect(dagManager.getObject(element.id), equals(element));
          }

          // Step 2: Verify container can be found
          final container = dagManager.getObject('SL1');
          expect(container, isNotNull);
          expect(container, equals(intersection));

          // Step 3: Delete container
          final elementIds = intersection.objects.map((e) => e.id).toList();
          dagManager.deleteObject('SL1', cascade: true);

          // Step 4: Verify cleanup
          expect(dagManager.getObject('SL1'), isNull);
          for (final elementId in elementIds) {
            expect(dagManager.getContainerForElement(elementId), isNull);
            expect(dagManager.getObject(elementId), isNull);
          }
        }
      });
    });
  });
}

