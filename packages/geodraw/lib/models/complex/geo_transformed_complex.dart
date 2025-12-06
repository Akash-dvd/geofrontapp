import 'package:flutter/material.dart';

import '../canvas_style.dart';
import '../geometry_object.dart';
import '../simple/geo_point.dart';
import '../transforms/geo_trans.dart';
import '../transforms/transformation_engine.dart';
import '../../core/dag/dag_manager.dart';
import 'complex_geometry_object.dart';
import 'geo_shapes.dart';

List<String> _normalizedDependencies(
  List<String>? dependencies,
  String primary,
  String transform,
) {
  if (dependencies == null || dependencies.isEmpty) {
    return List<String>.unmodifiable(<String>[primary, transform]);
  }
  final normalized = List<String>.from(dependencies);
  if (!normalized.contains(primary)) {
    normalized.insert(0, primary);
  }
  if (!normalized.contains(transform)) {
    normalized.add(transform);
  }
  return List<String>.unmodifiable(normalized);
}

GeoPointer _decodePoint(Map<String, dynamic>? data, String fallbackId) {
  final x = (data?['x'] as num?)?.toDouble() ?? 0;
  final y = (data?['y'] as num?)?.toDouble() ?? 0;
  final label = data?['label'] as String? ?? '';
  return GeoPointer(id: fallbackId, label: label, x: x, y: y, visible: true);
}

Map<String, dynamic> _encodePoint(GeoPoint point) {
  return {'id': point.id, 'label': point.label, 'x': point.x, 'y': point.y};
}

/// Segment produced by transforming another complex geometry object.
class GeoTransSegment extends GeoSegment {
  GeoTransSegment({
    required super.id,
    required super.label,
    required List<String>? dependencies,
    required super.boundary,
    required this.sourceObjectId,
    required this.transformId,
    super.visible,
    super.styleOverrides,
  }) : super(
         dependencies: _normalizedDependencies(
           dependencies,
           sourceObjectId,
           transformId,
         ),
       );

  final String sourceObjectId;
  final String transformId;

  @override
  GeoTransSegment copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    ComplexGeometryBoundary? boundary,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
    String? sourceObjectId,
    String? transformId,
  }) {
    final overrides = styleOverrides ?? this.styleOverrides;
    final updatedSource = sourceObjectId ?? this.sourceObjectId;
    final updatedTransform = transformId ?? this.transformId;
    final normalizedDependencies = _normalizedDependencies(
      dependencies ?? this.dependencies,
      updatedSource,
      updatedTransform,
    );

    return GeoTransSegment(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: normalizedDependencies,
      boundary: boundary ?? this.boundary,
      sourceObjectId: updatedSource,
      transformId: updatedTransform,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoTransSegment';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final props = Map<String, dynamic>.from(
      (json['properties'] as Map<String, dynamic>? ?? const {}),
    );
    props['sourceObjectId'] = sourceObjectId;
    props['transformId'] = transformId;
    props['startPoint'] = _encodePoint(boundary.startPoint);
    props['endPoint'] = _encodePoint(boundary.endPoint);
    json['properties'] = props;
    return json;
  }

  static GeoTransSegment fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final boundaryMv = SimpleGeometryObject.decodeMultivector(
      props['multivector'],
    );
    final start = _decodePoint(
      props['startPoint'] as Map<String, dynamic>?,
      '${json['id']}_start',
    );
    final end = _decodePoint(
      props['endPoint'] as Map<String, dynamic>?,
      '${json['id']}_end',
    );

    return GeoTransSegment(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      dependencies: (json['dependencies'] as List?)?.cast<String>(),
      boundary: ComplexGeometryBoundary(
        startPoint: start,
        endPoint: end,
        multivector: boundaryMv,
      ),
      sourceObjectId: props['sourceObjectId'] as String? ?? '',
      transformId: props['transformId'] as String? ?? '',
      visible: json['visible'] as bool? ?? true,
      styleOverrides: GeometryObject.extractStyleOverrides(json),
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final sourceObj = dagManager.getObject(sourceObjectId);
    final transformObj = dagManager.getObject(transformId);
    
    if (sourceObj is! GeoSegment || transformObj is! GeoTrans) {
      return null;
    }

    final result = TransformationEngine.transformComplex(
      source: sourceObj,
      transform: transformObj,
      id: id,
      label: label,
      dependencies: dependencies,
      visible: visible,
      styleOverrides: styleOverrides,
    );

    if (result == null) {
      return copyWith();
    }

    if (result is GeoTransSegment) {
      return result;
    }
    if (result is GeoTransArc) {
      return GeoTransArc(
        id: id,
        label: label,
        dependencies: dependencies,
        boundary: result.boundary,
        controlPoint: result.controlPoint,
        sourceObjectId: sourceObjectId,
        transformId: transformId,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    }
    return copyWith();
  }
}

/// Arc produced by transforming another complex geometry object.
class GeoTransArc extends GeoArc {
  GeoTransArc({
    required super.id,
    required super.label,
    required List<String>? dependencies,
    required super.boundary,
    required this.sourceObjectId,
    required this.transformId,
    this.controlPoint,
    super.visible,
    super.styleOverrides,
  }) : super(
         dependencies: _normalizedDependencies(
           dependencies,
           sourceObjectId,
           transformId,
         ),
       );

  final String sourceObjectId;
  final String transformId;
  final GeoPoint? controlPoint;

  @override
  GeoTransArc copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    ComplexGeometryBoundary? boundary,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
    String? sourceObjectId,
    String? transformId,
    GeoPoint? controlPoint,
  }) {
    final overrides = styleOverrides ?? this.styleOverrides;
    final updatedSource = sourceObjectId ?? this.sourceObjectId;
    final updatedTransform = transformId ?? this.transformId;
    final normalizedDependencies = _normalizedDependencies(
      dependencies ?? this.dependencies,
      updatedSource,
      updatedTransform,
    );

    return GeoTransArc(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: normalizedDependencies,
      boundary: boundary ?? this.boundary,
      sourceObjectId: updatedSource,
      transformId: updatedTransform,
      controlPoint: controlPoint ?? this.controlPoint,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoTransArc';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final props = Map<String, dynamic>.from(
      (json['properties'] as Map<String, dynamic>? ?? const {}),
    );
    props['sourceObjectId'] = sourceObjectId;
    props['transformId'] = transformId;
    props['startPoint'] = _encodePoint(boundary.startPoint);
    props['endPoint'] = _encodePoint(boundary.endPoint);
    if (controlPoint != null) {
      props['controlPoint'] = _encodePoint(controlPoint!);
    }
    json['properties'] = props;
    return json;
  }

  static GeoTransArc fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final mv = SimpleGeometryObject.decodeMultivector(props['multivector']);
    final start = _decodePoint(
      props['startPoint'] as Map<String, dynamic>?,
      '${json['id']}_start',
    );
    final end = _decodePoint(
      props['endPoint'] as Map<String, dynamic>?,
      '${json['id']}_end',
    );
    final control = props.containsKey('controlPoint')
        ? _decodePoint(
            props['controlPoint'] as Map<String, dynamic>?,
            '${json['id']}_control',
          )
        : null;

    return GeoTransArc(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      dependencies: (json['dependencies'] as List?)?.cast<String>(),
      boundary: ComplexGeometryBoundary(
        startPoint: start,
        endPoint: end,
        multivector: mv,
      ),
      sourceObjectId: props['sourceObjectId'] as String? ?? '',
      transformId: props['transformId'] as String? ?? '',
      controlPoint: control,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: GeometryObject.extractStyleOverrides(json),
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final sourceObj = dagManager.getObject(sourceObjectId);
    final transformObj = dagManager.getObject(transformId);
    
    if (sourceObj == null || transformObj is! GeoTrans) {
      return null;
    }

    if (sourceObj is! GeoSegment && sourceObj is! GeoArc) {
      return copyWith();
    }

    final result = TransformationEngine.transformComplex(
      source: sourceObj as ComplexGeometryObject,
      transform: transformObj,
      id: id,
      label: label,
      dependencies: dependencies,
      visible: visible,
      styleOverrides: styleOverrides,
    );

    if (result == null) {
      return copyWith();
    }

    if (result is GeoTransArc) {
      return copyWith(
        boundary: result.boundary,
        controlPoint: result.controlPoint ?? controlPoint,
      );
    }
    if (result is GeoTransSegment) {
      return GeoTransSegment(
        id: id,
        label: label,
        dependencies: dependencies,
        boundary: result.boundary,
        sourceObjectId: sourceObjectId,
        transformId: transformId,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    }
    return copyWith();
  }
}

/// Union geometry derived from transforming another union object.
class GeoTransUnionGeometryObjectList
    extends UnionGeometryObjectList<GeometryObject> {
  GeoTransUnionGeometryObjectList({
    required super.id,
    required super.label,
    required List<String>? dependencies,
    required super.elements,
    required this.sourceObjectId,
    required this.transformId,
    this.vertexCountValue = 0,
    this.areaValue = 0,
    this.perimeterValue = 0,
    super.visible,
    super.styleOverrides,
  }) : super(
         dependencies: _normalizedDependencies(
           dependencies,
           sourceObjectId,
           transformId,
         ),
       );

  final String sourceObjectId;
  final String transformId;
  final int vertexCountValue;
  final double areaValue;
  final double perimeterValue;

  @override
  List<Object?> get props => [
    ...super.props,
    sourceObjectId,
    transformId,
    vertexCountValue,
    areaValue,
    perimeterValue,
  ];

  @override
  int get vertexCount => vertexCountValue;

  @override
  double area() => areaValue;

  @override
  double perimeter() => perimeterValue;

  @override
  GeoTransUnionGeometryObjectList copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<GeometryObject>? elements,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    String? sourceObjectId,
    String? transformId,
    int? vertexCountValue,
    double? areaValue,
    double? perimeterValue,
  }) {
    final overrides = styleOverrides ?? this.styleOverrides;
    final updatedSource = sourceObjectId ?? this.sourceObjectId;
    final updatedTransform = transformId ?? this.transformId;
    final normalizedDependencies = _normalizedDependencies(
      dependencies ?? this.dependencies,
      updatedSource,
      updatedTransform,
    );

    return GeoTransUnionGeometryObjectList(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: normalizedDependencies,
      elements: elements ?? this.elements,
      sourceObjectId: updatedSource,
      transformId: updatedTransform,
      vertexCountValue: vertexCountValue ?? this.vertexCountValue,
      areaValue: areaValue ?? this.areaValue,
      perimeterValue: perimeterValue ?? this.perimeterValue,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoTransUnionGeometryObjectList';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final props = <String, dynamic>{
      'sourceObjectId': sourceObjectId,
      'transformId': transformId,
      'vertexCount': vertexCountValue,
      'area': areaValue,
      'perimeter': perimeterValue,
    };
    json['properties'] = props;
    json['elements'] = elements.map((element) => element.toJson()).toList();
    return json;
  }

  static GeoTransUnionGeometryObjectList fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final rawElements =
        (json['elements'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    final elements = rawElements
        .map((elementJson) {
          final type = elementJson['type'] as String?;
          switch (type) {
            case 'GeoTransSegment':
              return GeoTransSegment.fromJson(elementJson);
            case 'GeoTransArc':
              return GeoTransArc.fromJson(elementJson);
            default:
              return null;
          }
        })
        .whereType<GeometryObject>()
        .toList();

    return GeoTransUnionGeometryObjectList(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      dependencies: (json['dependencies'] as List?)?.cast<String>(),
      elements: elements,
      sourceObjectId: props['sourceObjectId'] as String? ?? '',
      transformId: props['transformId'] as String? ?? '',
      vertexCountValue: (props['vertexCount'] as num?)?.toInt() ?? 0,
      areaValue: (props['area'] as num?)?.toDouble() ?? 0,
      perimeterValue: (props['perimeter'] as num?)?.toDouble() ?? 0,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: GeometryObject.extractStyleOverrides(json),
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final sourceObj = dagManager.getObject(sourceObjectId);
    final transformObj = dagManager.getObject(transformId);
    
    if (sourceObj is! UnionGeometryObjectList || transformObj is! GeoTrans) {
      return null;
    }

    final transformedElements = <GeometryObject>[];

    for (final element in sourceObj.elements.cast<GeometryObject>()) {
      if (element is SimpleGeometryObject) {
        final simpleResult = TransformationEngine.transformSimple(
          source: element,
          transform: transformObj,
          id: '${element.id}_${transformObj.id}_point',
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
        final complexResult = TransformationEngine.transformComplex(
          source: element as ComplexGeometryObject,
          transform: transformObj,
          id: '${element.id}_${transformObj.id}_trans',
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

      transformedElements.add(element);
    }

    return copyWith(
      elements: transformedElements,
      vertexCountValue: sourceObj.vertexCount,
      areaValue: sourceObj.area(),
      perimeterValue: sourceObj.perimeter(),
    );
  }

  // TODO: Derive transformed area/perimeter instead of mirroring the source metrics.

  // TODO: Extend union handling to support polygons/poly-arcs and unify transformed IDs/dependencies.
}
