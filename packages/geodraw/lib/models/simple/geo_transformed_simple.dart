import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../geometry_object.dart';
import '../transforms/transformation_engine.dart';
import 'geo_circle.dart';
import 'geo_line.dart';
import 'geo_point.dart';
import '../transforms/geo_trans.dart';

List<String> _normalizedDependencies(
  List<String>? dependencies,
  String primary,
  String transform,
) {
  if (dependencies == null || dependencies.isEmpty) {
    return List<String>.unmodifiable(<String>[primary, transform]);
  }
  final normalized = List<String>.from(dependencies);
  if (!normalized.contains(primary)) {
    normalized.insert(0, primary);
  }
  if (!normalized.contains(transform)) {
    normalized.add(transform);
  }
  return List<String>.unmodifiable(normalized);
}

/// Point produced by a geometric transformation.
class GeoTransPoint extends GeoPoint {
  GeoTransPoint({
    required super.id,
    required super.label,
    required List<String>? dependencies,
    required super.multivector,
    required this.sourcePointId,
    required this.transformId,
    super.visible,
    super.styleOverrides,
  }) : super(dependencies: _normalizedDependencies(dependencies, sourcePointId, transformId));

  final String sourcePointId;
  final String transformId;

  @override
  GeoTransPoint copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? x,
    double? y,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    String? sourcePointId,
    String? transformId,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    final updatedSource = sourcePointId ?? this.sourcePointId;
    final updatedTransform = transformId ?? this.transformId;
  final List<String> rawDependencies = dependencies ?? this.dependencies;
  final normalizedDependencies =
    _normalizedDependencies(rawDependencies, updatedSource, updatedTransform);

    return GeoTransPoint(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: normalizedDependencies,
      multivector: multivector ?? this.multivector,
      sourcePointId: updatedSource,
      transformId: updatedTransform,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoTransPoint';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'x': x,
      'y': y,
      'sourcePointId': sourcePointId,
      'transformId': transformId,
    };
    return json;
  }

  static GeoTransPoint fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? const {};
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = GeometryObject.extractStyleOverrides(json);

    final sourceId =
        props['sourcePointId'] as String? ?? (deps.isNotEmpty ? deps.first : '');
    final transformId = props['transformId'] as String? ??
        (deps.length > 1 ? deps[1] : '');

    return GeoTransPoint(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      sourcePointId: sourceId,
      transformId: transformId,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    final sourcePoint = _findPoint(parents, sourcePointId);
    final transform = _findTransform(parents, transformId);
    if (sourcePoint == null || transform == null) {
      return null;
    }

    final result = TransformationEngine.transformSimple(
      source: sourcePoint,
      transform: transform,
      id: id,
      label: label,
      dependencies: dependencies,
      visible: visible,
      styleOverrides: styleOverrides,
    );

    if (result is! GeoTransPoint) {
      return copyWith();
    }

    return result;
  }

  GeoPoint? _findPoint(List<GeometryObject> parents, String targetId) {
    for (final parent in parents) {
      if (parent is GeoPoint && parent.id == targetId) {
        return parent;
      }
    }
    return null;
  }

  GeoTrans? _findTransform(List<GeometryObject> parents, String targetId) {
    for (final parent in parents) {
      if (parent is GeoTrans && parent.id == targetId) {
        return parent;
      }
    }
    return null;
  }
}

/// Line produced by a geometric transformation.
class GeoTransLine extends GeoLine {
  GeoTransLine({
    required super.id,
    required super.label,
    required List<String>? dependencies,
    required super.multivector,
    required this.sourceObjectId,
    required this.transformId,
    super.visible,
    super.styleOverrides,
  }) : super(dependencies: _normalizedDependencies(dependencies, sourceObjectId, transformId));

  final String sourceObjectId;
  final String transformId;

  @override
  GeoTransLine copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    String? sourceObjectId,
    String? transformId,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    final updatedSource = sourceObjectId ?? this.sourceObjectId;
    final updatedTransform = transformId ?? this.transformId;
  final List<String> rawDependencies = dependencies ?? this.dependencies;
  final normalizedDependencies =
    _normalizedDependencies(rawDependencies, updatedSource, updatedTransform);

    return GeoTransLine(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: normalizedDependencies,
      multivector: multivector ?? this.multivector,
      sourceObjectId: updatedSource,
      transformId: updatedTransform,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoTransLine';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'sourceObjectId': sourceObjectId,
      'transformId': transformId,
    };
    return json;
  }

  static GeoTransLine fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? const {};
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
  final styleOverrides = GeometryObject.extractStyleOverrides(json);

    final sourceId =
        props['sourceObjectId'] as String? ?? (deps.isNotEmpty ? deps.first : '');
    final transformId = props['transformId'] as String? ??
        (deps.length > 1 ? deps[1] : '');

    return GeoTransLine(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      sourceObjectId: sourceId,
      transformId: transformId,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    final source = _findSource(parents, sourceObjectId);
    final transform = _findTransform(parents, transformId);
    if (source == null || transform == null) {
      return null;
    }

    final result = TransformationEngine.transformSimple(
      source: source,
      transform: transform,
      id: id,
      label: label,
      dependencies: dependencies,
      visible: visible,
      styleOverrides: styleOverrides,
    );

    if (result is GeoTransLine) {
      return result;
    }
    if (result is GeoTransCircle) {
      return result;
    }
    return copyWith();
  }

  SimpleGeometryObject? _findSource(
    List<GeometryObject> parents,
    String targetId,
  ) {
    for (final parent in parents) {
      if (parent is SimpleGeometryObject && parent.id == targetId) {
        return parent;
      }
    }
    return null;
  }

  GeoTrans? _findTransform(List<GeometryObject> parents, String targetId) {
    for (final parent in parents) {
      if (parent is GeoTrans && parent.id == targetId) {
        return parent;
      }
    }
    return null;
  }
}

/// Circle produced by a geometric transformation.
class GeoTransCircle extends GeoCircle {
  GeoTransCircle({
    required super.id,
    required super.label,
    required List<String>? dependencies,
    required super.multivector,
    required this.sourceObjectId,
    required this.transformId,
    super.visible,
    super.styleOverrides,
  }) : super(dependencies: _normalizedDependencies(dependencies, sourceObjectId, transformId));

  final String sourceObjectId;
  final String transformId;

  @override
  GeoTransCircle copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    String? sourceObjectId,
    String? transformId,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    final updatedSource = sourceObjectId ?? this.sourceObjectId;
    final updatedTransform = transformId ?? this.transformId;
  final List<String> rawDependencies = dependencies ?? this.dependencies;
  final normalizedDependencies =
    _normalizedDependencies(rawDependencies, updatedSource, updatedTransform);

    return GeoTransCircle(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: normalizedDependencies,
      multivector: multivector ?? this.multivector,
      sourceObjectId: updatedSource,
      transformId: updatedTransform,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoTransCircle';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'sourceObjectId': sourceObjectId,
      'transformId': transformId,
    };
    return json;
  }

  static GeoTransCircle fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? const {};
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
  final styleOverrides = GeometryObject.extractStyleOverrides(json);

    final sourceId =
        props['sourceObjectId'] as String? ?? (deps.isNotEmpty ? deps.first : '');
    final transformId = props['transformId'] as String? ??
        (deps.length > 1 ? deps[1] : '');

    return GeoTransCircle(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      sourceObjectId: sourceId,
      transformId: transformId,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    final source = _findSource(parents, sourceObjectId);
    final transform = _findTransform(parents, transformId);
    if (source == null || transform == null) {
      return null;
    }

    final result = TransformationEngine.transformSimple(
      source: source,
      transform: transform,
      id: id,
      label: label,
      dependencies: dependencies,
      visible: visible,
      styleOverrides: styleOverrides,
    );

    if (result is GeoTransCircle) {
      return result;
    }
    if (result is GeoTransLine) {
      return result;
    }
    return copyWith();
  }

  SimpleGeometryObject? _findSource(
    List<GeometryObject> parents,
    String targetId,
  ) {
    for (final parent in parents) {
      if (parent is SimpleGeometryObject && parent.id == targetId) {
        return parent;
      }
    }
    return null;
  }

  GeoTrans? _findTransform(List<GeometryObject> parents, String targetId) {
    for (final parent in parents) {
      if (parent is GeoTrans && parent.id == targetId) {
        return parent;
      }
    }
    return null;
  }
}
