import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../simple/geo_line.dart';
import 'simple_list_utils.dart';
import '../../core/dag/dag_manager.dart';
import '../../core/label_manager.dart';
import '../transforms/geo_trans.dart';
import '../transforms/transformation_engine.dart';

/// List of angle bisector lines constructed from two lines (internal and external bisectors)
class GeoAngleBisector2L extends GenSimpleGeometryObjectList<GeoLine> {
  // Store counts for enumerator computation
  final int _internalCount;
  final int _externalCount;

  GeoAngleBisector2L({
    required String id,
    required String label,
    required List<String> dependencies,
    List<GeoLine>? objects,
    List<GeoLine>? internalBisectors,
    List<GeoLine>? externalBisectors,
    Color color = Colors.purple,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoAngleBisector2L requires exactly 2 line dependencies',
       ),
       // If objects provided, compute counts from array indices
       // objects[0,1] = internalBisectors, objects[2,3] = externalBisectors
       _internalCount = objects != null 
           ? (objects.length >= 2 ? 2 : objects.length)
           : (internalBisectors?.length ?? 0),
       _externalCount = objects != null
           ? (objects.length > 2 ? (objects.length >= 4 ? 2 : objects.length - 2) : 0)
           : (externalBisectors?.length ?? 0),
       super(
         id: id,
         label: label,
         dependencies: dependencies,
         objects: objects ?? List<GeoLine>.unmodifiable([
           ...(internalBisectors ?? []),
           ...(externalBisectors ?? []),
         ]),
         visible: visible,
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

    // Construct objects array: [internalBisectors (0,1), externalBisectors (2,3)]
    final allObjects = [
      ...computation.internalBisectors,
      ...computation.externalBisectors,
    ];
    
    return GeoAngleBisector2L(
      id: id,
      label: label,
      dependencies: [line1.id, line2.id],
      objects: allObjects,
      color: color,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );
  }

  // Enumerators: computed from objects array
  // objects[0,1] = internalBisectors
  List<GeoLine> get internalBisectors => objects.take(_internalCount).toList();

  // elements[2,3] = externalBisectors  
  List<GeoLine> get externalBisectors => elements.skip(_internalCount).take(_externalCount).toList();

  bool get hasBisectors => elements.isNotEmpty;

  @override
  String get type => 'GeoAngleBisector2L';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'internalCount': _internalCount,
      'externalCount': _externalCount,
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
    // Support both 'objects' (backward compatibility) and 'elements' (new format)
    final objectsJson = (json['objects'] as List?) ?? (json['elements'] as List?) ?? const [];
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

    // Construct objects array from decoded lines
    final allObjects = [
      ...internalBisectors,
      ...externalBisectors,
    ];
    
    return GeoAngleBisector2L(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? '',
      dependencies: deps,
      objects: allObjects,
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
    List<GeoLine>? objects,
    List<GeometryObject>? elementsAny,
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

    // Support both objects (backward compatibility) and elementsAny (unified API)
    // If objects provided, use it; otherwise use elementsAny; otherwise construct from separate lists or keep current
    final updatedObjects = objects ?? 
        (elementsAny?.cast<GeoLine>()) ??
        (internalBisectors != null || externalBisectors != null
            ? [
                ...(internalBisectors ?? this.internalBisectors),
                ...(externalBisectors ?? this.externalBisectors),
              ]
            : null);
    
    return GeoAngleBisector2L(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      objects: updatedObjects,
      internalBisectors: internalBisectors,
      externalBisectors: externalBisectors,
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
    
    if (line1Obj is! GeometryObject || line2Obj is! GeometryObject) {
      return null;
    }
    
    final first = line1Obj;
    final second = line2Obj;
    
    // Check if this is a transformed angle bisector list (one dependency is a transform)
    // Transformed angle bisector lists have dependencies [originalAngleBisector.id, transform.id]
    GeoTrans? transform;
    GeometryObject? originalAngleBisector;
    
    if (first is GeoTrans && second is GeoAngleBisector2L) {
      transform = first;
      originalAngleBisector = second;
    } else if (second is GeoTrans && first is GeoAngleBisector2L) {
      transform = second;
      originalAngleBisector = first;
    }
    
    // If this is a transformed angle bisector list, rebuild by transforming the original
    if (transform != null && originalAngleBisector != null) {
      // Get the current state of the original angle bisector from the DAG
      // (it may have been rebuilt already by propagateUpdates)
      final originalNode = dagManager.getNode(originalAngleBisector.id);
      if (originalNode != null) {
        final currentOriginal = originalNode.object;
        if (currentOriginal is GeometryObject) {
          originalAngleBisector = currentOriginal;
        }
      }
      
      // Transform the original angle bisector
      final transformed = TransformationEngine.transform(
        source: originalAngleBisector,
        transform: transform,
        id: id,
        label: label,
        dependencies: dependencies,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      
      if (transformed is GeoAngleBisector2L) {
        return transformed;
      }
      
      // If transformation failed, return null (will cause object to disappear)
      debugPrint('[GeoAngleBisector2L] Failed to transform original angle bisector');
      return null;
    }
    
    if (first is! GeoLine || second is! GeoLine) {
      return null;
    }
    
    final line1 = first as GeoLine;
    final line2 = second as GeoLine;

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

