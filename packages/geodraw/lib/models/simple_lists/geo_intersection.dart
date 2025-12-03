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
    
    final point = _pointFromMultivector(
      dagManager: dagManager,
      containerId: id,
      multivector: intersectionMv,
      preferredLabel: label.isNotEmpty ? label : null,
      color: color,
      visible: visible,
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
    
    final point = _pointFromMultivector(
      dagManager: dagManager,
      containerId: id,
      multivector: intersectionMv,
      preferredLabel: label.isNotEmpty ? label : null,
      color: color,
      visible: visible,
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
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing union-object intersection between ${union.label} and ${other.label}',
    // );
    
    final allPoints = <GeoPoint>[];
    
    // Iterate through all elements in the union
    for (final element in union.elements) {
      GeoIntersection? elementIntersection;
      
      // Compute intersection based on element and other object types
      // Note: These nested intersections create temporary containers, but we use the main container ID
      // The elements will be registered in the main container's elementToContainer map
      if (element is GeoLine && other is GeoLine) {
        elementIntersection = GeoIntersection.lineLine(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          line1: element,
          line2: other,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoLine && other is GeoCircle) {
        elementIntersection = GeoIntersection.lineCircle(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          line: element,
          circle: other,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoCircle && other is GeoLine) {
        elementIntersection = GeoIntersection.lineCircle(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          line: other,
          circle: element,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoCircle && other is GeoCircle) {
        elementIntersection = GeoIntersection.circleCircle(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          circle1: element,
          circle2: other,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoLine && other is GeoSegment) {
        elementIntersection = GeoIntersection.lineSegment(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          line: element,
          segment: other,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoSegment && other is GeoLine) {
        elementIntersection = GeoIntersection.lineSegment(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          line: other,
          segment: element,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoLine && other is GeoArc) {
        elementIntersection = GeoIntersection.lineArc(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          line: element,
          arc: other,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoArc && other is GeoLine) {
        elementIntersection = GeoIntersection.lineArc(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          line: other,
          arc: element,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoCircle && other is GeoSegment) {
        elementIntersection = GeoIntersection.circleSegment(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          circle: element,
          segment: other,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoSegment && other is GeoCircle) {
        elementIntersection = GeoIntersection.circleSegment(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          circle: other,
          segment: element,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoCircle && other is GeoArc) {
        elementIntersection = GeoIntersection.circleArc(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          circle: element,
          arc: other,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoArc && other is GeoCircle) {
        elementIntersection = GeoIntersection.circleArc(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          circle: other,
          arc: element,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoSegment && other is GeoSegment) {
        elementIntersection = GeoIntersection.segmentSegment(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          segment1: element,
          segment2: other,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoSegment && other is GeoArc) {
        elementIntersection = GeoIntersection.segmentArc(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          segment: element,
          arc: other,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoArc && other is GeoSegment) {
        elementIntersection = GeoIntersection.segmentArc(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          segment: other,
          arc: element,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      } else if (element is GeoArc && other is GeoArc) {
        elementIntersection = GeoIntersection.arcArc(
          id: '${id}_${element.id}',
          label: '${label}_${element.id}',
          arc1: element,
          arc2: other,
          dagManager: dagManager,
          color: color,
          visible: visible,
        );
      }
      
      // Collect points from this element's intersection
      if (elementIntersection != null && elementIntersection.objects.isNotEmpty) {
        for (final point in elementIntersection.objects) {
          // Check for duplicates before adding
          if (!_containsPoint(allPoints, point.multivector)) {
            allPoints.add(point);
          }
        }
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
  static GeoIntersection unionWithUnion({
    required String id,
    required String label,
    required UnionGeometryObjectList union1,
    required UnionGeometryObjectList union2,
    required DAGManager dagManager,
    Color color = Colors.orange,
    bool visible = true,
  }) {
    // debugPrint(
    //   '[GeoIntersection] Computing union-union intersection between ${union1.label} and ${union2.label}',
    // );
    
    final allPoints = <GeoPoint>[];
    
    // Iterate through all pairs of elements
    for (final element1 in union1.elements) {
      for (final element2 in union2.elements) {
        GeoIntersection? elementIntersection;
        
        // Compute intersection based on element types
        // Note: These nested intersections create temporary containers, but we use the main container ID
        // The elements will be registered in the main container's elementToContainer map
        if (element1 is GeoLine && element2 is GeoLine) {
          elementIntersection = GeoIntersection.lineLine(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            line1: element1,
            line2: element2,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoLine && element2 is GeoCircle) {
          elementIntersection = GeoIntersection.lineCircle(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            line: element1,
            circle: element2,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoCircle && element2 is GeoLine) {
          elementIntersection = GeoIntersection.lineCircle(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            line: element2,
            circle: element1,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoCircle && element2 is GeoCircle) {
          elementIntersection = GeoIntersection.circleCircle(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            circle1: element1,
            circle2: element2,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoLine && element2 is GeoSegment) {
          elementIntersection = GeoIntersection.lineSegment(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            line: element1,
            segment: element2,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoSegment && element2 is GeoLine) {
          elementIntersection = GeoIntersection.lineSegment(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            line: element2,
            segment: element1,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoLine && element2 is GeoArc) {
          elementIntersection = GeoIntersection.lineArc(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            line: element1,
            arc: element2,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoArc && element2 is GeoLine) {
          elementIntersection = GeoIntersection.lineArc(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            line: element2,
            arc: element1,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoCircle && element2 is GeoSegment) {
          elementIntersection = GeoIntersection.circleSegment(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            circle: element1,
            segment: element2,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoSegment && element2 is GeoCircle) {
          elementIntersection = GeoIntersection.circleSegment(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            circle: element2,
            segment: element1,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoCircle && element2 is GeoArc) {
          elementIntersection = GeoIntersection.circleArc(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            circle: element1,
            arc: element2,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoArc && element2 is GeoCircle) {
          elementIntersection = GeoIntersection.circleArc(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            circle: element2,
            arc: element1,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoSegment && element2 is GeoSegment) {
          elementIntersection = GeoIntersection.segmentSegment(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            segment1: element1,
            segment2: element2,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoSegment && element2 is GeoArc) {
          elementIntersection = GeoIntersection.segmentArc(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            segment: element1,
            arc: element2,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoArc && element2 is GeoSegment) {
          elementIntersection = GeoIntersection.segmentArc(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            segment: element2,
            arc: element1,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        } else if (element1 is GeoArc && element2 is GeoArc) {
          elementIntersection = GeoIntersection.arcArc(
            id: '${id}_${element1.id}_${element2.id}',
            label: '${label}_${element1.id}_${element2.id}',
            arc1: element1,
            arc2: element2,
            dagManager: dagManager,
            color: color,
            visible: visible,
          );
        }
        
        // Collect points from this pair's intersection
        if (elementIntersection != null && elementIntersection.objects.isNotEmpty) {
          for (final point in elementIntersection.objects) {
            // Check for duplicates before adding
            if (!_containsPoint(allPoints, point.multivector)) {
              allPoints.add(point);
            }
          }
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
    if (parents.length != 2) {
      debugPrint(
        '[GeoIntersection] Expected 2 parents, received ${parents.length}.',
      );
      return null;
    }

    // Cast dagManager to DAGManager
    if (dagManager is! DAGManager) {
      debugPrint('[GeoIntersection] rebuildFromParents: dagManager is not DAGManager');
      return null;
    }

    final GeometryObject parentA = parents[0];
    final GeometryObject parentB = parents[1];
    final color = style.strokeColor;

    GeoIntersection? rebuilt;

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
      );
    }

    if (rebuilt == null) {
      debugPrint(
        '[GeoIntersection] Unable to rebuild intersection for parents '
        '${parentA.runtimeType} and ${parentB.runtimeType}.',
      );
      return null;
    }

    return GeoIntersection(
      id: id,
      label: label,
      dependencies: [parentA.id, parentB.id],
      objects: rebuilt.objects,
      visible: visible,
      color: color,
      styleOverrides: styleOverrides,
    );
  }
}

const double _intersectionTolerance = 1e-8;

GeoPointer _pointFromMultivector({
  required DAGManager dagManager,
  required String containerId,
  required Multivector multivector,
  String? preferredLabel,
  required Color color,
  required bool visible,
}) {
  // Get unique label from LabelManager (uppercase for points)
  final elementLabel = LabelManager.getNextAvailableLabel(
    dagManager,
    GeometryObjectType.point,
    preferred: preferredLabel,
  );

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
