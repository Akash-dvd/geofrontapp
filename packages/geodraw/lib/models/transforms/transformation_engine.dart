import 'package:geocalc/Multivector.dart';

import '../geometry_object.dart';
import '../simple/geo_trans.dart';
import '../simple/geo_point.dart';
import '../simple/geo_line.dart';
import '../simple/geo_circle.dart';
import '../simple/geo_transformed_simple.dart';
import '../complex/complex_geometry_object.dart';
import '../complex/geo_shapes.dart';
import '../complex/geo_transformed_complex.dart';

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
    print('[TransformationEngine] transformSimple: source=${source.runtimeType} (${source.id}), transform=${transform.runtimeType} (${transform.id})');
    
    // Special case: Points always remain points (reflection, rotation, dilation preserve point type)
    if (source is GeoPoint) {
      print('[TransformationEngine] Source is a point - points always remain points');
      final transformed = transformMultivector(
        subject: source.multivector,
        transform: transform,
      );
      
      // Force the result to be treated as a point, even if kind inference says otherwise
      // This is because points should always remain points
      print('[TransformationEngine] Creating GeoTransPoint (point type preserved)');
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

    print('[TransformationEngine] Original multivector: o=${source.multivector.o}, e1=${source.multivector.e1}, e2=${source.multivector.e2}, O=${source.multivector.O}');
    print('[TransformationEngine] Transformed multivector (before normalization): o=${transformed.o}, e1=${transformed.e1}, e2=${transformed.e2}, O=${transformed.O}');
    print('[TransformationEngine] Checking multivector type (before normalization): isPoint=${transformed.isPoint()}, isLine=${transformed.isLine()}, isCircle=${transformed.isCircle()}');
    
    // Normalize the multivector using the function from definitions.dart
    transformed = normalizeTransformedMultivector(transformed);
    print('[TransformationEngine] After normalization: o=${transformed.o}, e1=${transformed.e1}, e2=${transformed.e2}, O=${transformed.O}');
    print('[TransformationEngine] Checking multivector type (after normalization): isPoint=${transformed.isPoint()}, isLine=${transformed.isLine()}, isCircle=${transformed.isCircle()}');
    
    final kind = _inferKind(transformed);
    print('[TransformationEngine] Transformed multivector kind: $kind');
    final sourceId = source.id;
    final transformId = transform.id;
    final isVisible = visible ?? source.visible;
    final overrides = styleOverrides ?? source.styleOverrides;

    switch (kind) {
      case SimpleTransformKind.point:
        print('[TransformationEngine] Kind is point, but source is not GeoPoint - this should not happen');
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
    if (transform is GeoInverse) {
      return _applyInverseToMultivector(
        subject,
        transform.multivector,
        useSignedOperators: useSignedOperators,
      );
    }

    if (transform is GeoRotate) {
      return applyRotationOperator(transform.multivector, subject);
    }

    if (transform is GeoDilate) {
      return applyDilationOperator(transform.multivector, subject);
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

    if (!result.isPoint()) {
      return GeoPointer(
        id: '${ownerId}_$suffix',
        label: source.label,
        x: source.x,
        y: source.y,
        visible: source.visible,
        styleOverrides: source.styleOverrides,
      );
    }

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
    if (subject.isLine()) {
      return useSignedOperators
          ? constructSignedReflectionAcrossLine(object, subject)
          : constructReflectionAcrossLine(object, subject);
    }

    if (subject.isCircle()) {
      return useSignedOperators
          ? constructSignedReflectionAcrossCircle(object, subject)
          : constructReflectionAcrossCircle(object, subject);
    }

    if (subject.isPoint()) {
      return useSignedOperators
          ? constructSignedReflectionAcrossPoint(object, subject)
          : constructReflectionAcrossPoint(object, subject);
    }

    return subject.reflection(object).getOrElse(() => object);
  }

  static SimpleTransformKind _inferKind(Multivector mv) {
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

    // For union lists, translate recursively
    if (source is UnionGeometryObjectList) {
      // TODO: Implement translation for union lists if needed
      throw UnimplementedError('Translation of UnionGeometryObjectList not yet implemented');
    }

    // Fallback: return source unchanged
    return source;
  }
}
