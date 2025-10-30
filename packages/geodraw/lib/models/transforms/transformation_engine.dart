import 'package:geocalc/Multivector.dart';

import '../geometry_object.dart';
import '../simple/geo_trans.dart';
import '../simple/geo_point.dart';
import '../simple/geo_line.dart';
import '../simple/geo_circle.dart';
import '../complex/complex_geometry_object.dart';
import '../complex/geo_shapes.dart';

/// Result of transforming a simple geometry object.
class SimpleTransformResult {
  SimpleTransformResult(this.multivector, this.kind);

  final Multivector multivector;
  final SimpleTransformKind kind;
}

/// Result of transforming a complex geometry object boundary.
class ComplexTransformResult {
  ComplexTransformResult({
    required this.boundary,
    required this.kind,
    this.controlPoint,
  });

  final ComplexGeometryBoundary boundary;
  final ComplexTransformKind kind;
  final GeoPoint? controlPoint;
}

/// Classification of the transformed simple object.
enum SimpleTransformKind { point, line, circle, unknown }

/// Classification of a transformed complex object.
enum ComplexTransformKind { segment, arc, unknown }

/// Centralised helpers for applying [GeoTrans] instances to geometry objects.
class TransformationEngine {
  /// Apply [transform] to [source] and return the resulting multivector
  /// alongside the inferred simple geometry kind.
  static SimpleTransformResult transformSimple({
    required SimpleGeometryObject source,
    required GeoTrans transform,
  }) {
    final transformed = transformMultivector(
      subject: source.multivector,
      transform: transform,
    );

    return SimpleTransformResult(transformed, _inferKind(transformed));
  }

  /// Apply [transform] to a raw multivector.
  static Multivector transformMultivector({
    required Multivector subject,
    required GeoTrans transform,
  }) {
    if (transform is GeoInverse) {
      return _applyInverseToMultivector(subject, transform.multivector);
    }

    if (transform is GeoRotate) {
      return applyRotationOperator(transform.multivector, subject);
    }

    if (transform is GeoDilate) {
      return applyDilationOperator(transform.multivector, subject);
    }

    return subject;
  }

  /// Transform a complex geometry object.
  static ComplexTransformResult transformComplex({
    required ComplexGeometryObject source,
    required GeoTrans transform,
  }) {
    if (source is GeoSegment) {
      return _transformSegment(source: source, transform: transform);
    }

    if (source is GeoArc) {
      return _transformArc(source: source, transform: transform);
    }

    return ComplexTransformResult(
      boundary: source.boundary,
      kind: ComplexTransformKind.unknown,
    );
  }

  static ComplexTransformResult _transformSegment({
    required GeoSegment source,
    required GeoTrans transform,
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
    );

    final kind = _inferKind(curve);

    if (kind == SimpleTransformKind.circle) {
      final control = _transformSegmentControlPoint(
        ownerId: source.id,
        source: source,
        transform: transform,
      );
      return ComplexTransformResult(
        boundary: ComplexGeometryBoundary(
          startPoint: start,
          endPoint: end,
          multivector: curve,
        ),
        kind: ComplexTransformKind.arc,
        controlPoint: control,
      );
    }

    return ComplexTransformResult(
      boundary: ComplexGeometryBoundary(
        startPoint: start,
        endPoint: end,
        multivector: curve,
      ),
      kind: ComplexTransformKind.segment,
    );
  }

  static ComplexTransformResult _transformArc({
    required GeoArc source,
    required GeoTrans transform,
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
    );

    final kind = _inferKind(curve);

    if (kind == SimpleTransformKind.line) {
      return ComplexTransformResult(
        boundary: ComplexGeometryBoundary(
          startPoint: start,
          endPoint: end,
          multivector: curve,
        ),
        kind: ComplexTransformKind.segment,
      );
    }

    final control = _transformArcControlPoint(
      ownerId: source.id,
      source: source,
      transform: transform,
    );

    return ComplexTransformResult(
      boundary: ComplexGeometryBoundary(
        startPoint: start,
        endPoint: end,
        multivector: curve,
      ),
      kind: ComplexTransformKind.arc,
      controlPoint: control,
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
    Multivector subject,
  ) {
    if (subject.isLine()) {
      return constructReflectionAcrossLine(object, subject);
    }

    if (subject.isCircle()) {
      return constructReflectionAcrossCircle(object, subject);
    }

    if (subject.isPoint()) {
      return constructReflectionAcrossPoint(object, subject);
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
    return SimpleTransformKind.unknown;
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
