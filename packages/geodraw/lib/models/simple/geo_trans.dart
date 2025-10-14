import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';
import '../geometry_object.dart';

/// Abstract base class for geometric transformations
abstract class GeoTrans extends SimpleGeometryObject {
  GeoTrans({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.color,
    super.visible,
  });

  // Transformations don't render themselves, they transform other objects
  @override
  void draw(canvas, paint) {
    // No-op: transformations don't have visual representation
  }

  @override
  bool contains(position) => false;

  @override
  Rect getBounds() => Rect.zero;

  @override
  double distanceTo(point) => double.infinity;

  @override
  bool intersects(other) => false;
}

/// Inversion transformation
class GeoInverse extends GeoTrans {
  /// Center of inversion
  final String centerPointId;

  /// Power of inversion (radius squared)
  final double power;

  GeoInverse({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    required this.centerPointId,
    required this.power,
    super.color,
    super.visible,
  });

  @override
  GeoInverse copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    String? centerPointId,
    double? power,
    Color? color,
    bool? visible,
  }) {
    return GeoInverse(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      centerPointId: centerPointId ?? this.centerPointId,
      power: power ?? this.power,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }

  @override
  List<Object?> get props => [...super.props, centerPointId, power];

  @override
  String get type => 'GeoInverse';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'centerPointId': centerPointId, 'power': power};
    return json;
  }

  static GeoInverse fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final colorHex = (json['color'] as String).replaceAll('#', '');
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoInverse(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: Multivector.zero(),
      centerPointId: props['centerPointId'] as String,
      power: (props['power'] as num).toDouble(),
      color: Color(int.parse(colorHex, radix: 16)),
      visible: json['visible'] as bool? ?? true,
    );
  }
}

/// Rotation transformation
class GeoRotate extends GeoTrans {
  /// Center of rotation
  final String centerPointId;

  /// Angle in radians
  final double angle;

  GeoRotate({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    required this.centerPointId,
    required this.angle,
    super.color,
    super.visible,
  });

  @override
  GeoRotate copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    String? centerPointId,
    double? angle,
    Color? color,
    bool? visible,
  }) {
    return GeoRotate(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      centerPointId: centerPointId ?? this.centerPointId,
      angle: angle ?? this.angle,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }

  @override
  List<Object?> get props => [...super.props, centerPointId, angle];

  @override
  String get type => 'GeoRotate';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'centerPointId': centerPointId, 'angle': angle};
    return json;
  }

  static GeoRotate fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final colorHex = (json['color'] as String).replaceAll('#', '');
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoRotate(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: Multivector.zero(),
      centerPointId: props['centerPointId'] as String,
      angle: (props['angle'] as num).toDouble(),
      color: Color(int.parse(colorHex, radix: 16)),
      visible: json['visible'] as bool? ?? true,
    );
  }
}

/// Dilation (scaling) transformation
class GeoDilate extends GeoTrans {
  /// Center of dilation
  final String centerPointId;

  /// Scale factor
  final double factor;

  GeoDilate({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    required this.centerPointId,
    required this.factor,
    super.color,
    super.visible,
  });

  @override
  GeoDilate copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    String? centerPointId,
    double? factor,
    Color? color,
    bool? visible,
  }) {
    return GeoDilate(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      centerPointId: centerPointId ?? this.centerPointId,
      factor: factor ?? this.factor,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }

  @override
  List<Object?> get props => [...super.props, centerPointId, factor];

  @override
  String get type => 'GeoDilate';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'centerPointId': centerPointId, 'factor': factor};
    return json;
  }

  static GeoDilate fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final colorHex = (json['color'] as String).replaceAll('#', '');
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoDilate(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: Multivector.zero(),
      centerPointId: props['centerPointId'] as String,
      factor: (props['factor'] as num).toDouble(),
      color: Color(int.parse(colorHex, radix: 16)),
      visible: json['visible'] as bool? ?? true,
    );
  }
}
