import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../../core/dag/dag_manager.dart';
import 'geo_line.dart';
import 'geo_circle.dart';
import 'geo_Inf.dart';
import 'geo_flex_elements.dart' show GeoFlexPoint, GeoFlexLine, GeoFlexCircle, FlexConstructorType;
import 'geo_flex_functions.dart'
    show
        styleOverridesFromStyle,
        styleOverridesFromJson,
        lineStyleOverridesFromStyle,
        lineStyleOverridesFromJson;

// ============================================================================
// FLEXIBLE GEOMETRY CLASSES
// ============================================================================
// These classes accept flexible input types (point, line, or circle) and
// automatically extract the appropriate multivector components.

/// Shared helper to create flex elements from a multivector
/// This reduces code duplication between Geo3Flex and GeoALCbc
SimpleGeometryObject? _createFlexElementFromMultivector({
  required String id,
  required String label,
  required Multivector multivector,
  required List<SimpleGeometryObject> objects,
  required FlexConstructorType constructorType,
  bool visible = true,
  CanvasStyle? style,
  Map<String, dynamic>? styleOverrides,
}) {
  final depIds = objects.map((o) => o.id).toList(growable: false);
  final dep1Id = depIds[0];
  final dep2Id = depIds[1];
  final dep3Id = depIds[2];

  // Check multivector type and return appropriate class
  // Use tolerance 1e-8 for type detection
  const double typeTolerance = 1e-8;
  
  if (multivector.isInf(customTolerance: typeTolerance)) {
    final normalizedOverrides = styleOverridesFromStyle(
      type: GeoInf,
      style: style,
      overrides: styleOverrides,
    );
    return GeoInf.fromMultivector(
      id: id,
      label: label,
      multivector: multivector,
      dependencies: depIds,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  if (multivector.isPoint(customTolerance: typeTolerance)) {
    final normalizedOverrides = styleOverridesFromStyle(
      type: GeoFlexPoint,
      style: style,
      overrides: styleOverrides,
    );
    return GeoFlexPoint(
      id: id,
      label: label,
      dependencies: depIds,
      multivector: multivector,
      dependency1Id: dep1Id,
      dependency2Id: dep2Id,
      dependency3Id: dep3Id,
      sourceConstructorType: constructorType,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  if (multivector.isLine(customTolerance: typeTolerance)) {
    final normalizedOverrides = lineStyleOverridesFromStyle(
      type: GeoFlexLine,
      style: style,
      overrides: styleOverrides,
    );
    return GeoFlexLine(
      id: id,
      label: label,
      dependencies: depIds,
      multivector: multivector,
      dependency1Id: dep1Id,
      dependency2Id: dep2Id,
      dependency3Id: dep3Id,
      sourceConstructorType: constructorType,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  if (multivector.isCircle(customTolerance: typeTolerance)) {
    final normalizedOverrides = styleOverridesFromStyle(
      type: GeoFlexCircle,
      style: style,
      overrides: styleOverrides,
    );
    return GeoFlexCircle(
      id: id,
      label: label,
      dependencies: depIds,
      multivector: multivector,
      dependency1Id: dep1Id,
      dependency2Id: dep2Id,
      dependency3Id: dep3Id,
      sourceConstructorType: constructorType,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  return null; // Type unclear, let caller handle fallback
}

/// Circle with flexible center and point (accepts point or circle, not line)
class GeoCircleFlex extends GeoCircle {
  GeoCircleFlex({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoCircleFlex requires exactly 2 dependencies',
       );

  /// Construct a circle from flexible dependencies (SimpleGeometryObject)
  static GeoCircleFlex fromDependencies({
    required String id,
    required String label,
    required List<SimpleGeometryObject> objects,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (objects.length != 2) {
      throw ArgumentError('GeoCircleFlex requires exactly 2 dependencies');
    }

    final centerObj = objects[0];
    final pointObj = objects[1];

    // Validate center: must be point or circle, not line
    if (centerObj is GeoLine) {
      throw ArgumentError('Center cannot be a line. Use a point or circle.');
    }

    // Validate point on circle: must be point or circle, not line
    if (pointObj is GeoLine) {
      throw ArgumentError('Point on circle cannot be a line. Use a point or circle.');
    }

    // Extract center multivector (point or circle center)
    final centerMv = centerObj is GeoCircle
        ? getCircleCenter(centerObj.multivector)
        : infForm(centerObj.multivector);

    // Extract point multivector (point or circle center)
    final pointMv = pointObj is GeoCircle
        ? getCircleCenter(pointObj.multivector)
        : infForm(pointObj.multivector);

    final mv = constructCircleFromCenterAndPoint(centerMv, pointMv);

    final normalizedOverrides = styleOverridesFromStyle(
      type: GeoCircleFlex,
      style: style,
      overrides: styleOverrides,
    );

    return GeoCircleFlex(
      id: id,
      label: label,
      dependencies: objects.map((o) => o.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoCircleFlex copyWith({
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
    return GeoCircleFlex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoCircleFlex';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'centerX': centerX,
      'centerY': centerY,
      'radius': radius,
    };
    return json;
  }

  static GeoCircleFlex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = styleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoCircleFlex)
          .strokeColor,
    );
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoCircleFlex(
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
    if (dagManager is! DAGManager || dependencies.length != 2) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final obj1 = dagManager.getObject(dependencies[0]);
    final obj2 = dagManager.getObject(dependencies[1]);
    
    if (obj1 is! SimpleGeometryObject || obj2 is! SimpleGeometryObject) {
      return null;
    }

    try {
      return GeoCircleFlex.fromDependencies(
        id: id,
        label: label,
        objects: [obj1, obj2],
        visible: visible,
        styleOverrides: styleOverrides,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Generic geometry through three flexible objects (accepts any SimpleGeometryObject)
/// Returns the appropriate type (point, line, circle, or infinity) based on multivector
class Geo3Flex extends SimpleGeometryObject {
  Geo3Flex({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 3 dependencies
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 3,
         'Geo3Flex requires exactly 3 dependencies',
       );

  /// Construct geometry through three flexible objects
  /// Returns the appropriate SimpleGeometryObject based on multivector type
  static SimpleGeometryObject? fromDependencies({
    required String id,
    required String label,
    required List<SimpleGeometryObject> objects,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (objects.length != 3) {
      throw ArgumentError('Geo3Flex requires exactly 3 dependencies');
    }

    final mv = constructCircleThrough3GeoSimpleObjects(
      objects[0].multivector,
      objects[1].multivector,
      objects[2].multivector,
    );

    return _fromMultivector(
      id: id,
      label: label,
      multivector: mv,
      objects: objects,
      constructorType: FlexConstructorType.geo3Flex,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );
  }

  /// Construct geometry from a multivector and three objects
  /// Returns the appropriate SimpleGeometryObject based on multivector type
  /// This is used when the multivector is computed separately (e.g., via aLCbc)
  static SimpleGeometryObject? fromMultivector({
    required String id,
    required String label,
    required Multivector multivector,
    required List<SimpleGeometryObject> objects,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (objects.length != 3) {
      throw ArgumentError('Geo3Flex requires exactly 3 dependencies');
    }

    return _fromMultivector(
      id: id,
      label: label,
      multivector: multivector,
      objects: objects,
      constructorType: FlexConstructorType.geo3Flex,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );
  }

  /// Internal helper to create the appropriate object from a multivector
  static SimpleGeometryObject? _fromMultivector({
    required String id,
    required String label,
    required Multivector multivector,
    required List<SimpleGeometryObject> objects,
    required FlexConstructorType constructorType,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    // Use shared helper function
    final result = _createFlexElementFromMultivector(
      id: id,
      label: label,
      multivector: multivector,
      objects: objects,
      constructorType: constructorType,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );

    // If result is null or type is unclear, return Geo3Flex itself as fallback
    if (result != null) {
      return result;
    }

    final normalizedOverrides = styleOverridesFromStyle(
      type: Geo3Flex,
      style: style,
      overrides: styleOverrides,
    );
    final depIds = objects.map((o) => o.id).toList(growable: false);
    return Geo3Flex(
      id: id,
      label: label,
      dependencies: depIds,
      multivector: multivector,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  Geo3Flex copyWith({
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
    return Geo3Flex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'Geo3Flex';

  @override
  bool contains(Offset position) {
    // Delegate to appropriate type using element classes
    final depIds = dependencies;
    if (multivector.isPoint() && depIds.length == 3) {
      final point = GeoFlexPoint(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.contains(position);
    }
    if (multivector.isLine() && depIds.length == 3) {
      final line = GeoFlexLine(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.contains(position);
    }
    if (multivector.isCircle() && depIds.length == 3) {
      final circle = GeoFlexCircle(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.contains(position);
    }
    return false;
  }

  @override
  Rect getBounds() {
    // Delegate to appropriate type using element classes
    final depIds = dependencies;
    if (multivector.isPoint() && depIds.length == 3) {
      final point = GeoFlexPoint(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.getBounds();
    }
    if (multivector.isLine() && depIds.length == 3) {
      final line = GeoFlexLine(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.getBounds();
    }
    if (multivector.isCircle() && depIds.length == 3) {
      final circle = GeoFlexCircle(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.getBounds();
    }
    return Rect.zero;
  }

  @override
  double distanceTo(Offset point) {
    // Delegate to appropriate type using element classes
    final depIds = dependencies;
    if (multivector.isPoint() && depIds.length == 3) {
      final pointObj = GeoFlexPoint(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return pointObj.distanceTo(point);
    }
    if (multivector.isLine() && depIds.length == 3) {
      final line = GeoFlexLine(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.distanceTo(point);
    }
    if (multivector.isCircle() && depIds.length == 3) {
      final circle = GeoFlexCircle(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.distanceTo(point);
    }
    return double.infinity;
  }

  @override
  bool intersects(SimpleGeometryObject other) {
    // Delegate to appropriate type using element classes
    final depIds = dependencies;
    if (multivector.isPoint() && depIds.length == 3) {
      final point = GeoFlexPoint(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.intersects(other);
    }
    if (multivector.isLine() && depIds.length == 3) {
      final line = GeoFlexLine(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.intersects(other);
    }
    if (multivector.isCircle() && depIds.length == 3) {
      final circle = GeoFlexCircle(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.intersects(other);
    }
    return false;
  }

  @override
  void draw(Canvas canvas, Paint paint) {
    // Delegate drawing based on type using element classes
    final depIds = dependencies;
    if (multivector.isPoint() && depIds.length == 3) {
      final point = GeoFlexPoint(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      point.draw(canvas, paint);
    } else if (multivector.isLine() && depIds.length == 3) {
      final line = GeoFlexLine(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      line.draw(canvas, paint);
    } else if (multivector.isCircle() && depIds.length == 3) {
      final circle = GeoFlexCircle(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geo3Flex,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      circle.draw(canvas, paint);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    // Store type information for proper reconstruction
    if (multivector.isPoint()) {
      json['properties'] = {'x': multivector.e1, 'y': multivector.e2};
    } else if (multivector.isLine()) {
      json['properties'] = {'a': multivector.e1, 'b': multivector.e2, 'c': multivector.O * -1};
    } else if (multivector.isCircle()) {
      json['properties'] = {
        'centerX': multivector.e1,
        'centerY': multivector.e2,
        'radius': radius,
      };
    }
    return json;
  }

  static Geo3Flex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = styleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(Geo3Flex)
          .strokeColor,
    );
    final deps = (json['dependencies'] as List).cast<String>();

    return Geo3Flex(
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
    if (dagManager is! DAGManager || dependencies.length != 3) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final obj1 = dagManager.getObject(dependencies[0]);
    final obj2 = dagManager.getObject(dependencies[1]);
    final obj3 = dagManager.getObject(dependencies[2]);
    
    if (obj1 is! SimpleGeometryObject || obj2 is! SimpleGeometryObject || obj3 is! SimpleGeometryObject) {
      return null;
    }

    return fromDependencies(
      id: id,
      label: label,
      objects: [obj1, obj2, obj3],
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }

  // Helper getters for convenience (only valid for circles)
  double get radius {
    if (!multivector.isCircle()) return 0.0;
    final circleInf = infForm(multivector);
    final radiusSquared = circleInf.e1 * circleInf.e1 + 
           circleInf.e2 * circleInf.e2 - 
           2 * circleInf.O;
    if (radiusSquared < 0) {
      return math.sqrt(radiusSquared.abs());
    }
    final normOpt = multivector.norm();
    return normOpt.fold(() => 0.0, (normValue) => math.sqrt(normValue.abs()));
  }

  double get centerX => multivector.e1;
  double get centerY => multivector.e2;
}

/// aLCbc operation on three flexible objects (accepts any SimpleGeometryObject)
/// Returns the appropriate type (point, line, circle, or infinity) based on multivector
/// Output type is not known beforehand
class GeoALCbc extends SimpleGeometryObject {
  GeoALCbc({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 3 dependencies
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 3,
         'GeoALCbc requires exactly 3 dependencies',
       );

  /// Construct geometry from three flexible objects using aLCbc operation
  /// Returns the appropriate SimpleGeometryObject based on multivector type
  static SimpleGeometryObject? fromDependencies({
    required String id,
    required String label,
    required List<SimpleGeometryObject> objects,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (objects.length != 3) {
      throw ArgumentError('GeoALCbc requires exactly 3 dependencies');
    }

    final mv = aLCbc(
      objects[0].multivector,
      objects[1].multivector,
      objects[2].multivector,
    );

    return _fromMultivector(
      id: id,
      label: label,
      multivector: mv,
      objects: objects,
      constructorType: FlexConstructorType.geoALCbc,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );
  }

  /// Internal helper to create the appropriate object from a multivector
  /// Returns specialized flex classes (GeoFlexPoint, GeoFlexLine, GeoFlexCircle) based on multivector type
  static SimpleGeometryObject? _fromMultivector({
    required String id,
    required String label,
    required Multivector multivector,
    required List<SimpleGeometryObject> objects,
    required FlexConstructorType constructorType,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    // Use shared helper function
    final result = _createFlexElementFromMultivector(
      id: id,
      label: label,
      multivector: multivector,
      objects: objects,
      constructorType: constructorType,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );

    // If result is null or type is unclear, return GeoALCbc itself as fallback
    if (result != null) {
      return result;
    }

    final normalizedOverrides = styleOverridesFromStyle(
      type: GeoALCbc,
      style: style,
      overrides: styleOverrides,
    );
    final depIds = objects.map((o) => o.id).toList(growable: false);
    return GeoALCbc(
      id: id,
      label: label,
      dependencies: depIds,
      multivector: multivector,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoALCbc copyWith({
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
    return GeoALCbc(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoALCbc';

  @override
  bool contains(Offset position) {
    // Delegate to appropriate type using element classes
    // GeoALCbc always has 3 dependencies, so use element classes
    final depIds = dependencies;
    if (multivector.isPoint()) {
      final point = GeoFlexPoint(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.contains(position);
    }
    if (multivector.isLine()) {
      final line = GeoFlexLine(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.contains(position);
    }
    if (multivector.isCircle()) {
      final circle = GeoFlexCircle(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.contains(position);
    }
    return false;
  }

  @override
  Rect getBounds() {
    // Delegate to appropriate type using element classes
    // GeoALCbc always has 3 dependencies, so use element classes
    final depIds = dependencies;
    if (multivector.isPoint()) {
      final point = GeoFlexPoint(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.getBounds();
    }
    if (multivector.isLine()) {
      final line = GeoFlexLine(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.getBounds();
    }
    if (multivector.isCircle()) {
      final circle = GeoFlexCircle(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.getBounds();
    }
    return Rect.zero;
  }

  @override
  double distanceTo(Offset point) {
    // Delegate to appropriate type using element classes
    // GeoALCbc always has 3 dependencies, so use element classes
    final depIds = dependencies;
    if (multivector.isPoint()) {
      final pointObj = GeoFlexPoint(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return pointObj.distanceTo(point);
    }
    if (multivector.isLine()) {
      final line = GeoFlexLine(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.distanceTo(point);
    }
    if (multivector.isCircle()) {
      final circle = GeoFlexCircle(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.distanceTo(point);
    }
    return double.infinity;
  }

  @override
  bool intersects(SimpleGeometryObject other) {
    // Delegate to appropriate type using element classes
    // GeoALCbc always has 3 dependencies, so use element classes
    final depIds = dependencies;
    if (multivector.isPoint()) {
      final point = GeoFlexPoint(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.intersects(other);
    }
    if (multivector.isLine()) {
      final line = GeoFlexLine(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.intersects(other);
    }
    if (multivector.isCircle()) {
      final circle = GeoFlexCircle(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.intersects(other);
    }
    return false;
  }

  @override
  void draw(Canvas canvas, Paint paint) {
    // Delegate drawing based on type using element classes
    // GeoALCbc always has 3 dependencies, so use element classes
    final depIds = dependencies;
    if (multivector.isPoint()) {
      final point = GeoFlexPoint(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      point.draw(canvas, paint);
    } else if (multivector.isLine()) {
      final line = GeoFlexLine(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      line.draw(canvas, paint);
    } else if (multivector.isCircle()) {
      final circle = GeoFlexCircle(
        id: id,
        label: label,
        dependencies: depIds,
        multivector: multivector,
        dependency1Id: depIds[0],
        dependency2Id: depIds[1],
        dependency3Id: depIds[2],
        sourceConstructorType: FlexConstructorType.geoALCbc,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      circle.draw(canvas, paint);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    // Store type information for proper reconstruction
    if (multivector.isPoint()) {
      json['properties'] = {'x': multivector.e1, 'y': multivector.e2};
    } else if (multivector.isLine()) {
      json['properties'] = {'a': multivector.e1, 'b': multivector.e2, 'c': multivector.O * -1};
    } else if (multivector.isCircle()) {
      json['properties'] = {
        'centerX': multivector.e1,
        'centerY': multivector.e2,
        'radius': radius,
      };
    }
    return json;
  }

  static GeoALCbc fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = styleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoALCbc)
          .strokeColor,
    );
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoALCbc(
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
    if (dagManager is! DAGManager || dependencies.length != 3) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final obj1 = dagManager.getObject(dependencies[0]);
    final obj2 = dagManager.getObject(dependencies[1]);
    final obj3 = dagManager.getObject(dependencies[2]);
    
    if (obj1 is! SimpleGeometryObject || obj2 is! SimpleGeometryObject || obj3 is! SimpleGeometryObject) {
      return null;
    }

    return fromDependencies(
      id: id,
      label: label,
      objects: [obj1, obj2, obj3],
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }

  // Helper getters for convenience (only valid for circles)
  double get radius {
    if (!multivector.isCircle()) return 0.0;
    final circleInf = infForm(multivector);
    final radiusSquared = circleInf.e1 * circleInf.e1 + 
           circleInf.e2 * circleInf.e2 - 
           2 * circleInf.O;
    if (radiusSquared < 0) {
      return math.sqrt(radiusSquared.abs());
    }
    final normOpt = multivector.norm();
    return normOpt.fold(() => 0.0, (normValue) => math.sqrt(normValue.abs()));
  }

  double get centerX => multivector.e1;
  double get centerY => multivector.e2;
}

/// Line through two flexible objects (accepts any SimpleGeometryObject)
class GeoLine2Sim extends GeoLine {
  GeoLine2Sim({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoLine2Sim requires exactly 2 dependencies',
       );

  /// Construct a line from flexible dependencies (SimpleGeometryObject)
  static GeoLine2Sim fromDependencies({
    required String id,
    required String label,
    required List<SimpleGeometryObject> objects,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.blue,
  }) {
    if (objects.length != 2) {
      throw ArgumentError('GeoLine2Sim requires exactly 2 dependencies');
    }

    // Extract multivectors (point or circle center)
    final mv1 = objects[0] is GeoCircle
        ? getCircleCenter(objects[0].multivector)
        : infForm(objects[0].multivector);
    final mv2 = objects[1] is GeoCircle
        ? getCircleCenter(objects[1].multivector)
        : infForm(objects[1].multivector);

    final mv = constructLineFrom2Points(mv1, mv2);

    final normalizedOverrides = lineStyleOverridesFromStyle(
      type: GeoLine2Sim,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoLine2Sim(
      id: id,
      label: label,
      dependencies: objects.map((o) => o.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoLine2Sim copyWith({
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
    return GeoLine2Sim(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoLine2Sim';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoLine2Sim fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance.resolveForType(GeoLine2Sim);
    final styleOverrides = lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoLine2Sim(
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
    if (dagManager is! DAGManager || dependencies.length != 2) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final obj1 = dagManager.getObject(dependencies[0]);
    final obj2 = dagManager.getObject(dependencies[1]);
    
    if (obj1 is! SimpleGeometryObject || obj2 is! SimpleGeometryObject) {
      return null;
    }

    return GeoLine2Sim.fromDependencies(
      id: id,
      label: label,
      objects: [obj1, obj2],
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

/// Perpendicular bisector with flexible arguments (point or circle, not line)
class GeoPerpendicularBisectorFlex extends GeoLine {
  GeoPerpendicularBisectorFlex({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoPerpendicularBisectorFlex requires exactly 2 dependencies',
       );

  /// Construct a perpendicular bisector from flexible dependencies
  static GeoPerpendicularBisectorFlex fromDependencies({
    required String id,
    required String label,
    required List<SimpleGeometryObject> objects,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.cyan,
  }) {
    if (objects.length != 2) {
      throw ArgumentError(
        'GeoPerpendicularBisectorFlex requires exactly 2 dependencies',
      );
    }

    // Validate: neither can be line
    if (objects[0] is GeoLine || objects[1] is GeoLine) {
      throw ArgumentError(
        'Perpendicular bisector requires points or circles, not lines.',
      );
    }

    // Extract multivectors (point or circle center)
    final mv1 = objects[0] is GeoCircle
        ? getCircleCenter(objects[0].multivector)
        : infForm(objects[0].multivector);
    final mv2 = objects[1] is GeoCircle
        ? getCircleCenter(objects[1].multivector)
        : infForm(objects[1].multivector);

    final mv = constructPerpendicularBisector(mv1, mv2);

    final normalizedOverrides = lineStyleOverridesFromStyle(
      type: GeoPerpendicularBisectorFlex,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoPerpendicularBisectorFlex(
      id: id,
      label: label,
      dependencies: objects.map((o) => o.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoPerpendicularBisectorFlex copyWith({
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
    return GeoPerpendicularBisectorFlex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoPerpendicularBisectorFlex';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoPerpendicularBisectorFlex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance
        .resolveForType(GeoPerpendicularBisectorFlex);
    final styleOverrides = lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoPerpendicularBisectorFlex(
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
    if (dagManager is! DAGManager || dependencies.length != 2) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final obj1 = dagManager.getObject(dependencies[0]);
    final obj2 = dagManager.getObject(dependencies[1]);
    
    if (obj1 is! SimpleGeometryObject || obj2 is! SimpleGeometryObject) {
      return null;
    }

    try {
      return GeoPerpendicularBisectorFlex.fromDependencies(
        id: id,
        label: label,
        objects: [obj1, obj2],
        visible: visible,
        styleOverrides: styleOverrides,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Perpendicular line with flexible point (point or circle)
class GeoPerpendicularLineFlex extends GeoLine {
  GeoPerpendicularLineFlex({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoPerpendicularLineFlex requires exactly 2 dependencies',
       );

  /// Construct a perpendicular line from flexible dependencies
  static GeoPerpendicularLineFlex fromDependencies({
    required String id,
    required String label,
    required List<GeometryObject> dependencies,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.orange,
  }) {
    if (dependencies.length != 2) {
      throw ArgumentError(
        'GeoPerpendicularLineFlex requires exactly a point/circle and a line dependency',
      );
    }

    final pointObj = dependencies[0];
    final reference = dependencies[1];

    if (reference is! GeoLine) {
      throw ArgumentError(
        'GeoPerpendicularLineFlex requires a line as the second dependency',
      );
    }

    if (pointObj is! SimpleGeometryObject) {
      throw ArgumentError(
        'GeoPerpendicularLineFlex requires a point or circle as the first dependency',
      );
    }

    // Extract point multivector (point or circle center)
    final pointMv = pointObj is GeoCircle
        ? getCircleCenter(pointObj.multivector)
        : infForm(pointObj.multivector);

    final mv = constructPerpendicularLine(reference.multivector, pointMv);

    final normalizedOverrides = lineStyleOverridesFromStyle(
      type: GeoPerpendicularLineFlex,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoPerpendicularLineFlex(
      id: id,
      label: label,
      dependencies: dependencies.map((d) => d.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoPerpendicularLineFlex copyWith({
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
    return GeoPerpendicularLineFlex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoPerpendicularLineFlex';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoPerpendicularLineFlex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults =
        CanvasStyleDefaults.instance.resolveForType(GeoPerpendicularLineFlex);
    final styleOverrides = lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoPerpendicularLineFlex(
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
    if (dagManager is! DAGManager || dependencies.length != 2) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final obj1 = dagManager.getObject(dependencies[0]);
    final obj2 = dagManager.getObject(dependencies[1]);
    
    if (obj1 is! SimpleGeometryObject || obj2 is! SimpleGeometryObject) {
      return null;
    }

    try {
      return GeoPerpendicularLineFlex.fromDependencies(
        id: id,
        label: label,
        dependencies: [obj1, obj2],
        visible: visible,
        styleOverrides: styleOverrides,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Parallel line with flexible point (point or circle)
class GeoParallelLineFlex extends GeoLine {
  GeoParallelLineFlex({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoParallelLineFlex requires exactly 2 dependencies',
       );

  /// Construct a parallel line from flexible dependencies
  static GeoParallelLineFlex fromDependencies({
    required String id,
    required String label,
    required List<GeometryObject> dependencies,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackStrokeWidth = 2.0,
    LineStyle fallbackLineStyle = LineStyle.solid,
    Color fallbackColor = Colors.teal,
  }) {
    if (dependencies.length != 2) {
      throw ArgumentError(
        'GeoParallelLineFlex requires exactly a line and a point/circle dependency',
      );
    }

    final reference = dependencies[0];
    final pointObj = dependencies[1];

    if (reference is! GeoLine) {
      throw ArgumentError(
        'GeoParallelLineFlex requires a line as the first dependency',
      );
    }

    if (pointObj is! SimpleGeometryObject) {
      throw ArgumentError(
        'GeoParallelLineFlex requires a point or circle as the second dependency',
      );
    }

    // Extract point multivector (point or circle center)
    final pointMv = pointObj is GeoCircle
        ? getCircleCenter(pointObj.multivector)
        : infForm(pointObj.multivector);

    final mv = constructParallelLine(reference.multivector, pointMv);

    final normalizedOverrides = lineStyleOverridesFromStyle(
      type: GeoParallelLineFlex,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoParallelLineFlex(
      id: id,
      label: label,
      dependencies: dependencies.map((d) => d.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoParallelLineFlex copyWith({
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
    return GeoParallelLineFlex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoParallelLineFlex';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = <String, dynamic>{
      'a': a,
      'b': b,
      'c': c,
      'linePattern': style.linePattern,
      'strokeWidth': style.strokeWidth,
    };
    properties.removeWhere((_, value) => value == null);
    json['properties'] = properties;
    return json;
  }

  static GeoParallelLineFlex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults =
        CanvasStyleDefaults.instance.resolveForType(GeoParallelLineFlex);
    final styleOverrides = lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoParallelLineFlex(
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
    if (dagManager is! DAGManager || dependencies.length != 2) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final obj1 = dagManager.getObject(dependencies[0]);
    final obj2 = dagManager.getObject(dependencies[1]);
    
    if (obj1 is! SimpleGeometryObject || obj2 is! SimpleGeometryObject) {
      return null;
    }

    try {
      return GeoParallelLineFlex.fromDependencies(
        id: id,
        label: label,
        dependencies: [obj1, obj2],
        visible: visible,
        styleOverrides: styleOverrides,
      );
    } catch (e) {
      return null;
    }
  }
}
