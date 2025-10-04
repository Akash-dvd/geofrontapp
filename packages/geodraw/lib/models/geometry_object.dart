import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'canvas_object.dart';

/// Abstract base class for all geometric objects
/// Extends CanvasObject and adds geometric properties
abstract class GeometryObject extends CanvasObject with EquatableMixin {
  /// Unique identifier
  final String id;
  
  /// Display label for this object
  final String label;
  
  /// List of object IDs this object depends on
  final List<String> dependencies;
  
  /// Color for rendering
  final Color color;
  
  /// Whether this object is visible on the canvas
  final bool visible;

  GeometryObject({
    required this.id,
    required this.label,
    required this.dependencies,
    this.color = Colors.blue,
    this.visible = true,
  });

  /// Calculate distance from this object to a point
  double distanceTo(Offset point);
  
  /// Create a copy of this object with updated properties
  GeometryObject copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Color? color,
    bool? visible,
  });

  @override
  List<Object?> get props => [id, label, dependencies, color, visible];
}

/// Base class for objects defined by a single equation
abstract class SimpleGeometryObject extends GeometryObject {
  SimpleGeometryObject({
    required super.id,
    required super.label,
    required super.dependencies,
    super.color,
    super.visible,
  });

  /// Check if this object intersects with another
  bool intersects(SimpleGeometryObject other);
}

/// Base class for lists of simple geometry objects
abstract class SimpleGeometryObjectList<T extends SimpleGeometryObject>
    extends GeometryObject {
  /// The objects in this list
  final List<T> objects;

  SimpleGeometryObjectList({
    required super.id,
    required super.label,
    required super.dependencies,
    required this.objects,
    super.color,
    super.visible,
  });

  /// Number of objects in this list
  int get length => objects.length;

  /// Access object by index
  T operator [](int index) => objects[index];

  @override
  void draw(Canvas canvas, Paint paint) {
    for (final obj in objects) {
      obj.draw(canvas, paint);
    }
  }

  @override
  bool contains(Offset position) {
    return objects.any((obj) => obj.contains(position));
  }

  @override
  Rect getBounds() {
    if (objects.isEmpty) return Rect.zero;
    
    return objects
        .map((obj) => obj.getBounds())
        .reduce((a, b) => a.expandToInclude(b));
  }

  @override
  double distanceTo(Offset point) {
    if (objects.isEmpty) return double.infinity;
    
    return objects
        .map((obj) => obj.distanceTo(point))
        .reduce((a, b) => a < b ? a : b);
  }

  @override
  List<Object?> get props => [...super.props, objects];
}

/// Base class for objects requiring boundary points + underlying simple object
abstract class ComplexGeometryObject extends GeometryObject {
  /// Starting boundary point
  final String startPointId;
  
  /// Ending boundary point
  final String endPointId;
  
  /// ID of the underlying simple object
  final String underlyingObjectId;

  ComplexGeometryObject({
    required super.id,
    required super.label,
    required super.dependencies,
    required this.startPointId,
    required this.endPointId,
    required this.underlyingObjectId,
    super.color,
    super.visible,
  });

  /// Calculate the length of this object
  double length();

  @override
  List<Object?> get props => [
        ...super.props,
        startPointId,
        endPointId,
        underlyingObjectId,
      ];
}

/// Base class for collections forming composite shapes
abstract class ComplexGeometryObjectList<T extends ComplexGeometryObject>
    extends GeometryObject {
  /// The elements in this list
  final List<T> elements;

  ComplexGeometryObjectList({
    required super.id,
    required super.label,
    required super.dependencies,
    required this.elements,
    super.color,
    super.visible,
  });

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
}
