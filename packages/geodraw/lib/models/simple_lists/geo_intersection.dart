import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../simple/geo_point.dart';
import '../simple/geo_line.dart';
import '../simple/geo_circle.dart';
import '../simple/geo_transformed_simple.dart';
import 'simple_list_utils.dart';

/// List of intersection points between two objects
class GeoIntersection extends GenSimpleGeometryObjectList<GeoPoint> {
  GeoIntersection({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.objects,
    Color color = Colors.orange,
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'Intersection requires exactly 2 object dependencies',
       ),
       super(
         styleOverrides: styleOverridesForType(
           type: GeoIntersection,
           style: style,
           overrides: styleOverrides,
           fallbackColor: color,
         ),
       );

  @override
  String get type => 'intersection';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'count': objects.length};
    return json;
  }

  static GeoIntersection fromJson(Map<String, dynamic> json) {
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final objectsJson = (json['objects'] as List?) ?? const [];
    final points = <GeoPoint>[];

    for (final entry in objectsJson) {
      final map = castJsonObject(entry);
      if (map == null) {
        continue;
      }
      final point = _decodePoint(map);
      if (point != null) {
        points.add(point);
      }
    }

    final defaults = CanvasStyleDefaults.instance.resolveForType(
      GeoIntersection,
    );
    final overrides = styleOverridesFromJson(json);

    return GeoIntersection(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? '',
      dependencies: deps,
      objects: points,
      visible: json['visible'] as bool? ?? true,
      color: defaults.strokeColor,
      styleOverrides: overrides,
    );
  }

  /// Calculate intersection between line and line using multivector algebra.
  static GeoIntersection? lineLine({
    required String id,
    required String label,
    required GeoLine line1,
    required GeoLine line2,
    Color color = Colors.orange,
    bool visible = true,
  }) {
    debugPrint(
      '[GeoIntersection] Computing line-line intersection between ${line1.label} and ${line2.label}',
    );
    final wedge = line1.multivector ^ line2.multivector;
    if (wedge.isZero()) {
      debugPrint('[GeoIntersection] Lines are parallel, no intersection.');
      return null;
    }

    final intersectionMv = constructLineLineIntersection(
      line1.multivector,
      line2.multivector,
    );

    if (!isPointOnLine(intersectionMv, line1.multivector) ||
        !isPointOnLine(intersectionMv, line2.multivector)) {
      debugPrint('[GeoIntersection] Computed point is not on both lines.');
      return null;
    }

    if (!_isFinitePoint(intersectionMv)) {
      debugPrint('[GeoIntersection] Intersection is at infinity, skipping.');
      return null;
    }

    final point = _pointFromMultivector(
      idSeed: id,
      index: 0,
      label: label,
      multivector: intersectionMv,
      color: color,
      visible: visible,
    );

    debugPrint('[GeoIntersection] Line-line intersection created with 1 point.');
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [line1.id, line2.id],
      objects: [point],
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between line and circle using multivector algebra.
  static GeoIntersection lineCircle({
    required String id,
    required String label,
    required GeoLine line,
    required GeoCircle circle,
    Color color = Colors.orange,
    bool visible = true,
  }) {
    debugPrint(
      '[GeoIntersection] Computing line-circle intersection between ${line.label} and ${circle.label}',
    );
    List<Multivector> intersections;
    try {
      intersections = constructLineCircleIntersection(
        line.multivector,
        circle.multivector,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[GeoIntersection] Error while solving line-circle intersection: $error\n$stackTrace',
      );
      rethrow;
    }

    if (intersections.isEmpty) {
      debugPrint(
        '[GeoIntersection] No intersection points returned from solver for ${line.label} × ${circle.label}.',
      );
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [line.id, circle.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }

    final points = <GeoPoint>[];

    for (final candidate in intersections) {
      debugPrint('  • Candidate MV: $candidate');
      final candidateNorm = (candidate | candidate).s;
      if (candidateNorm.isNaN || candidateNorm.isInfinite || candidateNorm == 0) {
        debugPrint('    ↳ candidate has invalid norm ($candidateNorm), skipping.');
        continue;
      }

      if (!_isFinitePoint(candidate)) {
        continue;
      }
      if (!isPointOnLine(candidate, line.multivector) ||
          !isPointOnCircle(candidate, circle.multivector)) {
        continue;
      }
      if (_containsPoint(points, candidate)) {
        continue;
      }
      final displayLabel = intersections.length == 1
          ? label
          : '${label}_${points.length + 1}';
      points.add(
        _pointFromMultivector(
          idSeed: id,
          index: points.length,
          label: displayLabel,
          multivector: candidate,
          color: color,
          visible: visible,
        ),
      );
    }

    debugPrint(
      '[GeoIntersection] Line-circle intersection produced ${points.length} point(s).',
    );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [line.id, circle.id],
      objects: points,
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between circle and circle using multivector algebra.
  static GeoIntersection circleCircle({
    required String id,
    required String label,
    required GeoCircle circle1,
    required GeoCircle circle2,
    Color color = Colors.orange,
    bool visible = true,
  }) {
    debugPrint(
      '[GeoIntersection] Computing circle-circle intersection between ${circle1.label} and ${circle2.label}',
    );
    List<Multivector> intersections;
    try {
      intersections = constructCircleCircleIntersection(
        circle1.multivector,
        circle2.multivector,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[GeoIntersection] Error while solving circle-circle intersection: $error\n$stackTrace',
      );
      rethrow;
    }

    if (intersections.isEmpty) {
      debugPrint(
        '[GeoIntersection] Circles ${circle1.label} and ${circle2.label} do not intersect (no real solutions).',
      );
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [circle1.id, circle2.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }

    final points = <GeoPoint>[];

    for (final candidate in intersections) {
      debugPrint('  • Candidate MV: $candidate');
      if (!_isFinitePoint(candidate)) {
        debugPrint('    ↳ discarded (not finite)');
        continue;
      }
      if (!isPointOnCircle(candidate, circle1.multivector) ||
          !isPointOnCircle(candidate, circle2.multivector)) {
        debugPrint('    ↳ discarded (not on both circles)');
        continue;
      }
      if (_containsPoint(points, candidate)) {
        debugPrint('    ↳ duplicate point, skipping');
        continue;
      }
      final displayLabel = intersections.length == 1
          ? label
          : '${label}_${points.length + 1}';
      points.add(
        _pointFromMultivector(
          idSeed: id,
          index: points.length,
          label: displayLabel,
          multivector: candidate,
          color: color,
          visible: visible,
        ),
      );
    }

    debugPrint(
      '[GeoIntersection] Circle-circle intersection produced ${points.length} point(s).',
    );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [circle1.id, circle2.id],
      objects: points,
      color: color,
      visible: visible,
    );
  }

  @override
  GeoIntersection copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<GeoPoint>? objects,
    Color? color,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? styleOverridesForType(type: GeoIntersection, style: style)
            : color != null
            ? styleOverridesForType(type: GeoIntersection, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;
    return GeoIntersection(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      objects: objects ?? this.objects,
      visible: visible ?? this.visible,
      styleOverrides: resolvedOverrides,
    );
  }
}

const double _intersectionTolerance = 1e-8;

GeoPointer _pointFromMultivector({
  required String idSeed,
  required int index,
  required String label,
  required Multivector multivector,
  required Color color,
  required bool visible,
}) {
  return GeoPointer(
    id: '${idSeed}_$index',
    label: label,
    x: multivector.e1,
    y: multivector.e2,
    visible: visible,
    styleOverrides: styleOverridesForType(
      type: GeoPointer,
      fallbackColor: color,
    ),
  );
}

bool _isFinitePoint(Multivector multivector) {
  return multivector.e1.isFinite && multivector.e2.isFinite;
}

bool _containsPoint(List<GeoPoint> points, Multivector candidate) {
  for (final point in points) {
    if ((point.x - candidate.e1).abs() <= _intersectionTolerance &&
        (point.y - candidate.e2).abs() <= _intersectionTolerance) {
      return true;
    }
  }
  return false;
}

GeoPoint? _decodePoint(Map<String, dynamic> json) {
  switch (json['type'] as String?) {
    case 'GeoPointer':
      return GeoPointer.fromJson(json);
    case 'GeoMidpoint':
      return GeoMidpoint.fromJson(json);
    case 'GeoInvPoint':
      return GeoTransPoint.fromJson(json);
    case 'GeoTransPoint':
      return GeoTransPoint.fromJson(json);
    default:
      return null;
  }
}
