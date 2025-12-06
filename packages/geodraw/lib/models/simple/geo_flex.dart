import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../../core/dag/dag_manager.dart';
import 'geo_point.dart';
import 'geo_line.dart';
import 'geo_circle.dart';
import 'geo_Inf.dart';

// ============================================================================
// FLEXIBLE GEOMETRY CLASSES
// ============================================================================
// These classes accept flexible input types (point, line, or circle) and
// automatically extract the appropriate multivector components.

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

    final normalizedOverrides = _styleOverridesFromStyle(
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
    final styleOverrides = _styleOverridesFromJson(
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
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final mv = multivector;

    // Check multivector type and return appropriate class
    if (mv.isInf()) {
      final normalizedOverrides = _styleOverridesFromStyle(
        type: GeoInf,
        style: style,
        overrides: styleOverrides,
      );
      return GeoInf.fromMultivector(
        id: id,
        label: label,
        multivector: mv,
        dependencies: objects.map((o) => o.id).toList(growable: false),
        visible: visible,
        styleOverrides: normalizedOverrides,
      );
    }

    if (mv.isPoint()) {
      // Create a temporary GeoPointer to use its resolveStyleOverrides method
      final tempPoint = GeoPointer(id: id, label: label, x: mv.e1, y: mv.e2);
      final normalizedOverrides = styleOverrides ?? 
          (style != null ? tempPoint.resolveStyleOverrides(style) : null);
      return GeoPointer(
        id: id,
        label: label,
        x: mv.e1,
        y: mv.e2,
        visible: visible,
        styleOverrides: normalizedOverrides,
      );
    }

    if (mv.isLine()) {
      // Create a temporary GeoLineFlex to use its resolveStyleOverrides method
      final tempLine = GeoLineFlex(
        id: id,
        label: label,
        dependencies: objects.map((o) => o.id).toList(growable: false),
        multivector: mv,
      );
      final normalizedOverrides = styleOverrides ?? 
          (style != null ? tempLine.resolveStyleOverrides(style) : null);
      return GeoLineFlex(
        id: id,
        label: label,
        dependencies: objects.map((o) => o.id).toList(growable: false),
        multivector: mv,
        visible: visible,
        styleOverrides: normalizedOverrides,
      );
    }

    if (mv.isCircle()) {
      final normalizedOverrides = _styleOverridesFromStyle(
        type: GeoCircle3P,
        style: style,
        overrides: styleOverrides,
      );
      return GeoCircle3P(
        id: id,
        label: label,
        dependencies: objects.map((o) => o.id).toList(growable: false),
        multivector: mv,
        visible: visible,
        styleOverrides: normalizedOverrides,
      );
    }

    // Fallback: return Geo3Flex itself if type is unclear
    final normalizedOverrides = _styleOverridesFromStyle(
      type: Geo3Flex,
      style: style,
      overrides: styleOverrides,
    );
    return Geo3Flex(
      id: id,
      label: label,
      dependencies: objects.map((o) => o.id).toList(growable: false),
      multivector: mv,
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
    // Delegate to appropriate type
    if (multivector.isPoint()) {
      final point = GeoPointer(
        id: id,
        label: label,
        x: multivector.e1,
        y: multivector.e2,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.contains(position);
    }
    if (multivector.isLine()) {
      final line = GeoLineFlex(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.contains(position);
    }
    if (multivector.isCircle()) {
      final circle = GeoCircle3P(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.contains(position);
    }
    return false;
  }

  @override
  Rect getBounds() {
    // Delegate to appropriate type
    if (multivector.isPoint()) {
      final point = GeoPointer(
        id: id,
        label: label,
        x: multivector.e1,
        y: multivector.e2,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.getBounds();
    }
    if (multivector.isLine()) {
      final line = GeoLineFlex(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.getBounds();
    }
    if (multivector.isCircle()) {
      final circle = GeoCircle3P(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.getBounds();
    }
    return Rect.zero;
  }

  @override
  double distanceTo(Offset point) {
    // Delegate to appropriate type
    if (multivector.isPoint()) {
      final pointObj = GeoPointer(
        id: id,
        label: label,
        x: multivector.e1,
        y: multivector.e2,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return pointObj.distanceTo(point);
    }
    if (multivector.isLine()) {
      final line = GeoLineFlex(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.distanceTo(point);
    }
    if (multivector.isCircle()) {
      final circle = GeoCircle3P(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.distanceTo(point);
    }
    return double.infinity;
  }

  @override
  bool intersects(SimpleGeometryObject other) {
    // Create temporary object of appropriate type for intersection check
    if (multivector.isPoint()) {
      final point = GeoPointer(
        id: id,
        label: label,
        x: multivector.e1,
        y: multivector.e2,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.intersects(other);
    }
    if (multivector.isLine()) {
      final line = GeoLineFlex(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.intersects(other);
    }
    if (multivector.isCircle()) {
      final circle = GeoCircle3P(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.intersects(other);
    }
    return false;
  }

  @override
  void draw(Canvas canvas, Paint paint) {
    // Delegate drawing based on type
    if (multivector.isPoint()) {
      // Create temporary point for drawing
      final point = GeoPointer(
        id: id,
        label: label,
        x: multivector.e1,
        y: multivector.e2,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      point.draw(canvas, paint);
    } else if (multivector.isLine()) {
      // Create temporary line for drawing
      final line = GeoLineFlex(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      line.draw(canvas, paint);
    } else if (multivector.isCircle()) {
      // Create temporary circle for drawing
      final circle = GeoCircle3P(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
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
    final styleOverrides = _styleOverridesFromJson(
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
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final mv = multivector;

    // Check multivector type and return appropriate class
    if (mv.isInf()) {
      final normalizedOverrides = _styleOverridesFromStyle(
        type: GeoInf,
        style: style,
        overrides: styleOverrides,
      );
      return GeoInf.fromMultivector(
        id: id,
        label: label,
        multivector: mv,
        dependencies: objects.map((o) => o.id).toList(growable: false),
        visible: visible,
        styleOverrides: normalizedOverrides,
      );
    }

    if (mv.isPoint()) {
      // Create a temporary GeoPointer to use its resolveStyleOverrides method
      final tempPoint = GeoPointer(id: id, label: label, x: mv.e1, y: mv.e2);
      final normalizedOverrides = styleOverrides ?? 
          (style != null ? tempPoint.resolveStyleOverrides(style) : null);
      return GeoPointer(
        id: id,
        label: label,
        x: mv.e1,
        y: mv.e2,
        visible: visible,
        styleOverrides: normalizedOverrides,
      );
    }

    if (mv.isLine()) {
      // Create a temporary GeoLineFlex to use its resolveStyleOverrides method
      final tempLine = GeoLineFlex(
        id: id,
        label: label,
        dependencies: objects.map((o) => o.id).toList(growable: false),
        multivector: mv,
      );
      final normalizedOverrides = styleOverrides ?? 
          (style != null ? tempLine.resolveStyleOverrides(style) : null);
      return GeoLineFlex(
        id: id,
        label: label,
        dependencies: objects.map((o) => o.id).toList(growable: false),
        multivector: mv,
        visible: visible,
        styleOverrides: normalizedOverrides,
      );
    }

    if (mv.isCircle()) {
      final normalizedOverrides = _styleOverridesFromStyle(
        type: GeoCircle3P,
        style: style,
        overrides: styleOverrides,
      );
      return GeoCircle3P(
        id: id,
        label: label,
        dependencies: objects.map((o) => o.id).toList(growable: false),
        multivector: mv,
        visible: visible,
        styleOverrides: normalizedOverrides,
      );
    }

    // Fallback: return GeoALCbc itself if type is unclear
    final normalizedOverrides = _styleOverridesFromStyle(
      type: GeoALCbc,
      style: style,
      overrides: styleOverrides,
    );
    return GeoALCbc(
      id: id,
      label: label,
      dependencies: objects.map((o) => o.id).toList(growable: false),
      multivector: mv,
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
    // Delegate to appropriate type
    if (multivector.isPoint()) {
      final point = GeoPointer(
        id: id,
        label: label,
        x: multivector.e1,
        y: multivector.e2,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.contains(position);
    }
    if (multivector.isLine()) {
      final line = GeoLineFlex(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.contains(position);
    }
    if (multivector.isCircle()) {
      final circle = GeoCircle3P(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.contains(position);
    }
    return false;
  }

  @override
  Rect getBounds() {
    // Delegate to appropriate type
    if (multivector.isPoint()) {
      final point = GeoPointer(
        id: id,
        label: label,
        x: multivector.e1,
        y: multivector.e2,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.getBounds();
    }
    if (multivector.isLine()) {
      final line = GeoLineFlex(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.getBounds();
    }
    if (multivector.isCircle()) {
      final circle = GeoCircle3P(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.getBounds();
    }
    return Rect.zero;
  }

  @override
  double distanceTo(Offset point) {
    // Delegate to appropriate type
    if (multivector.isPoint()) {
      final pointObj = GeoPointer(
        id: id,
        label: label,
        x: multivector.e1,
        y: multivector.e2,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return pointObj.distanceTo(point);
    }
    if (multivector.isLine()) {
      final line = GeoLineFlex(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.distanceTo(point);
    }
    if (multivector.isCircle()) {
      final circle = GeoCircle3P(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.distanceTo(point);
    }
    return double.infinity;
  }

  @override
  bool intersects(SimpleGeometryObject other) {
    // Create temporary object of appropriate type for intersection check
    if (multivector.isPoint()) {
      final point = GeoPointer(
        id: id,
        label: label,
        x: multivector.e1,
        y: multivector.e2,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return point.intersects(other);
    }
    if (multivector.isLine()) {
      final line = GeoLineFlex(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return line.intersects(other);
    }
    if (multivector.isCircle()) {
      final circle = GeoCircle3P(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      return circle.intersects(other);
    }
    return false;
  }

  @override
  void draw(Canvas canvas, Paint paint) {
    // Delegate drawing based on type
    if (multivector.isPoint()) {
      // Create temporary point for drawing
      final point = GeoPointer(
        id: id,
        label: label,
        x: multivector.e1,
        y: multivector.e2,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      point.draw(canvas, paint);
    } else if (multivector.isLine()) {
      // Create temporary line for drawing
      final line = GeoLineFlex(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      line.draw(canvas, paint);
    } else if (multivector.isCircle()) {
      // Create temporary circle for drawing
      final circle = GeoCircle3P(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: multivector,
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
    final styleOverrides = _styleOverridesFromJson(
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
class GeoLineFlex extends GeoLine {
  GeoLineFlex({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoLineFlex requires exactly 2 dependencies',
       );

  /// Construct a line from flexible dependencies (SimpleGeometryObject)
  static GeoLineFlex fromDependencies({
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
      throw ArgumentError('GeoLineFlex requires exactly 2 dependencies');
    }

    // Extract multivectors (point or circle center)
    final mv1 = objects[0] is GeoCircle
        ? getCircleCenter(objects[0].multivector)
        : infForm(objects[0].multivector);
    final mv2 = objects[1] is GeoCircle
        ? getCircleCenter(objects[1].multivector)
        : infForm(objects[1].multivector);

    final mv = constructLineFrom2Points(mv1, mv2);

    final normalizedOverrides = _lineStyleOverridesFromStyle(
      type: GeoLineFlex,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackStrokeWidth: fallbackStrokeWidth,
      fallbackLineStyle: fallbackLineStyle,
    );

    return GeoLineFlex(
      id: id,
      label: label,
      dependencies: objects.map((o) => o.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoLineFlex copyWith({
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
    return GeoLineFlex(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoLineFlex';

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

  static GeoLineFlex fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance.resolveForType(GeoLineFlex);
    final styleOverrides = _lineStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoLineFlex(
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

    return GeoLineFlex.fromDependencies(
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

    final normalizedOverrides = _lineStyleOverridesFromStyle(
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
    final styleOverrides = _lineStyleOverridesFromJson(
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

    final normalizedOverrides = _lineStyleOverridesFromStyle(
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
    final styleOverrides = _lineStyleOverridesFromJson(
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

    final normalizedOverrides = _lineStyleOverridesFromStyle(
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
    final styleOverrides = _lineStyleOverridesFromJson(
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

// ============================================================================
// HELPER FUNCTIONS FOR STYLE OVERRIDES
// ============================================================================

Map<String, dynamic>? _styleOverridesFromStyle({
  required Type type,
  CanvasStyle? style,
  Map<String, dynamic>? overrides,
}) {
  if (overrides != null) {
    return Map<String, dynamic>.unmodifiable(overrides);
  }
  if (style == null) {
    return null;
  }

  final defaults = CanvasStyleDefaults.instance.resolveForType(type);
  return Map<String, dynamic>.unmodifiable(style.diff(defaults));
}

Map<String, dynamic>? _styleOverridesFromJson(
  Map<String, dynamic> json, {
  Map<String, dynamic>? legacyProps,
  Color? fallbackColor,
}) {
  final existing = GeometryObject.extractStyleOverrides(json);
  if (existing != null) {
    return Map<String, dynamic>.unmodifiable(existing);
  }

  final overrides = <String, dynamic>{};

  final rawColor = json.containsKey('color') ? json['color'] : null;
  final parsedColor = GeometryObject.parseColor(rawColor) ?? fallbackColor;
  if (parsedColor != null) {
    overrides['strokeColor'] = CanvasStyle.colorToHex(parsedColor);
  }

  if (legacyProps != null) {
    final thickness = legacyProps['thickness'];
    if (thickness is num) {
      overrides['strokeWidth'] = thickness.toDouble();
    }
    final filled = legacyProps['filled'];
    if (filled is bool) {
      overrides['filled'] = filled;
    }
  }

  if (overrides.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(overrides);
}

Map<String, dynamic>? _lineStyleOverridesFromStyle({
  required Type type,
  CanvasStyle? style,
  Map<String, dynamic>? overrides,
  Color? fallbackColor,
  double? fallbackStrokeWidth,
  LineStyle? fallbackLineStyle,
}) {
  if (overrides != null) {
    return Map<String, dynamic>.unmodifiable(overrides);
  }

  if (style != null) {
    final defaults = CanvasStyleDefaults.instance.resolveForType(type);
    return Map<String, dynamic>.unmodifiable(style.diff(defaults));
  }

  final defaults = CanvasStyleDefaults.instance.resolveForType(type);
  final inferred = <String, dynamic>{};

  if (fallbackColor != null &&
      fallbackColor.value != defaults.strokeColor.value) {
    inferred['strokeColor'] = CanvasStyle.colorToHex(fallbackColor);
  }

  if (fallbackStrokeWidth != null &&
      !_almostEqual(fallbackStrokeWidth, defaults.strokeWidth)) {
    inferred['strokeWidth'] = fallbackStrokeWidth;
  }

  if (fallbackLineStyle != null) {
    final pattern = fallbackLineStyle.name;
    if (pattern != defaults.linePattern) {
      inferred['linePattern'] = pattern;
    }
  }

  if (inferred.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(inferred);
}

Map<String, dynamic>? _lineStyleOverridesFromJson(
  Map<String, dynamic> json, {
  Map<String, dynamic>? legacyProps,
  Color? fallbackColor,
}) {
  final existing = GeometryObject.extractStyleOverrides(json);
  if (existing != null) {
    return Map<String, dynamic>.unmodifiable(existing);
  }

  final overrides = <String, dynamic>{};

  final rawColor = json.containsKey('color') ? json['color'] : null;
  final parsedColor = GeometryObject.parseColor(rawColor);
  if (parsedColor != null) {
    overrides['strokeColor'] = CanvasStyle.colorToHex(parsedColor);
  }

  if (legacyProps != null) {
    final thickness = legacyProps['thickness'];
    if (thickness is num) {
      overrides['strokeWidth'] = thickness.toDouble();
    }

    final rawPattern = legacyProps['lineStyle'] ?? legacyProps['style'];
    final pattern = _normalizeLinePattern(rawPattern);
    if (pattern != null) {
      overrides['linePattern'] = pattern;
    }
  }

  if (overrides.isEmpty && fallbackColor != null) {
    overrides['strokeColor'] = CanvasStyle.colorToHex(fallbackColor);
  }

  if (overrides.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(overrides);
}

String? _normalizeLinePattern(dynamic raw) {
  if (raw is String) {
    final lower = raw.toLowerCase();
    switch (lower) {
      case 'solid':
      case 'dashed':
      case 'dotted':
        return lower;
    }
  } else if (raw is LineStyle) {
    return raw.name;
  }
  return null;
}

bool _almostEqual(double a, double b, [double epsilon = 0.0001]) {
  return (a - b).abs() < epsilon;
}
