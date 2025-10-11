import 'package:flutter/material.dart';
import '../geometry_object.dart';

/// Segment between two points
class GeoSegment extends ComplexGeometryObject {
  GeoSegment({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.startPointId,
    required super.endPointId,
    required super.underlyingObjectId,
    super.color = Colors.blue,
    super.visible,
  });

  @override
  String get type => 'segment';

  @override
  void draw(Canvas canvas, Paint paint) {
    // Drawing will be handled by retrieving actual points from DAG
    // This is a simplified implementation
  }

  @override
  bool contains(Offset position) {
    // Simplified: check if point is on segment
    return false;
  }

  @override
  Rect getBounds() {
    return Rect.zero;
  }

  @override
  double distanceTo(Offset point) {
    return double.infinity;
  }

  @override
  double length() {
    // Length would be calculated from actual start and end points
    return 0.0;
  }

  @override
  GeoSegment copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    String? startPointId,
    String? endPointId,
    String? underlyingObjectId,
    Color? color,
    bool? visible,
  }) {
    return GeoSegment(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      startPointId: startPointId ?? this.startPointId,
      endPointId: endPointId ?? this.endPointId,
      underlyingObjectId: underlyingObjectId ?? this.underlyingObjectId,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}

/// Triangle formed by three segments
class GeoTriangle extends ComplexGeometryObjectList<GeoSegment> {
  GeoTriangle({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.elements,
    super.color = Colors.purple,
    super.visible,
  }) : assert(elements.length == 3, 'Triangle requires exactly 3 segments');

  @override
  String get type => 'triangle';

  @override
  int get vertexCount => 3;

  @override
  double area() {
    // Calculate using Heron's formula or cross product
    // Simplified for now
    return 0.0;
  }

  @override
  double perimeter() {
    return elements.fold(0.0, (sum, segment) => sum + segment.length());
  }

  @override
  GeoTriangle copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<GeoSegment>? elements,
    Color? color,
    bool? visible,
  }) {
    return GeoTriangle(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      elements: elements ?? this.elements,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}

/// Polygon formed by multiple segments
class GeoPolygon extends ComplexGeometryObjectList<GeoSegment> {
  GeoPolygon({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.elements,
    super.color = Colors.brown,
    super.visible,
  });

  @override
  String get type => 'polygon';

  @override
  int get vertexCount => elements.length;

  @override
  double area() {
    // Calculate using shoelace formula
    // Simplified for now
    return 0.0;
  }

  @override
  double perimeter() {
    return elements.fold(0.0, (sum, segment) => sum + segment.length());
  }

  bool isConvex() {
    // Check if polygon is convex
    return false;
  }

  bool isClosed() {
    // Check if polygon is closed
    return true;
  }

  @override
  GeoPolygon copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<GeoSegment>? elements,
    Color? color,
    bool? visible,
  }) {
    return GeoPolygon(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      elements: elements ?? this.elements,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}
