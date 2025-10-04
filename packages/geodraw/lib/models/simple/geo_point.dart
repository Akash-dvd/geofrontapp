import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../geometry_object.dart';

/// Abstract base class for all point types
abstract class GeoPoint extends SimpleGeometryObject {
  /// X coordinate in world space
  final double x;
  
  /// Y coordinate in world space
  final double y;
  
  /// Rendering size in pixels
  final double size;

  GeoPoint({
    required super.id,
    required super.label,
    required super.dependencies,
    required this.x,
    required this.y,
    this.size = 5.0,
    super.color = Colors.red,
    super.visible,
  });

  Offset get position => Offset(x, y);

  @override
  void draw(Canvas canvas, Paint paint) {
    if (!visible) return;
    
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(position, size, pointPaint);
    
    // Draw label
    if (label.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + size + 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool contains(Offset position) {
    return distanceTo(position) <= size;
  }

  @override
  Rect getBounds() {
    return Rect.fromCircle(center: position, radius: size);
  }

  @override
  double distanceTo(Offset point) {
    return (position - point).distance;
  }

  @override
  bool intersects(SimpleGeometryObject other) {
    if (other is GeoPoint) {
      return distanceTo(other.position) < 0.001;
    }
    return other.intersects(this);
  }

  @override
  List<Object?> get props => [...super.props, x, y, size];
}

/// Free point that can be moved by the user
class GeoPointer extends GeoPoint {
  GeoPointer({
    required super.id,
    required super.label,
    required super.x,
    required super.y,
    super.size,
    super.color,
    super.visible,
  }) : super(dependencies: []); // Free points have no dependencies

  @override
  GeoPointer copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    double? x,
    double? y,
    double? size,
    Color? color,
    bool? visible,
  }) {
    return GeoPointer(
      id: id ?? this.id,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}

/// Midpoint between two points
class GeoMidpoint extends GeoPoint {
  GeoMidpoint({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.x,
    required super.y,
    super.size,
    super.color = Colors.green,
    super.visible,
  }) : assert(dependencies.length == 2, 'Midpoint requires exactly 2 points');

  /// Calculate midpoint from two points
  static GeoMidpoint fromPoints({
    required String id,
    required String label,
    required GeoPoint p1,
    required GeoPoint p2,
    double size = 5.0,
    Color color = Colors.green,
    bool visible = true,
  }) {
    return GeoMidpoint(
      id: id,
      label: label,
      dependencies: [p1.id, p2.id],
      x: (p1.x + p2.x) / 2,
      y: (p1.y + p2.y) / 2,
      size: size,
      color: color,
      visible: visible,
    );
  }

  @override
  GeoMidpoint copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    double? x,
    double? y,
    double? size,
    Color? color,
    bool? visible,
  }) {
    return GeoMidpoint(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}

/// Point after inversion transformation
class GeoInvPoint extends GeoPoint {
  GeoInvPoint({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.x,
    required super.y,
    super.size,
    super.color = Colors.purple,
    super.visible,
  });

  @override
  GeoInvPoint copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    double? x,
    double? y,
    double? size,
    Color? color,
    bool? visible,
  }) {
    return GeoInvPoint(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}
