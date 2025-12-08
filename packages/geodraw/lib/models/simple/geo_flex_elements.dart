import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../geometry_object.dart';
import '../../core/dag/dag_manager.dart';
import 'geo_point.dart';
import 'geo_line.dart';
import 'geo_circle.dart';
// Import Geo3Flex and GeoALCbc for rebuildFromParents
// Note: This creates a circular dependency, but it's safe because we only use static methods
import 'geo_flex.dart' show Geo3Flex, GeoALCbc;

/// Type-safe enum for flex constructor types
enum FlexConstructorType {
  geo3Flex,
  geoALCbc;

  /// Convert from string (for backward compatibility with JSON)
  static FlexConstructorType fromString(String? str) {
    switch (str?.toLowerCase()) {
      case 'geoalcbc':
      case 'alcbc':
        return FlexConstructorType.geoALCbc;
      case 'geo3flex':
      case '3flex':
      default:
        return FlexConstructorType.geo3Flex;
    }
  }

  /// Convert to string (for JSON serialization)
  String toJsonString() {
    switch (this) {
      case FlexConstructorType.geo3Flex:
        return 'Geo3Flex';
      case FlexConstructorType.geoALCbc:
        return 'GeoALCbc';
    }
  }
}

/// Point produced from three flexible objects (Geo3Flex or GeoALCbc)
/// Stores all 3 dependency IDs for proper rebuilding
class GeoFlexPoint extends GeoPoint {
  GeoFlexPoint({
    required super.id,
    required super.label,
    required List<String>? dependencies,
    required super.multivector,
    required this.dependency1Id,
    required this.dependency2Id,
    required this.dependency3Id,
    required this.sourceConstructorType,
    super.visible,
    super.styleOverrides,
  }) : super(
          dependencies: dependencies ??
              List<String>.unmodifiable([dependency1Id, dependency2Id, dependency3Id]),
        );

  final String dependency1Id;
  final String dependency2Id;
  final String dependency3Id;
  final FlexConstructorType sourceConstructorType;

  @override
  GeoFlexPoint copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    String? dependency1Id,
    String? dependency2Id,
    String? dependency3Id,
    FlexConstructorType? sourceConstructorType,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    final updatedDep1 = dependency1Id ?? this.dependency1Id;
    final updatedDep2 = dependency2Id ?? this.dependency2Id;
    final updatedDep3 = dependency3Id ?? this.dependency3Id;
    final normalizedDeps = dependencies ??
        List<String>.unmodifiable([updatedDep1, updatedDep2, updatedDep3]);

    return GeoFlexPoint(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: normalizedDeps,
      multivector: multivector ?? this.multivector,
      dependency1Id: updatedDep1,
      dependency2Id: updatedDep2,
      dependency3Id: updatedDep3,
      sourceConstructorType: sourceConstructorType ?? this.sourceConstructorType,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoFlexPoint';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'x': x,
      'y': y,
      'dependency1Id': dependency1Id,
      'dependency2Id': dependency2Id,
      'dependency3Id': dependency3Id,
      'sourceConstructorType': sourceConstructorType.toJsonString(),
    };
    return json;
  }

  static GeoFlexPoint fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? const {};
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = GeometryObject.extractStyleOverrides(json);

    final dep1 = props['dependency1Id'] as String? ?? (deps.isNotEmpty ? deps[0] : '');
    final dep2 = props['dependency2Id'] as String? ?? (deps.length > 1 ? deps[1] : '');
    final dep3 = props['dependency3Id'] as String? ?? (deps.length > 2 ? deps[2] : '');
    final sourceType = FlexConstructorType.fromString(
      props['sourceConstructorType'] as String?,
    );

    return GeoFlexPoint(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      dependency1Id: dep1,
      dependency2Id: dep2,
      dependency3Id: dep3,
      sourceConstructorType: sourceType,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager) {
      return null;
    }

    // Validate dependency count
    if (dependencies.length != 3) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final obj1 = dagManager.getObject(dependency1Id);
    final obj2 = dagManager.getObject(dependency2Id);
    final obj3 = dagManager.getObject(dependency3Id);

    if (obj1 is! SimpleGeometryObject ||
        obj2 is! SimpleGeometryObject ||
        obj3 is! SimpleGeometryObject) {
      return null;
    }

    // Use the stored source constructor type to rebuild deterministically
    try {
      final result = sourceConstructorType == FlexConstructorType.geoALCbc
          ? GeoALCbc.fromDependencies(
              id: id,
              label: label,
              objects: [obj1, obj2, obj3],
              visible: visible,
              styleOverrides: styleOverrides,
            )
          : Geo3Flex.fromDependencies(
              id: id,
              label: label,
              objects: [obj1, obj2, obj3],
              visible: visible,
              styleOverrides: styleOverrides,
            );
      if (result is GeoFlexPoint) {
        return result;
      }
    } catch (e) {
      return null;
    }

    return null;
  }
}

/// Line produced from three flexible objects (Geo3Flex or GeoALCbc)
/// Stores all 3 dependency IDs for proper rebuilding
class GeoFlexLine extends GeoLine {
  GeoFlexLine({
    required super.id,
    required super.label,
    required List<String>? dependencies,
    required super.multivector,
    required this.dependency1Id,
    required this.dependency2Id,
    required this.dependency3Id,
    required this.sourceConstructorType,
    super.visible,
    super.styleOverrides,
  }) : super(
          dependencies: dependencies ??
              List<String>.unmodifiable([dependency1Id, dependency2Id, dependency3Id]),
        );

  final String dependency1Id;
  final String dependency2Id;
  final String dependency3Id;
  final FlexConstructorType sourceConstructorType;

  @override
  GeoFlexLine copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    String? dependency1Id,
    String? dependency2Id,
    String? dependency3Id,
    FlexConstructorType? sourceConstructorType,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    final updatedDep1 = dependency1Id ?? this.dependency1Id;
    final updatedDep2 = dependency2Id ?? this.dependency2Id;
    final updatedDep3 = dependency3Id ?? this.dependency3Id;
    final normalizedDeps = dependencies ??
        List<String>.unmodifiable([updatedDep1, updatedDep2, updatedDep3]);

    return GeoFlexLine(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: normalizedDeps,
      multivector: multivector ?? this.multivector,
      dependency1Id: updatedDep1,
      dependency2Id: updatedDep2,
      dependency3Id: updatedDep3,
      sourceConstructorType: sourceConstructorType ?? this.sourceConstructorType,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoFlexLine';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'a': a,
      'b': b,
      'c': c,
      'dependency1Id': dependency1Id,
      'dependency2Id': dependency2Id,
      'dependency3Id': dependency3Id,
      'sourceConstructorType': sourceConstructorType.toJsonString(),
    };
    return json;
  }

  static GeoFlexLine fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? const {};
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = GeometryObject.extractStyleOverrides(json);

    final dep1 = props['dependency1Id'] as String? ?? (deps.isNotEmpty ? deps[0] : '');
    final dep2 = props['dependency2Id'] as String? ?? (deps.length > 1 ? deps[1] : '');
    final dep3 = props['dependency3Id'] as String? ?? (deps.length > 2 ? deps[2] : '');
    final sourceType = FlexConstructorType.fromString(
      props['sourceConstructorType'] as String?,
    );

    return GeoFlexLine(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      dependency1Id: dep1,
      dependency2Id: dep2,
      dependency3Id: dep3,
      sourceConstructorType: sourceType,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager) {
      return null;
    }

    // Validate dependency count
    if (dependencies.length != 3) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final obj1 = dagManager.getObject(dependency1Id);
    final obj2 = dagManager.getObject(dependency2Id);
    final obj3 = dagManager.getObject(dependency3Id);

    if (obj1 is! SimpleGeometryObject ||
        obj2 is! SimpleGeometryObject ||
        obj3 is! SimpleGeometryObject) {
      return null;
    }

    // Use the stored source constructor type to rebuild deterministically
    try {
      final result = sourceConstructorType == FlexConstructorType.geoALCbc
          ? GeoALCbc.fromDependencies(
              id: id,
              label: label,
              objects: [obj1, obj2, obj3],
              visible: visible,
              styleOverrides: styleOverrides,
            )
          : Geo3Flex.fromDependencies(
              id: id,
              label: label,
              objects: [obj1, obj2, obj3],
              visible: visible,
              styleOverrides: styleOverrides,
            );
      if (result is GeoFlexLine) {
        return result;
      }
    } catch (e) {
      return null;
    }

    return null;
  }
}

/// Circle produced from three flexible objects (Geo3Flex or GeoALCbc)
/// Stores all 3 dependency IDs for proper rebuilding
class GeoFlexCircle extends GeoCircle {
  GeoFlexCircle({
    required super.id,
    required super.label,
    required List<String>? dependencies,
    required super.multivector,
    required this.dependency1Id,
    required this.dependency2Id,
    required this.dependency3Id,
    required this.sourceConstructorType,
    super.visible,
    super.styleOverrides,
  }) : super(
          dependencies: dependencies ??
              List<String>.unmodifiable([dependency1Id, dependency2Id, dependency3Id]),
        );

  final String dependency1Id;
  final String dependency2Id;
  final String dependency3Id;
  final FlexConstructorType sourceConstructorType;

  @override
  GeoFlexCircle copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    String? dependency1Id,
    String? dependency2Id,
    String? dependency3Id,
    FlexConstructorType? sourceConstructorType,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    final updatedDep1 = dependency1Id ?? this.dependency1Id;
    final updatedDep2 = dependency2Id ?? this.dependency2Id;
    final updatedDep3 = dependency3Id ?? this.dependency3Id;
    final normalizedDeps = dependencies ??
        List<String>.unmodifiable([updatedDep1, updatedDep2, updatedDep3]);

    return GeoFlexCircle(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: normalizedDeps,
      multivector: multivector ?? this.multivector,
      dependency1Id: updatedDep1,
      dependency2Id: updatedDep2,
      dependency3Id: updatedDep3,
      sourceConstructorType: sourceConstructorType ?? this.sourceConstructorType,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoFlexCircle';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'centerX': centerX,
      'centerY': centerY,
      'radius': radius,
      'dependency1Id': dependency1Id,
      'dependency2Id': dependency2Id,
      'dependency3Id': dependency3Id,
      'sourceConstructorType': sourceConstructorType.toJsonString(),
    };
    return json;
  }

  static GeoFlexCircle fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? const {};
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = GeometryObject.extractStyleOverrides(json);

    final dep1 = props['dependency1Id'] as String? ?? (deps.isNotEmpty ? deps[0] : '');
    final dep2 = props['dependency2Id'] as String? ?? (deps.length > 1 ? deps[1] : '');
    final dep3 = props['dependency3Id'] as String? ?? (deps.length > 2 ? deps[2] : '');
    final sourceType = FlexConstructorType.fromString(
      props['sourceConstructorType'] as String?,
    );

    return GeoFlexCircle(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      dependency1Id: dep1,
      dependency2Id: dep2,
      dependency3Id: dep3,
      sourceConstructorType: sourceType,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager) {
      return null;
    }

    // Validate dependency count
    if (dependencies.length != 3) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final obj1 = dagManager.getObject(dependency1Id);
    final obj2 = dagManager.getObject(dependency2Id);
    final obj3 = dagManager.getObject(dependency3Id);

    if (obj1 is! SimpleGeometryObject ||
        obj2 is! SimpleGeometryObject ||
        obj3 is! SimpleGeometryObject) {
      return null;
    }

    // Use the stored source constructor type to rebuild deterministically
    try {
      final result = sourceConstructorType == FlexConstructorType.geoALCbc
          ? GeoALCbc.fromDependencies(
              id: id,
              label: label,
              objects: [obj1, obj2, obj3],
              visible: visible,
              styleOverrides: styleOverrides,
            )
          : Geo3Flex.fromDependencies(
              id: id,
              label: label,
              objects: [obj1, obj2, obj3],
              visible: visible,
              styleOverrides: styleOverrides,
            );
      if (result is GeoFlexCircle) {
        return result;
      }
    } catch (e) {
      return null;
    }

    return null;
  }
}

