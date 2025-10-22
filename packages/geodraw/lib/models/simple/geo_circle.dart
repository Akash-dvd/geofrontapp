import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import 'geo_point.dart';

/// Abstract base class for all circle types
abstract class GeoCircle extends SimpleGeometryObject {
  GeoCircle({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
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

    final effectiveStyle = style;
    final strokeColor = effectiveStyle.strokeColor;
    final fillColor = effectiveStyle.fillColor;

    final circlePaint = Paint()
      ..color = effectiveStyle.filled ? fillColor : strokeColor
      ..strokeWidth = effectiveStyle.strokeWidth
      ..style = effectiveStyle.filled
          ? PaintingStyle.fill
          : PaintingStyle.stroke;

    canvas.drawCircle(center, radius, circlePaint);

    // Draw label
    if (label.isNotEmpty) {
      final labelColor = effectiveStyle.labelColor;
      final labelFontSize = effectiveStyle.labelFontSize;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: labelColor,
            fontSize: labelFontSize,
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
    final effectiveStyle = style;

    return effectiveStyle.filled
        ? dist <= radius
        : (dist - radius).abs() <= effectiveStyle.strokeWidth;
  }

  @override
  Rect getBounds() {
    return Rect.fromCircle(center: center, radius: radius + style.strokeWidth);
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
  List<Object?> get props => [...super.props];
}

/// Circle defined by center point and a point on the circumference
class GeoCircle2P extends GeoCircle {
  GeoCircle2P({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.multivector,
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
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    return fromDependencies(
      id: id,
      label: label,
      points: [center, pointOnCircle],
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );
  }

  /// Construct a circle from a list of dependent points.
  static GeoCircle2P fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (points.length != 2) {
      throw ArgumentError('GeoCircle2P requires exactly 2 point dependencies');
    }

    final mv = constructCircleFromCenterAndPoint(
      points[0].multivector,
      points[1].multivector,
    );

    final normalizedOverrides = _styleOverridesFromStyle(
      type: GeoCircle2P,
      style: style,
      overrides: styleOverrides,
    );

    return GeoCircle2P(
      id: id,
      label: label,
      dependencies: points.map((p) => p.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoCircle2P copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoCircle2P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
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
    };
    return json;
  }

  static GeoCircle2P fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = _styleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoCircle2P)
          .strokeColor,
    );
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoCircle2P(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents) {
    final points = parents.whereType<GeoPoint>().toList(growable: false);
    if (points.length != 2) {
      return null;
    }

    return GeoCircle2P.fromDependencies(
      id: id,
      label: label,
      points: points,
      visible: visible,
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
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    return fromDependencies(
      id: id,
      label: label,
      points: [p1, p2, p3],
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );
  }

  /// Construct a circle through three points using dependency list.
  static GeoCircle3P? fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (points.length != 3) {
      throw ArgumentError('GeoCircle3P requires exactly 3 point dependencies');
    }

    final p1 = points[0];
    final p2 = points[1];
    final p3 = points[2];

    final d =
        2 *
        (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y));

    if (d.abs() < 0.001) {
      return null;
    }

    final mv = constructCircleThrough3Points(
      p1.multivector,
      p2.multivector,
      p3.multivector,
    );

    final normalizedOverrides = _styleOverridesFromStyle(
      type: GeoCircle3P,
      style: style,
      overrides: styleOverrides,
    );

    return GeoCircle3P(
      id: id,
      label: label,
      dependencies: points.map((p) => p.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoCircle3P copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoCircle3P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
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
    };
    return json;
  }

  static GeoCircle3P fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = _styleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoCircle3P)
          .strokeColor,
    );
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoCircle3P(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents) {
    final points = parents.whereType<GeoPoint>().toList(growable: false);
    if (points.length != 3) {
      return null;
    }

    return GeoCircle3P.fromDependencies(
      id: id,
      label: label,
      points: points,
      visible: visible,
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
    super.visible,
    super.styleOverrides,
  });

  @override
  GeoInvCircle copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoInvCircle(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
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
    };
    return json;
  }

  static GeoInvCircle fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = _styleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoInvCircle)
          .strokeColor,
    );
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoInvCircle(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }
}

Map<String, dynamic>? _styleOverridesFromStyle({
  required Type type,
  CanvasStyle? style,
  Map<String, dynamic>? overrides,
}) {
  if (overrides != null) {
    return Map<String, dynamic>.unmodifiable(overrides);
  }
  if (style == null) {
    return null;
  }

  final defaults = CanvasStyleDefaults.instance.resolveForType(type);
  return Map<String, dynamic>.unmodifiable(style.diff(defaults));
}

Map<String, dynamic>? _styleOverridesFromJson(
  Map<String, dynamic> json, {
  Map<String, dynamic>? legacyProps,
  Color? fallbackColor,
}) {
  final existing = GeometryObject.extractStyleOverrides(json);
  if (existing != null) {
    return Map<String, dynamic>.unmodifiable(existing);
  }

  final overrides = <String, dynamic>{};

  final rawColor = json.containsKey('color') ? json['color'] : null;
  final parsedColor = GeometryObject.parseColor(rawColor) ?? fallbackColor;
  if (parsedColor != null) {
    overrides['strokeColor'] = CanvasStyle.colorToHex(parsedColor);
  }

  if (legacyProps != null) {
    final thickness = legacyProps['thickness'];
    if (thickness is num) {
      overrides['strokeWidth'] = thickness.toDouble();
    }
    final filled = legacyProps['filled'];
    if (filled is bool) {
      overrides['filled'] = filled;
    }
  }

  if (overrides.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(overrides);
}
