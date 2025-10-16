import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../geometry_object.dart';
import 'geo_point.dart';

/// Abstract base class for all circle types
abstract class GeoCircle extends SimpleGeometryObject {
  /// Rendering thickness
  final double thickness;

  /// Whether to fill the circle
  final bool filled;

  GeoCircle({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    this.thickness = 2.0,
    this.filled = false,
    super.color = Colors.green,
    super.visible,
    super.styleOverrides,
  });

  /// Center x coordinate derived from multivector
  double get centerX => multivector.e1;

  /// Center y coordinate derived from multivector
  double get centerY => multivector.e2;

  /// Radius derived from multivector norm
  double get radius {
    final normOpt = multivector.norm();
    return normOpt.fold(() => 0.0, (normValue) => math.sqrt(normValue.abs()));
  }

  Offset get center => Offset(centerX, centerY);

  @override
  void draw(Canvas canvas, Paint paint) {
    if (!visible) return;

    final circlePaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke;

    canvas.drawCircle(center, radius, circlePaint);

    // Draw label
    if (label.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            backgroundColor: Colors.white.withOpacity(0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center + Offset(radius + 5, -textPainter.height / 2),
      );
    }
  }

  @override
  bool contains(Offset position) {
    final dist = (position - center).distance;
    return filled ? dist <= radius : (dist - radius).abs() <= thickness;
  }

  @override
  Rect getBounds() {
    return Rect.fromCircle(center: center, radius: radius + thickness);
  }

  @override
  double distanceTo(Offset point) {
    // Convert the offset to a Multivector point
    final pointMv = constructFreePoint(point.dx, point.dy);
    // Use Multivector-based distance calculation
    return distancePointToCircle(pointMv, multivector);
  }

  @override
  bool intersects(SimpleGeometryObject other) {
    if (other is GeoCircle) {
      final centerDist = (center - other.center).distance;
      return centerDist <= (radius + other.radius) &&
          centerDist >= (radius - other.radius).abs();
    }
    return other.intersects(this);
  }

  @override
  List<Object?> get props => [...super.props, thickness, filled];
}

/// Circle defined by center point and a point on the circumference
class GeoCircle2P extends GeoCircle {
  GeoCircle2P({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.multivector,
    super.thickness,
    super.filled,
    super.color,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'Circle from 2 points requires exactly 2 point dependencies',
       );

  /// Create circle from center and point on circumference
  static GeoCircle2P fromPoints({
    required String id,
    required String label,
    required GeoPoint center,
    required GeoPoint pointOnCircle,
    double thickness = 2.0,
    bool filled = false,
    Color color = Colors.green,
    bool visible = true,
  }) {
    // Calculate multivector using definitions.dart placeholder
    final mv = constructCircleFromCenterAndPoint(
      center.multivector,
      pointOnCircle.multivector,
    );

    return GeoCircle2P(
      id: id,
      label: label,
      dependencies: [center.id, pointOnCircle.id],
      multivector: mv,
      thickness: thickness,
      filled: filled,
      color: color,
      visible: visible,
    );
  }

  @override
  GeoCircle2P copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? centerX,
    double? centerY,
    double? radius,
    double? thickness,
    bool? filled,
    Color? color,
    bool? visible,
    CanvasStyle? style,
  }) {
    final overrides = resolveStyleOverrides(style);
    final resolvedColor = resolveColor(color, style);
    return GeoCircle2P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      thickness: thickness ?? this.thickness,
      filled: filled ?? this.filled,
      color: resolvedColor,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoCircle2P';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'centerX': centerX,
      'centerY': centerY,
      'radius': radius,
      'thickness': thickness,
      'filled': filled,
    };
    return json;
  }

  static GeoCircle2P fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final styleOverrides = GeometryObject.extractStyleOverrides(json);
    final color = GeometryObject.colorFromJson(json, Colors.green);
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoCircle2P(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector:
          Multivector.zero(), // Will be recalculated during DAG reconstruction
      thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
      filled: props['filled'] as bool? ?? false,
      color: color,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }
}

/// Circle through three points
class GeoCircle3P extends GeoCircle {
  GeoCircle3P({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 3 dependencies
    required super.multivector,
    super.thickness,
    super.filled,
    super.color,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 3,
         'Circle through 3 points requires exactly 3 point dependencies',
       );

  /// Create circle through three points
  static GeoCircle3P? fromPoints({
    required String id,
    required String label,
    required GeoPoint p1,
    required GeoPoint p2,
    required GeoPoint p3,
    double thickness = 2.0,
    bool filled = false,
    Color color = Colors.green,
    bool visible = true,
  }) {
    // Check if points are collinear before creating multivector
    final d =
        2 *
        (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y));

    if (d.abs() < 0.001) {
      // Points are collinear
      return null;
    }

    // Calculate multivector using definitions.dart placeholder
    final mv = constructCircleThrough3Points(
      p1.multivector,
      p2.multivector,
      p3.multivector,
    );

    return GeoCircle3P(
      id: id,
      label: label,
      dependencies: [p1.id, p2.id, p3.id],
      multivector: mv,
      thickness: thickness,
      filled: filled,
      color: color,
      visible: visible,
    );
  }

  @override
  GeoCircle3P copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? centerX,
    double? centerY,
    double? radius,
    double? thickness,
    bool? filled,
    Color? color,
    bool? visible,
    CanvasStyle? style,
  }) {
    final overrides = resolveStyleOverrides(style);
    final resolvedColor = resolveColor(color, style);
    return GeoCircle3P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      thickness: thickness ?? this.thickness,
      filled: filled ?? this.filled,
      color: resolvedColor,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoCircle3P';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'centerX': centerX,
      'centerY': centerY,
      'radius': radius,
      'thickness': thickness,
      'filled': filled,
    };
    return json;
  }

  static GeoCircle3P fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final styleOverrides = GeometryObject.extractStyleOverrides(json);
    final color = GeometryObject.colorFromJson(json, Colors.green);
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoCircle3P(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector:
          Multivector.zero(), // Will be recalculated during DAG reconstruction
      thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
      filled: props['filled'] as bool? ?? false,
      color: color,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }
}

/// Circle after inversion transformation
class GeoInvCircle extends GeoCircle {
  GeoInvCircle({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.thickness,
    super.filled,
    super.color = Colors.purple,
    super.visible,
    super.styleOverrides,
  });

  @override
  GeoInvCircle copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? centerX,
    double? centerY,
    double? radius,
    double? thickness,
    bool? filled,
    Color? color,
    bool? visible,
    CanvasStyle? style,
  }) {
    final overrides = resolveStyleOverrides(style);
    final resolvedColor = resolveColor(color, style);
    return GeoInvCircle(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      thickness: thickness ?? this.thickness,
      filled: filled ?? this.filled,
      color: resolvedColor,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoInvCircle';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'centerX': centerX,
      'centerY': centerY,
      'radius': radius,
      'thickness': thickness,
      'filled': filled,
    };
    return json;
  }

  static GeoInvCircle fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final styleOverrides = GeometryObject.extractStyleOverrides(json);
    final color = GeometryObject.colorFromJson(json, Colors.purple);
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoInvCircle(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector:
          Multivector.zero(), // Will be recalculated during DAG reconstruction
      thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
      filled: props['filled'] as bool? ?? false,
      color: color,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }
}
