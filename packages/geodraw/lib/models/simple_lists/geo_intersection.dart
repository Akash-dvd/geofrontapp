import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../simple/geo_point.dart';
import '../simple/geo_line.dart';
import '../simple/geo_circle.dart';
import '../simple/geo_transformed_simple.dart';
import '../complex/geo_shapes.dart';
import '../complex/complex_geometry_object.dart';
import 'simple_list_utils.dart';
import '../../core/dag/dag_manager.dart';
import '../../core/label_manager.dart';

/// List of intersection points between two objects
class GeoIntersection extends GenSimpleGeometryObjectList<GeoPoint> {
  GeoIntersection({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.objects,
    Color color = Colors.orange,
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) : assert(
         dependencies.length == 2,
         'Intersection requires exactly 2 object dependencies',
       ),
       super(
         styleOverrides: styleOverridesForType(
           type: GeoIntersection,
           style: style,
           overrides: styleOverrides,
           fallbackColor: color,
         ),
       );

  @override
  String get type => 'GeoIntersection';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'count': objects.length};
    return json;
  }

  static GeoIntersection fromJson(
    Map<String, dynamic> json, {
    DAGManager? dagManager,
  }) {
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    final objectsJson = (json['objects'] as List?) ?? const [];
    final points = <GeoPoint>[];

    // Migration: Detect pattern IDs (e.g., intersection_6_0) and convert to display labels
    final containerId = json['id'] as String;
    final needsMigration = _hasPatternIds(objectsJson);

    for (var i = 0; i < objectsJson.length; i++) {
      final entry = objectsJson[i];
      final map = castJsonObject(entry);
      if (map == null) {
        continue;
      }
      
      var point = _decodePoint(map);
      if (point != null) {
        // Migration: If point has pattern ID, convert to display label
        if (needsMigration && dagManager != null) {
          final oldId = point.id;
          if (_isPatternId(oldId)) {
            // Generate new unique label
            final newLabel = LabelManager.getNextAvailableLabel(
              dagManager,
              GeometryObjectType.point,
            );
            // Create point with new ID (copyWith returns GeometryObject, cast to GeoPoint)
            final updatedPoint = point.copyWith(id: newLabel, label: newLabel);
            if (updatedPoint is GeoPoint) {
              point = updatedPoint;
              // Register in elementToContainer map
              dagManager.registerElement(newLabel, containerId);
            }
          }
        }
        points.add(point);
      }
    }

    final defaults = CanvasStyleDefaults.instance.resolveForType(
      GeoIntersection,
    );
    final overrides = styleOverridesFromJson(json);

    // Migration: Convert container ID if it's a pattern ID
    String finalContainerId = containerId;
    String finalLabel = (json['label'] as String?) ?? '';
    if (_isContainerPatternId(containerId) && dagManager != null) {
      finalContainerId = LabelManager.getNextAvailableLabel(
        dagManager,
        GeometryObjectType.simpleList,
      );
      finalLabel = finalContainerId;
    }

    return GeoIntersection(
      id: finalContainerId,
      label: finalLabel,
      dependencies: deps,
      objects: points,
      visible: json['visible'] as bool? ?? true,
      color: defaults.strokeColor,
      styleOverrides: overrides,
    );
  }

  /// Check if any objects have pattern IDs (for migration detection)
  static bool _hasPatternIds(List<dynamic> objectsJson) {
    for (final entry in objectsJson) {
      final map = castJsonObject(entry);
      if (map == null) continue;
      final id = map['id'] as String?;
      if (id != null && _isPatternId(id)) {
        return true;
      }
    }
    return false;
  }

  /// Check if an ID is a pattern ID (e.g., intersection_6_0)
  static bool _isPatternId(String id) {
    // Pattern: intersection_<number>_<number> or similar
    return RegExp(r'^intersection_\d+_\d+$').hasMatch(id) ||
           RegExp(r'^.*_\d+_\d+$').hasMatch(id);
  }

  /// Check if container ID is a pattern ID (e.g., intersection_6)
  static bool _isContainerPatternId(String id) {
    // Pattern: intersection_<number> or similar
    return RegExp(r'^intersection_\d+$').hasMatch(id) ||
           RegExp(r'^.*_\d+$').hasMatch(id);
  }

  /// Calculate intersection between line and line using multivector algebra.
  static GeoIntersection? lineLine({
    required String id,
    required String label,
    required GeoLine line1,
    required GeoLine line2,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing line-line intersection between ${line1.label} and ${line2.label}',
    // );
    final wedge = line1.multivector ^ line2.multivector;
    if (wedge.isZero()) {
      debugPrint('[GeoIntersection] Lines are parallel, no intersection.');
      return null;
    }

    final intersectionMv = constructLineLineIntersection(
      line1.multivector,
      line2.multivector,
    );

    // if (!isPointOnLine(intersectionMv, line1.multivector) ||
    //     !isPointOnLine(intersectionMv, line2.multivector)) {
    //   debugPrint('[GeoIntersection] Computed point is not on both lines.');
    //   return null;
    // }

    if (!_isFinitePoint(intersectionMv)) {
      debugPrint('[GeoIntersection] Intersection is at infinity, skipping.');
      return null;
    }

    final point = _pointFromMultivector(
      dagManager: dagManager,
      containerId: id,
      multivector: intersectionMv,
      preferredLabel: label.isNotEmpty ? label : null,
      color: color,
      visible: visible,
      reservedLabels: reservedLabels,
      usedReservedLabels: usedReservedLabels,
    );

    // debugPrint('[GeoIntersection] Line-line intersection created with 1 point.');
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [line1.id, line2.id],
      objects: [point],
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between line and circle using multivector algebra.
  static GeoIntersection lineCircle({
    required String id,
    required String label,
    required GeoLine line,
    required GeoCircle circle,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing line-circle intersection between ${line.label} and ${circle.label}',
    // );
    List<Multivector> intersections;
    try {
      intersections = constructLineCircleIntersection(
        line.multivector,
        circle.multivector,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[GeoIntersection] Error while solving line-circle intersection: $error\n$stackTrace',
      );
      rethrow;
    }

    if (intersections.isEmpty) {
      debugPrint(
        '[GeoIntersection] No intersection points returned from solver for ${line.label} × ${circle.label}.',
      );
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [line.id, circle.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }

    final points = <GeoPoint>[];
    // debugPrint('intersections: $intersections');

    for (final candidate in intersections) {
      // debugPrint('  • Candidate MV: $candidate');
      // final candidateNorm = (candidate | candidate).s;
      // if (candidateNorm.isNaN || candidateNorm.isInfinite || candidateNorm == 0) {
      //   debugPrint('    ↳ candidate has invalid norm ($candidateNorm), skipping.');
      //   continue;
      // }

      // if (!_isFinitePoint(candidate)) {
      //   continue;
      // }
      // if (!isPointOnLine(candidate, line.multivector) ||
      //     !isPointOnCircle(candidate, circle.multivector)) {
      //   continue;
      // }
      // if (_containsPoint(points, candidate)) {
      //   continue;
      // }
      // For multiple intersections, don't use displayLabel suffix
      // LabelManager will assign unique labels automatically
      points.add(
        _pointFromMultivector(
          dagManager: dagManager,
          containerId: id,
          multivector: candidate,
          preferredLabel: intersections.length == 1 && label.isNotEmpty ? label : null,
          color: color,
          visible: visible,
          reservedLabels: reservedLabels,
          usedReservedLabels: usedReservedLabels,
        ),
      );
    }

    // debugPrint(
    //   '[GeoIntersection] Line-circle intersection produced ${points.length} point(s).',
    // );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [line.id, circle.id],
      objects: points,
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between circle and circle using multivector algebra.
  static GeoIntersection circleCircle({
    required String id,
    required String label,
    required GeoCircle circle1,
    required GeoCircle circle2,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing circle-circle intersection between ${circle1.label} and ${circle2.label}',
    // );
    List<Multivector> intersections;
    try {
      intersections = constructCircleCircleIntersection(
        circle1.multivector,
        circle2.multivector,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[GeoIntersection] Error while solving circle-circle intersection: $error\n$stackTrace',
      );
      rethrow;
    }

    if (intersections.isEmpty) {
      debugPrint(
        '[GeoIntersection] Circles ${circle1.label} and ${circle2.label} do not intersect (no real solutions).',
      );
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [circle1.id, circle2.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }

    final points = <GeoPoint>[];

    // debugPrint('intersections: $intersections');

    for (final candidate in intersections) {
      // debugPrint('  • Candidate MV: $candidate');
      if (!_isFinitePoint(candidate)) {
        debugPrint('    ↳ discarded (not finite)');
        continue;
      }
      // if (!isPointOnCircle(candidate, circle1.multivector) ||
      //     !isPointOnCircle(candidate, circle2.multivector)) {
      //   debugPrint('    ↳ discarded (not on both circles)');
      //   continue;
      // }
      // if (_containsPoint(points, candidate)) {
      //   debugPrint('    ↳ duplicate point, skipping');
      //   continue;
      // }
      // For multiple intersections, don't use displayLabel suffix
      // LabelManager will assign unique labels automatically
      points.add(
        _pointFromMultivector(
          dagManager: dagManager,
          containerId: id,
          multivector: candidate,
          preferredLabel: intersections.length == 1 && label.isNotEmpty ? label : null,
          color: color,
          visible: visible,
          reservedLabels: reservedLabels,
          usedReservedLabels: usedReservedLabels,
        ),
      );
    }

    debugPrint(
      '[GeoIntersection] Circle-circle intersection produced ${points.length} point(s).',
    );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [circle1.id, circle2.id],
      objects: points,
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between line and segment
  static GeoIntersection lineSegment({
    required String id,
    required String label,
    required GeoLine line,
    required GeoSegment segment,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing line-segment intersection between ${line.label} and ${segment.label}',
    // );
    
    // Use line-line intersection with multivectors directly
    Multivector? intersectionMv;
    try {
      intersectionMv = constructLineLineIntersection(
        line.multivector,
        segment.boundary.multivector,
      );
    } catch (e) {
      debugPrint('[GeoIntersection] Lines are parallel, no intersection.');
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [line.id, segment.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    
    if (!_isFinitePoint(intersectionMv)) {
      debugPrint('[GeoIntersection] Intersection is at infinity, skipping.');
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [line.id, segment.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    
    // Check if point lies on the segment
    if (!isPointOnSegment(intersectionMv, segment.boundary.boundary)) {
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [line.id, segment.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    
    // Create tracking set if not provided (for initial creation to track labels used in this operation)
    final trackingSet = usedReservedLabels ?? <String>{};
    
    final point = _pointFromMultivector(
      dagManager: dagManager,
      containerId: id,
      multivector: intersectionMv,
      preferredLabel: label.isNotEmpty ? label : null,
      color: color,
      visible: visible,
      reservedLabels: reservedLabels,
      usedReservedLabels: trackingSet,
    );
    
    debugPrint(
      '[GeoIntersection] Line-segment intersection produced 1 point.',
    );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [line.id, segment.id],
      objects: [point],
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between line and arc
  static GeoIntersection lineArc({
    required String id,
    required String label,
    required GeoLine line,
    required GeoArc arc,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing line-arc intersection between ${line.label} and ${arc.label}',
    // );
    
    // Use line-circle intersection with multivectors directly
    List<Multivector> intersections;
    try {
      intersections = constructLineCircleIntersection(
        line.multivector,
        arc.boundary.multivector,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[GeoIntersection] Error while solving line-arc intersection: $error\n$stackTrace',
      );
      rethrow;
    }
    
    if (intersections.isEmpty) {
      debugPrint('[GeoIntersection] No intersection found.');
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [line.id, arc.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    // debugPrint('[GeoIntersection] Intersections: ${intersections.length}');
    // Filter points that lie on the arc
    final validPoints = <GeoPoint>[];
    
    for (final candidate in intersections) {
      if (!_isFinitePoint(candidate)) {
        debugPrint('[GeoIntersection] Point is not finite: $candidate');
        continue;
      }
      if (isPointOnArc(candidate, arc.boundary.boundary)) {
        // debugPrint('[GeoIntersection] Point on arc: $candidate');
        // For multiple intersections, don't use displayLabel suffix
        // LabelManager will assign unique labels automatically
        validPoints.add(
          _pointFromMultivector(
            dagManager: dagManager,
            containerId: id,
            multivector: candidate,
            preferredLabel: intersections.length == 1 && label.isNotEmpty ? label : null,
            color: color,
            visible: visible,
            reservedLabels: reservedLabels,
            usedReservedLabels: usedReservedLabels,
          ),
        );
      }
      // else{
      //   debugPrint('[GeoIntersection] Point not on arc: $candidate');
      // }
    }
    
    // debugPrint(
    //   '[GeoIntersection] Line-arc intersection produced ${validPoints.length} point(s).',
    // );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [line.id, arc.id],
      objects: validPoints,
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between circle and segment
  static GeoIntersection circleSegment({
    required String id,
    required String label,
    required GeoCircle circle,
    required GeoSegment segment,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing circle-segment intersection between ${circle.label} and ${segment.label}',
    // );
    
    // Use line-circle intersection with multivectors directly
    List<Multivector> intersections;
    try {
      intersections = constructLineCircleIntersection(
        segment.boundary.multivector,
        circle.multivector,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[GeoIntersection] Error while solving circle-segment intersection: $error\n$stackTrace',
      );
      rethrow;
    }
    
    if (intersections.isEmpty) {
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [circle.id, segment.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    
    // Filter points that lie on the segment
    final validPoints = <GeoPoint>[];
    
    for (final candidate in intersections) {
      if (!_isFinitePoint(candidate)) {
        continue;
      }
      if (isPointOnSegment(candidate, segment.boundary.boundary)) {
        // For multiple intersections, don't use displayLabel suffix
        // LabelManager will assign unique labels automatically
        validPoints.add(
          _pointFromMultivector(
            dagManager: dagManager,
            containerId: id,
            multivector: candidate,
            preferredLabel: intersections.length == 1 && label.isNotEmpty ? label : null,
            color: color,
            visible: visible,
            reservedLabels: reservedLabels,
            usedReservedLabels: usedReservedLabels,
          ),
        );
      }
    }
    
    // debugPrint(
    //   '[GeoIntersection] Circle-segment intersection produced ${validPoints.length} point(s).',
    // );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [circle.id, segment.id],
      objects: validPoints,
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between circle and arc
  static GeoIntersection circleArc({
    required String id,
    required String label,
    required GeoCircle circle,
    required GeoArc arc,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing circle-arc intersection between ${circle.label} and ${arc.label}',
    // );
    
    // Use circle-circle intersection with multivectors directly
    List<Multivector> intersections;
    try {
      intersections = constructCircleCircleIntersection(
        circle.multivector,
        arc.boundary.multivector,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[GeoIntersection] Error while solving circle-arc intersection: $error\n$stackTrace',
      );
      rethrow;
    }
    
    if (intersections.isEmpty) {
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [circle.id, arc.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    
    // Filter points that lie on the arc
    final validPoints = <GeoPoint>[];
    
    for (final candidate in intersections) {
      if (!_isFinitePoint(candidate)) {
        continue;
      }
      if (isPointOnArc(candidate, arc.boundary.boundary)) {
        // For multiple intersections, don't use displayLabel suffix
        // LabelManager will assign unique labels automatically
        validPoints.add(
          _pointFromMultivector(
            dagManager: dagManager,
            containerId: id,
            multivector: candidate,
            preferredLabel: intersections.length == 1 && label.isNotEmpty ? label : null,
            color: color,
            visible: visible,
            reservedLabels: reservedLabels,
            usedReservedLabels: usedReservedLabels,
          ),
        );
      }
    }
    
    // debugPrint(
    //   '[GeoIntersection] Circle-arc intersection produced ${validPoints.length} point(s).',
    // );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [circle.id, arc.id],
      objects: validPoints,
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between two segments
  static GeoIntersection segmentSegment({
    required String id,
    required String label,
    required GeoSegment segment1,
    required GeoSegment segment2,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing segment-segment intersection between ${segment1.label} and ${segment2.label}',
    // );
    
    // Use line-line intersection with multivectors directly
    Multivector? intersectionMv;
    try {
      intersectionMv = constructLineLineIntersection(
        segment1.boundary.multivector,
        segment2.boundary.multivector,
      );
    } catch (e) {
      debugPrint('[GeoIntersection] Segments are parallel, no intersection.');
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [segment1.id, segment2.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    debugPrint('intersectionMv: $intersectionMv');
    if (!_isFinitePoint(intersectionMv)) {
      debugPrint('[GeoIntersection] Intersection is at infinity, skipping.');
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [segment1.id, segment2.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    
    // Check if point lies on both segments
    if (!isPointOnSegment(intersectionMv, segment1.boundary.boundary) ||
        !isPointOnSegment(intersectionMv, segment2.boundary.boundary)) {
      // debugPrint('[GeoIntersection] Intersection is not on both segments, skipping.');
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [segment1.id, segment2.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    
    // Create tracking set if not provided (for initial creation to track labels used in this operation)
    final trackingSet = usedReservedLabels ?? <String>{};
    
    final point = _pointFromMultivector(
      dagManager: dagManager,
      containerId: id,
      multivector: intersectionMv,
      preferredLabel: label.isNotEmpty ? label : null,
      color: color,
      visible: visible,
      reservedLabels: reservedLabels,
      usedReservedLabels: trackingSet,
    );
    
    // debugPrint(
    //   '[GeoIntersection] Segment-segment intersection produced 1 point.',
    // );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [segment1.id, segment2.id],
      objects: [point],
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between segment and arc
  static GeoIntersection segmentArc({
    required String id,
    required String label,
    required GeoSegment segment,
    required GeoArc arc,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing segment-arc intersection between ${segment.label} and ${arc.label}',
    // );
    
    // Use line-circle intersection with multivectors directly
    List<Multivector> intersections;
    try {
      intersections = constructLineCircleIntersection(
        segment.boundary.multivector,
        arc.boundary.multivector,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[GeoIntersection] Error while solving segment-arc intersection: $error\n$stackTrace',
      );
      rethrow;
    }
    
    if (intersections.isEmpty) {
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [segment.id, arc.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    // debugPrint('[GeoIntersection] Intersections: ${intersections.length}');
    // Filter points that lie on both the segment and the arc
    final validPoints = <GeoPoint>[];
    
    for (final candidate in intersections) {
      if (!_isFinitePoint(candidate)) {
        continue;
      }
      if (isPointOnSegment(candidate, segment.boundary.boundary) &&
          isPointOnArc(candidate, arc.boundary.boundary)) {
        // For multiple intersections, don't use displayLabel suffix
        // LabelManager will assign unique labels automatically
        validPoints.add(
          _pointFromMultivector(
            dagManager: dagManager,
            containerId: id,
            multivector: candidate,
            preferredLabel: intersections.length == 1 && label.isNotEmpty ? label : null,
            color: color,
            visible: visible,
            reservedLabels: reservedLabels,
            usedReservedLabels: usedReservedLabels,
          ),
        );
      }else{
        debugPrint('[GeoIntersection] Point not on segment or arc: $candidate');
      }
    }
    
    // debugPrint(
    //   '[GeoIntersection] Segment-arc intersection produced ${validPoints.length} point(s).',
    // );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [segment.id, arc.id],
      objects: validPoints,
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between a union object and another object
  /// Iterates through all elements in the union and finds intersections
  static GeoIntersection unionWithObject({
    required String id,
    required String label,
    required UnionGeometryObjectList union,
    required GeometryObject other,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing union-object intersection between ${union.label} and ${other.label}',
    // );
    
    final allPoints = <GeoPoint>[];
    
    // Create tracking set if not provided (for initial creation to track labels used in this operation)
    final trackingSet = usedReservedLabels ?? <String>{};
    
    // Iterate through all elements in the union
    // Compute intersections directly without creating temporary containers
    for (final element in union.elements) {
      final intersectionMvs = _computeIntersectionMultivectors(element, other);
      
      // Convert multivectors to points and register with main container ID
      for (final mv in intersectionMvs) {
        if (!_isFinitePoint(mv)) continue;
        
        // Check if point is valid for the geometry types (e.g., on segment/arc)
        if (!_isValidIntersectionPoint(mv, element, other)) continue;
        
        // Check for duplicates before adding
        if (_containsPoint(allPoints, mv)) continue;
        
        // Create point directly with main container ID (no temporary containers)
        final point = _pointFromMultivector(
          dagManager: dagManager,
          containerId: id, // Use main container ID directly
          multivector: mv,
          preferredLabel: null, // Let LabelManager assign unique label
          color: color,
          visible: visible,
          reservedLabels: reservedLabels,
          usedReservedLabels: trackingSet, // Use tracking set to track labels used in this operation
        );
        
        allPoints.add(point);
      }
    }
    
    // debugPrint(
    //   '[GeoIntersection] Union-object intersection produced ${allPoints.length} point(s).',
    // );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [union.id, other.id],
      objects: allPoints,
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between two union objects
  /// Iterates through all elements in both unions and finds intersections
  /// Computes intersections directly without creating temporary containers
  /// All label assignment is handled by LabelManager via _pointFromMultivector
  static GeoIntersection unionWithUnion({
    required String id,
    required String label,
    required UnionGeometryObjectList union1,
    required UnionGeometryObjectList union2,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing union-union intersection between ${union1.label} and ${union2.label}',
    // );
    
    final allPoints = <GeoPoint>[];
    
    // Create tracking set if not provided (for initial creation to track labels used in this operation)
    final trackingSet = usedReservedLabels ?? <String>{};
    
    // Iterate through all pairs of elements
    // Compute intersections directly without creating temporary containers
    for (final element1 in union1.elements) {
      for (final element2 in union2.elements) {
        final intersectionMvs = _computeIntersectionMultivectors(element1, element2);
        
        // Convert multivectors to points and register with main container ID
        for (final mv in intersectionMvs) {
          if (!_isFinitePoint(mv)) continue;
          
          // Check if point is valid for the geometry types (e.g., on segment/arc)
          if (!_isValidIntersectionPoint(mv, element1, element2)) continue;
          
          // Check for duplicates before adding
          if (_containsPoint(allPoints, mv)) continue;
          
          // Create point directly with main container ID (no temporary containers)
          final point = _pointFromMultivector(
            dagManager: dagManager,
            containerId: id, // Use main container ID directly
            multivector: mv,
            preferredLabel: null, // Let LabelManager assign unique label
            color: color,
            visible: visible,
            reservedLabels: reservedLabels,
            usedReservedLabels: trackingSet, // Use tracking set to track labels used in this operation
          );
          
          allPoints.add(point);
        }
      }
    }
    
    // debugPrint(
    //   '[GeoIntersection] Union-union intersection produced ${allPoints.length} point(s).',
    // );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [union1.id, union2.id],
      objects: allPoints,
      color: color,
      visible: visible,
    );
  }

  /// Calculate intersection between two arcs
  static GeoIntersection arcArc({
    required String id,
    required String label,
    required GeoArc arc1,
    required GeoArc arc2,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing arc-arc intersection between ${arc1.label} and ${arc2.label}',
    // );
    
    // Use circle-circle intersection with multivectors directly
    List<Multivector> intersections;
    try {
      intersections = constructCircleCircleIntersection(
        arc1.boundary.multivector,
        arc2.boundary.multivector,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[GeoIntersection] Error while solving arc-arc intersection: $error\n$stackTrace',
      );
      rethrow;
    }
    
    if (intersections.isEmpty) {
      return GeoIntersection(
        id: id,
        label: label,
        dependencies: [arc1.id, arc2.id],
        objects: const [],
        color: color,
        visible: visible,
      );
    }
    
    // Filter points that lie on both arcs
    final validPoints = <GeoPoint>[];
    
    for (final candidate in intersections) {
      if (!_isFinitePoint(candidate)) {
        continue;
      }
      if (isPointOnArc(candidate, arc1.boundary.boundary) &&
          isPointOnArc(candidate, arc2.boundary.boundary)) {
        // For multiple intersections, don't use displayLabel suffix
        // LabelManager will assign unique labels automatically
        validPoints.add(
          _pointFromMultivector(
            dagManager: dagManager,
            containerId: id,
            multivector: candidate,
            preferredLabel: intersections.length == 1 && label.isNotEmpty ? label : null,
            color: color,
            visible: visible,
            reservedLabels: reservedLabels,
            usedReservedLabels: usedReservedLabels,
          ),
        );
      }
    }
    
    // debugPrint(
    //   '[GeoIntersection] Arc-arc intersection produced ${validPoints.length} point(s).',
    // );
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [arc1.id, arc2.id],
      objects: validPoints,
      color: color,
      visible: visible,
    );
  }

  @override
  GeoIntersection copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<GeoPoint>? objects,
    Color? color,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? styleOverridesForType(type: GeoIntersection, style: style)
            : color != null
            ? styleOverridesForType(type: GeoIntersection, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;
    return GeoIntersection(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      objects: objects ?? this.objects,
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
      debugPrint(
        '[GeoIntersection] Expected 2 dependencies, received ${dependencies.length}.',
      );
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final parentAObj = dagManager.getObject(dependencies[0]);
    final parentBObj = dagManager.getObject(dependencies[1]);
    
    if (parentAObj is! GeometryObject || parentBObj is! GeometryObject) {
      debugPrint('[GeoIntersection] Failed to resolve dependencies');
      return null;
    }
    
    final GeometryObject parentA = parentAObj;
    final GeometryObject parentB = parentBObj;
    final color = style.strokeColor;

    // STEP 1: Reserve old labels for this rebuild (DON'T unregister yet)
    // This ensures they're only available for THIS container's rebuild, not others
    final oldPointLabels = this.objects.map((p) => p.id).toSet();
    
    // Track which reserved labels have been consumed during rebuild
    // This prevents multiple points from getting the same label
    final usedReservedLabels = <String>{};

    // STEP 2: Rebuild intersection (factory methods will create new points)
    // LabelManager will consume reserved labels as they're used
    // Reserved labels ensure old labels are only reused by THIS container, not others
    GeoIntersection? rebuilt;
    try {
      // Simple × Simple cases
      if (parentA is GeoLine && parentB is GeoLine) {
        rebuilt = GeoIntersection.lineLine(
          id: id,
          label: label,
          line1: parentA,
          line2: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoLine && parentB is GeoCircle) {
        rebuilt = GeoIntersection.lineCircle(
          id: id,
          label: label,
          line: parentA,
          circle: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoCircle && parentB is GeoLine) {
        rebuilt = GeoIntersection.lineCircle(
          id: id,
          label: label,
          line: parentB,
          circle: parentA,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoCircle && parentB is GeoCircle) {
        rebuilt = GeoIntersection.circleCircle(
          id: id,
          label: label,
          circle1: parentA,
          circle2: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      }
      // Simple × Complex cases
      else if (parentA is GeoLine && parentB is GeoSegment) {
        rebuilt = GeoIntersection.lineSegment(
          id: id,
          label: label,
          line: parentA,
          segment: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoSegment && parentB is GeoLine) {
        rebuilt = GeoIntersection.lineSegment(
          id: id,
          label: label,
          line: parentB,
          segment: parentA,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoLine && parentB is GeoArc) {
        rebuilt = GeoIntersection.lineArc(
          id: id,
          label: label,
          line: parentA,
          arc: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoArc && parentB is GeoLine) {
        rebuilt = GeoIntersection.lineArc(
          id: id,
          label: label,
          line: parentB,
          arc: parentA,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoCircle && parentB is GeoSegment) {
        rebuilt = GeoIntersection.circleSegment(
          id: id,
          label: label,
          circle: parentA,
          segment: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoSegment && parentB is GeoCircle) {
        rebuilt = GeoIntersection.circleSegment(
          id: id,
          label: label,
          circle: parentB,
          segment: parentA,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoCircle && parentB is GeoArc) {
        rebuilt = GeoIntersection.circleArc(
          id: id,
          label: label,
          circle: parentA,
          arc: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoArc && parentB is GeoCircle) {
        rebuilt = GeoIntersection.circleArc(
          id: id,
          label: label,
          circle: parentB,
          arc: parentA,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      }
      // Complex × Complex cases
      else if (parentA is GeoSegment && parentB is GeoSegment) {
        rebuilt = GeoIntersection.segmentSegment(
          id: id,
          label: label,
          segment1: parentA,
          segment2: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoSegment && parentB is GeoArc) {
        rebuilt = GeoIntersection.segmentArc(
          id: id,
          label: label,
          segment: parentA,
          arc: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoArc && parentB is GeoSegment) {
        rebuilt = GeoIntersection.segmentArc(
          id: id,
          label: label,
          segment: parentB,
          arc: parentA,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentA is GeoArc && parentB is GeoArc) {
        rebuilt = GeoIntersection.arcArc(
          id: id,
          label: label,
          arc1: parentA,
          arc2: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      }
      // Union × Union case (check this first)
      else if (parentA is UnionGeometryObjectList && parentB is UnionGeometryObjectList) {
        rebuilt = GeoIntersection.unionWithUnion(
          id: id,
          label: label,
          union1: parentA,
          union2: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      }
      // Union × Simple/Complex cases
      else if (parentA is UnionGeometryObjectList) {
        rebuilt = GeoIntersection.unionWithObject(
          id: id,
          label: label,
          union: parentA,
          other: parentB,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      } else if (parentB is UnionGeometryObjectList) {
        rebuilt = GeoIntersection.unionWithObject(
          id: id,
          label: label,
          union: parentB,
          other: parentA,
          dagManager: dagManager,
          color: color,
          visible: visible,
          reservedLabels: oldPointLabels,
          usedReservedLabels: usedReservedLabels,
        );
      }
    } catch (e) {
      // If rebuild fails, restore old labels to prevent label loss
      for (final label in oldPointLabels) {
        if (!dagManager.elementToContainer.containsKey(label)) {
          dagManager.registerElement(label, id);
        }
      }
      rethrow;
    }

    if (rebuilt == null) {
      debugPrint(
        '[GeoIntersection] Unable to rebuild intersection for parents '
        '${parentA.runtimeType} and ${parentB.runtimeType}.',
      );
      // Restore old labels if rebuild returned null
      for (final label in oldPointLabels) {
        if (!dagManager.elementToContainer.containsKey(label)) {
          dagManager.registerElement(label, id);
        }
      }
      return null;
    }

    // STEP 3: Unregister old labels that weren't reused
    // Only unregister labels that are no longer in the new intersection
    final newPointLabels = rebuilt.objects.map((p) => p.id).toSet();
    for (final oldLabel in oldPointLabels) {
      if (!newPointLabels.contains(oldLabel)) {
        // Old label not reused, unregister it (becomes available for future use)
        dagManager.unregisterElement(oldLabel);
      }
    }

    // STEP 4: Factory methods have already registered the new points
    // Labels are preserved for reused points, new labels assigned for new points
    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [parentA.id, parentB.id],
      objects: rebuilt.objects, // Labels preserved via reserved labels mechanism
      visible: visible,
      color: color,
      styleOverrides: styleOverrides,
    );
  }
}

const double _intersectionTolerance = 1e-8;

/// Compute intersection multivectors directly from two geometry objects
/// Returns list of Multivectors representing intersection points
/// Does NOT create temporary containers - just computes the geometry
List<Multivector> _computeIntersectionMultivectors(
  GeometryObject obj1,
  GeometryObject obj2,
) {
  if (obj1 is GeoLine && obj2 is GeoLine) {
    final wedge = obj1.multivector ^ obj2.multivector;
    if (wedge.isZero()) {
      return []; // Parallel lines
    }
    try {
      final mv = constructLineLineIntersection(
        obj1.multivector,
        obj2.multivector,
      );
      return [mv];
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoLine && obj2 is GeoCircle) {
    try {
      return constructLineCircleIntersection(
        obj1.multivector,
        obj2.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoCircle && obj2 is GeoLine) {
    try {
      return constructLineCircleIntersection(
        obj2.multivector,
        obj1.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoCircle && obj2 is GeoCircle) {
    try {
      return constructCircleCircleIntersection(
        obj1.multivector,
        obj2.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoLine && obj2 is GeoSegment) {
    try {
      final mv = constructLineLineIntersection(
        obj1.multivector,
        obj2.boundary.multivector,
      );
      return [mv];
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoSegment && obj2 is GeoLine) {
    try {
      final mv = constructLineLineIntersection(
        obj2.multivector,
        obj1.boundary.multivector,
      );
      return [mv];
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoLine && obj2 is GeoArc) {
    try {
      return constructLineCircleIntersection(
        obj1.multivector,
        obj2.boundary.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoArc && obj2 is GeoLine) {
    try {
      return constructLineCircleIntersection(
        obj2.multivector,
        obj1.boundary.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoCircle && obj2 is GeoSegment) {
    try {
      return constructLineCircleIntersection(
        obj2.boundary.multivector,
        obj1.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoSegment && obj2 is GeoCircle) {
    try {
      return constructLineCircleIntersection(
        obj1.boundary.multivector,
        obj2.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoCircle && obj2 is GeoArc) {
    try {
      return constructCircleCircleIntersection(
        obj1.multivector,
        obj2.boundary.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoArc && obj2 is GeoCircle) {
    try {
      return constructCircleCircleIntersection(
        obj2.multivector,
        obj1.boundary.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoSegment && obj2 is GeoSegment) {
    try {
      final mv = constructLineLineIntersection(
        obj1.boundary.multivector,
        obj2.boundary.multivector,
      );
      return [mv];
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoSegment && obj2 is GeoArc) {
    try {
      return constructLineCircleIntersection(
        obj1.boundary.multivector,
        obj2.boundary.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoArc && obj2 is GeoSegment) {
    try {
      return constructLineCircleIntersection(
        obj2.boundary.multivector,
        obj1.boundary.multivector,
      );
    } catch (_) {
      return [];
    }
  } else if (obj1 is GeoArc && obj2 is GeoArc) {
    try {
      return constructCircleCircleIntersection(
        obj1.boundary.multivector,
        obj2.boundary.multivector,
      );
    } catch (_) {
      return [];
    }
  }
  
  return [];
}

/// Check if an intersection point is valid for the given geometry objects
/// (e.g., point lies on segment/arc boundaries)
bool _isValidIntersectionPoint(
  Multivector mv,
  GeometryObject obj1,
  GeometryObject obj2,
) {
  // For segments, check if point lies on the segment
  if (obj1 is GeoSegment) {
    if (!isPointOnSegment(mv, obj1.boundary.boundary)) {
      return false;
    }
  }
  if (obj2 is GeoSegment) {
    if (!isPointOnSegment(mv, obj2.boundary.boundary)) {
      return false;
    }
  }
  
  // For arcs, check if point lies on the arc
  if (obj1 is GeoArc) {
    if (!isPointOnArc(mv, obj1.boundary.boundary)) {
      return false;
    }
  }
  if (obj2 is GeoArc) {
    if (!isPointOnArc(mv, obj2.boundary.boundary)) {
      return false;
    }
  }
  
  return true;
}

GeoPointer _pointFromMultivector({
  required DAGManager dagManager,
  required String containerId,
  required Multivector multivector,
  String? preferredLabel,
  required Color color,
  required bool visible,
  Set<String>? reservedLabels,
  Set<String>? usedReservedLabels,
}) {
  // Get unique label from LabelManager (uppercase for points)
  // Only exclude container during rebuild (when reservedLabels is provided)
  // During initial creation, we track labels via usedReservedLabels set
  // Reserved labels ensure old labels are only reused by THIS container, not others
  // usedReservedLabels tracks which labels have been consumed in this operation
  final elementLabel = LabelManager.getNextAvailableLabel(
    dagManager,
    GeometryObjectType.point,
    preferred: preferredLabel,
    excludeContainerId: reservedLabels != null ? containerId : null, // Only exclude during rebuild
    reservedLabels: reservedLabels,
    usedReservedLabels: usedReservedLabels,
  );
  
  // Track this label as used (add to set if provided)
  usedReservedLabels?.add(elementLabel);

  // Create point with label as ID
  final point = GeoPointer(
    id: elementLabel,
    label: elementLabel,
    x: multivector.e1,
    y: multivector.e2,
    visible: visible,
    styleOverrides: styleOverridesForType(
      type: GeoPointer,
      fallbackColor: color,
    ),
  );

  // Register element in elementToContainer map
  dagManager.registerElement(elementLabel, containerId);

  return point;
}

bool _isFinitePoint(Multivector multivector) {
  return multivector.e1.isFinite && multivector.e2.isFinite;
}

bool _containsPoint(List<GeoPoint> points, Multivector candidate) {
  for (final point in points) {
    if ((point.x - candidate.e1).abs() <= _intersectionTolerance &&
        (point.y - candidate.e2).abs() <= _intersectionTolerance) {
      return true;
    }
  }
  return false;
}

GeoPoint? _decodePoint(Map<String, dynamic> json) {
  switch (json['type'] as String?) {
    case 'GeoPointer':
      return GeoPointer.fromJson(json);
    case 'GeoMidpoint':
      return GeoMidpoint.fromJson(json);
    case 'GeoInvPoint':
      return GeoTransPoint.fromJson(json);
    case 'GeoTransPoint':
      return GeoTransPoint.fromJson(json);
    default:
      return null;
  }
}
