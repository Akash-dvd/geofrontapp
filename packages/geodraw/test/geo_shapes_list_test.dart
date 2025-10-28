import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geodraw/geodraw.dart';

GeoPointer _point(String id, double x, double y) =>
    GeoPointer(id: id, label: id.toUpperCase(), x: x, y: y);

void main() {
  group('GeoPolyLine', () {
    test('builds open chain from points', () {
      final p1 = _point('p1', 0, 0);
      final p2 = _point('p2', 3, 0);
      final p3 = _point('p3', 3, 4);

      final polyLine = GeoPolyLine(
        id: 'line1',
        label: 'Line',
        points: [p1, p2, p3],
      );

      expect(polyLine.vertexCount, 3);
      expect(polyLine.points.map((p) => p.id), ['p1', 'p2', 'p3']);
      expect(polyLine.elements.length, 2);
      expect(polyLine.perimeter(), closeTo(7.0, 1e-6));
      expect(polyLine.dependencies.toSet(), {'p1', 'p2', 'p3'});

      final updated = polyLine.copyWith(
        points: [p1, p2, _point('p4', 6, 8)],
        color: Colors.green,
      );

      expect(updated.id, 'line1');
      expect(updated.points.last.id, 'p4');
      expect(updated.dependencies.toSet(), {'p1', 'p2', 'p4'});
  expect(updated.styleOverrides['strokeColor'], isNotNull);
      expect(polyLine.points.last.id, 'p3', reason: 'original remains unchanged');
    });

    test('rejects closed loops in open chains', () {
      final p1 = _point('p1', 0, 0);
      final p2 = _point('p2', 1, 1);

      expect(
        () => GeoPolyLine(id: 'loop', label: 'Loop', points: [p1, p2, p1]),
        throwsArgumentError,
      );
    });
  });

  group('GeoPolygon', () {
    test('computes area and perimeter for rectangle', () {
      final points = [
        _point('p1', 0, 0),
        _point('p2', 4, 0),
        _point('p3', 4, 3),
        _point('p4', 0, 3),
      ];

      final polygon = GeoPolygon(
        id: 'poly1',
        label: 'Rect',
        points: points,
      );

      expect(polygon.vertexCount, 4);
      expect(polygon.area(), closeTo(12, 1e-6));
      expect(polygon.perimeter(), closeTo(14, 1e-6));
      expect(polygon.uniqueVertices.map((p) => p.id).toList(), ['p1', 'p2', 'p3', 'p4']);

  final copy = polygon.copyWith(color: Colors.red);
  expect(copy.styleOverrides['strokeColor'], isNotNull);
  expect(copy.dependencies.toSet(), {'p1', 'p2', 'p3', 'p4'});

      final fromElements = polygon.copyWith(elements: polygon.elements);
      expect(fromElements.uniqueVertices.map((p) => p.id), ['p1', 'p2', 'p3', 'p4']);
    });

    test('requires three unique points minimum', () {
      final p1 = _point('p1', 0, 0);
      final p2 = _point('p2', 1, 0);

      expect(
        () => GeoPolygon(id: 'bad', label: 'Bad', points: [p1, p1, p2]),
        throwsArgumentError,
      );
    });
  });

  group('GeoTriangle', () {
    test('enforces three distinct points', () {
      final p1 = _point('p1', 0, 0);
      final p2 = _point('p2', 1, 0);

      expect(
        () => GeoTriangle(id: 'tri', label: 'Tri', points: [p1, p2, p1]),
        throwsArgumentError,
      );
    });

    test('copyWith updates vertices while keeping dependencies optional', () {
      final p1 = _point('p1', 0, 0);
      final p2 = _point('p2', 1, 0);
      final p3 = _point('p3', 0, 1);
      final triangle = GeoTriangle(
        id: 'tri',
        label: 'Tri',
        points: [p1, p2, p3],
      );

      final updated = triangle.copyWith(
        points: [p1, p2, _point('p4', 1, 1)],
        dependencies: ['p1', 'p2', 'p4'],
      );

      expect(updated.uniqueVertices.map((p) => p.id).toList(), ['p1', 'p2', 'p4']);
      expect(updated.dependencies, ['p1', 'p2', 'p4']);
      expect(triangle.uniqueVertices.map((p) => p.id).toList(), ['p1', 'p2', 'p3']);
    });
  });

  group('GeoRegularPolygon', () {
    test('generates vertices from center and reference point', () {
      final center = _point('c', 0, 0);
      final reference = _point('r', 2, 0);

      final polygon = GeoRegularPolygon2P(
        id: 'reg1',
        label: 'Hex',
        center: center,
        reference: reference,
        sides: 6,
      );

      expect(polygon.vertexCount, 6);
      expect(polygon.dependencies, ['c', 'r']);
      expect(polygon.vertices.length, 7, reason: 'closed chain includes start twice');
    });

    test('generates vertices from base segment', () {
      final p1 = _point('p1', 0, 0);
      final p2 = _point('p2', 4, 0);
      final segment = GeoSegment2P.fromDependencies(
        id: 's1',
        label: 'Base',
        points: [p1, p2],
      );

      final polygon = GeoRegularPolygonSegment(
        id: 'reg2',
        label: 'Square',
        baseSegment: segment,
        sides: 4,
      );

      expect(polygon.vertexCount, 4);
      expect(polygon.dependencies.toSet(), {'s1', 'p1', 'p2'});
      expect(polygon.vertices.length, 5);
    });
  });

  group('GeoPolyArc', () {
    GeoArc3P _arc(
      String id,
      GeoPoint start,
      GeoPoint through,
      GeoPoint end,
    ) {
      final arc = GeoArc3P.fromDependencies(
        id: id,
        label: id.toUpperCase(),
        points: [start, through, end],
      );
      expect(arc, isNotNull, reason: 'arc $id should be constructible');
      return arc!;
    }

    test('builds open chain of arcs', () {
      final p1 = _point('p1', 0, 0);
      final p2 = _point('p2', 1, 2);
      final p3 = _point('p3', 2, 0);
      final p4 = _point('p4', 3, -2);
      final p5 = _point('p5', 4, 0);

      final arc1 = _arc('arc1', p1, p2, p3);
      final arc2 = _arc('arc2', p3, p4, p5);

      final chain = GeoPolyArc(
        id: 'chain',
        label: 'Chain',
        dependencies: ['p1', 'p2', 'p3', 'p4', 'p5'],
        elements: [arc1, arc2],
      );

      expect(chain.vertexCount, 3);
      expect(chain.orderedVertices.map((p) => p.id).toList(), ['p1', 'p3', 'p5']);
      expect(chain.perimeter(), greaterThan(arc1.length()));

  final copy = chain.copyWith(color: Colors.orange);
  expect(copy.styleOverrides['strokeColor'], isNotNull);
  expect(copy.dependencies.toSet(), {'p1', 'p2', 'p3', 'p4', 'p5'});
    });

    test('rejects non-continuous arcs', () {
      final p1 = _point('p1', 0, 0);
      final p2 = _point('p2', 1, 2);
      final p3 = _point('p3', 2, 0);
      final p4 = _point('p4', 3, 1);
      final p5 = _point('p5', 4, 2);
      final p6 = _point('p6', 5, 0);

      final arc1 = GeoArc3P.fromDependencies(
        id: 'arc1',
        label: 'A1',
        points: [p1, p2, p3],
      );
      final arc2 = GeoArc3P.fromDependencies(
        id: 'arc2',
        label: 'A2',
        points: [p4, p5, p6],
      );

      expect(arc1, isNotNull);
      expect(arc2, isNotNull);

      expect(
        () => GeoPolyArc(
          id: 'bad',
          label: 'BadChain',
          dependencies: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
          elements: [arc1!, arc2!],
        ),
        throwsArgumentError,
      );
    });
  });
}
