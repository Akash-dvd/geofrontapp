import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../simple/geo_line.dart';
import 'simple_list_utils.dart';
import '../../core/dag/dag_manager.dart';
import '../../core/label_manager.dart';

/// List of angle bisector lines constructed from two lines (internal and external bisectors)
class GeoAngleBisector2L extends GenSimpleGeometryObjectList<GeoLine> {
  final List<GeoLine> _internalBisectors;
  final List<GeoLine> _externalBisectors;

  GeoAngleBisector2L({
    required super.id,
    required super.label,
    required super.dependencies,
    List<GeoLine> internalBisectors = const [],
    List<GeoLine> externalBisectors = const [],
    Color color = Colors.purple,
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoAngleBisector2L requires exactly 2 line dependencies',
       ),
       _internalBisectors = List<GeoLine>.unmodifiable(internalBisectors),
       _externalBisectors = List<GeoLine>.unmodifiable(externalBisectors),
       super(
         objects: List<GeoLine>.unmodifiable([
           ...internalBisectors,
           ...externalBisectors,
         ]),
         styleOverrides: styleOverridesForType(
           type: GeoAngleBisector2L,
           style: style,
           overrides: styleOverrides,
           fallbackColor: color,
         ),
       );

  factory GeoAngleBisector2L.constructFromLines({
    required String id,
    required String label,
    required GeoLine line1,
    required GeoLine line2,
    required DAGManager dagManager,
    Color color = Colors.purple,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    // line1 and line2 are already required to be GeoLine, so no need to check

    final computation = _computeAngleBisectors(
      dagManager: dagManager,
      containerId: id,
      line1: line1,
      line2: line2,
      visible: visible,
    );

    return GeoAngleBisector2L(
      id: id,
      label: label,
      dependencies: [line1.id, line2.id],
      internalBisectors: computation.internalBisectors,
      externalBisectors: computation.externalBisectors,
      color: color,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );
  }

  List<GeoLine> get internalBisectors => _internalBisectors;

  List<GeoLine> get externalBisectors => _externalBisectors;

  bool get hasBisectors => objects.isNotEmpty;

  @override
  String get type => 'GeoAngleBisector2L';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'internalCount': _internalBisectors.length,
      'externalCount': _externalBisectors.length,
    };
    return json;
  }

  static GeoAngleBisector2L fromJson(Map<String, dynamic> json) {
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final properties =
        (json['properties'] as Map<String, dynamic>?) ?? const {};
    final internalCount =
        (properties['internalCount'] as num?)?.toInt() ?? 0;
    final externalCount =
        (properties['externalCount'] as num?)?.toInt() ?? 0;
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

    final internalBisectors =
        lines.take(internalCount).toList(growable: false);
    final externalBisectors = lines
        .skip(internalCount)
        .take(externalCount)
        .toList(growable: false);

    final defaults =
        CanvasStyleDefaults.instance.resolveForType(GeoAngleBisector2L);
    final overrides = styleOverridesFromJson(json);

    return GeoAngleBisector2L(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? '',
      dependencies: deps,
      internalBisectors: internalBisectors,
      externalBisectors: externalBisectors,
      visible: json['visible'] as bool? ?? true,
      color: defaults.strokeColor,
      styleOverrides: overrides,
    );
  }

  @override
  GeoAngleBisector2L copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<GeoLine>? internalBisectors,
    List<GeoLine>? externalBisectors,
    Color? color,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? styleOverridesForType(
                type: GeoAngleBisector2L,
                style: style,
              )
            : color != null
            ? styleOverridesForType(
                type: GeoAngleBisector2L,
                fallbackColor: color,
              )
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    return GeoAngleBisector2L(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      internalBisectors: internalBisectors ?? _internalBisectors,
      externalBisectors: externalBisectors ?? _externalBisectors,
      visible: visible ?? this.visible,
      styleOverrides: resolvedOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(
    List<GeometryObject> parents,
    dynamic dagManager,
  ) {
    if (dagManager is! DAGManager || dependencies.length != 2) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final line1Obj = dagManager.getObject(dependencies[0]);
    final line2Obj = dagManager.getObject(dependencies[1]);
    
    if (line1Obj is! GeoLine || line2Obj is! GeoLine) {
      return null;
    }
    
    final line1 = line1Obj;
    final line2 = line2Obj;

    try {
      return GeoAngleBisector2L.constructFromLines(
        id: id,
        label: label,
        line1: line1,
        line2: line2,
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
    case 'GeoAngleBisector3P':
      return GeoAngleBisector3P.fromJson(json);
    case 'GeoPolarLine':
      return GeoPolarLine.fromJson(json);
    case 'GeoTangentLine':
      return GeoTangentLine.fromJson(json);
    default:
      return null;
  }
}

_AngleBisectorComputation _computeAngleBisectors({
  required DAGManager dagManager,
  required String containerId,
  required GeoLine line1,
  required GeoLine line2,
  required bool visible,
}) {
  // constructAngleBisector2Lines returns a list of 2 Multivectors (internal and external bisectors)
  final bisectors = constructAngleBisector2Lines(
    line1.multivector,
    line2.multivector,
  );

  final internalLines = <GeoLine>[];
  final externalLines = <GeoLine>[];

  if (bisectors.isNotEmpty) {
    // Get unique lowercase label for internal bisector line
    final internalLabel = LabelManager.getNextAvailableLabel(
      dagManager,
      GeometryObjectType.line,
    );
    
    final internalLine = GeoLine2P(
      id: internalLabel,
      label: internalLabel,
      dependencies: [line1.id, line2.id],
      multivector: bisectors[0],
      visible: visible,
    );
    
    // Register element in elementToContainer map
    dagManager.registerElement(internalLabel, containerId);
    internalLines.add(internalLine);
  }

  if (bisectors.length >= 2) {
    // Get unique lowercase label for external bisector line
    final externalLabel = LabelManager.getNextAvailableLabel(
      dagManager,
      GeometryObjectType.line,
    );
    
    final externalLine = GeoLine2P(
      id: externalLabel,
      label: externalLabel,
      dependencies: [line1.id, line2.id],
      multivector: bisectors[1],
      visible: visible,
    );
    
    // Register element in elementToContainer map
    dagManager.registerElement(externalLabel, containerId);
    externalLines.add(externalLine);
  }

  return _AngleBisectorComputation(
    internalBisectors: internalLines,
    externalBisectors: externalLines,
  );
}

class _AngleBisectorComputation {
  final List<GeoLine> internalBisectors;
  final List<GeoLine> externalBisectors;

  const _AngleBisectorComputation({
    required this.internalBisectors,
    required this.externalBisectors,
  });

}

