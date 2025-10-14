import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';
import '../geometry_object.dart';

/// Abstract base class for all point types
abstract class GeoPoint extends SimpleGeometryObject {
  /// Rendering size in pixels
  final double size;

  GeoPoint({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    this.size = 5.0,
    super.color = Colors.red,
    super.visible,
  });

  /// X coordinate derived from multivector
  double get x => multivector.e1;

  /// Y coordinate derived from multivector
  double get y => multivector.e2;

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
    // Convert the offset to a Multivector point
    final pointMv = constructFreePoint(point.dx, point.dy);
    // Use Multivector-based distance calculation
    return distancePointToPoint(multivector, pointMv);
  }

  @override
  bool intersects(SimpleGeometryObject other) {
    if (other is GeoPoint) {
      return distanceTo(other.position) < 0.001;
    }
    return other.intersects(this);
  }

  @override
  List<Object?> get props => [...super.props, size];
}

/// Free point that can be moved by the user
class GeoPointer extends GeoPoint {
  GeoPointer({
    required super.id,
    required super.label,
    required double x,
    required double y,
    super.size,
    super.color,
    super.visible,
  }) : super(
         dependencies: [], // Free points have no dependencies
         multivector: constructFreePoint(x, y),
       );

  @override
  GeoPointer copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? x,
    double? y,
    double? size,
    Color? color,
    bool? visible,
  }) {
    // Recalculate multivector from x, y if provided
    final newX = x ?? this.x;
    final newY = y ?? this.y;
    return GeoPointer(
      id: id ?? this.id,
      label: label ?? this.label,
      x: newX,
      y: newY,
      size: size ?? this.size,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }

  @override
  String get type => 'GeoPointer';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'x': x, 'y': y, 'size': size};
    return json;
  }

  static GeoPointer fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final colorHex = (json['color'] as String).replaceAll('#', '');

    return GeoPointer(
      id: json['id'] as String,
      label: json['label'] as String,
      x: (props['x'] as num).toDouble(),
      y: (props['y'] as num).toDouble(),
      size: (props['size'] as num?)?.toDouble() ?? 5.0,
      color: Color(int.parse(colorHex, radix: 16)),
      visible: json['visible'] as bool? ?? true,
    );
  }
}

/// Midpoint between two points
class GeoMidpoint extends GeoPoint {
  GeoMidpoint({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.multivector,
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
    final mv = constructMidpoint(p1.multivector, p2.multivector);

    return GeoMidpoint(
      id: id,
      label: label,
      dependencies: [p1.id, p2.id],
      multivector: mv,
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
    Multivector? multivector,
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
      multivector: multivector ?? this.multivector,
      size: size ?? this.size,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }

  @override
  String get type => 'GeoMidpoint';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'x': x, 'y': y, 'size': size};
    return json;
  }

  static GeoMidpoint fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final colorHex = (json['color'] as String).replaceAll('#', '');
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoMidpoint(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector:
          Multivector.zero(), // Will be recalculated during DAG reconstruction
      size: (props['size'] as num?)?.toDouble() ?? 5.0,
      color: Color(int.parse(colorHex, radix: 16)),
      visible: json['visible'] as bool? ?? true,
    );
  }
}

/// Point after inversion transformation
class GeoInvPoint extends GeoPoint {
  GeoInvPoint({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.size,
    super.color = Colors.purple,
    super.visible,
  });

  @override
  GeoInvPoint copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
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
      multivector: multivector ?? this.multivector,
      size: size ?? this.size,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }

  @override
  String get type => 'GeoInvPoint';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'x': x, 'y': y, 'size': size};
    return json;
  }

  static GeoInvPoint fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final colorHex = (json['color'] as String).replaceAll('#', '');
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoInvPoint(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector:
          Multivector.zero(), // Will be recalculated during DAG reconstruction
      size: (props['size'] as num?)?.toDouble() ?? 5.0,
      color: Color(int.parse(colorHex, radix: 16)),
      visible: json['visible'] as bool? ?? true,
    );
  }
}
