import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import 'canvas_object.dart';
import 'canvas_style.dart';

/// Abstract base class for all geometric objects
/// Extends CanvasObject and adds geometric properties
abstract class GeometryObject extends CanvasObject with EquatableMixin {
  /// Unique identifier
  @override
  final String id;

  /// Display label for this object
  final String label;

  /// List of object IDs this object depends on
  final List<String> dependencies;

  /// Whether this object is visible on the canvas
  @override
  final bool visible;

  /// Serialized style overrides relative to [defaultStyle].
  final Map<String, dynamic> styleOverrides;

  GeometryObject({
    required this.id,
    required this.label,
    required this.dependencies,
    this.visible = true,
    Map<String, dynamic>? styleOverrides,
  }) : styleOverrides = Map.unmodifiable(styleOverrides ?? const {});

  @override
  CanvasStyle get style {
    return CanvasStyle.fromDiff(defaultStyle, styleOverrides);
  }

  /// Resolve the style overrides map to use for a new instance.
  Map<String, dynamic> resolveStyleOverrides(CanvasStyle? newStyle) {
    if (newStyle == null) {
      return styleOverrides;
    }
    return Map.unmodifiable(newStyle.diff(defaultStyle));
  }

  /// Extracts the style override map from serialized JSON if present.
  static Map<String, dynamic>? extractStyleOverrides(
    Map<String, dynamic> json,
  ) {
    final raw = json['style'];
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  /// Parse a color representation from JSON (hex string or int value).
  static Color? parseColor(dynamic raw) {
    if (raw is String) {
      return CanvasStyle.colorFromHex(raw);
    }
    if (raw is int) {
      return Color(raw);
    }
    return null;
  }

  /// Calculate distance from this object to a point
  double distanceTo(Offset point);

  /// Create a copy of this object with updated properties
  GeometryObject copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    bool? visible,
    CanvasStyle? style,
  });

  /// Rebuild this object from the provided parent geometries.
  ///
  /// Subclasses that can derive their state entirely from dependencies
  /// should override this and return a new instance constructed from [parents].
  /// The default implementation returns null to indicate the object
  /// cannot be reconstructed generically.
  GeometryObject? rebuildFromParents(List<GeometryObject> parents) => null;

  @override
  List<Object?> get props => [id, label, dependencies, styleOverrides, visible];

  /// Subclasses should override and call super.toJson() then add their properties
  @override
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'type': type,
      'label': label,
      'dependencies': dependencies,
      'visible': visible,
    };

    if (styleOverrides.isNotEmpty) {
      data['style'] = styleOverrides;
    }

    return data;
  }
}

/// Base class for objects defined by a single equation
abstract class SimpleGeometryObject extends GeometryObject {
  /// The Multivector representing this geometric object's equation
  final Multivector multivector;

  static const String multivectorKey = 'mv';

  SimpleGeometryObject({
    required super.id,
    required super.label,
    required super.dependencies,
    required this.multivector,
    super.visible,
    super.styleOverrides,
  });

  /// Check if this object intersects with another
  bool intersects(SimpleGeometryObject other);

  @override
  List<Object?> get props => [...super.props, multivector];

  /// Serialize the multivector to a compact list representation.
  static List<double> encodeMultivector(Multivector mv) {
    return <double>[mv.o, mv.e1, mv.e2, mv.O];
  }

  /// Decode a multivector from a serialized representation.
  static Multivector decodeMultivector(dynamic raw) {
    if (raw is! List) {
      return Multivector.zero();
    }

    double readComponent(int index) {
      if (index >= raw.length) return 0.0;
      final value = raw[index];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return Multivector(
      o: readComponent(0),
      e1: readComponent(1),
      e2: readComponent(2),
      O: readComponent(3),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json[multivectorKey] = encodeMultivector(multivector);
    return json;
  }
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
    super.visible,
    super.styleOverrides,
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

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['objects'] = objects.map((obj) => obj.toJson()).toList();
    return json;
  }
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
    super.visible,
    super.styleOverrides,
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

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'startPointId': startPointId,
      'endPointId': endPointId,
      'underlyingObjectId': underlyingObjectId,
    };
    return json;
  }
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
    super.visible,
    super.styleOverrides,
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

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['elements'] = elements.map((element) => element.toJson()).toList();
    return json;
  }
}
