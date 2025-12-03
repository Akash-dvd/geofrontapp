import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import 'geo_point.dart';
import 'geo_line.dart';

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

  /// Calculate radius squared using the same formula as measureCircleRadius
  /// For a circle in the form (o, e1, e2, O):
  /// radius² = (e1² + e2²) / o² - 2*O/o
  double get _radiusSquared {
    final circleInf = infForm(multivector);
    return circleInf.e1 * circleInf.e1 + 
           circleInf.e2 * circleInf.e2 - 
           2 * circleInf.O;
  }

  /// Check if the circle has an imaginary radius
  bool get hasImaginaryRadius => _radiusSquared < 0;

  /// Radius derived from multivector norm
  double get radius {
    if (hasImaginaryRadius) {
      // For imaginary radius, return the absolute value of the imaginary part
      return math.sqrt(_radiusSquared.abs());
    }
    final normOpt = multivector.norm();
    return normOpt.fold(() => 0.0, (normValue) => math.sqrt(normValue.abs()));
  }

  Offset get center => Offset(centerX, centerY);

  @override
  void draw(Canvas canvas, Paint paint) {
    if (!visible) return;

    final effectiveStyle = style;
    
    // Check if paint has highlight colors (different from base style)
    final isHighlighted = paint.color != effectiveStyle.strokeColor ||
        (effectiveStyle.highlightStrokeColor != null &&
            paint.color == effectiveStyle.highlightStrokeColor);
    
    // Use highlight colors if paint indicates highlighting, otherwise use style
    final strokeColor = effectiveStyle.getEffectiveStrokeColor(isHighlighted);
    final fillColor = effectiveStyle.getEffectiveFillColor(isHighlighted);
    // Use paint's strokeWidth (already includes 1.5x multiplier when selected)
    final strokeWidth = paint.strokeWidth;

    final circlePaint = Paint()
      ..color = effectiveStyle.filled && !hasImaginaryRadius ? fillColor : strokeColor
      ..strokeWidth = strokeWidth
      ..style = (effectiveStyle.filled && !hasImaginaryRadius)
          ? PaintingStyle.fill
          : PaintingStyle.stroke;

    // Use dashed line for imaginary radius circles
    if (hasImaginaryRadius) {
      circlePaint.style = PaintingStyle.stroke; // Force stroke for imaginary
      // Create dashed path effect
      final path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius));
      
      // Draw with dashed pattern
      final dashPath = _createDashedPath(path, dashArray: const [5.0, 5.0]);
      canvas.drawPath(dashPath, circlePaint);
    } else {
    canvas.drawCircle(center, radius, circlePaint);
    }

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

  /// Create a dashed path from a given path
  Path _createDashedPath(Path path, {List<double> dashArray = const [5.0, 5.0]}) {
    final dashPath = Path();
    final metrics = path.computeMetrics();
    
    for (final metric in metrics) {
      var distance = 0.0;
      var dashIndex = 0;
      var draw = true;
      
      while (distance < metric.length) {
        final dashLength = dashArray[dashIndex % dashArray.length];
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, math.min(distance + dashLength, metric.length)),
            Offset.zero,
          );
        }
        distance += dashLength;
        dashIndex++;
        draw = !draw;
      }
    }
    
    return dashPath;
  }

  @override
  bool contains(Offset position) {
    if (hasImaginaryRadius) {
      // For imaginary circles, a point is "contained" if it's within the stroke width
      // of the imaginary circle boundary
      final dist = (position - center).distance;
      final imaginaryRadius = math.sqrt(_radiusSquared.abs());
      return (dist - imaginaryRadius).abs() <= style.strokeWidth;
    }
    
    final dist = (position - center).distance;
    final effectiveStyle = style;

    return effectiveStyle.filled
        ? dist <= radius
        : (dist - radius).abs() <= effectiveStyle.strokeWidth;
  }

  @override
  Rect getBounds() {
    if (hasImaginaryRadius) {
      // For imaginary circles, bounds are still based on the radius magnitude
      return Rect.fromCircle(center: center, radius: radius + style.strokeWidth);
    }
    return Rect.fromCircle(center: center, radius: radius + style.strokeWidth);
  }

  @override
  double distanceTo(Offset point) {
    // Convert the offset to a Multivector point
    final pointMv = constructFreePoint(point.dx, point.dy);
    
    if (hasImaginaryRadius) {
      // For imaginary radius circles, calculate distance differently
      // Distance to center minus the imaginary radius magnitude
      final centerMv = constructFreePoint(centerX, centerY);
      final distToCenter = distancePointToPoint(pointMv, centerMv);
      final imaginaryRadius = math.sqrt(_radiusSquared.abs());
      
      // For imaginary circles, the "distance" is how far inside/outside
      // the imaginary circle the point is
      // If point is closer to center than imaginary radius, it's "inside" (negative distance)
      // Otherwise, it's the distance beyond the imaginary radius
      return distToCenter - imaginaryRadius;
    }
    
    // Use Multivector-based distance calculation for real circles
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
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
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
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
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

/// Circle with flexible center and point (accepts point or circle, not line)
class GeoCircleFlex extends GeoCircle {
  GeoCircleFlex({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoCircleFlex requires exactly 2 dependencies',
       );

  /// Construct a circle from flexible dependencies (SimpleGeometryObject)
  static GeoCircleFlex fromDependencies({
    required String id,
    required String label,
    required List<SimpleGeometryObject> objects,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (objects.length != 2) {
      throw ArgumentError('GeoCircleFlex requires exactly 2 dependencies');
    }

    final centerObj = objects[0];
    final pointObj = objects[1];

    // Validate center: must be point or circle, not line
    if (centerObj is GeoLine) {
      throw ArgumentError('Center cannot be a line. Use a point or circle.');
    }

    // Validate point on circle: must be point or circle, not line
    if (pointObj is GeoLine) {
      throw ArgumentError('Point on circle cannot be a line. Use a point or circle.');
    }

    // Extract center multivector (point or circle center)
    final centerMv = centerObj is GeoCircle
        ? getCircleCenter(centerObj.multivector)
        : infForm(centerObj.multivector);

    // Extract point multivector (point or circle center)
    final pointMv = pointObj is GeoCircle
        ? getCircleCenter(pointObj.multivector)
        : infForm(pointObj.multivector);

    final mv = constructCircleFromCenterAndPoint(centerMv, pointMv);

    final normalizedOverrides = _styleOverridesFromStyle(
      type: GeoCircleFlex,
      style: style,
      overrides: styleOverrides,
    );

    return GeoCircleFlex(
      id: id,
      label: label,
      dependencies: objects.map((o) => o.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoCircleFlex copyWith({
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
    return GeoCircleFlex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoCircleFlex';

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

  static GeoCircleFlex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = _styleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoCircleFlex)
          .strokeColor,
    );
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoCircleFlex(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    final objects = parents.whereType<SimpleGeometryObject>().toList(growable: false);
    if (objects.length != 2) {
      return null;
    }

    try {
      return GeoCircleFlex.fromDependencies(
        id: id,
        label: label,
        objects: objects,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Circle through three flexible objects (accepts any SimpleGeometryObject)
class GeoCircle3Flex extends GeoCircle {
  GeoCircle3Flex({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 3 dependencies
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 3,
         'GeoCircle3Flex requires exactly 3 dependencies',
       );

  /// Construct a circle through three flexible objects
  static GeoCircle3Flex? fromDependencies({
    required String id,
    required String label,
    required List<SimpleGeometryObject> objects,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (objects.length != 3) {
      throw ArgumentError('GeoCircle3Flex requires exactly 3 dependencies');
    }

    // Extract multivectors (point or circle center)
    final mv1 = objects[0] is GeoCircle
        ? getCircleCenter(objects[0].multivector)
        : infForm(objects[0].multivector);
    final mv2 = objects[1] is GeoCircle
        ? getCircleCenter(objects[1].multivector)
        : infForm(objects[1].multivector);
    final mv3 = objects[2] is GeoCircle
        ? getCircleCenter(objects[2].multivector)
        : infForm(objects[2].multivector);

    // Check for collinearity (similar to GeoCircle3P)
    final p1 = constructFreePoint(mv1.e1, mv1.e2);
    final p2 = constructFreePoint(mv2.e1, mv2.e2);
    final p3 = constructFreePoint(mv3.e1, mv3.e2);

    final d = 2 *
        (p1.e1 * (p2.e2 - p3.e2) +
            p2.e1 * (p3.e2 - p1.e2) +
            p3.e1 * (p1.e2 - p2.e2));

    if (d.abs() < 0.001) {
      return null;
    }

    final mv = constructCircleThrough3Points(mv1, mv2, mv3);

    final normalizedOverrides = _styleOverridesFromStyle(
      type: GeoCircle3Flex,
      style: style,
      overrides: styleOverrides,
    );

    return GeoCircle3Flex(
      id: id,
      label: label,
      dependencies: objects.map((o) => o.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoCircle3Flex copyWith({
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
    return GeoCircle3Flex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoCircle3Flex';

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

  static GeoCircle3Flex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = _styleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoCircle3Flex)
          .strokeColor,
    );
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoCircle3Flex(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    final objects = parents.whereType<SimpleGeometryObject>().toList(growable: false);
    if (objects.length != 3) {
      return null;
    }

    return GeoCircle3Flex.fromDependencies(
      id: id,
      label: label,
      objects: objects,
      visible: visible,
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
