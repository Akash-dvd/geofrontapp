import 'dart:math' as math;

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

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    final parentsById = {for (final parent in parents) parent.id: parent};

    Multivector? subjectMv;

    for (final depId in dependencies) {
      if (depId == centerPointId) {
        continue;
      }
      final parent = parentsById[depId];
      if (parent is SimpleGeometryObject) {
        subjectMv = _subjectFromSimple(parent);
        if (subjectMv != null) {
          break;
        }
      }
    }

      if (subjectMv == null && centerPointId.isNotEmpty) {
        final centerParent = parentsById[centerPointId];
        if (centerParent is SimpleGeometryObject) {
          final centerMv = centerParent.multivector;
          if (centerMv.isPoint() && power > 0) {
            final radius = math.sqrt(power);
            final circleMv = constructCircleFromCenterAndRadius(
              centerMv,
              radius,
            );
            subjectMv = constructCircleReflectionOperator(circleMv);
          }
        }
    }

    if (subjectMv == null) {
      return null;
    }

    return copyWith(multivector: subjectMv);
  }

  Multivector? _subjectFromSimple(SimpleGeometryObject subject) {
    final subjectMv = subject.multivector;
      if (subjectMv.isLine()) {
      return constructLineReflectionOperator(subjectMv);
    }
    if (subjectMv.isCircle()) {
      return constructCircleReflectionOperator(subjectMv);
    }
    if (subjectMv.isPoint()) {
      return constructPointReflectionOperator(subjectMv);
    }
    return null;
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

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    final centerMv = _findPointMv(parents, centerPointId);
    if (centerMv == null) {
      return null;
    }

    final rotor = constructRotationOperator(centerMv, angle);
    return copyWith(multivector: rotor);
  }

  Multivector? _findPointMv(List<GeometryObject> parents, String targetId) {
    for (final parent in parents) {
      if (parent is SimpleGeometryObject && parent.id == targetId) {
        final mv = parent.multivector;
        if (mv.isPoint()) {
          return mv;
        }
      }
    }
    return null;
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

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    final centerMv = _findPointMv(parents, centerPointId);
    if (centerMv == null) {
      return null;
    }

    final dilator = constructDilationOperator(centerMv, factor);
    return copyWith(multivector: dilator);
  }

  Multivector? _findPointMv(List<GeometryObject> parents, String targetId) {
    for (final parent in parents) {
      if (parent is SimpleGeometryObject && parent.id == targetId) {
        final mv = parent.multivector;
        if (mv.isPoint()) {
          return mv;
        }
      }
    }
    return null;
  }
}

/// Translation transformation
class GeoTranslate extends GeoTrans {
  /// Starting point of translation vector
  final String fromPointId;

  /// Ending point of translation vector
  final String toPointId;

  GeoTranslate({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    required this.fromPointId,
    required this.toPointId,
    super.visible,
    super.styleOverrides,
  });

  @override
  GeoTranslate copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    String? fromPointId,
    String? toPointId,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoTranslate(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      fromPointId: fromPointId ?? this.fromPointId,
      toPointId: toPointId ?? this.toPointId,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  List<Object?> get props => [...super.props, fromPointId, toPointId];

  @override
  String get type => 'GeoTranslate';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'fromPointId': fromPointId,
      'toPointId': toPointId,
    };
    return json;
  }

  static GeoTranslate fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final deps = (json['dependencies'] as List).cast<String>();
    final styleOverrides = _transformStyleOverridesFromJson(json, GeoTranslate);
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );

    return GeoTranslate(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      fromPointId: props['fromPointId'] as String,
      toPointId: props['toPointId'] as String,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    final fromMv = _findPointMv(parents, fromPointId);
    final toMv = _findPointMv(parents, toPointId);
    if (fromMv == null || toMv == null) {
      return null;
    }

    // Calculate translation vector (dx, dy)
    final dx = toMv.e1 - fromMv.e1;
    final dy = toMv.e2 - fromMv.e2;

    // Construct translation operator
    final translator = constructTranslationOperator(dx, dy);

    return copyWith(multivector: translator);
  }

  Multivector? _findPointMv(List<GeometryObject> parents, String targetId) {
    for (final parent in parents) {
      if (parent is SimpleGeometryObject && parent.id == targetId) {
        final mv = parent.multivector;
        if (mv.isPoint()) {
          return mv;
        }
      }
    }
    return null;
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

