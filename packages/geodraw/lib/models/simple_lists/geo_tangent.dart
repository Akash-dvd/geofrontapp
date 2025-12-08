import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../simple/geo_point.dart';
import '../simple/geo_line.dart';
import '../simple/geo_circle.dart';
import 'simple_list_utils.dart';
import '../../core/dag/dag_manager.dart';
import '../../core/label_manager.dart';
import '../transforms/geo_trans.dart';
import '../transforms/transformation_engine.dart';

/// List of tangent lines constructed from point/circle inputs.
class GeoTangentList extends GenSimpleGeometryObjectList<GeoLine> {
  // Store counts for enumerator computation
  final int _externalCount;
  final int _internalCount;
  // Store preserved labels to maintain them even when tangents go to 0
  final List<String>? _preservedExternalLabels;
  final List<String>? _preservedInternalLabels;

  GeoTangentList({
    required String id,
    required String label,
    required List<String> dependencies,
    List<GeoLine>? objects,
    List<GeoLine>? externalTangents,
    List<GeoLine>? internalTangents,
    List<String>? preservedExternalLabels,
    List<String>? preservedInternalLabels,
    Color color = Colors.pink,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'GeoTangentList requires exactly 2 object dependencies',
       ),
       // If objects provided, compute counts from array indices
       // objects[0,1] = externalTangents, objects[2,3] = internalTangents
       _externalCount = objects != null
           ? (objects.length >= 2 ? 2 : objects.length)
           : (externalTangents?.length ?? 0),
       _internalCount = objects != null
           ? (objects.length > 2 ? (objects.length >= 4 ? 2 : objects.length - 2) : 0)
           : (internalTangents?.length ?? 0),
       _preservedExternalLabels = preservedExternalLabels,
       _preservedInternalLabels = preservedInternalLabels,
       super(
         id: id,
         label: label,
         dependencies: dependencies,
         objects: objects ?? List<GeoLine>.unmodifiable([
           ...(externalTangents ?? []),
           ...(internalTangents ?? []),
         ]),
         visible: visible,
         styleOverrides: styleOverridesForType(
           type: GeoTangentList,
           style: style,
           overrides: styleOverrides,
           fallbackColor: color,
         ),
       );

  factory GeoTangentList.constructFromObjects({
    required String id,
    required String label,
    required GeometryObject first,
    required GeometryObject second,
    required DAGManager dagManager,
    Color color = Colors.pink,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    if (!_isValidTangentInput(first) || !_isValidTangentInput(second)) {
      throw ArgumentError('Tangent requires point or circle inputs');
    }

    if (first is! GeoCircle && second is! GeoCircle) {
      throw ArgumentError('Tangent requires at least one circle input');
    }

    // Create tracking set if not provided (for initial creation to track labels used in this operation)
    final trackingSet = usedReservedLabels ?? <String>{};

    final computation = _computeTangents(
      dagManager: dagManager,
      containerId: id,
      first: first,
      second: second,
      visible: visible,
      reservedLabels: reservedLabels,
      usedReservedLabels: trackingSet,
    );

    // Preserve labels: if tangents are created, store their labels for future use
    // If tangents are empty but we had reserved labels, preserve those
    final preservedExternalLabels = computation.externalTangents.isNotEmpty
        ? computation.externalTangents.map((e) => e.id).toList()
        : null;
    final preservedInternalLabels = computation.internalTangents.isNotEmpty
        ? computation.internalTangents.map((e) => e.id).toList()
        : null;

    // Construct objects array: [externalTangents (0,1), internalTangents (2,3)]
    final allObjects = [
      ...computation.externalTangents,
      ...computation.internalTangents,
    ];
    
    return GeoTangentList(
      id: id,
      label: label,
      dependencies: [first.id, second.id],
      objects: allObjects,
      preservedExternalLabels: preservedExternalLabels,
      preservedInternalLabels: preservedInternalLabels,
      color: color,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
    );
  }

  // Enumerators: computed from objects array
  // objects[0,1] = externalTangents
  List<GeoLine> get externalTangents => objects.take(_externalCount).toList();

  // elements[2,3] = internalTangents
  List<GeoLine> get internalTangents => elements.skip(_externalCount).take(_internalCount).toList();

  bool get hasTangents => elements.isNotEmpty;

  @override
  String get type => 'GeoTangentList';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'externalCount': _externalCount,
      'internalCount': _internalCount,
      if (_preservedExternalLabels != null)
        'preservedExternalLabels': _preservedExternalLabels,
      if (_preservedInternalLabels != null)
        'preservedInternalLabels': _preservedInternalLabels,
    };
    return json;
  }

  static GeoTangentList fromJson(Map<String, dynamic> json) {
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final properties =
        (json['properties'] as Map<String, dynamic>?) ?? const {};
    final externalCount = (properties['externalCount'] as num?)?.toInt() ?? 0;
    final internalCount = (properties['internalCount'] as num?)?.toInt() ?? 0;
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

    // Construct objects array from decoded lines
    final allObjects = [
      ...lines.take(externalCount),
      ...lines.skip(externalCount).take(internalCount),
    ];

    final defaults = CanvasStyleDefaults.instance.resolveForType(GeoTangentList);
    final overrides = styleOverridesFromJson(json);

    return GeoTangentList(
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
  GeoTangentList copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<GeoLine>? objects,
    List<GeometryObject>? elementsAny,
    List<GeoLine>? externalTangents,
    List<GeoLine>? internalTangents,
    List<String>? preservedExternalLabels,
    List<String>? preservedInternalLabels,
    Color? color,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? styleOverridesForType(type: GeoTangentList, style: style)
            : color != null
            ? styleOverridesForType(type: GeoTangentList, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    // Support both objects (backward compatibility) and elementsAny (unified API)
    // If objects provided, use it; otherwise use elementsAny; otherwise construct from separate lists or keep current
    final updatedObjects = objects ?? 
        (elementsAny?.cast<GeoLine>()) ??
        (externalTangents != null || internalTangents != null
            ? [
                ...(externalTangents ?? this.externalTangents),
                ...(internalTangents ?? this.internalTangents),
              ]
            : null);

    return GeoTangentList(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      objects: updatedObjects,
      externalTangents: externalTangents,
      internalTangents: internalTangents,
      preservedExternalLabels: preservedExternalLabels ?? _preservedExternalLabels,
      preservedInternalLabels: preservedInternalLabels ?? _preservedInternalLabels,
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
    final firstObj = dagManager.getObject(dependencies[0]);
    final secondObj = dagManager.getObject(dependencies[1]);
    
    if (firstObj is! GeometryObject || secondObj is! GeometryObject) {
      return null;
    }
    
    final first = firstObj;
    final second = secondObj;
    
    // Check if this is a transformed tangent list (one dependency is a transform)
    // Transformed tangent lists have dependencies [originalTangentList.id, transform.id]
    GeoTrans? transform;
    GeometryObject? originalTangentList;
    
    if (first is GeoTrans && second is GeoTangentList) {
      transform = first;
      originalTangentList = second;
    } else if (second is GeoTrans && first is GeoTangentList) {
      transform = second;
      originalTangentList = first;
    }
    
    // If this is a transformed tangent list, rebuild by transforming the original
    if (transform != null && originalTangentList != null) {
      // Get the current state of the original tangent list from the DAG
      // (it may have been rebuilt already by propagateUpdates)
      final originalNode = dagManager.getNode(originalTangentList.id);
      if (originalNode != null) {
        final currentOriginal = originalNode.object;
        if (currentOriginal is GeometryObject) {
          originalTangentList = currentOriginal;
        }
      }
      
      // Transform the original tangent list
      final transformed = TransformationEngine.transform(
        source: originalTangentList,
        transform: transform,
        id: id,
        label: label,
        dependencies: dependencies,
        visible: visible,
        styleOverrides: styleOverrides,
      );
      
      if (transformed is GeoTangentList) {
        return transformed;
      }
      
      // If transformation failed, return null (will cause object to disappear)
      debugPrint('[GeoTangentList] Failed to transform original tangent list');
      return null;
    }

    if (!_isValidTangentInput(first) || !_isValidTangentInput(second)) {
      return null;
    }

    // STEP 1: Reserve old labels for this rebuild (DON'T unregister yet)
    // This ensures they're only available for THIS container's rebuild, not others
    // Collect labels from current tangents AND preserved labels (for when tangents went to 0)
    final oldExternalLabels = externalTangents.map((e) => e.id).toSet();
    final oldInternalLabels = internalTangents.map((e) => e.id).toSet();
    if (_preservedExternalLabels != null) {
      oldExternalLabels.addAll(_preservedExternalLabels);
    }
    if (_preservedInternalLabels != null) {
      oldInternalLabels.addAll(_preservedInternalLabels);
    }
    final oldTangentLabels = {...oldExternalLabels, ...oldInternalLabels};
    
    // Track which reserved labels have been consumed during rebuild
    // This prevents multiple tangents from getting the same label
    final usedReservedLabels = <String>{};

    // STEP 2: Rebuild tangents (factory methods will create new tangent lines)
    // LabelManager will consume reserved labels as they're used
    // Reserved labels ensure old labels are only reused by THIS container, not others
    GeoTangentList? rebuilt;
    try {
      rebuilt = GeoTangentList.constructFromObjects(
        id: id,
        label: label,
        first: first,
        second: second,
        dagManager: dagManager,
        visible: visible,
        styleOverrides: styleOverrides,
        reservedLabels: oldTangentLabels,
        usedReservedLabels: usedReservedLabels,
      );
    } catch (e) {
      // If rebuild fails, restore old labels to prevent label loss
      for (final label in oldTangentLabels) {
        if (!dagManager.elementToContainer.containsKey(label)) {
          dagManager.registerElement(label, id);
        }
      }
      return null;
    }

    // STEP 3: Unregister old labels that weren't reused
    // Only unregister labels that are no longer in the new tangents
    final newExternalLabels = rebuilt.externalTangents.map((e) => e.id).toSet();
    final newInternalLabels = rebuilt.internalTangents.map((e) => e.id).toSet();
    final newTangentLabels = {...newExternalLabels, ...newInternalLabels};
    
    for (final oldLabel in oldTangentLabels) {
      if (!newTangentLabels.contains(oldLabel)) {
        // Old label not reused, unregister it (becomes available for future use)
        dagManager.unregisterElement(oldLabel);
      }
    }

    // STEP 4: Factory method has already registered the new tangent lines
    // Labels are preserved for reused tangents, new labels assigned for new tangents
    return rebuilt;
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

bool _isValidTangentInput(GeometryObject object) {
  return object is GeoCircle || object is GeoPoint;
}

_TangentComputation _computeTangents({
  required DAGManager dagManager,
  required String containerId,
  required GeometryObject first,
  required GeometryObject second,
  required bool visible,
  Set<String>? reservedLabels,
  Set<String>? usedReservedLabels,
}) {
  // Compute tangents using constructTangents from geocalc
  final tangentMvs = constructTangents(
    (first as SimpleGeometryObject).multivector,
    (second as SimpleGeometryObject).multivector,
  );

  final externalLines = <GeoLine>[];
  final internalLines = <GeoLine>[];

  // Frugal label usage: preserve labels by position/index
  // When circle size changes, tangents move but keep their labels by position
  // First external tangent keeps first external label, etc.
  
  // For point-circle: all tangents are external
  // For circle-circle: need to determine which are external vs internal
  // For now, we'll classify based on the number of tangents:
  // - 2 tangents from point to circle: both external
  // - 4 tangents between circles: first 2 are external, last 2 are internal
  
  if (first is GeoPoint && second is GeoCircle) {
    // Point to circle: all tangents are external
    for (var i = 0; i < tangentMvs.length; i++) {
      // Use LabelManager with reserved labels to preserve old labels
      // Reserved labels ensure old labels are only reused by THIS container, not others
      // usedReservedLabels tracks which labels have been consumed in this operation
      final label = LabelManager.getNextAvailableLabel(
        dagManager,
        GeometryObjectType.line,
        excludeContainerId: reservedLabels != null ? containerId : null, // Only exclude during rebuild
        reservedLabels: reservedLabels,
        usedReservedLabels: usedReservedLabels,
      );
      
      // Track this label as used (add to set if provided)
      usedReservedLabels?.add(label);
      
      final line = GeoTangentLine.fromDependencies(
        id: label,
        label: label,
        dependencies: [first, second],
        multivector: tangentMvs[i],
        visible: visible,
      );
      
      // Register element in elementToContainer map
      dagManager.registerElement(label, containerId);
      externalLines.add(line);
    }
  } else if (first is GeoCircle && second is GeoPoint) {
    // Circle to point: all tangents are external
    for (var i = 0; i < tangentMvs.length; i++) {
      // Use LabelManager with reserved labels to preserve old labels
      final label = LabelManager.getNextAvailableLabel(
        dagManager,
        GeometryObjectType.line,
        excludeContainerId: reservedLabels != null ? containerId : null,
        reservedLabels: reservedLabels,
        usedReservedLabels: usedReservedLabels,
      );
      
      usedReservedLabels?.add(label);
      
      final line = GeoTangentLine.fromDependencies(
        id: label,
        label: label,
        dependencies: [first, second],
        multivector: tangentMvs[i],
        visible: visible,
      );
      
      dagManager.registerElement(label, containerId);
      externalLines.add(line);
    }
  } else if (first is GeoCircle && second is GeoCircle) {
    // Circle to circle: first 2 are external, rest are internal
    final numExternal = math.min(2, tangentMvs.length);
    
    for (var i = 0; i < numExternal; i++) {
      // Use LabelManager with reserved labels to preserve old labels
      final label = LabelManager.getNextAvailableLabel(
        dagManager,
        GeometryObjectType.line,
        excludeContainerId: reservedLabels != null ? containerId : null,
        reservedLabels: reservedLabels,
        usedReservedLabels: usedReservedLabels,
      );
      
      usedReservedLabels?.add(label);
      
      final line = GeoTangentLine.fromDependencies(
        id: label,
        label: label,
        dependencies: [first, second],
        multivector: tangentMvs[i],
        visible: visible,
      );
      
      dagManager.registerElement(label, containerId);
      externalLines.add(line);
    }
    
    for (var i = numExternal; i < tangentMvs.length; i++) {
      // Use LabelManager with reserved labels to preserve old labels
      final label = LabelManager.getNextAvailableLabel(
        dagManager,
        GeometryObjectType.line,
        excludeContainerId: reservedLabels != null ? containerId : null,
        reservedLabels: reservedLabels,
        usedReservedLabels: usedReservedLabels,
      );
      
      usedReservedLabels?.add(label);
      
      final line = GeoTangentLine.fromDependencies(
        id: label,
        label: label,
        dependencies: [first, second],
        multivector: tangentMvs[i],
        visible: visible,
      );
      
      dagManager.registerElement(label, containerId);
      internalLines.add(line);
    }
  }

  return _TangentComputation(
    externalTangents: externalLines,
    internalTangents: internalLines,
  );
}

class _TangentComputation {
  final List<GeoLine> externalTangents;
  final List<GeoLine> internalTangents;

  const _TangentComputation({
    required this.externalTangents,
    required this.internalTangents,
  });

}
