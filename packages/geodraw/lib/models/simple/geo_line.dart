import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../geometry_object.dart';
import 'geo_point.dart';

/// Abstract base class for all line types
abstract class GeoLine extends SimpleGeometryObject {
  /// Rendering thickness
  final double thickness;

  /// Line style (solid, dashed, dotted)
  final LineStyle lineStyle;

  GeoLine({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    this.thickness = 2.0,
    this.lineStyle = LineStyle.solid,
    super.color = Colors.blue,
    super.visible,
    super.styleOverrides,
  });

  /// Line equation coefficient a (from multivector)
  /// Line equation: ax + by + c = 0
  double get a => multivector.e1;

  /// Line equation coefficient b (from multivector)
  double get b => multivector.e2;

  /// Line equation coefficient c (from multivector)
  double get c => multivector.O;

  @override
  void draw(Canvas canvas, Paint paint) {
    if (!visible) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    // Apply line style
    if (lineStyle == LineStyle.dashed) {
      linePaint.strokeCap = StrokeCap.round;
    }

    // Draw line across canvas bounds (approximate as large segment)
    // This will be clipped by the viewport
    final points = _getLinePoints();
    if (points != null) {
      if (lineStyle == LineStyle.dashed) {
        _drawDashedLine(canvas, linePaint, points.$1, points.$2);
      } else if (lineStyle == LineStyle.dotted) {
        _drawDottedLine(canvas, linePaint, points.$1, points.$2);
      } else {
        canvas.drawLine(points.$1, points.$2, linePaint);
      }
    }

    // Draw label at midpoint
    if (label.isNotEmpty && points != null) {
      final mid = (points.$1 + points.$2) / 2;
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
      textPainter.paint(canvas, mid + Offset(5, -textPainter.height - 5));
    }
  }

  /// Get two points on the line for drawing (extends far in both directions)
  (Offset, Offset)? _getLinePoints() {
    if (b.abs() > 0.001) {
      // Non-vertical line
      final x1 = -10000.0;
      final y1 = -(a * x1 + c) / b;
      final x2 = 10000.0;
      final y2 = -(a * x2 + c) / b;
      return (Offset(x1, y1), Offset(x2, y2));
    } else if (a.abs() > 0.001) {
      // Vertical line
      final x = -c / a;
      return (Offset(x, -10000.0), Offset(x, 10000.0));
    }
    return null; // Invalid line
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

  void _drawDottedLine(Canvas canvas, Paint paint, Offset p1, Offset p2) {
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
      canvas.drawCircle(point, thickness / 2, paint);
      currentDistance += dotSpace;
    }
  }

  @override
  bool contains(Offset position) {
    return distanceTo(position) <= thickness;
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
  List<Object?> get props => [...super.props, thickness, lineStyle];
}

enum LineStyle { solid, dashed, dotted }

/// Line through two points
class GeoLine2P extends GeoLine {
  GeoLine2P({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.multivector,
    super.thickness,
    super.lineStyle,
    super.color,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'Line through 2 points requires exactly 2 point dependencies',
       );

  /// Create line from two points
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
  }) {
    // Calculate multivector using definitions.dart placeholder
    final mv = constructLineFrom2Points(p1.multivector, p2.multivector);
    final resolvedColor = style?.strokeColor ?? color;
    final overrides = style != null
        ? Map<String, dynamic>.unmodifiable(
            style.diff(CanvasStyle.baseDefaults),
          )
        : null;

    return GeoLine2P(
      id: id,
      label: label,
      dependencies: [p1.id, p2.id],
      multivector: mv,
      thickness: thickness,
      lineStyle: lineStyle,
      color: resolvedColor,
      visible: visible,
      styleOverrides: overrides,
    );
  }

  @override
  GeoLine2P copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? a,
    double? b,
    double? c,
    double? thickness,
    LineStyle? lineStyle,
    Color? color,
    bool? visible,
    CanvasStyle? style,
  }) {
    final overrides = resolveStyleOverrides(style);
    final resolvedColor = resolveColor(color, style);
    return GeoLine2P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      thickness: thickness ?? this.thickness,
      lineStyle: lineStyle ?? this.lineStyle,
      color: resolvedColor,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoLine2P';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'a': a,
      'b': b,
      'c': c,
      'thickness': thickness,
      'lineStyle': lineStyle.toString().split('.').last,
    };
    return json;
  }

  static GeoLine2P fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final styleOverrides = GeometryObject.extractStyleOverrides(json);
    final color = GeometryObject.colorFromJson(json, Colors.blue);
    final deps = (json['dependencies'] as List).cast<String>();
    final lineStyleToken = props['lineStyle'] ?? props['style'];

    return GeoLine2P(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector:
          Multivector.zero(), // Will be recalculated during DAG reconstruction
      thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
      lineStyle: GeoLine2P._parseLineStyle(lineStyleToken as String?),
      color: color,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  static LineStyle _parseLineStyle(String? style) {
    switch (style) {
      case 'dashed':
        return LineStyle.dashed;
      case 'dotted':
        return LineStyle.dotted;
      default:
        return LineStyle.solid;
    }
  }
}

/// Perpendicular bisector of a segment
class GeoPerpendicularBisector extends GeoLine {
  GeoPerpendicularBisector({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.thickness,
    super.lineStyle,
    super.color = Colors.cyan,
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
  }) {
    // Calculate multivector using definitions.dart placeholder
    final mv = constructPerpendicularBisector(p1.multivector, p2.multivector);

    return GeoPerpendicularBisector(
      id: id,
      label: label,
      dependencies: [p1.id, p2.id],
      multivector: mv,
      thickness: thickness,
      lineStyle: lineStyle,
      color: color,
      visible: visible,
    );
  }

  @override
  GeoPerpendicularBisector copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? a,
    double? b,
    double? c,
    double? thickness,
    LineStyle? lineStyle,
    Color? color,
    bool? visible,
    CanvasStyle? style,
  }) {
    final overrides = resolveStyleOverrides(style);
    final resolvedColor = resolveColor(color, style);
    return GeoPerpendicularBisector(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      thickness: thickness ?? this.thickness,
      lineStyle: lineStyle ?? this.lineStyle,
      color: resolvedColor,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoPerpendicularBisector';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'a': a,
      'b': b,
      'c': c,
      'thickness': thickness,
      'lineStyle': lineStyle.toString().split('.').last,
    };
    return json;
  }

  static GeoPerpendicularBisector fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final styleOverrides = GeometryObject.extractStyleOverrides(json);
    final color = GeometryObject.colorFromJson(json, Colors.cyan);
    final deps = (json['dependencies'] as List).cast<String>();
    final lineStyleToken = props['lineStyle'] ?? props['style'];

    return GeoPerpendicularBisector(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector:
          Multivector.zero(), // Will be recalculated during DAG reconstruction
      thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
      lineStyle: GeoLine2P._parseLineStyle(lineStyleToken as String?),
      color: color,
      visible: json['visible'] as bool? ?? true,
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
    super.thickness,
    super.lineStyle,
    super.color = Colors.orange,
    super.visible,
    super.styleOverrides,
  });

  /// Create perpendicular line to another line through a point
  static GeoPerpendicularLine fromLine({
    required String id,
    required String label,
    required GeoLine line,
    required GeoPoint point,
    double thickness = 2.0,
    LineStyle lineStyle = LineStyle.solid,
    Color color = Colors.orange,
    bool visible = true,
  }) {
    final mv = constructPerpendicularLine(line.multivector, point.multivector);

    return GeoPerpendicularLine(
      id: id,
      label: label,
      dependencies: [line.id, point.id],
      multivector: mv,
      thickness: thickness,
      lineStyle: lineStyle,
      color: color,
      visible: visible,
    );
  }

  @override
  GeoPerpendicularLine copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? a,
    double? b,
    double? c,
    double? thickness,
    LineStyle? lineStyle,
    Color? color,
    bool? visible,
    CanvasStyle? style,
  }) {
    final overrides = resolveStyleOverrides(style);
    final resolvedColor = resolveColor(color, style);
    return GeoPerpendicularLine(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      thickness: thickness ?? this.thickness,
      lineStyle: lineStyle ?? this.lineStyle,
      color: resolvedColor,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoPerpendicularLine';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'a': a,
      'b': b,
      'c': c,
      'thickness': thickness,
      'lineStyle': lineStyle.toString().split('.').last,
    };
    return json;
  }

  static GeoPerpendicularLine fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final styleOverrides = GeometryObject.extractStyleOverrides(json);
    final color = GeometryObject.colorFromJson(json, Colors.orange);
    final deps = (json['dependencies'] as List).cast<String>();
    final lineStyleToken = props['lineStyle'] ?? props['style'];

    return GeoPerpendicularLine(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector:
          Multivector.zero(), // Will be recalculated during DAG reconstruction
      thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
      lineStyle: GeoLine2P._parseLineStyle(lineStyleToken as String?),
      color: color,
      visible: json['visible'] as bool? ?? true,
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
    super.thickness,
    super.lineStyle,
    super.color = Colors.teal,
    super.visible,
    super.styleOverrides,
  });

  /// Create parallel line to another line through a point
  static GeoParallelLine fromLine({
    required String id,
    required String label,
    required GeoLine line,
    required GeoPoint point,
    double thickness = 2.0,
    LineStyle lineStyle = LineStyle.solid,
    Color color = Colors.teal,
    bool visible = true,
  }) {
    final mv = constructParallelLine(line.multivector, point.multivector);

    return GeoParallelLine(
      id: id,
      label: label,
      dependencies: [line.id, point.id],
      multivector: mv,
      thickness: thickness,
      lineStyle: lineStyle,
      color: color,
      visible: visible,
    );
  }

  @override
  GeoParallelLine copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? a,
    double? b,
    double? c,
    double? thickness,
    LineStyle? lineStyle,
    Color? color,
    bool? visible,
    CanvasStyle? style,
  }) {
    final overrides = resolveStyleOverrides(style);
    final resolvedColor = resolveColor(color, style);
    return GeoParallelLine(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      thickness: thickness ?? this.thickness,
      lineStyle: lineStyle ?? this.lineStyle,
      color: resolvedColor,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoParallelLine';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'a': a,
      'b': b,
      'c': c,
      'thickness': thickness,
      'lineStyle': lineStyle.toString().split('.').last,
    };
    return json;
  }

  static GeoParallelLine fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final styleOverrides = GeometryObject.extractStyleOverrides(json);
    final color = GeometryObject.colorFromJson(json, Colors.teal);
    final deps = (json['dependencies'] as List).cast<String>();
    final lineStyleToken = props['lineStyle'] ?? props['style'];

    return GeoParallelLine(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector:
          Multivector.zero(), // Will be recalculated during DAG reconstruction
      thickness: (props['thickness'] as num?)?.toDouble() ?? 2.0,
      lineStyle: GeoLine2P._parseLineStyle(lineStyleToken as String?),
      color: color,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }
}
