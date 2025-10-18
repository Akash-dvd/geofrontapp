import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';

/// Abstract base class for geometric transformations
abstract class GeoTrans extends SimpleGeometryObject {
  GeoTrans({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
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
    super.visible,
    super.styleOverrides,
  });

  @override
  GeoInverse copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    String? centerPointId,
    double? power,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoInverse(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      centerPointId: centerPointId ?? this.centerPointId,
      power: power ?? this.power,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
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
    final deps = (json['dependencies'] as List).cast<String>();
    final styleOverrides = _transformStyleOverridesFromJson(json, GeoInverse);
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );

    return GeoInverse(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      centerPointId: props['centerPointId'] as String,
      power: (props['power'] as num).toDouble(),
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
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
    super.visible,
    super.styleOverrides,
  });

  @override
  GeoRotate copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    String? centerPointId,
    double? angle,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoRotate(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      centerPointId: centerPointId ?? this.centerPointId,
      angle: angle ?? this.angle,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
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
    final deps = (json['dependencies'] as List).cast<String>();
    final styleOverrides = _transformStyleOverridesFromJson(json, GeoRotate);
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );

    return GeoRotate(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      centerPointId: props['centerPointId'] as String,
      angle: (props['angle'] as num).toDouble(),
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
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
    super.visible,
    super.styleOverrides,
  });

  @override
  GeoDilate copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    String? centerPointId,
    double? factor,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoDilate(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      centerPointId: centerPointId ?? this.centerPointId,
      factor: factor ?? this.factor,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
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
    final deps = (json['dependencies'] as List).cast<String>();
    final styleOverrides = _transformStyleOverridesFromJson(json, GeoDilate);
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );

    return GeoDilate(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      centerPointId: props['centerPointId'] as String,
      factor: (props['factor'] as num).toDouble(),
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }
}

Map<String, dynamic>? _transformStyleOverridesFromJson(
  Map<String, dynamic> json,
  Type type,
) {
  final existing = GeometryObject.extractStyleOverrides(json);
  if (existing != null) {
    return Map<String, dynamic>.unmodifiable(existing);
  }

  final parsedColor = GeometryObject.parseColor(json['color']);
  if (parsedColor == null) {
    return null;
  }

  final defaults = CanvasStyleDefaults.instance.resolveForType(type);
  final diff = defaults.copyWith(strokeColor: parsedColor).diff(defaults);
  if (diff.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(diff);
}
