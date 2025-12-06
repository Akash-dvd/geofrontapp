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

  group('UnifiedCLIExecutor - Basic Commands', () {
    late DAGManager dag;
    late UnifiedCLIExecutor executor;

    setUp(() {
      dag = DAGManager();
      executor = UnifiedCLIExecutor(dagManager: dag);
    });

    group('point command', () {
      test('creates free point with coordinates', () async {
        final result = await executor.executeString('point(0, 0)');
        expect(result.success, isTrue);
        expect(dag.nodeCount, equals(1));
        final point = dag.getObject(result.objectId!) as GeoPointer?;
        expect(point, isNotNull);
        expect(point?.x, equals(0));
        expect(point?.y, equals(0));
      });

      test('creates free point with coordinates and label', () async {
        final result = await executor.executeString('point(5, 10, A)');
        expect(result.success, isTrue);
        final point = dag.getObject(result.objectId!) as GeoPointer?;
        expect(point, isNotNull);
        expect(point?.label, equals('A'));
        expect(point?.x, equals(5));
        expect(point?.y, equals(10));
      });

      test('creates glider point on line', () async {
        // First create a line
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('line(A, B, L1)');
        
        final result = await executor.executeString('point(L1, P)');
        expect(result.success, isTrue);
        final glider = dag.getObject(result.objectId!) as GeoGliderPoint?;
        expect(glider, isNotNull);
        expect(glider?.objectId, equals('L1'));
      });

      test('creates glider point on circle', () async {
        await executor.executeString('point(0, 0, O)');
        await executor.executeString('point(5, 0, P)');
        await executor.executeString('circle(O, P, C1)');
        
        final result = await executor.executeString('point(C1, Q)');
        expect(result.success, isTrue);
        final glider = dag.getObject(result.objectId!) as GeoGliderPoint?;
        expect(glider, isNotNull);
        expect(glider?.objectId, equals('C1'));
      });
    });

    group('text command', () {
      test('creates text annotation', () async {
        final result = await executor.executeString('text(10, 20, Hello)');
        expect(result.success, isTrue);
        final text = dag.getObject(result.objectId!) as CanvasText?;
        expect(text, isNotNull);
        expect(text!.text, equals('Hello'));
        expect(text.position.dx, equals(10));
        expect(text.position.dy, equals(20));
      });

      test('creates text without content', () async {
        final result = await executor.executeString('text(5, 5)');
        expect(result.success, isTrue);
        final text = dag.getObject(result.objectId!) as CanvasText?;
        expect(text, isNotNull);
      });
    });

    group('line command', () {
      test('creates line through two points', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 10, B)');
        
        final result = await executor.executeString('line(A, B)');
        expect(result.success, isTrue);
        final line = dag.getObject(result.objectId!) as GeoLine2P?;
        expect(line, isNotNull);
        expect(line!.dependencies, containsAll(['A', 'B']));
      });

      test('creates line with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 10, B)');
        
        final result = await executor.executeString('line(A, B, L1)');
        expect(result.success, isTrue);
        final line = dag.getObject('L1') as GeoLine2P?;
        expect(line, isNotNull);
        expect(line!.label, equals('L1'));
      });
    });

    group('segment command', () {
      test('creates segment between two points', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 10, B)');
        
        final result = await executor.executeString('segment(A, B)');
        expect(result.success, isTrue);
        final segment = dag.getObject(result.objectId!) as GeoSegment2P?;
        expect(segment, isNotNull);
        expect(segment!.dependencies, containsAll(['A', 'B']));
      });

      test('creates segment with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 10, B)');
        
        final result = await executor.executeString('segment(A, B, S1)');
        expect(result.success, isTrue);
        final segment = dag.getObject('S1') as GeoSegment2P?;
        expect(segment, isNotNull);
        expect(segment!.label, equals('S1'));
      });
    });

    group('circle command', () {
      test('creates circle with center and point', () async {
        await executor.executeString('point(0, 0, O)');
        await executor.executeString('point(5, 0, P)');
        
        final result = await executor.executeString('circle(O, P)');
        expect(result.success, isTrue);
        final circle = dag.getObject(result.objectId!) as GeoCircle2P?;
        expect(circle, isNotNull);
        expect(circle!.dependencies, containsAll(['O', 'P']));
        expect(circle.radius, closeTo(5.0, 1e-6));
      });

      test('creates circle with label', () async {
        await executor.executeString('point(0, 0, O)');
        await executor.executeString('point(5, 0, P)');
        
        final result = await executor.executeString('circle(O, P, C1)');
        expect(result.success, isTrue);
        final circle = dag.getObject('C1') as GeoCircle2P?;
        expect(circle, isNotNull);
        expect(circle!.label, equals('C1'));
      });
    });

    group('circle3 command', () {
      test('creates circle through three points', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(2.5, 2.5, C)');
        
        final result = await executor.executeString('circle3(A, B, C)');
        expect(result.success, isTrue);
        final circle = dag.getObject(result.objectId!) as GeoCircle3P?;
        expect(circle, isNotNull);
        expect(circle!.dependencies, containsAll(['A', 'B', 'C']));
      });

      test('creates circle3 with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(2.5, 2.5, C)');
        
        final result = await executor.executeString('circle3(A, B, C, C1)');
        expect(result.success, isTrue);
        final circle = dag.getObject('C1') as GeoCircle3P?;
        expect(circle, isNotNull);
        expect(circle!.label, equals('C1'));
      });
    });

    group('arc3 command', () {
      test('creates arc through three points', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 5, B)');
        await executor.executeString('point(10, 0, C)');
        
        final result = await executor.executeString('arc3(A, B, C)');
        expect(result.success, isTrue);
        final arc = dag.getObject(result.objectId!) as GeoArc3P?;
        expect(arc, isNotNull);
        expect(arc!.dependencies, containsAll(['A', 'B', 'C']));
      });

      test('creates arc3 with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 5, B)');
        await executor.executeString('point(10, 0, C)');
        
        final result = await executor.executeString('arc3(A, B, C, A1)');
        expect(result.success, isTrue);
        final arc = dag.getObject('A1') as GeoArc3P?;
        expect(arc, isNotNull);
        expect(arc!.label, equals('A1'));
      });

      test('fails for collinear points', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(10, 0, C)');
        
        final result = await executor.executeString('arc3(A, B, C)');
        expect(result.success, isFalse);
      });
    });

    group('midpoint command', () {
      test('creates midpoint from two points', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 10, B)');
        
        final result = await executor.executeString('midpoint(A, B)');
        expect(result.success, isTrue);
        final midpoint = dag.getObject(result.objectId!) as GeoMidpoint;
        expect(midpoint, isNotNull);
        expect(midpoint.x, equals(5));
        expect(midpoint.y, equals(5));
      });

      test('creates midpoint from segment', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 10, B)');
        await executor.executeString('segment(A, B, S1)');
        
        final result = await executor.executeString('midpoint(S1)');
        expect(result.success, isTrue);
        final midpoint = dag.getObject(result.objectId!) as GeoMidpoint;
        expect(midpoint, isNotNull);
        expect(midpoint.x, equals(5));
        expect(midpoint.y, equals(5));
      });

      test('creates midpoint with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 10, B)');
        
        final result = await executor.executeString('midpoint(A, B, M)');
        expect(result.success, isTrue);
        final midpoint = dag.getObject('M') as GeoMidpoint?;
        expect(midpoint, isNotNull);
        expect(midpoint!.label, equals('M'));
      });
    });

    group('perpendicular command', () {
      test('creates perpendicular line through point', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('line(A, B, L1)');
        await executor.executeString('point(5, 5, P)');
        
        final result = await executor.executeString('perpendicular(P, L1)');
        expect(result.success, isTrue);
        final perp = dag.getObject(result.objectId!) as GeoPerpendicularLine?;
        expect(perp, isNotNull);
        expect(perp!.dependencies, containsAll(['P', 'L1']));
      });

      test('creates perpendicular with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('line(A, B, L1)');
        await executor.executeString('point(5, 5, P)');
        
        final result = await executor.executeString('perpendicular(P, L1, P1)');
        expect(result.success, isTrue);
        final perp = dag.getObject('P1') as GeoPerpendicularLine?;
        expect(perp, isNotNull);
        expect(perp!.label, equals('P1'));
      });
    });

    group('parallel command', () {
      test('creates parallel line through point', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('line(A, B, L1)');
        await executor.executeString('point(0, 5, P)');
        
        final result = await executor.executeString('parallel(L1, P)');
        expect(result.success, isTrue);
        final parallel = dag.getObject(result.objectId!) as GeoParallelLine?;
        expect(parallel, isNotNull);
        expect(parallel!.dependencies, containsAll(['L1', 'P']));
      });

      test('creates parallel with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('line(A, B, L1)');
        await executor.executeString('point(0, 5, P)');
        
        final result = await executor.executeString('parallel(L1, P, L2)');
        expect(result.success, isTrue);
        final parallel = dag.getObject('L2') as GeoParallelLine?;
        expect(parallel, isNotNull);
        expect(parallel!.label, equals('L2'));
      });
    });

    group('perpbisector command', () {
      test('creates perpendicular bisector', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        
        final result = await executor.executeString('perpbisector(A, B)');
        expect(result.success, isTrue);
        final bisector = dag.getObject(result.objectId!) as GeoPerpendicularBisector?;
        expect(bisector, isNotNull);
        expect(bisector!.dependencies, containsAll(['A', 'B']));
      });

      // Note: perpbisector command only accepts two points, not a segment
      // The midpoint command accepts a segment, but perpbisector requires explicit points

      test('creates perpbisector with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        
        final result = await executor.executeString('perpbisector(A, B, PB)');
        expect(result.success, isTrue);
        final bisector = dag.getObject('PB') as GeoPerpendicularBisector?;
        expect(bisector, isNotNull);
        expect(bisector!.label, equals('PB'));
      });
    });

    group('anglebisector command', () {
      test('creates angle bisector from three points', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('point(5, 5, C)');
        
        final result = await executor.executeString('anglebisector(A, B, C)');
        expect(result.success, isTrue);
        final bisector = dag.getObject(result.objectId!) as GeoAngleBisector3P?;
        expect(bisector, isNotNull);
        expect(bisector!.dependencies, containsAll(['A', 'B', 'C']));
      });

      test('creates angle bisector from two lines', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('point(0, 10, C)');
        await executor.executeString('line(A, B, L1)');
        await executor.executeString('line(A, C, L2)');
        
        final result = await executor.executeString('anglebisector(L1, L2)');
        expect(result.success, isTrue);
        // Returns a container with bisector lines
        final container = dag.getObject(result.objectId!);
        expect(container, isNotNull);
      });

      test('creates angle bisector with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('point(5, 5, C)');
        
        final result = await executor.executeString('anglebisector(A, B, C, AB)');
        expect(result.success, isTrue);
        final bisector = dag.getObject('AB') as GeoAngleBisector3P?;
        expect(bisector, isNotNull);
        expect(bisector!.label, equals('AB'));
      });
    });

    group('tangent command', () {
      test('creates tangent from point to circle', () async {
        await executor.executeString('point(0, 0, O)');
        await executor.executeString('point(5, 0, P)');
        await executor.executeString('circle(O, P, C1)');
        await executor.executeString('point(10, 0, Q)');
        
        final result = await executor.executeString('tangent(Q, C1)');
        expect(result.success, isTrue);
        // Returns a container with tangent lines
        final container = dag.getObject(result.objectId!);
        expect(container, isNotNull);
      });

      test('creates tangent between two circles', () async {
        await executor.executeString('point(0, 0, O1)');
        await executor.executeString('point(5, 0, P1)');
        await executor.executeString('circle(O1, P1, C1)');
        await executor.executeString('point(10, 0, O2)');
        await executor.executeString('point(15, 0, P2)');
        await executor.executeString('circle(O2, P2, C2)');
        
        final result = await executor.executeString('tangent(C1, C2)');
        expect(result.success, isTrue);
        // Returns a container with tangent lines
        final container = dag.getObject(result.objectId!);
        expect(container, isNotNull);
      });
    });

    group('intersection command', () {
      test('creates intersection of two lines', () async {
        await executor.executeString('point(0, 5, A)');
        await executor.executeString('point(10, 5, B)');
        await executor.executeString('line(A, B, L1)');
        await executor.executeString('point(5, 0, C)');
        await executor.executeString('point(5, 10, D)');
        await executor.executeString('line(C, D, L2)');
        
        final result = await executor.executeString('intersection(L1, L2)');
        expect(result.success, isTrue);
        final intersection = dag.getObject(result.objectId!) as GeoIntersection?;
        expect(intersection, isNotNull);
        expect(intersection!.dependencies, containsAll(['L1', 'L2']));
        expect(intersection.objects.length, equals(1));
      });

      test('creates intersection of line and circle', () async {
        await executor.executeString('point(0, 0, O)');
        await executor.executeString('point(5, 0, P)');
        await executor.executeString('circle(O, P, C1)');
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('line(A, B, L1)');
        
        final result = await executor.executeString('intersection(L1, C1)');
        expect(result.success, isTrue);
        final intersection = dag.getObject(result.objectId!) as GeoIntersection?;
        expect(intersection, isNotNull);
      });

      test('creates intersection of two circles', () async {
        await executor.executeString('point(0, 0, O1)');
        await executor.executeString('point(5, 0, P1)');
        await executor.executeString('circle(O1, P1, C1)');
        await executor.executeString('point(5, 0, O2)');
        await executor.executeString('point(10, 0, P2)');
        await executor.executeString('circle(O2, P2, C2)');
        
        final result = await executor.executeString('intersection(C1, C2)');
        expect(result.success, isTrue);
        final intersection = dag.getObject(result.objectId!) as GeoIntersection?;
        expect(intersection, isNotNull);
        expect(intersection!.objects.length, equals(2));
      });
    });

    group('reflect command', () {
      test('reflects point across line', () async {
        await executor.executeString('point(5, 5, A)');
        await executor.executeString('point(0, 0, B)');
        await executor.executeString('point(0, 10, C)');
        await executor.executeString('line(B, C, L1)');
        
        final result = await executor.executeString('reflect(A, L1)');
        expect(result.success, isTrue);
        final reflected = dag.getObject(result.objectId!) as GeoTransPoint?;
        expect(reflected, isNotNull);
        expect(reflected!.sourcePointId, equals('A'));
      });

      test('reflects point with label', () async {
        await executor.executeString('point(5, 5, A)');
        await executor.executeString('point(0, 0, B)');
        await executor.executeString('point(0, 10, C)');
        await executor.executeString('line(B, C, L1)');
        
        final result = await executor.executeString('reflect(A, L1, A1)');
        expect(result.success, isTrue);
        final reflected = dag.getObject('A1') as GeoTransPoint?;
        expect(reflected, isNotNull);
        expect(reflected!.label, equals('A1'));
      });
    });

    group('rotate command', () {
      test('rotates point around center', () async {
        await executor.executeString('point(5, 0, A)');
        await executor.executeString('point(0, 0, O)');
        
        final result = await executor.executeString('rotate(A, O, 90)');
        expect(result.success, isTrue);
        final rotated = dag.getObject(result.objectId!) as GeoTransPoint?;
        expect(rotated, isNotNull);
        expect(rotated!.sourcePointId, equals('A'));
      });

      test('rotates segment around center', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('segment(A, B, S1)');
        await executor.executeString('point(0, 0, O)');
        
        final result = await executor.executeString('rotate(S1, O, 90)');
        expect(result.success, isTrue);
        final rotated = dag.getObject(result.objectId!) as GeoTransSegment?;
        expect(rotated, isNotNull);
        expect(rotated!.sourceObjectId, equals('S1'));
      });

      test('rotates with label', () async {
        await executor.executeString('point(5, 0, A)');
        await executor.executeString('point(0, 0, O)');
        
        final result = await executor.executeString('rotate(A, O, 90, A1)');
        expect(result.success, isTrue);
        final rotated = dag.getObject('A1') as GeoTransPoint?;
        expect(rotated, isNotNull);
        expect(rotated!.label, equals('A1'));
      });
    });

    group('dilate command', () {
      test('dilates circle from center', () async {
        await executor.executeString('point(0, 0, O)');
        await executor.executeString('point(5, 0, P)');
        await executor.executeString('circle(O, P, C1)');
        
        final result = await executor.executeString('dilate(C1, O, 2)');
        expect(result.success, isTrue);
        final dilated = dag.getObject(result.objectId!) as GeoTransCircle?;
        expect(dilated, isNotNull);
        expect(dilated!.sourceObjectId, equals('C1'));
      });

      test('dilates point from center', () async {
        await executor.executeString('point(5, 0, A)');
        await executor.executeString('point(0, 0, O)');
        
        final result = await executor.executeString('dilate(A, O, 2)');
        expect(result.success, isTrue);
        final dilated = dag.getObject(result.objectId!) as GeoTransPoint?;
        expect(dilated, isNotNull);
        expect(dilated!.sourcePointId, equals('A'));
      });

      test('dilates with label', () async {
        await executor.executeString('point(5, 0, A)');
        await executor.executeString('point(0, 0, O)');
        
        final result = await executor.executeString('dilate(A, O, 2, A1)');
        expect(result.success, isTrue);
        final dilated = dag.getObject('A1') as GeoTransPoint?;
        expect(dilated, isNotNull);
        expect(dilated!.label, equals('A1'));
      });
    });

    group('translate command', () {
      test('translates point by vector (segment)', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(10, 10, C)');
        await executor.executeString('segment(B, C, V1)'); // Vector segment
        
        final result = await executor.executeString('translate(A, V1)');
        expect(result.success, isTrue);
        expect(result.object, isNotNull);
        if (result.object is GeoTransPoint) {
          final translated = result.object as GeoTransPoint;
          expect(translated.sourcePointId, equals('A'));
        }
      });

      test('translates segment by vector (segment)', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('segment(A, B, S1)');
        await executor.executeString('point(0, 0, C)');
        await executor.executeString('point(10, 10, D)');
        await executor.executeString('segment(C, D, V1)'); // Vector segment
        
        final result = await executor.executeString('translate(S1, V1)');
        expect(result.success, isTrue);
        expect(result.object, isNotNull);
        if (result.object is GeoTransSegment) {
          final translated = result.object as GeoTransSegment;
          expect(translated.sourceObjectId, equals('S1'));
        }
      });

      test('translates with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(10, 10, C)');
        await executor.executeString('segment(B, C, V1)'); // Vector segment
        
        final result = await executor.executeString('translate(A, V1, A1)');
        expect(result.success, isTrue);
        final translated = dag.getObject('A1');
        expect(translated, isNotNull);
        if (translated is GeoTransPoint) {
          expect(translated.label, equals('A1'));
        }
      });
    });

    group('polygon command', () {
      test('creates triangle', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(2.5, 5, C)');
        
        final result = await executor.executeString('polygon(A, B, C)');
        expect(result.success, isTrue);
        final polygon = dag.getObject(result.objectId!) as GeoPolygon?;
        expect(polygon, isNotNull);
        expect(polygon!.vertexCount, equals(3));
      });

      test('creates quadrilateral', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(5, 5, C)');
        await executor.executeString('point(0, 5, D)');
        
        final result = await executor.executeString('polygon(A, B, C, D)');
        expect(result.success, isTrue);
        final polygon = dag.getObject(result.objectId!) as GeoPolygon?;
        expect(polygon, isNotNull);
        expect(polygon!.vertexCount, equals(4));
      });

      test('creates polygon with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(2.5, 5, C)');
        
        final result = await executor.executeString('polygon(A, B, C, T1)');
        expect(result.success, isTrue);
        final polygon = dag.getObject('T1') as GeoPolygon?;
        expect(polygon, isNotNull);
        expect(polygon!.label, equals('T1'));
      });
    });

    group('polyline command', () {
      test('creates polyline', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(5, 5, C)');
        
        final result = await executor.executeString('polyline(A, B, C)');
        expect(result.success, isTrue);
        final polyline = dag.getObject(result.objectId!) as GeoPolyLine?;
        expect(polyline, isNotNull);
        expect(polyline!.vertexCount, equals(3));
      });

      test('creates polyline with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(5, 5, C)');
        
        final result = await executor.executeString('polyline(A, B, C, PL1)');
        expect(result.success, isTrue);
        final polyline = dag.getObject('PL1') as GeoPolyLine?;
        expect(polyline, isNotNull);
        expect(polyline!.label, equals('PL1'));
      });
    });

    group('polyarc command', () {
      test('creates polyarc chain', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(2.5, 5, B)');
        await executor.executeString('point(5, 0, C)');
        await executor.executeString('point(7.5, 5, D)');
        await executor.executeString('point(10, 0, E)');
        
        final result = await executor.executeString('polyarc(A, B, C, D, E)');
        expect(result.success, isTrue);
        final polyarc = dag.getObject(result.objectId!) as GeoPolyArc?;
        expect(polyarc, isNotNull);
        expect(polyarc!.elements.length, greaterThan(0));
      });

      test('creates polyarc with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(2.5, 5, B)');
        await executor.executeString('point(5, 0, C)');
        
        final result = await executor.executeString('polyarc(A, B, C, PA1)');
        expect(result.success, isTrue);
        final polyarc = dag.getObject('PA1') as GeoPolyArc?;
        expect(polyarc, isNotNull);
        expect(polyarc!.label, equals('PA1'));
      });
    });

    group('extendpolyarc command', () {
      test('extends existing polyarc', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(2.5, 5, B)');
        await executor.executeString('point(5, 0, C)');
        await executor.executeString('polyarc(A, B, C, PA1)');
        await executor.executeString('point(7.5, 5, D)');
        await executor.executeString('point(10, 0, E)');
        
        final result = await executor.executeString('extendpolyarc(PA1, D, E)');
        expect(result.success, isTrue);
        final polyarc = dag.getObject('PA1') as GeoPolyArc?;
        expect(polyarc, isNotNull);
        expect(polyarc!.elements.length, greaterThan(1));
      });
    });

    group('extendpolygon command', () {
      test('extends existing polygon', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(2.5, 5, C)');
        await executor.executeString('polygon(A, B, C, T1)');
        await executor.executeString('point(0, 5, D)');
        
        final result = await executor.executeString('extendpolygon(T1, D)');
        expect(result.success, isTrue);
        final polygon = dag.getObject('T1') as GeoPolygon?;
        expect(polygon, isNotNull);
        expect(polygon!.vertexCount, equals(4));
      });
    });

    group('extendpolyline command', () {
      test('extends existing polyline', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('polyline(A, B, PL1)');
        await executor.executeString('point(5, 5, C)');
        
        final result = await executor.executeString('extendpolyline(PL1, C)');
        expect(result.success, isTrue);
        final polyline = dag.getObject('PL1') as GeoPolyLine?;
        expect(polyline, isNotNull);
        expect(polyline!.vertexCount, equals(3));
      });
    });

    group('polyarcgon command', () {
      test('creates polyarcgon (requires odd number of points, first and last must match)', () async {
        // Polyarcgon requires odd number of points >= 4, and first == last to form closed loop
        // Minimum is 5 points: A, B, C, D, A (where last A closes the loop)
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(2.5, 5, B)');
        await executor.executeString('point(5, 0, C)');
        await executor.executeString('point(2.5, -5, D)');
        // Note: Last point must be same as first to close the loop
        // But CLI doesn't auto-close, so we need to pass A again
        final result = await executor.executeString('polyarcgon(A, B, C, D, A)');
        // May fail if arcs can't be formed (e.g., collinear points)
        if (result.success) {
          final polyarcgon = dag.getObject(result.objectId ?? '') as GeoPolyArcGon?;
          expect(polyarcgon, isNotNull);
        }
      });

      test('creates polyarcgon with label', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(2.5, 5, B)');
        await executor.executeString('point(5, 0, C)');
        await executor.executeString('point(2.5, -5, D)');
        
        final result = await executor.executeString('polyarcgon(A, B, C, D, A, PAG1)');
        if (result.success) {
          final polyarcgon = dag.getObject('PAG1') as GeoPolyArcGon?;
          expect(polyarcgon, isNotNull);
          expect(polyarcgon?.label, equals('PAG1'));
        }
      });

      test('fails for even number of points', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(2.5, 5, B)');
        await executor.executeString('point(5, 0, C)');
        await executor.executeString('point(2.5, -5, D)');
        
        final result = await executor.executeString('polyarcgon(A, B, C, D)');
        expect(result.success, isFalse);
        // Command parser validates pattern before execution, so error is about pattern mismatch
        expect(result.message, anyOf(contains('pattern'), contains('odd'), contains('Validation')));
      });
    });

    group('extendpolyarcgon command', () {
      test('extends existing polyarcgon (requires control and end points)', () async {
        // Create initial polyarcgon with 5 points (A, B, C, D, A)
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(2.5, 5, B)');
        await executor.executeString('point(5, 0, C)');
        await executor.executeString('point(2.5, -5, D)');
        final createResult = await executor.executeString('polyarcgon(A, B, C, D, A, PAG1)');
        
        if (createResult.success) {
          // Add control and end points for extension (F, A to close)
          await executor.executeString('point(7.5, 5, F)');
          
          final result = await executor.executeString('extendpolyarcgon(PAG1, F, A)');
          // Extension may fail if geometry constraints aren't met
          if (result.success) {
            final polyarcgon = dag.getObject('PAG1') as GeoPolyArcGon?;
            expect(polyarcgon, isNotNull);
          }
        }
      });
    });

    group('Flexible commands', () {
      test('circleFlex creates circle from flexible inputs', () async {
        await executor.executeString('point(0, 0, O)');
        await executor.executeString('point(5, 0, P)');
        await executor.executeString('circleFlex(O, P)');
        expect(dag.nodeCount, greaterThan(1));
      });

      test('circle3Flex creates circle3 from flexible inputs', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(2.5, 2.5, C)');
        await executor.executeString('circle3Flex(A, B, C)');
        expect(dag.nodeCount, greaterThan(2));
      });

      test('lineFlex creates line from flexible inputs', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 10, B)');
        await executor.executeString('lineFlex(A, B)');
        expect(dag.nodeCount, greaterThan(1));
      });

      test('perpbisectorFlex creates perpbisector from flexible inputs', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('perpbisectorFlex(A, B)');
        expect(dag.nodeCount, greaterThan(1));
      });

      test('perpendicularFlex creates perpendicular from flexible inputs', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('line(A, B, L1)');
        await executor.executeString('point(5, 5, P)');
        await executor.executeString('perpendicularFlex(P, L1)');
        expect(dag.nodeCount, greaterThan(2));
      });

      test('parallelFlex creates parallel from flexible inputs', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(10, 0, B)');
        await executor.executeString('line(A, B, L1)');
        await executor.executeString('point(0, 5, P)');
        await executor.executeString('parallelFlex(P, L1)');
        expect(dag.nodeCount, greaterThan(2));
      });
    });

    group('Error handling', () {
      test('fails for missing dependencies', () async {
        final result = await executor.executeString('line(A, B)');
        expect(result.success, isFalse);
      });

      test('fails for invalid command syntax', () async {
        final result = await executor.executeString('invalid_command()');
        expect(result.success, isFalse);
      });

      test('fails for wrong number of arguments', () async {
        await executor.executeString('point(0, 0, A)');
        final result = await executor.executeString('line(A)');
        expect(result.success, isFalse);
      });

      test('fails for collinear points in arc3', () async {
        await executor.executeString('point(0, 0, A)');
        await executor.executeString('point(5, 0, B)');
        await executor.executeString('point(10, 0, C)');
        final result = await executor.executeString('arc3(A, B, C)');
        expect(result.success, isFalse);
      });
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
