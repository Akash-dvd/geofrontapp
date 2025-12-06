import 'package:flutter_test/flutter_test.dart';
import 'package:geodraw/geodraw.dart';

void main() {
  group('GeoPoint Tests', () {
    test('GeoPointer creates free point correctly', () {
      final point = GeoPointer(id: 'p1', label: 'A', x: 10, y: 20);

      expect(point.id, 'p1');
      expect(point.label, 'A');
      expect(point.x, 10);
      expect(point.y, 20);
      expect(point.dependencies, isEmpty);
      expect(point.visible, true);
    });

    test('GeoPointer calculates distance correctly', () {
      final point = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);

      final distance = point.distanceTo(const Offset(3, 4));
      expect(distance, 5.0);
    });

    test('GeoMidpoint calculates correctly from two points', () {
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 10, y: 10);

      final midpoint = GeoMidpoint.fromPoints(
        id: 'm1',
        label: 'M',
        p1: p1,
        p2: p2,
      );

      expect(midpoint.x, 5);
      expect(midpoint.y, 5);
      expect(midpoint.dependencies, ['p1', 'p2']);
    });

    test('GeoPoint contains works correctly', () {
      final point = GeoPointer(id: 'p1', label: 'A', x: 10, y: 10);

      expect(point.contains(const Offset(10, 10)), true);
      expect(point.contains(const Offset(12, 12)), true);
      expect(point.contains(const Offset(20, 20)), false);
    });
  });

  group('Midpoint Command Schema', () {
    test('Schema accepts points or segment inputs', () {
      final registry = CommandRegistry.standard;
      final midpointDef = registry.definitionByName('midpoint');

      expect(midpointDef, isNotNull, reason: 'Midpoint command is registered');
      final schema = midpointDef!.schema;

      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 4, y: 0);
      final segment = GeoSegment2P.fromDependencies(
        id: 's1',
        label: 'AB',
        points: [p1, p2],
      );

      expect(schema.validate([p1, p2]).isValid, isTrue);
      expect(schema.validate([p1, p2, 'M']).isValid, isTrue);
      expect(schema.validate([segment]).isValid, isTrue);
      expect(schema.validate([segment, 'M']).isValid, isTrue);
      expect(schema.validate([p1]).isValid, isFalse);
    });

    test('Midpoint command resolves segment endpoints through DAG', () async {
      final registry = CommandRegistry.standard;
      final midpointDef = registry.definitionByName('midpoint');
      expect(midpointDef, isNotNull);

      final dag = DAGManager();
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 6, y: 0);
      dag.addObject(p1, []);
      dag.addObject(p2, []);

      final segment = GeoSegment2P.fromDependencies(
        id: 's1',
        label: 'AB',
        points: [p1, p2],
      );
      dag.addObject(segment, [p1.id, p2.id]);

      final context = CommandExecutionContext(dagManager: dag);
      final result = await midpointDef!.run(context, [segment]);

      expect(result.success, isTrue);
      expect(result.object, isA<GeoMidpoint>());

      final midpoint = dag.getObject(result.objectId ?? '') as GeoMidpoint?;
      expect(midpoint, isNotNull);
      expect(midpoint!.dependencies, [p1.id, p2.id]);
    });
  });

  group('GeoLine Tests', () {
    test('GeoLine2P creates line correctly from two points', () {
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 10, y: 10);

      final line = GeoLine2P.fromPoints(id: 'l1', label: 'AB', p1: p1, p2: p2);

      expect(line.id, 'l1');
      expect(line.label, 'AB');
      expect(line.dependencies, ['p1', 'p2']);
    });

    test('GeoLine calculates distance to point correctly', () {
      // Horizontal line at y = 5
      final p1 = GeoPointer(id: 'p1', label: 'A', x: -10, y: 5);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 10, y: 5);

      final line = GeoLine2P.fromPoints(
        id: 'l1',
        label: 'L',
        p1: p1,
        p2: p2,
      );

      final distance = line.distanceTo(const Offset(10, 10));
      expect(distance, 5.0);
    });
  });

  group('GeoCircle Tests', () {
    test('GeoCircle2P creates circle correctly', () {
      final center = GeoPointer(id: 'c', label: 'C', x: 0, y: 0);
      final point = GeoPointer(id: 'p', label: 'P', x: 3, y: 4);

      final circle = GeoCircle2P.fromPoints(
        id: 'circ1',
        label: 'Circle',
        center: center,
        pointOnCircle: point,
      );

      expect(circle.radius, 5.0);
      expect(circle.centerX, 0);
      expect(circle.centerY, 0);
    });

    test('GeoCircle3P creates circle through three points', () {
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 10, y: 0);
      final p3 = GeoPointer(id: 'p3', label: 'C', x: 5, y: 5);

      final circle = GeoCircle3P.fromPoints(
        id: 'circ1',
        label: 'Circle',
        p1: p1,
        p2: p2,
        p3: p3,
      );

      expect(circle, isNotNull);
      expect(circle!.centerX, closeTo(5, 0.1));
    });

    test('GeoCircle contains works correctly', () {
      final center = GeoPointer(id: 'p1', label: 'C', x: 0, y: 0);
      final pointOnCircle = GeoPointer(id: 'p2', label: 'P', x: 10, y: 0);

      final circle = GeoCircle2P.fromPoints(
        id: 'c1',
        label: 'C',
        center: center,
        pointOnCircle: pointOnCircle,
      );

      expect(circle.contains(const Offset(0, 0)), false); // Not filled
      expect(circle.contains(const Offset(10, 0)), true); // On circumference
    });
  });

  group('GeoArc Tests', () {
    test('GeoArc3P creates arc through three points', () {
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 5, y: 5);
      final p3 = GeoPointer(id: 'p3', label: 'C', x: 10, y: 0);

      final arc = GeoArc3P.fromDependencies(
        id: 'arc1',
        label: 'Arc',
        points: [p1, p2, p3],
      );

      expect(arc, isNotNull);
      expect(arc!.dependencies, ['p1', 'p2', 'p3']);
      expect(arc.contains(p2.position), true);
      expect(arc.length(), greaterThan(0));
    });
  });

  group('GeoSegment Tests', () {
    test('GeoSegment2P creates segment through two points', () {
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 6, y: 8);

      final segment = GeoSegment2P.fromDependencies(
        id: 'seg1',
        label: 'AB',
        points: [p1, p2],
      );

      expect(segment.dependencies, ['p1', 'p2']);
      expect(segment.usesDirectSweep, isTrue);
      expect(segment.length(), closeTo(10, 1e-6));
      expect(segment.contains(const Offset(3, 4)), isTrue);
      expect(segment.type, 'GeoSegment2P');
    });
  });

  group('DAGManager Tests', () {
    test('DAGManager adds and retrieves objects', () {
      final dag = DAGManager();
      final point = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);

      final id = dag.addObject(point, []);

      expect(id, 'p1');
      expect(dag.getObject('p1'), point);
      expect(dag.nodeCount, 1);
    });

    test('DAGManager handles dependencies correctly', () {
      final dag = DAGManager();
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 10, y: 10);

      dag.addObject(p1, []);
      dag.addObject(p2, []);

      final line = GeoLine2P.fromPoints(id: 'l1', label: 'AB', p1: p1, p2: p2);
      dag.addObject(line, ['p1', 'p2']);

      final lineNode = dag.getNode('l1');
      expect(lineNode, isNotNull);
      expect(lineNode!.parentIds, ['p1', 'p2']);
      expect(lineNode.depth, 1);
    });

    test('DAGManager detects invalid dependencies', () {
      final dag = DAGManager();
      final p1 = GeoPointer(id: 'p1', label: 'A', x: -5, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 5, y: 0);

      final line = GeoLine2P.fromPoints(
        id: 'l1',
        label: 'L',
        p1: p1,
        p2: p2,
      );

      expect(() => dag.addObject(line, ['p1', 'p2']), throwsArgumentError);
    });

    test('DAGManager deletes objects correctly', () {
      final dag = DAGManager();
      final point = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);

      dag.addObject(point, []);
      expect(dag.nodeCount, 1);

      dag.deleteObject('p1');
      expect(dag.nodeCount, 0);
    });

    test('DAGManager prevents deletion of objects with dependencies', () {
      final dag = DAGManager();
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 10, y: 10);

      dag.addObject(p1, []);
      dag.addObject(p2, []);

      final line = GeoLine2P.fromPoints(id: 'l1', label: 'AB', p1: p1, p2: p2);
      dag.addObject(line, ['p1', 'p2']);

      expect(() => dag.deleteObject('p1'), throwsStateError);
    });

    test('DAGManager cascade delete works', () {
      final dag = DAGManager();
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 10, y: 10);

      dag.addObject(p1, []);
      dag.addObject(p2, []);

      final line = GeoLine2P.fromPoints(id: 'l1', label: 'AB', p1: p1, p2: p2);
      dag.addObject(line, ['p1', 'p2']);

      expect(dag.nodeCount, 3);
      dag.deleteObject('p1', cascade: true);
      expect(dag.nodeCount, 1); // Only p2 should remain
    });

    test('DAGManager proximity search works', () {
      final dag = DAGManager();
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 100, y: 100);

      dag.addObject(p1, []);
      dag.addObject(p2, []);

      final nearby = dag.proximitySearch(const Offset(5, 5), threshold: 10);
      expect(nearby.length, 1);
      expect(nearby.first.id, 'p1');
    });

    test('DAGManager topological sort respects depth', () {
      final dag = DAGManager();
      final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'B', x: 10, y: 10);

      dag.addObject(p1, []);
      dag.addObject(p2, []);

      final line = GeoLine2P.fromPoints(id: 'l1', label: 'AB', p1: p1, p2: p2);
      dag.addObject(line, ['p1', 'p2']);

      final midpoint = GeoMidpoint.fromPoints(
        id: 'm1',
        label: 'M',
        p1: p1,
        p2: p2,
      );
      dag.addObject(midpoint, ['p1', 'p2']);

      final sorted = dag.topologicalSort();
      expect(sorted[0].depth, 0);
      expect(sorted[1].depth, 0);
      expect(sorted[2].depth, 1);
      expect(sorted[3].depth, 1);
    });
  });

  group('Intersection Tests', () {
    test('Line-Line intersection calculates correctly', () {
      final dag = DAGManager();
      // Horizontal and vertical lines intersecting at (5, 5)
      final line1 = GeoLine2P.fromPoints(
        id: 'l1',
        label: 'L1',
        p1: GeoPointer(id: 'p1', label: 'A', x: 0, y: 5),
        p2: GeoPointer(id: 'p2', label: 'B', x: 10, y: 5),
      );
      final line2 = GeoLine2P.fromPoints(
        id: 'l2',
        label: 'L2',
        p1: GeoPointer(id: 'p3', label: 'C', x: 5, y: 0),
        p2: GeoPointer(id: 'p4', label: 'D', x: 5, y: 10),
      );

      final intersection = GeoIntersection.lineLine(
        id: 'i1',
        label: 'I',
        line1: line1,
        line2: line2,
        dagManager: dag,
      );

      expect(intersection, isNotNull);
      expect(intersection!.objects.length, 1);
      expect(intersection.objects[0].x, 5.0);
      expect(intersection.objects[0].y, 5.0);
    });

    test('Parallel lines have no intersection', () {
      final dag = DAGManager();
      // Create two parallel horizontal lines (same slope, different y-intercepts)
      final line1 = GeoLine2P.fromPoints(
        id: 'l1',
        label: 'L1',
        p1: GeoPointer(id: 'p1', label: 'A', x: 0, y: 0),
        p2: GeoPointer(id: 'p2', label: 'B', x: 5, y: 0),
      );
      final line2 = GeoLine2P.fromPoints(
        id: 'l2',
        label: 'L2',
        p1: GeoPointer(id: 'p3', label: 'C', x: 0, y: 5),
        p2: GeoPointer(id: 'p4', label: 'D', x: 5, y: 5),
      );

      final intersection = GeoIntersection.lineLine(
        id: 'i1',
        label: '',
        line1: line1,
        line2: line2,
        dagManager: dag,
      );

      // Parallel lines should return null
      expect(intersection, isNull);
    });

    test('Circle-Circle intersection calculates correctly', () {
      final dag = DAGManager();
      final circle1 = GeoCircle2P.fromPoints(
        id: 'c1',
        label: 'C1',
        center: GeoPointer(id: 'p1', label: 'C1', x: 0, y: 0),
        pointOnCircle: GeoPointer(id: 'p2', label: 'P1', x: 5, y: 0),
      );
      final circle2 = GeoCircle2P.fromPoints(
        id: 'c2',
        label: 'C2',
        center: GeoPointer(id: 'p3', label: 'C2', x: 5, y: 0),
        pointOnCircle: GeoPointer(id: 'p4', label: 'P2', x: 10, y: 0),
      );

      final intersection = GeoIntersection.circleCircle(
        id: 'i1',
        label: 'I',
        circle1: circle1,
        circle2: circle2,
        dagManager: dag,
      );

      expect(intersection.objects.length, 2);
    });
  });
}
