import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import 'geo_point.dart';
import 'geo_circle.dart';

/// Abstract base class for all line types
abstract class GeoLine extends SimpleGeometryObject {
  GeoLine({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  });

  /// Line equation coefficient a (from multivector)
  /// Line equation: ax + by + c = 0
  double get a => multivector.e1;

  /// Line equation coefficient b (from multivector)
  double get b => multivector.e2;

  /// Line equation coefficient c (from multivector)
  double get c => multivector.O * -1;

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
    // Use paint's strokeWidth (already includes 1.5x multiplier when selected)
    final strokeWidth = paint.strokeWidth;
    final resolvedLineStyle =
        _lineStyleFromPattern(effectiveStyle.linePattern) ?? LineStyle.solid;

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Apply line style
    if (resolvedLineStyle == LineStyle.dashed ||
        resolvedLineStyle == LineStyle.dotted) {
      linePaint.strokeCap = StrokeCap.round;
    }

    // Draw line across canvas bounds (approximate as large segment)
    // This will be clipped by the viewport
    final points = _getLinePoints(canvas);
    if (points != null) {
      if (resolvedLineStyle == LineStyle.dashed) {
        _drawDashedLine(canvas, linePaint, points.$1, points.$2);
      } else if (resolvedLineStyle == LineStyle.dotted) {
        _drawDottedLine(canvas, linePaint, points.$1, points.$2, strokeWidth);
      } else {
        canvas.drawLine(points.$1, points.$2, linePaint);
      }
    }

    // Draw label at midpoint
    if (label.isNotEmpty && points != null) {
      final mid = (points.$1 + points.$2) / 2;
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
      textPainter.paint(canvas, mid + Offset(5, -textPainter.height - 5));
    }
  }

  /// Get two points on the line for drawing (extends far in both directions)
  (Offset, Offset)? _getLinePoints(Canvas canvas) {
    final clipBounds = canvas.getLocalClipBounds();
    if (clipBounds.isEmpty) {
      return _fallbackLinePoints();
    }

    final intersections = <Offset>[];
    Rect expandedBounds = clipBounds;

    // Inflate slightly to account for floating point inaccuracies.
    const double tolerance = 0.001;
    expandedBounds = expandedBounds.inflate(tolerance);

    void addIfInside(double x, double y) {
      if (!x.isFinite || !y.isFinite) {
        return;
      }
      final candidate = Offset(x, y);
      if (!expandedBounds.contains(candidate)) {
        return;
      }
      for (final existing in intersections) {
        if (_almostEqual(existing.dx, candidate.dx) &&
            _almostEqual(existing.dy, candidate.dy)) {
          return;
        }
      }
      intersections.add(candidate);
    }

    if (b.abs() > tolerance) {
      addIfInside(clipBounds.left, -(a * clipBounds.left + c) / b);
      addIfInside(clipBounds.right, -(a * clipBounds.right + c) / b);
    }

    if (a.abs() > tolerance) {
      addIfInside(-(b * clipBounds.top + c) / a, clipBounds.top);
      addIfInside(-(b * clipBounds.bottom + c) / a, clipBounds.bottom);
    }

    if (intersections.length >= 2) {
      return (intersections[0], intersections[1]);
    }

    // Fallback to the old large-bounds approach when we cannot find two
    // distinct intersections (e.g. nearly degenerate lines).
    return _fallbackLinePoints();
  }

  (Offset, Offset)? _fallbackLinePoints() {
    if (b.abs() > 0.001) {
      final x1 = -10000.0;
      final y1 = -(a * x1 + c) / b;
      final x2 = 10000.0;
      final y2 = -(a * x2 + c) / b;
      return (Offset(x1, y1), Offset(x2, y2));
    } else if (a.abs() > 0.001) {
      final x = -c / a;
      return (Offset(x, -10000.0), Offset(x, 10000.0));
    }
    return null;
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset p1, Offset p2) {
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    final distance = (p2 - p1).distance;
    final dx = (p2.dx - p1.dx) / distance;
    final dy = (p2.dy - p1.dy) / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final start = Offset(
        p1.dx + dx * currentDistance,
        p1.dy + dy * currentDistance,
      );
      currentDistance += dashWidth;
      if (currentDistance > distance) currentDistance = distance;
      final end = Offset(
        p1.dx + dx * currentDistance,
        p1.dy + dy * currentDistance,
      );
      canvas.drawLine(start, end, paint);
      currentDistance += dashSpace;
    }
  }

  void _drawDottedLine(
    Canvas canvas,
    Paint paint,
    Offset p1,
    Offset p2,
    double strokeWidth,
  ) {
    const dotSpace = 8.0;
    final distance = (p2 - p1).distance;
    final dx = (p2.dx - p1.dx) / distance;
    final dy = (p2.dy - p1.dy) / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final point = Offset(
        p1.dx + dx * currentDistance,
        p1.dy + dy * currentDistance,
      );
      canvas.drawCircle(point, strokeWidth / 2, paint);
      currentDistance += dotSpace;
    }
  }

  @override
  bool contains(Offset position) {
    final effectiveStyle = style;
    return distanceTo(position) <= effectiveStyle.strokeWidth;
  }

  @override
  Rect getBounds() {
    // Lines extend infinitely, return a large bounds
    return const Rect.fromLTRB(-10000, -10000, 10000, 10000);
  }

  @override
  double distanceTo(Offset point) {
    // Convert the offset to a Multivector point
    final pointMv = constructFreePoint(point.dx, point.dy);
    // Use Multivector-based distance calculation
    return distancePointToLine(pointMv, multivector);
  }

  @override
  bool intersects(SimpleGeometryObject other) {
    // Lines intersect unless parallel
    if (other is GeoLine) {
      final det = a * other.b - b * other.a;
      return det.abs() > 0.001; // Not parallel
    }
    return other.intersects(this);
  }

  @override
  List<Object?> get props => [...super.props];

  LineStyle? _lineStyleFromPattern(String? pattern) {
    if (pattern == null) return null;
    switch (pattern.toLowerCase()) {
      case 'dashed':
        return LineStyle.dashed;
      case 'dotted':
        return LineStyle.dotted;
      case 'solid':
        return LineStyle.solid;
      default:
        return null;
    }
  }
}

enum LineStyle { solid, dashed, dotted }

/// Line through two points
class GeoLine2P extends GeoLine {
  GeoLine2P({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'Line through 2 points requires exactly 2 point dependencies',
       );

  static GeoLine2P fromPoints({
    required String id,
    required String label,
    required GeoPoint p1,
    required GeoPoint p2,
    double thickness = 2.0,
    LineStyle lineStyle = LineStyle.solid,
    Color color = Colors.blue,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    return fromDependencies(
      id: id,
      label: label,
      points: [p1, p2],
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      fallbackColor: color,
      fallbackStrokeWidth: thickness,
      fallbackLineStyle: lineStyle,
    );
  }

  /// Construct a line from a list of dependent points.
  static GeoLine2P fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.blue,
  }) {
    if (points.length != 2) {
      throw ArgumentError('GeoLine2P requires exactly 2 point dependencies');
    }

    final mv = constructLineFrom2Points(
      points[0].multivector,
      points[1].multivector,
    );

    final normalizedOverrides = _lineStyleOverridesFromStyle(
      type: GeoLine2P,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoLine2P(
      id: id,
      label: label,
      dependencies: points.map((p) => p.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoLine2P copyWith({
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
    return GeoLine2P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoLine2P';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoLine2P fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance.resolveForType(GeoLine2P);
    final styleOverrides = _lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoLine2P(
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

    return GeoLine2P.fromDependencies(
      id: id,
      label: label,
      points: points,
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

/// Perpendicular bisector of a segment
class GeoPerpendicularBisector extends GeoLine {
  GeoPerpendicularBisector({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  });

  static GeoPerpendicularBisector fromPoints({
    required String id,
    required String label,
    required GeoPoint p1,
    required GeoPoint p2,
    double thickness = 2.0,
    LineStyle lineStyle = LineStyle.solid,
    Color color = Colors.cyan,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    return fromDependencies(
      id: id,
      label: label,
      points: [p1, p2],
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      fallbackColor: color,
      fallbackStrokeWidth: thickness,
      fallbackLineStyle: lineStyle,
    );
  }

  static GeoPerpendicularBisector fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.cyan,
  }) {
    if (points.length != 2) {
      throw ArgumentError(
        'GeoPerpendicularBisector requires exactly 2 point dependencies',
      );
    }

    final mv = constructPerpendicularBisector(
      points[0].multivector,
      points[1].multivector,
    );

    final normalizedOverrides = _lineStyleOverridesFromStyle(
      type: GeoPerpendicularBisector,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoPerpendicularBisector(
      id: id,
      label: label,
      dependencies: points.map((p) => p.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoPerpendicularBisector copyWith({
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
    return GeoPerpendicularBisector(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoPerpendicularBisector';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoPerpendicularBisector fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance.resolveForType(
      GeoPerpendicularBisector,
    );
    final styleOverrides = _lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoPerpendicularBisector(
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

    return GeoPerpendicularBisector.fromDependencies(
      id: id,
      label: label,
      points: points,
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

/// Perpendicular line to another line through a point
class GeoPerpendicularLine extends GeoLine {
  GeoPerpendicularLine({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  });

  static GeoPerpendicularLine fromLine({
    required String id,
    required String label,
    required GeoLine line,
    required GeoPoint point,
    double thickness = 2.0,
    LineStyle lineStyle = LineStyle.solid,
    Color color = Colors.orange,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    return fromDependencies(
      id: id,
      label: label,
      dependencies: [point, line],
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      fallbackColor: color,
      fallbackStrokeWidth: thickness,
      fallbackLineStyle: lineStyle,
    );
  }

  static GeoPerpendicularLine fromDependencies({
    required String id,
    required String label,
    required List<GeometryObject> dependencies,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.orange,
  }) {
    if (dependencies.length != 2) {
      throw ArgumentError(
        'GeoPerpendicularLine requires exactly a point and a line dependency',
      );
    }

    final point = dependencies[0];
    final line = dependencies[1];

    if (point is! GeoPoint || line is! GeoLine) {
      throw ArgumentError(
        'GeoPerpendicularLine expects dependencies of type GeoPoint and GeoLine',
      );
    }

    final mv = constructPerpendicularLine(line.multivector, point.multivector);
    final normalizedOverrides = _lineStyleOverridesFromStyle(
      type: GeoPerpendicularLine,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoPerpendicularLine(
      id: id,
      label: label,
      dependencies: [point.id, line.id],
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoPerpendicularLine copyWith({
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
    return GeoPerpendicularLine(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoPerpendicularLine';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoPerpendicularLine fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance.resolveForType(
      GeoPerpendicularLine,
    );
    final styleOverrides = _lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoPerpendicularLine(
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
    if (parents.length != 2) {
      return null;
    }

    // fromDependencies expects [point, line] order (see line 601 and 628-629)
    final point = parents[0];
    final line = parents[1];

    if (point is! GeoPoint || line is! GeoLine) {
      return null;
    }

    return GeoPerpendicularLine.fromDependencies(
      id: id,
      label: label,
      dependencies: parents,
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

/// Parallel line to another line through a point
class GeoParallelLine extends GeoLine {
  GeoParallelLine({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  });

  static GeoParallelLine fromLine({
    required String id,
    required String label,
    required GeoLine line,
    required GeoPoint point,
    double thickness = 2.0,
    LineStyle lineStyle = LineStyle.solid,
    Color color = Colors.teal,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    return fromDependencies(
      id: id,
      label: label,
      dependencies: [line, point],
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      fallbackColor: color,
      fallbackStrokeWidth: thickness,
      fallbackLineStyle: lineStyle,
    );
  }

  static GeoParallelLine fromDependencies({
    required String id,
    required String label,
    required List<GeometryObject> dependencies,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.teal,
  }) {
    if (dependencies.length != 2) {
      throw ArgumentError(
        'GeoParallelLine requires exactly a line and a point dependency',
      );
    }

    final line = dependencies[0];
    final point = dependencies[1];

    if (line is! GeoLine || point is! GeoPoint) {
      throw ArgumentError(
        'GeoParallelLine expects dependencies of type GeoLine and GeoPoint',
      );
    }

    final mv = constructParallelLine(line.multivector, point.multivector);
    final normalizedOverrides = _lineStyleOverridesFromStyle(
      type: GeoParallelLine,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoParallelLine(
      id: id,
      label: label,
      dependencies: [line.id, point.id],
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoParallelLine copyWith({
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
    return GeoParallelLine(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoParallelLine';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoParallelLine fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance.resolveForType(
      GeoParallelLine,
    );
    final styleOverrides = _lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoParallelLine(
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
    if (parents.length != 2) {
      return null;
    }

    final line = parents[0];
    final point = parents[1];

    if (line is! GeoLine || point is! GeoPoint) {
      return null;
    }

    return GeoParallelLine.fromDependencies(
      id: id,
      label: label,
      dependencies: parents,
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

Map<String, dynamic>? _lineStyleOverridesFromStyle({
  required Type type,
  CanvasStyle? style,
  Map<String, dynamic>? overrides,
  Color? fallbackColor,
  double? fallbackStrokeWidth,
  LineStyle? fallbackLineStyle,
}) {
  if (overrides != null) {
    return Map<String, dynamic>.unmodifiable(overrides);
  }

  if (style != null) {
    final defaults = CanvasStyleDefaults.instance.resolveForType(type);
    return Map<String, dynamic>.unmodifiable(style.diff(defaults));
  }

  final defaults = CanvasStyleDefaults.instance.resolveForType(type);
  final inferred = <String, dynamic>{};

  if (fallbackColor != null &&
      fallbackColor.value != defaults.strokeColor.value) {
    inferred['strokeColor'] = CanvasStyle.colorToHex(fallbackColor);
  }

  if (fallbackStrokeWidth != null &&
      !_almostEqual(fallbackStrokeWidth, defaults.strokeWidth)) {
    inferred['strokeWidth'] = fallbackStrokeWidth;
  }

  if (fallbackLineStyle != null) {
    final pattern = fallbackLineStyle.name;
    if (pattern != defaults.linePattern) {
      inferred['linePattern'] = pattern;
    }
  }

  if (inferred.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(inferred);
}

Map<String, dynamic>? _lineStyleOverridesFromJson(
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
  final parsedColor = GeometryObject.parseColor(rawColor);
  if (parsedColor != null) {
    overrides['strokeColor'] = CanvasStyle.colorToHex(parsedColor);
  }

  if (legacyProps != null) {
    final thickness = legacyProps['thickness'];
    if (thickness is num) {
      overrides['strokeWidth'] = thickness.toDouble();
    }

    final rawPattern = legacyProps['lineStyle'] ?? legacyProps['style'];
    final pattern = _normalizeLinePattern(rawPattern);
    if (pattern != null) {
      overrides['linePattern'] = pattern;
    }
  }

  if (overrides.isEmpty && fallbackColor != null) {
    overrides['strokeColor'] = CanvasStyle.colorToHex(fallbackColor);
  }

  if (overrides.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(overrides);
}

String? _normalizeLinePattern(dynamic raw) {
  if (raw is String) {
    final lower = raw.toLowerCase();
    switch (lower) {
      case 'solid':
      case 'dashed':
      case 'dotted':
        return lower;
    }
  } else if (raw is LineStyle) {
    return raw.name;
  }
  return null;
}

bool _almostEqual(double a, double b, [double epsilon = 0.0001]) {
  return (a - b).abs() < epsilon;
}

/// Angle bisector from three points (vertex at middle point)
class GeoAngleBisector3P extends GeoLine {
  GeoAngleBisector3P({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  });

  static GeoAngleBisector3P fromDependencies({
    required String id,
    required String label,
    required List<GeometryObject> dependencies,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.purple,
  }) {
    if (dependencies.length != 3) {
      throw ArgumentError(
        'GeoAngleBisector3P requires exactly 3 point dependencies',
      );
    }

    final p1 = dependencies[0];
    final vertex = dependencies[1];
    final p2 = dependencies[2];

    if (p1 is! GeoPoint || vertex is! GeoPoint || p2 is! GeoPoint) {
      throw ArgumentError(
        'GeoAngleBisector3P expects all dependencies to be GeoPoint',
      );
    }

    final mv = constructAngleBisector3Points(
      p1.multivector,
      vertex.multivector,
      p2.multivector,
    );

    final normalizedOverrides = _lineStyleOverridesFromStyle(
      type: GeoAngleBisector3P,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoAngleBisector3P(
      id: id,
      label: label,
      dependencies: [p1.id, vertex.id, p2.id],
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoAngleBisector3P copyWith({
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
    return GeoAngleBisector3P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoAngleBisector3P';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoAngleBisector3P fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults =
        CanvasStyleDefaults.instance.resolveForType(GeoAngleBisector3P);
    final styleOverrides = _lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoAngleBisector3P(
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
    if (parents.length != 3) {
      return null;
    }

    final p1 = parents[0];
    final vertex = parents[1];
    final p2 = parents[2];

    if (p1 is! GeoPoint || vertex is! GeoPoint || p2 is! GeoPoint) {
      return null;
    }

    return GeoAngleBisector3P.fromDependencies(
      id: id,
      label: label,
      dependencies: parents,
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

/// Line through two flexible objects (accepts any SimpleGeometryObject)
class GeoLineFlex extends GeoLine {
  GeoLineFlex({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoLineFlex requires exactly 2 dependencies',
       );

  /// Construct a line from flexible dependencies (SimpleGeometryObject)
  static GeoLineFlex fromDependencies({
    required String id,
    required String label,
    required List<SimpleGeometryObject> objects,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.blue,
  }) {
    if (objects.length != 2) {
      throw ArgumentError('GeoLineFlex requires exactly 2 dependencies');
    }

    // Extract multivectors (point or circle center)
    final mv1 = objects[0] is GeoCircle
        ? getCircleCenter(objects[0].multivector)
        : infForm(objects[0].multivector);
    final mv2 = objects[1] is GeoCircle
        ? getCircleCenter(objects[1].multivector)
        : infForm(objects[1].multivector);

    final mv = constructLineFrom2Points(mv1, mv2);

    final normalizedOverrides = _lineStyleOverridesFromStyle(
      type: GeoLineFlex,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoLineFlex(
      id: id,
      label: label,
      dependencies: objects.map((o) => o.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoLineFlex copyWith({
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
    return GeoLineFlex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoLineFlex';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoLineFlex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance.resolveForType(GeoLineFlex);
    final styleOverrides = _lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoLineFlex(
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

    return GeoLineFlex.fromDependencies(
      id: id,
      label: label,
      objects: objects,
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

/// Perpendicular bisector with flexible arguments (point or circle, not line)
class GeoPerpendicularBisectorFlex extends GeoLine {
  GeoPerpendicularBisectorFlex({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoPerpendicularBisectorFlex requires exactly 2 dependencies',
       );

  /// Construct a perpendicular bisector from flexible dependencies
  static GeoPerpendicularBisectorFlex fromDependencies({
    required String id,
    required String label,
    required List<SimpleGeometryObject> objects,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.cyan,
  }) {
    if (objects.length != 2) {
      throw ArgumentError(
        'GeoPerpendicularBisectorFlex requires exactly 2 dependencies',
      );
    }

    // Validate: neither can be line
    if (objects[0] is GeoLine || objects[1] is GeoLine) {
      throw ArgumentError(
        'Perpendicular bisector requires points or circles, not lines.',
      );
    }

    // Extract multivectors (point or circle center)
    final mv1 = objects[0] is GeoCircle
        ? getCircleCenter(objects[0].multivector)
        : infForm(objects[0].multivector);
    final mv2 = objects[1] is GeoCircle
        ? getCircleCenter(objects[1].multivector)
        : infForm(objects[1].multivector);

    final mv = constructPerpendicularBisector(mv1, mv2);

    final normalizedOverrides = _lineStyleOverridesFromStyle(
      type: GeoPerpendicularBisectorFlex,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoPerpendicularBisectorFlex(
      id: id,
      label: label,
      dependencies: objects.map((o) => o.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoPerpendicularBisectorFlex copyWith({
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
    return GeoPerpendicularBisectorFlex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoPerpendicularBisectorFlex';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoPerpendicularBisectorFlex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance
        .resolveForType(GeoPerpendicularBisectorFlex);
    final styleOverrides = _lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoPerpendicularBisectorFlex(
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
      return GeoPerpendicularBisectorFlex.fromDependencies(
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

/// Perpendicular line with flexible point (point or circle)
class GeoPerpendicularLineFlex extends GeoLine {
  GeoPerpendicularLineFlex({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoPerpendicularLineFlex requires exactly 2 dependencies',
       );

  /// Construct a perpendicular line from flexible dependencies
  static GeoPerpendicularLineFlex fromDependencies({
    required String id,
    required String label,
    required List<GeometryObject> dependencies,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.orange,
  }) {
    if (dependencies.length != 2) {
      throw ArgumentError(
        'GeoPerpendicularLineFlex requires exactly a point/circle and a line dependency',
      );
    }

    final pointObj = dependencies[0];
    final reference = dependencies[1];

    if (reference is! GeoLine) {
      throw ArgumentError(
        'GeoPerpendicularLineFlex requires a line as the second dependency',
      );
    }

    if (pointObj is! SimpleGeometryObject) {
      throw ArgumentError(
        'GeoPerpendicularLineFlex requires a point or circle as the first dependency',
      );
    }

    // Extract point multivector (point or circle center)
    final pointMv = pointObj is GeoCircle
        ? getCircleCenter(pointObj.multivector)
        : infForm(pointObj.multivector);

    final mv = constructPerpendicularLine(reference.multivector, pointMv);

    final normalizedOverrides = _lineStyleOverridesFromStyle(
      type: GeoPerpendicularLineFlex,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoPerpendicularLineFlex(
      id: id,
      label: label,
      dependencies: dependencies.map((d) => d.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoPerpendicularLineFlex copyWith({
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
    return GeoPerpendicularLineFlex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoPerpendicularLineFlex';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoPerpendicularLineFlex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults =
        CanvasStyleDefaults.instance.resolveForType(GeoPerpendicularLineFlex);
    final styleOverrides = _lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoPerpendicularLineFlex(
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
    if (parents.length != 2) {
      return null;
    }

    try {
      return GeoPerpendicularLineFlex.fromDependencies(
        id: id,
        label: label,
        dependencies: parents,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Parallel line with flexible point (point or circle)
class GeoParallelLineFlex extends GeoLine {
  GeoParallelLineFlex({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoParallelLineFlex requires exactly 2 dependencies',
       );

  /// Construct a parallel line from flexible dependencies
  static GeoParallelLineFlex fromDependencies({
    required String id,
    required String label,
    required List<GeometryObject> dependencies,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.teal,
  }) {
    if (dependencies.length != 2) {
      throw ArgumentError(
        'GeoParallelLineFlex requires exactly a line and a point/circle dependency',
      );
    }

    final reference = dependencies[0];
    final pointObj = dependencies[1];

    if (reference is! GeoLine) {
      throw ArgumentError(
        'GeoParallelLineFlex requires a line as the first dependency',
      );
    }

    if (pointObj is! SimpleGeometryObject) {
      throw ArgumentError(
        'GeoParallelLineFlex requires a point or circle as the second dependency',
      );
    }

    // Extract point multivector (point or circle center)
    final pointMv = pointObj is GeoCircle
        ? getCircleCenter(pointObj.multivector)
        : infForm(pointObj.multivector);

    final mv = constructParallelLine(reference.multivector, pointMv);

    final normalizedOverrides = _lineStyleOverridesFromStyle(
      type: GeoParallelLineFlex,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoParallelLineFlex(
      id: id,
      label: label,
      dependencies: dependencies.map((d) => d.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoParallelLineFlex copyWith({
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
    return GeoParallelLineFlex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoParallelLineFlex';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoParallelLineFlex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults =
        CanvasStyleDefaults.instance.resolveForType(GeoParallelLineFlex);
    final styleOverrides = _lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoParallelLineFlex(
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
    if (parents.length != 2) {
      return null;
    }

    try {
      return GeoParallelLineFlex.fromDependencies(
        id: id,
        label: label,
        dependencies: parents,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    } catch (e) {
      return null;
    }
  }
}
