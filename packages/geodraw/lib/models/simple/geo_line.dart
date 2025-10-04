import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../geometry_object.dart';
import 'geo_point.dart';

/// Abstract base class for all line types
abstract class GeoLine extends SimpleGeometryObject {
  /// Line equation: ax + by + c = 0
  final double a;
  final double b;
  final double c;
  
  /// Rendering thickness
  final double thickness;
  
  /// Line style (solid, dashed, dotted)
  final LineStyle style;

  GeoLine({
    required super.id,
    required super.label,
    required super.dependencies,
    required this.a,
    required this.b,
    required this.c,
    this.thickness = 2.0,
    this.style = LineStyle.solid,
    super.color = Colors.blue,
    super.visible,
  });

  @override
  void draw(Canvas canvas, Paint paint) {
    if (!visible) return;
    
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;
    
    // Apply line style
    if (style == LineStyle.dashed) {
      linePaint.strokeCap = StrokeCap.round;
    }
    
    // Draw line across canvas bounds (approximate as large segment)
    // This will be clipped by the viewport
    final points = _getLinePoints();
    if (points != null) {
      if (style == LineStyle.dashed) {
        _drawDashedLine(canvas, linePaint, points.$1, points.$2);
      } else if (style == LineStyle.dotted) {
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
    // Perpendicular distance from point to line
    final numerator = (a * point.dx + b * point.dy + c).abs();
    final denominator = math.sqrt(a * a + b * b);
    return numerator / denominator;
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
  List<Object?> get props => [...super.props, a, b, c, thickness, style];
}

enum LineStyle {
  solid,
  dashed,
  dotted,
}

/// Line through two points
class GeoLine2P extends GeoLine {
  GeoLine2P({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.a,
    required super.b,
    required super.c,
    super.thickness,
    super.style,
    super.color,
    super.visible,
  }) : assert(dependencies.length == 2, 'Line through 2 points requires exactly 2 point dependencies');

  /// Create line from two points
  static GeoLine2P fromPoints({
    required String id,
    required String label,
    required GeoPoint p1,
    required GeoPoint p2,
    double thickness = 2.0,
    LineStyle style = LineStyle.solid,
    Color color = Colors.blue,
    bool visible = true,
  }) {
    // Line equation: (y2-y1)x - (x2-x1)y + (x2-x1)y1 - (y2-y1)x1 = 0
    final a = p2.y - p1.y;
    final b = -(p2.x - p1.x);
    final c = (p2.x - p1.x) * p1.y - (p2.y - p1.y) * p1.x;
    
    return GeoLine2P(
      id: id,
      label: label,
      dependencies: [p1.id, p2.id],
      a: a,
      b: b,
      c: c,
      thickness: thickness,
      style: style,
      color: color,
      visible: visible,
    );
  }

  @override
  GeoLine2P copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    double? a,
    double? b,
    double? c,
    double? thickness,
    LineStyle? style,
    Color? color,
    bool? visible,
  }) {
    return GeoLine2P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      a: a ?? this.a,
      b: b ?? this.b,
      c: c ?? this.c,
      thickness: thickness ?? this.thickness,
      style: style ?? this.style,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}

/// Perpendicular bisector of a segment
class GeoPerpendicularBisector extends GeoLine {
  GeoPerpendicularBisector({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.a,
    required super.b,
    required super.c,
    super.thickness,
    super.style,
    super.color = Colors.cyan,
    super.visible,
  });

  static GeoPerpendicularBisector fromPoints({
    required String id,
    required String label,
    required GeoPoint p1,
    required GeoPoint p2,
    double thickness = 2.0,
    LineStyle style = LineStyle.solid,
    Color color = Colors.cyan,
    bool visible = true,
  }) {
    // Midpoint
    final mx = (p1.x + p2.x) / 2;
    final my = (p1.y + p2.y) / 2;
    
    // Perpendicular slope
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    
    // Line equation: -dx * (x - mx) + dy * (y - my) = 0
    // Simplified: -dx * x + dy * y + dx * mx - dy * my = 0
    final a = -dx;
    final b = dy;
    final c = dx * mx - dy * my;
    
    return GeoPerpendicularBisector(
      id: id,
      label: label,
      dependencies: [p1.id, p2.id],
      a: a,
      b: b,
      c: c,
      thickness: thickness,
      style: style,
      color: color,
      visible: visible,
    );
  }

  @override
  GeoPerpendicularBisector copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    double? a,
    double? b,
    double? c,
    double? thickness,
    LineStyle? style,
    Color? color,
    bool? visible,
  }) {
    return GeoPerpendicularBisector(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      a: a ?? this.a,
      b: b ?? this.b,
      c: c ?? this.c,
      thickness: thickness ?? this.thickness,
      style: style ?? this.style,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}

/// Perpendicular line to another line through a point
class GeoPerpendicularLine extends GeoLine {
  GeoPerpendicularLine({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.a,
    required super.b,
    required super.c,
    super.thickness,
    super.style,
    super.color = Colors.orange,
    super.visible,
  });

  @override
  GeoPerpendicularLine copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    double? a,
    double? b,
    double? c,
    double? thickness,
    LineStyle? style,
    Color? color,
    bool? visible,
  }) {
    return GeoPerpendicularLine(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      a: a ?? this.a,
      b: b ?? this.b,
      c: c ?? this.c,
      thickness: thickness ?? this.thickness,
      style: style ?? this.style,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}

/// Parallel line to another line through a point
class GeoParallelLine extends GeoLine {
  GeoParallelLine({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.a,
    required super.b,
    required super.c,
    super.thickness,
    super.style,
    super.color = Colors.teal,
    super.visible,
  });

  @override
  GeoParallelLine copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    double? a,
    double? b,
    double? c,
    double? thickness,
    LineStyle? style,
    Color? color,
    bool? visible,
  }) {
    return GeoParallelLine(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      a: a ?? this.a,
      b: b ?? this.b,
      c: c ?? this.c,
      thickness: thickness ?? this.thickness,
      style: style ?? this.style,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}
