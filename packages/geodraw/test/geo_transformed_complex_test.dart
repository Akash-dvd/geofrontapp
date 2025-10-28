import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:geocalc/Multivector.dart';
import 'package:geodraw/geodraw.dart';
import 'package:geodraw/models/transforms/transformation_engine.dart';

void main() {
  group('TransformationEngine.transformComplex', () {
    test('rotating a segment keeps it a segment with rotated endpoints', () {
      final center = GeoPointer(id: 'c', label: 'C', x: 0, y: 0);
      final start = GeoPointer(id: 'p1', label: 'P1', x: 1, y: 0);
      final end = GeoPointer(id: 'p2', label: 'P2', x: 1, y: 1);

      final segment = GeoSegment2P.fromDependencies(
        id: 'seg1',
        label: 'S1',
        points: [start, end],
      );

      final rotor = constructRotationOperator(center.multivector, math.pi / 2);
      final rotate = GeoRotate(
        id: 'rot1',
        label: 'Rotate 90',
        dependencies: [center.id],
        multivector: rotor,
        centerPointId: center.id,
        angle: math.pi / 2,
      );

      final result = TransformationEngine.transformComplex(
        source: segment,
        transform: rotate,
      );

      expect(result.kind, ComplexTransformKind.segment);
      expect(result.boundary.multivector.isLine(), isTrue);

      final transformedStart = result.boundary.startPoint;
      final transformedEnd = result.boundary.endPoint;

      expect(transformedStart.x.isFinite, isTrue);
      expect(transformedStart.y.isFinite, isTrue);
      expect(transformedEnd.x.isFinite, isTrue);
      expect(transformedEnd.y.isFinite, isTrue);

      final startChanged =
          (transformedStart.x - start.x).abs() > 1e-6 ||
          (transformedStart.y - start.y).abs() > 1e-6;
      final endChanged =
          (transformedEnd.x - end.x).abs() > 1e-6 ||
          (transformedEnd.y - end.y).abs() > 1e-6;

      expect(startChanged, isTrue);
      expect(endChanged, isTrue);
    });
  });

  group('GeoTransSegment', () {
    test('rebuild promotes segment to arc under inversion', () {
      final center = GeoPointer(id: 'c', label: 'C', x: 0, y: 0);
      final start = GeoPointer(id: 'p1', label: 'P1', x: 2, y: 1);
      final end = GeoPointer(id: 'p2', label: 'P2', x: -1, y: 2);

      final segment = GeoSegment2P.fromDependencies(
        id: 'seg1',
        label: 'S1',
        points: [start, end],
      );

      final circle = constructCircleFromCenterAndRadius(center.multivector, 2);
      final inversionOperator = constructCircleReflectionOperator(circle);

      final inverse = GeoInverse(
        id: 'inv1',
        label: 'Inverse',
        dependencies: [center.id],
        multivector: inversionOperator,
        centerPointId: center.id,
        power: 4, // radius squared
      );

      final transSegment = GeoTransSegment(
        id: 'ts1',
        label: 'TransSeg',
        dependencies: [segment.id, inverse.id],
        boundary: segment.boundary,
        sourceObjectId: segment.id,
        transformId: inverse.id,
      );

      final rebuilt = transSegment.rebuildFromParents([
        segment,
        inverse,
        center,
      ]);

      expect(rebuilt, isA<GeoTransArc>());
      final arc = rebuilt as GeoTransArc;
      expect(arc.sourceObjectId, segment.id);
      expect(arc.transformId, inverse.id);
      expect(arc.boundary.multivector.isCircle(), isTrue);
      expect(arc.controlPoint, isNotNull);
    });
  });

  group('GeoTransUnionGeometryObjectList', () {
    test('rebuild transforms child segments with rotation', () {
      final center = GeoPointer(id: 'c', label: 'C', x: 0, y: 0);
      final p1 = GeoPointer(id: 'p1', label: 'P1', x: 0, y: 0);
      final p2 = GeoPointer(id: 'p2', label: 'P2', x: 1, y: 0);
      final p3 = GeoPointer(id: 'p3', label: 'P3', x: 1, y: 1);

      final polyLine = GeoPolyLine(
        id: 'poly1',
        label: 'Chain',
        points: [p1, p2, p3],
      );

      final rotor = constructRotationOperator(center.multivector, math.pi / 2);
      final rotate = GeoRotate(
        id: 'rot1',
        label: 'Rotate 90',
        dependencies: [center.id],
        multivector: rotor,
        centerPointId: center.id,
        angle: math.pi / 2,
      );

      final union = GeoTransUnionGeometryObjectList(
        id: 'u1',
        label: 'TransUnion',
        dependencies: [polyLine.id, rotate.id],
        elements: List<GeometryObject>.from(polyLine.elements),
        sourceObjectId: polyLine.id,
        transformId: rotate.id,
        vertexCountValue: polyLine.vertexCount,
        areaValue: polyLine.area(),
        perimeterValue: polyLine.perimeter(),
      );

      final rebuilt = union.rebuildFromParents([polyLine, rotate]);

      expect(rebuilt, isA<GeoTransUnionGeometryObjectList>());
      final transformedUnion = rebuilt as GeoTransUnionGeometryObjectList;
      expect(transformedUnion.elements.length, polyLine.elements.length);
      expect(
        transformedUnion.elements.every(
          (element) => element is GeoTransSegment,
        ),
        isTrue,
      );
      expect(
        transformedUnion.dependencies,
        containsAll(<String>[polyLine.id, rotate.id]),
      );
    });
  });
}
