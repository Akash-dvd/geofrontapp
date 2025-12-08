import 'package:flutter/foundation.dart';
import 'package:geocalc/Multivector.dart';

import '../geometry_object.dart';
import 'geo_trans.dart';
import '../simple/geo_point.dart';
import '../simple/geo_line.dart';
import '../simple/geo_circle.dart';
import '../simple/geo_Inf.dart';
import '../simple/geo_transformed_simple.dart';
import '../complex/complex_geometry_object.dart';
import '../complex/geo_shapes.dart';
import '../complex/geo_transformed_complex.dart';
import '../simple_lists/geo_tangent.dart';
import '../simple_lists/geo_angle_bisector.dart';
import '../simple_lists/geo_intersection.dart';

/// Classification of the transformed simple object.
enum SimpleTransformKind { point, line, circle }

/// Classification of a transformed complex object.
enum ComplexTransformKind { segment, arc }

/// Centralised helpers for applying [GeoTrans] instances to geometry objects.
class TransformationEngine {
  /// Apply [transform] to [source] and return the resulting GeometryObject.
  /// Returns null if the transformation cannot produce a valid geometry object.
  static GeometryObject? transformSimple({
    required SimpleGeometryObject source,
    required GeoTrans transform,
    required String id,
    required String label,
    required List<String> dependencies,
    bool? visible,
    Map<String, dynamic>? styleOverrides,
  }) {
    //debugPrint('[TransformationEngine] transformSimple: source=${source.runtimeType} (${source.id}), transform=${transform.runtimeType} (${transform.id})');
    
    // Special case: Points always remain points (reflection, rotation, dilation preserve point type)
    if (source is GeoPoint) {
      //debugPrint('[TransformationEngine] Source is a point - points always remain points');
      final transformed = transformMultivector(
        subject: source.multivector,
        transform: transform,
      );
      
      // Check if the result is infinity (e.g., center point inverted around circle)
      if (transformed.isInf()) {
        return GeoInf.fromMultivector(
          id: id,
          label: label,
          multivector: transformed,
          dependencies: dependencies,
          visible: visible ?? source.visible,
          styleOverrides: styleOverrides ?? source.styleOverrides,
        );
      }
      
      // Force the result to be treated as a point, even if kind inference says otherwise
      // This is because points should always remain points
      //debugPrint('[TransformationEngine] Creating GeoTransPoint (point type preserved)');
      return GeoTransPoint(
        id: id,
        label: label,
        dependencies: dependencies,
        multivector: transformed,
        sourcePointId: source.id,
        transformId: transform.id,
        visible: visible ?? source.visible,
        styleOverrides: styleOverrides ?? source.styleOverrides,
      );
    }
    
    var transformed = transformMultivector(
      subject: source.multivector,
      transform: transform,
    );

    //debugPrint('[TransformationEngine] Original multivector: o=${source.multivector.o}, e1=${source.multivector.e1}, e2=${source.multivector.e2}, O=${source.multivector.O}');
    //debugPrint('[TransformationEngine] Transformed multivector (before normalization): o=${transformed.o}, e1=${transformed.e1}, e2=${transformed.e2}, O=${transformed.O}');
    //debugPrint('[TransformationEngine] Checking multivector type (before normalization): isPoint=${transformed.isPoint()}, isLine=${transformed.isLine()}, isCircle=${transformed.isCircle()}');
    
    // Normalize the multivector using the function from definitions.dart
    transformed = normalizeTransformedMultivector(transformed);
    //debugPrint('[TransformationEngine] After normalization: o=${transformed.o}, e1=${transformed.e1}, e2=${transformed.e2}, O=${transformed.O}');
    //debugPrint('[TransformationEngine] Checking multivector type (after normalization): isPoint=${transformed.isPoint()}, isLine=${transformed.isLine()}, isCircle=${transformed.isCircle()}');
    
    final kind = _inferKind(transformed);
    //debugPrint('[TransformationEngine] Transformed multivector kind: $kind');
    final sourceId = source.id;
    final transformId = transform.id;
    final isVisible = visible ?? source.visible;
    final overrides = styleOverrides ?? source.styleOverrides;

    switch (kind) {
      case SimpleTransformKind.point:
        //debugPrint('[TransformationEngine] Kind is point, but source is not GeoPoint - this should not happen');
        return null;
      case SimpleTransformKind.line:
        return GeoTransLine(
          id: id,
          label: label,
          dependencies: dependencies,
          multivector: transformed,
          sourceObjectId: sourceId,
          transformId: transformId,
          visible: isVisible,
          styleOverrides: overrides,
        );
      case SimpleTransformKind.circle:
        return GeoTransCircle(
          id: id,
          label: label,
          dependencies: dependencies,
          multivector: transformed,
          sourceObjectId: sourceId,
          transformId: transformId,
          visible: isVisible,
          styleOverrides: overrides,
        );
    }
  }

  /// Apply [transform] to a raw multivector.
  static Multivector transformMultivector({
    required Multivector subject,
    required GeoTrans transform,
    bool useSignedOperators = false,
  }) {
    // All rotor-based operators (rotation, dilation, translation, inversions) use signed forms for complex types
    if (transform is GeoRotate) {
      // For rotation, the reflection method does R^-1 * object * R, but we need R * object * R^-1
      // So we reverse the operator before applying: (R^-1)^-1 = R, giving us R * object * R^-1
      final reversedRotor = transform.multivector.reversion();
      final result = applyRotationOperator(reversedRotor, subject);
      return useSignedOperators 
          ? _normalizeWithSignedForms(result)
          : normalizeTransformedMultivector(result);
    }
    if (transform is GeoDilate) {
      // For dilation, the reflection method does D^-1 * object * D, but we need D * object * D^-1
      // So we reverse the operator before applying: (D^-1)^-1 = D, giving us D * object * D^-1
      final reversedDilator = transform.multivector.reversion();
      final result = applyDilationOperator(reversedDilator, subject);
      return useSignedOperators 
          ? _normalizeWithSignedForms(result)
          : normalizeTransformedMultivector(result);
    }

    if (transform is GeoLineInverse || 
        transform is GeoCircleInverse || 
        transform is GeoPointInverse) {
      return _applyInverseToMultivector(
        subject,
        transform.multivector,
        useSignedOperators: useSignedOperators,
      );
    }

    if (transform is GeoTranslate) {
      final result = applyTranslationOperator(transform.multivector, subject);
      return useSignedOperators 
          ? _normalizeWithSignedForms(result)
          : normalizeTransformedMultivector(result);
    }

    return subject;
  }

  /// Transform a complex geometry object and return the resulting GeometryObject.
  /// Returns null if the transformation cannot produce a valid geometry object.
  static GeometryObject? transformComplex({
    required ComplexGeometryObject source,
    required GeoTrans transform,
    required String id,
    required String label,
    required List<String> dependencies,
    bool? visible,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (source is GeoSegment) {
      return _transformSegment(
        source: source,
        transform: transform,
        id: id,
        label: label,
        dependencies: dependencies,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    }

    if (source is GeoArc) {
      return _transformArc(
        source: source,
        transform: transform,
        id: id,
        label: label,
        dependencies: dependencies,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    }

    return null;
  }

  /// Transform all objects in a GenSimpleGeometryObjectList
  /// Returns a list of transformed geometry objects
  static List<GeometryObject> transformSimpleList({
    required GenSimpleGeometryObjectList source,
    required GeoTrans transform,
  }) {
    final transformedObjects = <GeometryObject>[];
    
    for (final element in source.elements) {
      final transformed = transformSimple(
        source: element,
        transform: transform,
        id: '${element.id}_${transform.id}',
        label: element.label,
        dependencies: element.dependencies,
        visible: element.visible,
        styleOverrides: element.styleOverrides,
      );
      
      if (transformed != null) {
        transformedObjects.add(transformed);
      } else {
        // If transformation failed, keep original
        transformedObjects.add(element);
      }
    }
    
    return transformedObjects;
  }

  /// Transform any GeometryObject with a GeoTrans transform
  /// Returns the transformed geometry object, or null if transformation is not supported
  static GeometryObject? transform({
    required GeometryObject source,
    required GeoTrans transform,
    required String id,
    required String label,
    required List<String> dependencies,
    bool? visible,
    Map<String, dynamic>? styleOverrides,
  }) {
    // Simple geometry objects
    if (source is SimpleGeometryObject) {
      return transformSimple(
        source: source,
        transform: transform,
        id: id,
        label: label,
        dependencies: dependencies,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    }

    // Complex geometry objects
    if (source is ComplexGeometryObject) {
      return transformComplex(
        source: source,
        transform: transform,
        id: id,
        label: label,
        dependencies: dependencies,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    }

    // GenSimpleGeometryObjectList (now extends UnionGeometryObjectList)
    // Check this first since it's more specific
    if (source is GenSimpleGeometryObjectList) {
      return transformGenSimpleList(
        source: source,
        transform: transform,
        id: id,
        label: label,
        dependencies: dependencies,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    }

    // Union geometry object list (general case, after GenSimpleGeometryObjectList)
    if (source is UnionGeometryObjectList) {
      final elements = transformUnionElements(source, transform);
      return GeoTransUnionGeometryObjectList(
        id: id,
        label: label,
        dependencies: dependencies,
        elements: elements,
        sourceObjectId: source.id,
        transformId: transform.id,
        vertexCountValue: source.vertexCount,
        areaValue: source.area(),
        perimeterValue: source.perimeter(),
        visible: visible ?? source.visible,
        styleOverrides: styleOverrides ?? source.styleOverrides,
      );
    }

    return null;
  }

  /// Transform a GenSimpleGeometryObjectList, preserving structure for specific types
  /// Since GenSimpleGeometryObjectList now extends UnionGeometryObjectList,
  /// we can use the same transformation logic but need to check type compatibility
  static GeometryObject? transformGenSimpleList({
    required GenSimpleGeometryObjectList source,
    required GeoTrans transform,
    required String id,
    required String label,
    required List<String> dependencies,
    bool? visible,
    Map<String, dynamic>? styleOverrides,
  }) {
    // Transform all objects in the list
    final transformedObjects = transformSimpleList(
      source: source,
      transform: transform,
    );

    // Check if all transformed objects match the expected type for the container
    // If not, convert to UnionGeometryObjectList (which GenSimpleGeometryObjectList already is)
    bool allMatchExpectedType = true;
    Type? expectedType;
    
    if (source is GeoTangentList || source is GeoAngleBisector2L) {
      expectedType = GeoLine;
      allMatchExpectedType = transformedObjects.every((obj) => obj is GeoLine);
    } else if (source is GeoIntersection) {
      expectedType = GeoPoint;
      allMatchExpectedType = transformedObjects.every((obj) => obj is GeoPoint);
    }
    
    // If types don't match, return as UnionGeometryObjectList (which GenSimpleGeometryObjectList extends)
    // This preserves all transformed objects regardless of type
    if (!allMatchExpectedType) {
      debugPrint('[TransformationEngine] Transformed objects don\'t all match expected type $expectedType, returning as UnionGeometryObjectList');
      return GeoTransUnionGeometryObjectList(
        id: id,
        label: label,
        dependencies: dependencies,
        elements: transformedObjects,
        sourceObjectId: source.id,
        transformId: transform.id,
        vertexCountValue: source.elements.length,
        areaValue: 0.0, // Union doesn't have area
        perimeterValue: 0.0, // Union doesn't have perimeter
        visible: visible ?? source.visible,
        styleOverrides: styleOverrides ?? source.styleOverrides,
      );
    }
    
    // For GeoTangentList and GeoAngleBisector2L, use unified objects array approach
    // The transformedObjects array already preserves the structure:
    // - GeoTangentList: objects[0,1] = external, objects[2,3] = internal
    // - GeoAngleBisector2L: objects[0,1] = internal, objects[2,3] = external
    // Just pass the transformed objects array directly
    if (source is GeoTangentList || source is GeoAngleBisector2L) {
      return (source as dynamic).copyWith(
        id: id,
        label: label,
        dependencies: dependencies,
        objects: transformedObjects.cast<GeoLine>(),
        visible: visible ?? source.visible,
        styleOverrides: styleOverrides ?? source.styleOverrides,
      ) as GeometryObject;
    }

    // For GeoIntersection, transform all points in the intersection list
    if (source is GeoIntersection) {
      return source.copyWith(
        id: id,
        label: label,
        dependencies: dependencies,
        objects: transformedObjects.cast<GeoPoint>(),
        visible: visible ?? source.visible,
        styleOverrides: styleOverrides ?? source.styleOverrides,
      );
    }

    // For other GenSimpleGeometryObjectList types, return null
    // They should handle transformation through rebuildFromParents or have specific handlers above
    debugPrint('[TransformationEngine] No specific handler for GenSimpleGeometryObjectList type: ${source.runtimeType}');
    return null;
  }

  /// Transform all elements in a UnionGeometryObjectList
  /// Handles simple, complex, GenSimpleGeometryObjectList, and nested union elements
  static List<GeometryObject> transformUnionElements(
    UnionGeometryObjectList source,
    GeoTrans transform,
  ) {
    final transformedElements = <GeometryObject>[];

    for (final element in source.elements.cast<GeometryObject>()) {
      if (element is SimpleGeometryObject) {
        final simpleResult = transformSimple(
          source: element,
          transform: transform,
          id: '${element.id}_${transform.id}_point',
          label: element.label,
          dependencies: element.dependencies,
          visible: element.visible,
          styleOverrides: element.styleOverrides,
        );

        if (simpleResult != null) {
          transformedElements.add(simpleResult);
        } else {
          transformedElements.add(element);
        }
        continue;
      }

      if (element is GeoSegment || element is GeoArc) {
        final transformedId = '${element.id}_${transform.id}_trans';
        final complexResult = transformComplex(
          source: element as ComplexGeometryObject,
          transform: transform,
          id: transformedId,
          label: element.label,
          dependencies: element.dependencies,
          visible: element.visible,
          styleOverrides: element.styleOverrides,
        );

        if (complexResult != null) {
          transformedElements.add(complexResult);
        } else {
          transformedElements.add(element);
        }
        continue;
      }

      // Handle GenSimpleGeometryObjectList elements in union
      if (element is GenSimpleGeometryObjectList) {
        final transformed = transformGenSimpleList(
          source: element,
          transform: transform,
          id: '${element.id}_${transform.id}',
          label: element.label,
          dependencies: element.dependencies,
          visible: element.visible,
          styleOverrides: element.styleOverrides,
        );

        if (transformed != null) {
          transformedElements.add(transformed);
        } else {
          transformedElements.add(element);
        }
        continue;
      }

      // Handle nested UnionGeometryObjectList elements
      if (element is UnionGeometryObjectList) {
        final nestedElements = transformUnionElements(element, transform);
        final label = '${element.id}_${transform.id}';
        transformedElements.add(GeoTransUnionGeometryObjectList(
          id: label,
          label: element.label,
          dependencies: element.dependencies,
          elements: nestedElements,
          sourceObjectId: element.id,
          transformId: transform.id,
          vertexCountValue: element.vertexCount,
          areaValue: element.area(),
          perimeterValue: element.perimeter(),
          visible: element.visible,
          styleOverrides: element.styleOverrides,
        ));
        continue;
      }

      // Fallback: add element unchanged
      transformedElements.add(element);
    }

    return transformedElements;
  }

  static GeometryObject? _transformSegment({
    required GeoSegment source,
    required GeoTrans transform,
    required String id,
    required String label,
    required List<String> dependencies,
    bool? visible,
    Map<String, dynamic>? styleOverrides,
  }) {
    final start = _transformPoint(
      ownerId: source.id,
      suffix: 'start',
      source: source.startPoint,
      transform: transform,
    );
    final end = _transformPoint(
      ownerId: source.id,
      suffix: 'end',
      source: source.endPoint,
      transform: transform,
    );

    final curve = transformMultivector(
      subject: source.boundary.multivector,
      transform: transform,
      useSignedOperators: true,
    );

    final kind = _inferKind(curve);
    final isVisible = visible ?? source.visible;
    final overrides = styleOverrides ?? source.styleOverrides;
    final sourceId = source.id;
    final transformId = transform.id;

    // Validate that start and end points are perpendicular to the curve
    if (!isPerpendicular(start.multivector, curve)) {
      debugPrint('[TransformationEngine] ========== VALIDATION ERROR ==========');
      debugPrint('[TransformationEngine] Start point multivector is not perpendicular to curve multivector');
      debugPrint('[TransformationEngine] Original segment start point: (${source.startPoint.x}, ${source.startPoint.y})');
      debugPrint('[TransformationEngine] Original segment end point: (${source.endPoint.x}, ${source.endPoint.y})');
      debugPrint('[TransformationEngine] Transformed start point: (${start.x}, ${start.y})');
      debugPrint('[TransformationEngine] Transformed end point: (${end.x}, ${end.y})');
      debugPrint('[TransformationEngine] Original segment multivector: o=${source.boundary.multivector.o}, e1=${source.boundary.multivector.e1}, e2=${source.boundary.multivector.e2}, O=${source.boundary.multivector.O}');
      debugPrint('[TransformationEngine] Transformed curve multivector: o=${curve.o}, e1=${curve.e1}, e2=${curve.e2}, O=${curve.O}');
      debugPrint('[TransformationEngine] Curve kind: $kind');
      debugPrint('[TransformationEngine] Transform type: ${transform.runtimeType} (${transform.id})');
      debugPrint('[TransformationEngine] ======================================');
      throw StateError('Start point is not perpendicular to transformed curve');
    }
    if (!isPerpendicular(end.multivector, curve)) {
      debugPrint('[TransformationEngine] ========== VALIDATION ERROR ==========');
      debugPrint('[TransformationEngine] End point multivector is not perpendicular to curve multivector');
      debugPrint('[TransformationEngine] Original segment start point: (${source.startPoint.x}, ${source.startPoint.y})');
      debugPrint('[TransformationEngine] Original segment end point: (${source.endPoint.x}, ${source.endPoint.y})');
      debugPrint('[TransformationEngine] Transformed start point: (${start.x}, ${start.y})');
      debugPrint('[TransformationEngine] Transformed end point: (${end.x}, ${end.y})');
      debugPrint('[TransformationEngine] Original segment multivector: o=${source.boundary.multivector.o}, e1=${source.boundary.multivector.e1}, e2=${source.boundary.multivector.e2}, O=${source.boundary.multivector.O}');
      debugPrint('[TransformationEngine] Transformed curve multivector: o=${curve.o}, e1=${curve.e1}, e2=${curve.e2}, O=${curve.O}');
      debugPrint('[TransformationEngine] Curve kind: $kind');
      debugPrint('[TransformationEngine] Transform type: ${transform.runtimeType} (${transform.id})');
      debugPrint('[TransformationEngine] ======================================');
      throw StateError('End point is not perpendicular to transformed curve');
    }

    if (kind == SimpleTransformKind.circle) {
      final control = _transformSegmentControlPoint(
        ownerId: source.id,
        source: source,
        transform: transform,
      );
      return GeoTransArc(
        id: id,
        label: label,
        dependencies: dependencies,
        boundary: ComplexGeometryBoundary(
          startPoint: start,
          endPoint: end,
          multivector: curve,
        ),
        sourceObjectId: sourceId,
        transformId: transformId,
        controlPoint: control,
        visible: isVisible,
        styleOverrides: overrides,
      );
    }

    return GeoTransSegment(
      id: id,
      label: label,
      dependencies: dependencies,
      boundary: ComplexGeometryBoundary(
        startPoint: start,
        endPoint: end,
        multivector: curve,
      ),
      sourceObjectId: sourceId,
      transformId: transformId,
      visible: isVisible,
      styleOverrides: overrides,
    );
  }

  static GeometryObject? _transformArc({
    required GeoArc source,
    required GeoTrans transform,
    required String id,
    required String label,
    required List<String> dependencies,
    bool? visible,
    Map<String, dynamic>? styleOverrides,
  }) {
    final start = _transformPoint(
      ownerId: source.id,
      suffix: 'start',
      source: source.startPoint,
      transform: transform,
    );
    final end = _transformPoint(
      ownerId: source.id,
      suffix: 'end',
      source: source.endPoint,
      transform: transform,
    );

    final curve = transformMultivector(
      subject: source.boundary.multivector,
      transform: transform,
      useSignedOperators: true,
    );

    final kind = _inferKind(curve);
    final isVisible = visible ?? source.visible;
    final overrides = styleOverrides ?? source.styleOverrides;
    final sourceId = source.id;
    final transformId = transform.id;

    // Validate that start and end points are perpendicular to the curve
    if (!isPerpendicular(start.multivector, curve)) {
      debugPrint('[TransformationEngine] ========== VALIDATION ERROR ==========');
      debugPrint('[TransformationEngine] Start point multivector is not perpendicular to curve multivector');
      debugPrint('[TransformationEngine] Original arc start point: (${source.startPoint.x}, ${source.startPoint.y})');
      debugPrint('[TransformationEngine] Original arc end point: (${source.endPoint.x}, ${source.endPoint.y})');
      debugPrint('[TransformationEngine] Transformed start point: (${start.x}, ${start.y})');
      debugPrint('[TransformationEngine] Transformed end point: (${end.x}, ${end.y})');
      debugPrint('[TransformationEngine] Original arc multivector: o=${source.boundary.multivector.o}, e1=${source.boundary.multivector.e1}, e2=${source.boundary.multivector.e2}, O=${source.boundary.multivector.O}');
      debugPrint('[TransformationEngine] Transformed curve multivector: o=${curve.o}, e1=${curve.e1}, e2=${curve.e2}, O=${curve.O}');
      debugPrint('[TransformationEngine] Curve kind: $kind');
      debugPrint('[TransformationEngine] Transform type: ${transform.runtimeType} (${transform.id})');
      debugPrint('[TransformationEngine] ======================================');
      throw StateError('Start point is not perpendicular to transformed curve');
    }
    if (!isPerpendicular(end.multivector, curve)) {
      debugPrint('[TransformationEngine] ========== VALIDATION ERROR ==========');
      debugPrint('[TransformationEngine] End point multivector is not perpendicular to curve multivector');
      debugPrint('[TransformationEngine] Original arc start point: (${source.startPoint.x}, ${source.startPoint.y})');
      debugPrint('[TransformationEngine] Original arc end point: (${source.endPoint.x}, ${source.endPoint.y})');
      debugPrint('[TransformationEngine] Transformed start point: (${start.x}, ${start.y})');
      debugPrint('[TransformationEngine] Transformed end point: (${end.x}, ${end.y})');
      debugPrint('[TransformationEngine] Original arc multivector: o=${source.boundary.multivector.o}, e1=${source.boundary.multivector.e1}, e2=${source.boundary.multivector.e2}, O=${source.boundary.multivector.O}');
      debugPrint('[TransformationEngine] Transformed curve multivector: o=${curve.o}, e1=${curve.e1}, e2=${curve.e2}, O=${curve.O}');
      debugPrint('[TransformationEngine] Curve kind: $kind');
      debugPrint('[TransformationEngine] Transform type: ${transform.runtimeType} (${transform.id})');
      debugPrint('[TransformationEngine] ======================================');
      throw StateError('End point is not perpendicular to transformed curve');
    }

    if (kind == SimpleTransformKind.line) {
      return GeoTransSegment(
        id: id,
        label: label,
        dependencies: dependencies,
        boundary: ComplexGeometryBoundary(
          startPoint: start,
          endPoint: end,
          multivector: curve,
        ),
        sourceObjectId: sourceId,
        transformId: transformId,
        visible: isVisible,
        styleOverrides: overrides,
      );
    }

    final control = _transformArcControlPoint(
      ownerId: source.id,
      source: source,
      transform: transform,
    );

    return GeoTransArc(
      id: id,
      label: label,
      dependencies: dependencies,
      boundary: ComplexGeometryBoundary(
        startPoint: start,
        endPoint: end,
        multivector: curve,
      ),
      sourceObjectId: sourceId,
      transformId: transformId,
      controlPoint: control,
      visible: isVisible,
      styleOverrides: overrides,
    );
  }

  static GeoPointer _transformPoint({
    required String ownerId,
    required String suffix,
    required GeoPoint source,
    required GeoTrans transform,
  }) {
    final result = transformMultivector(
      subject: source.multivector,
      transform: transform,
    );

    // Extract coordinates from transformed multivector and create a new GeoPointer
    // This ensures the point remains a point regardless of multivector type detection
    return GeoPointer(
      id: '${ownerId}_$suffix',
      label: source.label,
      x: result.e1,
      y: result.e2,
      visible: source.visible,
      styleOverrides: source.styleOverrides,
    );
  }

  static GeoPointer _transformSegmentControlPoint({
    required String ownerId,
    required GeoSegment source,
    required GeoTrans transform,
  }) {
    final midpoint = GeoPointer(
      id: '${ownerId}_mid',
      label: source.label,
      x: (source.startPoint.x + source.endPoint.x) / 2,
      y: (source.startPoint.y + source.endPoint.y) / 2,
      visible: source.visible,
      styleOverrides: source.styleOverrides,
    );

    return _transformPoint(
      ownerId: ownerId,
      suffix: 'control',
      source: midpoint,
      transform: transform,
    );
  }

  static GeoPointer _transformArcControlPoint({
    required String ownerId,
    required GeoArc source,
    required GeoTrans transform,
  }) {
    final sampled = GeoPointer(
      id: '${ownerId}_control',
      label: source.label,
      x: (source.startPoint.x + source.endPoint.x) / 2,
      y: (source.startPoint.y + source.endPoint.y) / 2,
      visible: source.visible,
      styleOverrides: source.styleOverrides,
    );

    return _transformPoint(
      ownerId: ownerId,
      suffix: 'control',
      source: sampled,
      transform: transform,
    );
  }

  static Multivector _applyInverseToMultivector(
    Multivector object,
    Multivector subject, {
    bool useSignedOperators = false,
  }) {
    // Use the consolidated helper from definitions.dart
    return applyReflectionByType(object, subject, useSignedOperators);
  }

  /// Normalize a multivector with signed forms for complex geometry (segments/arcs)
  /// This preserves orientation information needed for correct arc rendering
  static Multivector _normalizeWithSignedForms(Multivector mv) {
    // Infinity multivectors don't need normalization - return as-is
    if (mv.isInf()) {
      return mv;
    }
    if (mv.isCircle()) {
      return signedInfForm(mv);
    }
    
    if (mv.isLine()) {
      return uniForm(mv);
    }
    
    if (mv.isPoint()) {
      return infForm(mv);
    }
    
    // Fallback to standard normalization if type is unclear
    return normalizeTransformedMultivector(mv);
  }

  static SimpleTransformKind _inferKind(Multivector mv) {
    // Check for infinity first - infinity is a special case
    if (mv.isInf()) {
      // Infinity points don't have a standard transform kind
      // Return point kind as infinity is conceptually a point at infinity
      return SimpleTransformKind.point;
    }
    if (mv.isPoint()) {
      return SimpleTransformKind.point;
    }
    if (mv.isLine()) {
      return SimpleTransformKind.line;
    }
    if (mv.isCircle()) {
      return SimpleTransformKind.circle;
    }
    // Multivector should be normalized before calling this function
    // If we still can't determine the kind, something is wrong
    throw ArgumentError('Cannot determine geometry type from multivector. Multivector may need normalization.');
  }

  /// Translate a geometry object by a vector (dx, dy)
  static GeometryObject translate(
    GeometryObject source,
    double dx,
    double dy, {
    required String newId,
    required String newLabel,
    required List<String> dependencies,
  }) {
    // For points, just shift coordinates
    if (source is GeoPoint) {
      return GeoPointer(
        id: newId,
        label: newLabel,
        x: source.x + dx,
        y: source.y + dy,
        visible: source.visible,
        styleOverrides: source.styleOverrides,
      );
    }

    // For other simple geometry, translate the multivector
    if (source is SimpleGeometryObject) {
      final translatedMv = Multivector(
        o: source.multivector.o,
        e1: source.multivector.e1 + dx * source.multivector.o,
        e2: source.multivector.e2 + dy * source.multivector.o,
        O: source.multivector.O + (dx * source.multivector.e1 + dy * source.multivector.e2) + 
           0.5 * (dx * dx + dy * dy) * source.multivector.o,
      );

      // Determine the type and create appropriate object
      final kind = _inferKind(translatedMv);
      
      if (kind == SimpleTransformKind.line && source is GeoLine) {
        return GeoLine2P(
          id: newId,
          label: newLabel,
          dependencies: dependencies,
          multivector: translatedMv,
          visible: source.visible,
          styleOverrides: source.styleOverrides,
        );
      }

      if (kind == SimpleTransformKind.circle && source is GeoCircle) {
        return GeoCircle2P(
          id: newId,
          label: newLabel,
          dependencies: dependencies,
          multivector: translatedMv,
          visible: source.visible,
          styleOverrides: source.styleOverrides,
        );
      }

      // Default: return as simple object
      return GeoPointer(
        id: newId,
        label: newLabel,
        x: translatedMv.e1,
        y: translatedMv.e2,
        visible: source.visible,
        styleOverrides: source.styleOverrides,
      );
    }

    // For complex objects (segments, arcs), translate endpoints
    if (source is GeoSegment) {
      final start = GeoPointer(
        id: '${newId}_start',
        label: '${source.startPoint.label}\'',
        x: source.startPoint.x + dx,
        y: source.startPoint.y + dy,
        visible: source.startPoint.visible,
        styleOverrides: source.startPoint.styleOverrides,
      );

      final end = GeoPointer(
        id: '${newId}_end',
        label: '${source.endPoint.label}\'',
        x: source.endPoint.x + dx,
        y: source.endPoint.y + dy,
        visible: source.endPoint.visible,
        styleOverrides: source.endPoint.styleOverrides,
      );

      final translatedLineMv = Multivector(
        o: source.boundary.multivector.o,
        e1: source.boundary.multivector.e1 + dx * source.boundary.multivector.o,
        e2: source.boundary.multivector.e2 + dy * source.boundary.multivector.o,
        O: source.boundary.multivector.O + (dx * source.boundary.multivector.e1 + dy * source.boundary.multivector.e2) + 
           0.5 * (dx * dx + dy * dy) * source.boundary.multivector.o,
      );

      return GeoSegment(
        id: newId,
        label: newLabel,
        dependencies: dependencies,
        boundary: ComplexGeometryBoundary(
          startPoint: start,
          endPoint: end,
          multivector: translatedLineMv,
        ),
        visible: source.visible,
        styleOverrides: source.styleOverrides,
      );
    }

    if (source is GeoArc) {
      final start = GeoPointer(
        id: '${newId}_start',
        label: '${source.startPoint.label}\'',
        x: source.startPoint.x + dx,
        y: source.startPoint.y + dy,
        visible: source.startPoint.visible,
        styleOverrides: source.startPoint.styleOverrides,
      );

      final end = GeoPointer(
        id: '${newId}_end',
        label: '${source.endPoint.label}\'',
        x: source.endPoint.x + dx,
        y: source.endPoint.y + dy,
        visible: source.endPoint.visible,
        styleOverrides: source.endPoint.styleOverrides,
      );

      // Translate the circle
      final translatedCircleMv = Multivector(
        o: source.boundary.multivector.o,
        e1: source.boundary.multivector.e1 + dx * source.boundary.multivector.o,
        e2: source.boundary.multivector.e2 + dy * source.boundary.multivector.o,
        O: source.boundary.multivector.O + (dx * source.boundary.multivector.e1 + dy * source.boundary.multivector.e2) + 
           0.5 * (dx * dx + dy * dy) * source.boundary.multivector.o,
      );

      return GeoArc(
        id: newId,
        label: newLabel,
        dependencies: dependencies,
        boundary: ComplexGeometryBoundary(
          startPoint: start,
          endPoint: end,
          multivector: translatedCircleMv,
        ),
        visible: source.visible,
        styleOverrides: source.styleOverrides,
      );
    }

    // For union lists, use the transformation system instead
    // The translate command now uses GeoTranslate transform objects and _createTransformedGeometry
    // which properly handles union types by creating GeoTransUnionGeometryObjectList
    if (source is UnionGeometryObjectList) {
      throw UnimplementedError(
        'Translation of UnionGeometryObjectList should use the transformation system '
        '(GeoTranslate transform object) instead of TransformationEngine.translate(). '
        'Use the translate command which properly handles union types.'
      );
    }

    // Fallback: return source unchanged
    return source;
  }
}
