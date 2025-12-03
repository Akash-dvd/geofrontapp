import 'package:flutter/material.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../simple/geo_point.dart';
import '../simple/geo_line.dart';
import '../simple/geo_circle.dart';
import 'simple_list_utils.dart';
import '../../core/dag/dag_manager.dart';
// Note: LabelManager import will be needed when _computeTangents is implemented

/// List of tangent lines constructed from point/circle inputs.
class GeoTangent extends GenSimpleGeometryObjectList<GeoLine> {
  final List<GeoLine> _externalTangents;
  final List<GeoLine> _internalTangents;

  GeoTangent({
    required super.id,
    required super.label,
    required super.dependencies,
    List<GeoLine> externalTangents = const [],
    List<GeoLine> internalTangents = const [],
    Color color = Colors.pink,
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoTangent requires exactly 2 object dependencies',
       ),
       _externalTangents = List<GeoLine>.unmodifiable(externalTangents),
       _internalTangents = List<GeoLine>.unmodifiable(internalTangents),
       super(
         objects: List<GeoLine>.unmodifiable([
           ...externalTangents,
           ...internalTangents,
         ]),
         styleOverrides: styleOverridesForType(
           type: GeoTangent,
           style: style,
           overrides: styleOverrides,
           fallbackColor: color,
         ),
       );

  factory GeoTangent.constructFromObjects({
    required String id,
    required String label,
    required GeometryObject first,
    required GeometryObject second,
    required DAGManager dagManager,
    Color color = Colors.pink,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (!_isValidTangentInput(first) || !_isValidTangentInput(second)) {
      throw ArgumentError('Tangent requires point or circle inputs');
    }

    if (first is! GeoCircle && second is! GeoCircle) {
      throw ArgumentError('Tangent requires at least one circle input');
    }

    final computation = _computeTangents(
      dagManager: dagManager,
      containerId: id,
      first: first,
      second: second,
      visible: visible,
    );

    return GeoTangent(
      id: id,
      label: label,
      dependencies: [first.id, second.id],
      externalTangents: computation.externalTangents,
      internalTangents: computation.internalTangents,
      color: color,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );
  }

  List<GeoLine> get externalTangents => _externalTangents;

  List<GeoLine> get internalTangents => _internalTangents;

  bool get hasTangents => objects.isNotEmpty;

  @override
  String get type => 'GeoTangent';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'externalCount': _externalTangents.length,
      'internalCount': _internalTangents.length,
    };
    return json;
  }

  static GeoTangent fromJson(Map<String, dynamic> json) {
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final properties =
        (json['properties'] as Map<String, dynamic>?) ?? const {};
    final externalCount = (properties['externalCount'] as num?)?.toInt() ?? 0;
    final internalCount = (properties['internalCount'] as num?)?.toInt() ?? 0;
    final objectsJson = (json['objects'] as List?) ?? const [];
    final lines = <GeoLine>[];

    for (final entry in objectsJson) {
      final map = castJsonObject(entry);
      if (map == null) {
        continue;
      }
      final line = _decodeLine(map);
      if (line != null) {
        lines.add(line);
      }
    }

    final externalTangents = lines.take(externalCount).toList(growable: false);
    final internalTangents = lines
        .skip(externalCount)
        .take(internalCount)
        .toList(growable: false);

    final defaults = CanvasStyleDefaults.instance.resolveForType(GeoTangent);
    final overrides = styleOverridesFromJson(json);

    return GeoTangent(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? '',
      dependencies: deps,
      externalTangents: externalTangents,
      internalTangents: internalTangents,
      visible: json['visible'] as bool? ?? true,
      color: defaults.strokeColor,
      styleOverrides: overrides,
    );
  }

  @override
  GeoTangent copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<GeoLine>? externalTangents,
    List<GeoLine>? internalTangents,
    Color? color,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? styleOverridesForType(type: GeoTangent, style: style)
            : color != null
            ? styleOverridesForType(type: GeoTangent, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    return GeoTangent(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      externalTangents: externalTangents ?? _externalTangents,
      internalTangents: internalTangents ?? _internalTangents,
      visible: visible ?? this.visible,
      styleOverrides: resolvedOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(
    List<GeometryObject> parents,
    dynamic dagManager,
  ) {
    if (parents.length != 2) {
      return null;
    }

    // Cast dagManager to DAGManager
    if (dagManager is! DAGManager) {
      return null;
    }

    final first = parents[0];
    final second = parents[1];

    if (!_isValidTangentInput(first) || !_isValidTangentInput(second)) {
      return null;
    }

    try {
      return GeoTangent.constructFromObjects(
        id: id,
        label: label,
        first: first,
        second: second,
        dagManager: dagManager,
        visible: visible,
        styleOverrides: styleOverrides,
      );
    } catch (_) {
      return null;
    }
  }
}

GeoLine? _decodeLine(Map<String, dynamic> json) {
  switch (json['type'] as String?) {
    case 'GeoLine2P':
      return GeoLine2P.fromJson(json);
    case 'GeoPerpendicularBisector':
      return GeoPerpendicularBisector.fromJson(json);
    case 'GeoPerpendicularLine':
      return GeoPerpendicularLine.fromJson(json);
    case 'GeoParallelLine':
      return GeoParallelLine.fromJson(json);
    default:
      return null;
  }
}

bool _isValidTangentInput(GeometryObject object) {
  return object is GeoCircle || object is GeoPoint;
}

_TangentComputation _computeTangents({
  required DAGManager dagManager,
  required String containerId,
  required GeometryObject first,
  required GeometryObject second,
  required bool visible,
}) {
  // Placeholder implementation. Actual tangent calculations will be supplied later.
  // When implemented, tangent lines should be created with unique labels using:
  // LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.line)
  // And registered with: dagManager.registerElement(lineId, containerId)
  return const _TangentComputation.empty();
}

class _TangentComputation {
  final List<GeoLine> externalTangents;
  final List<GeoLine> internalTangents;

  const _TangentComputation({
    required this.externalTangents,
    required this.internalTangents,
  });

  const _TangentComputation.empty()
    : externalTangents = const <GeoLine>[],
      internalTangents = const <GeoLine>[];
}
