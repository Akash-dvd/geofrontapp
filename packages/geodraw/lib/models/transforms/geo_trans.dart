import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../../core/dag/dag_manager.dart';

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

/// Line inversion (reflection) transformation
class GeoLineInverse extends GeoTrans {
  GeoLineInverse({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  });

  @override
  GeoLineInverse copyWith({
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
    return GeoLineInverse(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoLineInverse';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = <String, dynamic>{};
    // Line inversion uses simple encoding (o, e1, e2, O)
    json[SimpleGeometryObject.multivectorKey] = 
        SimpleGeometryObject.encodeMultivector(multivector);
    return json;
  }

  static GeoLineInverse fromJson(Map<String, dynamic> json) {
    final deps = (json['dependencies'] as List).cast<String>();
    final styleOverrides = _transformStyleOverridesFromJson(json, GeoLineInverse);
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );

    return GeoLineInverse(
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
    if (dagManager is! DAGManager) {
      return null;
    }

    // Parents order: parents[0] = object, parents[1] = subject (mirror line)
    // For GeoLineInverse: dependencies = [lineId], so parents[0] = mirror line
    if (parents.isEmpty) {
      return null;
    }

    final mirrorObj = parents[0];
    if (mirrorObj is! SimpleGeometryObject) {
      return null;
    }

    final mirrorMv = mirrorObj.multivector;
    // Cannot create line reflection with infinity
    if (mirrorMv.isInf()) {
      return null;
    }
    if (!mirrorMv.isLine()) {
      return null;
    }

    final operator = constructLineReflectionOperator(mirrorMv);
    return copyWith(multivector: operator);
  }
}

/// Circle inversion (reflection) transformation
class GeoCircleInverse extends GeoTrans {
  /// Power of inversion (radius squared)
  final double power;

  GeoCircleInverse({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    required this.power,
    super.visible,
    super.styleOverrides,
  });

  @override
  GeoCircleInverse copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? power,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoCircleInverse(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      power: power ?? this.power,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  List<Object?> get props => [...super.props, power];

  @override
  String get type => 'GeoCircleInverse';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'power': power};
    // Circle inversion uses simple encoding (o, e1, e2, O)
    json[SimpleGeometryObject.multivectorKey] = 
        SimpleGeometryObject.encodeMultivector(multivector);
    return json;
  }

  static GeoCircleInverse fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final deps = (json['dependencies'] as List).cast<String>();
    final styleOverrides = _transformStyleOverridesFromJson(json, GeoCircleInverse);
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );

    return GeoCircleInverse(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      power: (props['power'] as num).toDouble(),
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager) {
      return null;
    }

    // Parents order: parents[0] = object, parents[1] = subject (mirror circle)
    // For GeoCircleInverse: dependencies = [circleId], so parents[0] = mirror circle
    if (parents.isEmpty) {
      return null;
    }

    final mirrorObj = parents[0];
    if (mirrorObj is! SimpleGeometryObject) {
      return null;
    }

    final mirrorMv = mirrorObj.multivector;
    // Cannot create circle reflection with infinity
    if (mirrorMv.isInf()) {
      return null;
    }
    if (!mirrorMv.isCircle()) {
      return null;
    }

    final operator = constructCircleReflectionOperator(mirrorMv);
    return copyWith(multivector: operator);
  }
}

/// Point inversion (reflection) transformation
class GeoPointInverse extends GeoTrans {
  GeoPointInverse({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  });

  @override
  GeoPointInverse copyWith({
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
    return GeoPointInverse(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoPointInverse';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = <String, dynamic>{};
    // Point inversion uses full transform operator encoding (s, oe1, oe2, oO, e12, e1O, e2O)
    json[SimpleGeometryObject.multivectorKey] = 
        SimpleGeometryObject.encodeTransformOperator(multivector);
    return json;
  }

  static GeoPointInverse fromJson(Map<String, dynamic> json) {
    final deps = (json['dependencies'] as List).cast<String>();
    final styleOverrides = _transformStyleOverridesFromJson(json, GeoPointInverse);
    final mv = SimpleGeometryObject.decodeTransformOperator(
      json[SimpleGeometryObject.multivectorKey],
    );

    return GeoPointInverse(
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
    if (dagManager is! DAGManager) {
      return null;
    }

    // Parents order: parents[0] = object, parents[1] = subject (mirror point)
    // For GeoPointInverse: dependencies = [pointId], so parents[0] = mirror point
    if (parents.isEmpty) {
      return null;
    }

    final mirrorObj = parents[0];
    if (mirrorObj is! SimpleGeometryObject) {
      return null;
    }

    final mirrorMv = mirrorObj.multivector;
    // Cannot create point reflection with infinity
    if (mirrorMv.isInf()) {
      return null;
    }
    if (!mirrorMv.isPoint()) {
      return null;
    }

    final operator = constructPointReflectionOperator(mirrorMv);
    return copyWith(multivector: operator);
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
    // Use transform operator encoding for rotation
    json[SimpleGeometryObject.multivectorKey] = 
        SimpleGeometryObject.encodeTransformOperator(multivector);
    return json;
  }

  static GeoRotate fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final deps = (json['dependencies'] as List).cast<String>();
    final styleOverrides = _transformStyleOverridesFromJson(json, GeoRotate);
    final mv = SimpleGeometryObject.decodeTransformOperator(
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
    if (dagManager is! DAGManager) {
      return null;
    }

    // Parents order: parents[0] = object, parents[1] = subject (center point for rotation)
    // For GeoRotate: dependencies = [centerPointId], so parents[0] = center point
    if (parents.isEmpty) {
      return null;
    }

    final centerObj = parents[0];
    if (centerObj is! SimpleGeometryObject) {
      return null;
    }
    
    final centerMv = centerObj.multivector;
    // Cannot create rotation with infinity center
    if (centerMv.isInf()) {
      return null;
    }
    if (!centerMv.isPoint()) {
      return null;
    }

    final rotor = constructRotationOperator(centerMv, angle);
    return copyWith(multivector: rotor);
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
    // Use transform operator encoding for dilation
    json[SimpleGeometryObject.multivectorKey] = 
        SimpleGeometryObject.encodeTransformOperator(multivector);
    return json;
  }

  static GeoDilate fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final deps = (json['dependencies'] as List).cast<String>();
    final styleOverrides = _transformStyleOverridesFromJson(json, GeoDilate);
    final mv = SimpleGeometryObject.decodeTransformOperator(
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
    if (dagManager is! DAGManager) {
      return null;
    }

    // Parents order: parents[0] = object, parents[1] = subject (center point for dilation)
    // For GeoDilate: dependencies = [centerPointId], so parents[0] = center point
    if (parents.isEmpty) {
      return null;
    }

    final centerObj = parents[0];
    if (centerObj is! SimpleGeometryObject) {
      return null;
    }
    
    final centerMv = centerObj.multivector;
    // Cannot create dilation with infinity center
    if (centerMv.isInf()) {
      return null;
    }
    if (!centerMv.isPoint()) {
      return null;
    }

    final dilator = constructDilationOperator(centerMv, factor);
    return copyWith(multivector: dilator);
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
    // Use transform operator encoding for translation
    json[SimpleGeometryObject.multivectorKey] = 
        SimpleGeometryObject.encodeTransformOperator(multivector);
    return json;
  }

  static GeoTranslate fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final deps = (json['dependencies'] as List).cast<String>();
    final styleOverrides = _transformStyleOverridesFromJson(json, GeoTranslate);
    final mv = SimpleGeometryObject.decodeTransformOperator(
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
    if (dagManager is! DAGManager) {
      return null;
    }

    // Parents order: parents[0] = object, parents[1] = from point, parents[2] = to point
    // For GeoTranslate: dependencies = [fromPointId, toPointId], so parents[0] = from, parents[1] = to
    if (parents.length < 2) {
      return null;
    }

    final fromObj = parents[0];
    final toObj = parents[1];
    
    if (fromObj is! SimpleGeometryObject || toObj is! SimpleGeometryObject) {
      return null;
    }
    
    final fromMv = fromObj.multivector;
    final toMv = toObj.multivector;
    
    // Cannot create translation with infinity points
    if (fromMv.isInf() || toMv.isInf()) {
      return null;
    }
    if (!fromMv.isPoint() || !toMv.isPoint()) {
      return null;
    }

    // Calculate translation vector (dx, dy)
    final dx = toMv.e1 - fromMv.e1;
    final dy = toMv.e2 - fromMv.e2;

    // Construct translation operator
    final translator = constructTranslationOperator(dx, dy);

    return copyWith(multivector: translator);
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

