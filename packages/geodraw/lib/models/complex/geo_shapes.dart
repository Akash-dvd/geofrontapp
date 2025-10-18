import 'package:flutter/material.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
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
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.blue,
  }) : super(
         styleOverrides: _shapeStyleOverrides(
           type: GeoSegment,
           style: style,
           overrides: styleOverrides,
           fallbackColor: color,
         ),
       );

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
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoSegment, style: style)
            : color != null
            ? _shapeStyleOverrides(
                type: GeoSegment,
                fallbackColor: color,
              )
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;
    return GeoSegment(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      startPointId: startPointId ?? this.startPointId,
      endPointId: endPointId ?? this.endPointId,
      underlyingObjectId: underlyingObjectId ?? this.underlyingObjectId,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.blue,
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
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.purple,
  }) : assert(elements.length == 3, 'Triangle requires exactly 3 segments'),
       super(
         styleOverrides: _shapeStyleOverrides(
           type: GeoTriangle,
           style: style,
           overrides: styleOverrides,
           fallbackColor: color,
         ),
       );

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
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoTriangle, style: style)
            : color != null
            ? _shapeStyleOverrides(
                type: GeoTriangle,
                fallbackColor: color,
              )
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;
    return GeoTriangle(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      elements: elements ?? this.elements,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.purple,
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
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.brown,
  }) : super(
         styleOverrides: _shapeStyleOverrides(
           type: GeoPolygon,
           style: style,
           overrides: styleOverrides,
           fallbackColor: color,
         ),
       );

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
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoPolygon, style: style)
            : color != null
            ? _shapeStyleOverrides(
                type: GeoPolygon,
                fallbackColor: color,
              )
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;
    return GeoPolygon(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      elements: elements ?? this.elements,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.brown,
    );
  }
}

Map<String, dynamic>? _shapeStyleOverrides({
  required Type type,
  CanvasStyle? style,
  Map<String, dynamic>? overrides,
  Color? fallbackColor,
}) {
  if (overrides != null) {
    return Map<String, dynamic>.unmodifiable(overrides);
  }

  if (style != null) {
    final defaults = CanvasStyleDefaults.instance.resolveForType(type);
    final diff = style.diff(defaults);
    if (diff.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.unmodifiable(diff);
  }

  if (fallbackColor != null) {
    final defaults = CanvasStyleDefaults.instance.resolveForType(type);
    if (fallbackColor.value != defaults.strokeColor.value) {
      return Map<String, dynamic>.unmodifiable({
        'strokeColor': CanvasStyle.colorToHex(fallbackColor),
      });
    }
  }

  return null;
}
