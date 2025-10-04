import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../geometry_object.dart';
import 'geo_point.dart';

/// Abstract base class for all circle types
abstract class GeoCircle extends SimpleGeometryObject {
  /// Center x coordinate
  final double centerX;
  
  /// Center y coordinate
  final double centerY;
  
  /// Radius
  final double radius;
  
  /// Rendering thickness
  final double thickness;
  
  /// Whether to fill the circle
  final bool filled;

  GeoCircle({
    required super.id,
    required super.label,
    required super.dependencies,
    required this.centerX,
    required this.centerY,
    required this.radius,
    this.thickness = 2.0,
    this.filled = false,
    super.color = Colors.green,
    super.visible,
  });

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
    return filled
        ? dist <= radius
        : (dist - radius).abs() <= thickness;
  }

  @override
  Rect getBounds() {
    return Rect.fromCircle(center: center, radius: radius + thickness);
  }

  @override
  double distanceTo(Offset point) {
    final distToCenter = (point - center).distance;
    return (distToCenter - radius).abs();
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
  List<Object?> get props =>
      [...super.props, centerX, centerY, radius, thickness, filled];
}

/// Circle defined by center point and a point on the circumference
class GeoCircle2P extends GeoCircle {
  GeoCircle2P({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.centerX,
    required super.centerY,
    required super.radius,
    super.thickness,
    super.filled,
    super.color,
    super.visible,
  }) : assert(
            dependencies.length == 2,
            'Circle from 2 points requires exactly 2 point dependencies');

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
    final radius = (center.position - pointOnCircle.position).distance;
    
    return GeoCircle2P(
      id: id,
      label: label,
      dependencies: [center.id, pointOnCircle.id],
      centerX: center.x,
      centerY: center.y,
      radius: radius,
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
    double? centerX,
    double? centerY,
    double? radius,
    double? thickness,
    bool? filled,
    Color? color,
    bool? visible,
  }) {
    return GeoCircle2P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      radius: radius ?? this.radius,
      thickness: thickness ?? this.thickness,
      filled: filled ?? this.filled,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}

/// Circle through three points
class GeoCircle3P extends GeoCircle {
  GeoCircle3P({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 3 dependencies
    required super.centerX,
    required super.centerY,
    required super.radius,
    super.thickness,
    super.filled,
    super.color,
    super.visible,
  }) : assert(
            dependencies.length == 3,
            'Circle through 3 points requires exactly 3 point dependencies');

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
    // Calculate circumcircle using determinant method
    final d = 2 * (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y));
    
    if (d.abs() < 0.001) {
      // Points are collinear
      return null;
    }
    
    final p1Sq = p1.x * p1.x + p1.y * p1.y;
    final p2Sq = p2.x * p2.x + p2.y * p2.y;
    final p3Sq = p3.x * p3.x + p3.y * p3.y;
    
    final cx = (p1Sq * (p2.y - p3.y) + p2Sq * (p3.y - p1.y) + p3Sq * (p1.y - p2.y)) / d;
    final cy = (p1Sq * (p3.x - p2.x) + p2Sq * (p1.x - p3.x) + p3Sq * (p2.x - p1.x)) / d;
    
    final radius = math.sqrt((p1.x - cx) * (p1.x - cx) + (p1.y - cy) * (p1.y - cy));
    
    return GeoCircle3P(
      id: id,
      label: label,
      dependencies: [p1.id, p2.id, p3.id],
      centerX: cx,
      centerY: cy,
      radius: radius,
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
    double? centerX,
    double? centerY,
    double? radius,
    double? thickness,
    bool? filled,
    Color? color,
    bool? visible,
  }) {
    return GeoCircle3P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      radius: radius ?? this.radius,
      thickness: thickness ?? this.thickness,
      filled: filled ?? this.filled,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}

/// Circle after inversion transformation
class GeoInvCircle extends GeoCircle {
  GeoInvCircle({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.centerX,
    required super.centerY,
    required super.radius,
    super.thickness,
    super.filled,
    super.color = Colors.purple,
    super.visible,
  });

  @override
  GeoInvCircle copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    double? centerX,
    double? centerY,
    double? radius,
    double? thickness,
    bool? filled,
    Color? color,
    bool? visible,
  }) {
    return GeoInvCircle(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      radius: radius ?? this.radius,
      thickness: thickness ?? this.thickness,
      filled: filled ?? this.filled,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}
