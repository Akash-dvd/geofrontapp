import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../canvas_style.dart';
import '../geometry_object.dart';
import '../simple/geo_point.dart';
import '../simple/geo_line.dart';
import '../simple/geo_circle.dart';

/// List of intersection points between two objects
class GeoIntersection extends SimpleGeometryObjectList<GeoPoint> {
  GeoIntersection({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.objects,
    super.color = Colors.orange,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'Intersection requires exactly 2 object dependencies',
       );

  @override
  String get type => 'intersection';

  /// Calculate intersection between line and line
  static GeoIntersection? lineLine({
    required String id,
    required String label,
    required GeoLine line1,
    required GeoLine line2,
    Color color = Colors.orange,
    bool visible = true,
  }) {
    // Solve system: a1*x + b1*y + c1 = 0, a2*x + b2*y + c2 = 0
    final det = line1.a * line2.b - line1.b * line2.a;

    if (det.abs() < 0.001) {
      // Lines are parallel
      return null;
    }

    final x = (line1.b * line2.c - line2.b * line1.c) / det;
    final y = (line2.a * line1.c - line1.a * line2.c) / det;

    final point = GeoPointer(
      id: '${id}_0',
      label: label,
      x: x,
      y: y,
      color: color,
      visible: visible,
    );

    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [line1.id, line2.id],
      objects: [point],
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between line and circle
  static GeoIntersection lineCircle({
    required String id,
    required String label,
    required GeoLine line,
    required GeoCircle circle,
    Color color = Colors.orange,
    bool visible = true,
  }) {
    // Substitute line equation into circle equation
    // This is a simplified placeholder
    final points = <GeoPoint>[];

    // Complex calculation would go here
    // For now, return empty intersection

    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [line.id, circle.id],
      objects: points,
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between circle and circle
  static GeoIntersection circleCircle({
    required String id,
    required String label,
    required GeoCircle circle1,
    required GeoCircle circle2,
    Color color = Colors.orange,
    bool visible = true,
  }) {
    final points = <GeoPoint>[];

    final dx = circle2.centerX - circle1.centerX;
    final dy = circle2.centerY - circle1.centerY;
    final d = math.sqrt(dx * dx + dy * dy);

    // Check if circles intersect
    if (d > circle1.radius + circle2.radius ||
        d < (circle1.radius - circle2.radius).abs() ||
        d < 0.001) {
      // No intersection
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [circle1.id, circle2.id],
        objects: points,
        color: color,
        visible: visible,
      );
    }

    // Calculate intersection points
    final a =
        (circle1.radius * circle1.radius -
            circle2.radius * circle2.radius +
            d * d) /
        (2 * d);
    final h = math.sqrt(circle1.radius * circle1.radius - a * a);

    final px = circle1.centerX + a * dx / d;
    final py = circle1.centerY + a * dy / d;

    final x1 = px + h * dy / d;
    final y1 = py - h * dx / d;
    final x2 = px - h * dy / d;
    final y2 = py + h * dx / d;

    points.add(
      GeoPointer(
        id: '${id}_0',
        label: '${label}_1',
        x: x1,
        y: y1,
        color: color,
        visible: visible,
      ),
    );

    if (h.abs() > 0.001) {
      points.add(
        GeoPointer(
          id: '${id}_1',
          label: '${label}_2',
          x: x2,
          y: y2,
          color: color,
          visible: visible,
        ),
      );
    }

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
  }) {
    final overrides = resolveStyleOverrides(style);
    final resolvedColor = resolveColor(color, style);
    return GeoIntersection(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      objects: objects ?? this.objects,
      color: resolvedColor,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }
}

/// List of tangent lines from a point to a circle or between circles
class GeoTangent extends SimpleGeometryObjectList<GeoLine> {
  GeoTangent({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.objects,
    super.color = Colors.pink,
    super.visible,
    super.styleOverrides,
  });

  @override
  String get type => 'tangent';

  @override
  GeoTangent copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<GeoLine>? objects,
    Color? color,
    bool? visible,
    CanvasStyle? style,
  }) {
    final overrides = resolveStyleOverrides(style);
    final resolvedColor = resolveColor(color, style);
    return GeoTangent(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      objects: objects ?? this.objects,
      color: resolvedColor,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }
}
