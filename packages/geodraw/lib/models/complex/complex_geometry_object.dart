import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../geometry_object.dart';
import '../simple/geo_point.dart';

/// Immutable tuple describing the geometric boundary for a complex object.
/// Application-layer wrapper for ComplexBoundary that provides GeoPoint access.
class ComplexGeometryBoundary extends Equatable {
  ComplexGeometryBoundary({
    required this.startPoint,
    required this.endPoint,
    required this.multivector,
  }) : _boundary = ComplexBoundary(
         startPoint: startPoint.multivector,
         endPoint: endPoint.multivector,
         curve: multivector,
       );

  final GeoPoint startPoint;
  final GeoPoint endPoint;
  final Multivector multivector;
  
  /// Internal mathematical representation
  final ComplexBoundary _boundary;
  
  /// Expose the pure mathematical representation
  ComplexBoundary get boundary => _boundary;

  ComplexGeometryBoundary copyWith({
    GeoPoint? startPoint,
    GeoPoint? endPoint,
    Multivector? multivector,
  }) {
    return ComplexGeometryBoundary(
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      multivector: multivector ?? this.multivector,
    );
  }

  /// Check if a point lies on this boundary (segment or arc)
  /// Returns: bool indicating if point is on the boundary
  bool containsPoint(GeoPoint point, {double tolerance = 1e-10}) {
    final pointMv = constructFreePoint(point.x, point.y);
    // Call the global function from definitions.dart
    return isPointOnBoundary(pointMv, _boundary, tolerance: tolerance);
  }

  Map<String, dynamic> toJson() {
    return {
      'startPointId': startPoint.id,
      'endPointId': endPoint.id,
      'multivector': SimpleGeometryObject.encodeMultivector(multivector),
    };
  }

  @override
  List<Object?> get props => [startPoint, endPoint, multivector];
}

/// Base class for objects composed from boundary points and an implicit curve.
abstract class ComplexGeometryObject extends GeometryObject {
  ComplexGeometryObject({
    required super.id,
    required super.label,
    required super.dependencies,
    required this.boundary,
    super.visible,
    super.styleOverrides,
  });

  final ComplexGeometryBoundary boundary;

  GeoPoint get startPoint => boundary.startPoint;
  GeoPoint get endPoint => boundary.endPoint;
  Multivector get multivector => boundary.multivector;

  /// Calculate the length of the object following its boundary definition.
  double length();

  @override
  List<Object?> get props => [...super.props, boundary];

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = boundary.toJson();
    return json;
  }
}

/// Groups together simple or complex geometry elements into a single object.
///
/// The constituent elements must be either [SimpleGeometryObject] or
/// [ComplexGeometryObject]; nested groupings are handled by
/// [RecursiveUnionGeo].
abstract class UnionGeometryObjectList<T extends GeometryObject>
    extends GeometryObject {
  UnionGeometryObjectList({
    required super.id,
    required super.label,
    required super.dependencies,
    required List<T> elements,
    super.visible,
    super.styleOverrides,
  })  : assert(
          elements.every(
            (element) =>
                element is SimpleGeometryObject ||
                element is ComplexGeometryObject,
          ),
          'UnionGeometryObjectList supports only simple or complex elements',
        ),
        elements = List.unmodifiable(elements);

  final List<T> elements;

  /// Number of vertices in this shape
  int get vertexCount;

  /// Calculate the area of this shape
  double area();

  /// Calculate the perimeter of this shape
  double perimeter();

  @override
  void draw(Canvas canvas, Paint paint) {
    for (final element in elements) {
      element.draw(canvas, paint);
    }
  }

  @override
  bool contains(Offset position) {
    return elements.any((element) => element.contains(position));
  }

  @override
  Rect getBounds() {
    if (elements.isEmpty) return Rect.zero;

    return elements
        .map((element) => element.getBounds())
        .reduce((a, b) => a.expandToInclude(b));
  }

  @override
  double distanceTo(Offset point) {
    if (elements.isEmpty) return double.infinity;

    return elements
        .map((element) => element.distanceTo(point))
        .reduce((a, b) => a < b ? a : b);
  }

  @override
  List<Object?> get props => [...super.props, elements];

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['elements'] = elements.map((element) => element.toJson()).toList();
    return json;
  }
}

/// Specialized union ensuring all elements are complex geometry objects.
abstract class UnionComplexObjectList<T extends ComplexGeometryObject>
    extends UnionGeometryObjectList<T> {
  UnionComplexObjectList({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.elements,
    super.visible,
    super.styleOverrides,
  });
}

/// Placeholder for recursive unions that can contain other groupings.
///
/// This will eventually support nesting lists of simple, complex, or union
/// geometries. For now the class exists to reserve the API surface and will be
/// fleshed out in a future iteration.
abstract class RecursiveUnionGeo extends GeometryObject {
  RecursiveUnionGeo({
    required super.id,
    required super.label,
    required super.dependencies,
    super.visible,
    super.styleOverrides,
  });
}
