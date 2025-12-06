part of '../geo_shapes_list.dart';

class _PolyChainData<T extends ComplexGeometryObject> {
  const _PolyChainData({
    required this.points,
    required this.elements,
    required this.dependencies,
  });

  final List<GeoPoint> points;
  final List<T> elements;
  final List<String> dependencies;
}

_PolyChainData<GeoSegment> _prepareOpenChain(
  String ownerId,
  String label,
  List<GeoPoint> input,
  Color color,
  DAGManager dagManager, {
  List<String>? existingElementLabels,
}) {
  if (input.length < 2) {
    throw ArgumentError('PolyLine requires at least two points');
  }

  final normalized = List<GeoPoint>.from(input);
  for (var i = 0; i < normalized.length - 1; i++) {
    if (normalized[i].id == normalized[i + 1].id) {
      throw ArgumentError('Consecutive points must be distinct');
    }
  }

  final segments = <GeoSegment>[];
  // Track labels used in this construction for sequential naming
  final usedLabelsInConstruction = <String>{};
  
  // Find the starting point for sequential labels
  // If we have existing labels, continue from the last one
  // Otherwise, start from 'a'
  String? lastExistingLabel;
  if (existingElementLabels != null && existingElementLabels.isNotEmpty) {
    lastExistingLabel = existingElementLabels.last;
    // Add all existing labels to used set
    usedLabelsInConstruction.addAll(existingElementLabels);
  }
  
  for (var i = 0; i < normalized.length - 1; i++) {
    // Use existing label if provided, otherwise generate sequential label
    final String segmentLabel;
    if (existingElementLabels != null && i < existingElementLabels.length) {
      segmentLabel = existingElementLabels[i];
      // Update lastExistingLabel to track the last label we've seen
      lastExistingLabel = segmentLabel;
    } else {
      // Generate next sequential label after the last label we've seen
      String startLabel;
      if (lastExistingLabel != null) {
        // Continue from last label we've seen (existing or newly generated)
        startLabel = _generateNextSequentialLowercase(lastExistingLabel);
      } else {
        // Start from 'a' if no existing labels
        startLabel = 'a';
      }
      
      // Find the first available label starting from startLabel
      String candidate = startLabel;
      int attempts = 0;
      String foundLabel = startLabel; // Initialize as fallback
      
      // Always check global uniqueness, but when continuing from existing labels,
      // the old container's labels should be unregistered before calling this function
      // so they're available for reuse and sequential naming works naturally
      while (attempts < 1000) {
        // Check if label is not used in this construction AND is globally unique
        if (!usedLabelsInConstruction.contains(candidate) &&
            LabelManager.isLabelUnique(
              dagManager, 
              candidate, 
              excludeContainerId: ownerId,
            )) {
          foundLabel = candidate;
          break;
        }
        // Try next sequential label
        candidate = _generateNextSequentialLowercase(candidate);
        attempts++;
      }
      
      // Fallback if we couldn't find a sequential label
      if (attempts >= 1000) {
        foundLabel = LabelManager.getNextAvailableLabel(
      dagManager,
      GeometryObjectType.line,
          excludeContainerId: ownerId,
        );
      }
      
      segmentLabel = foundLabel;
      // Update lastExistingLabel to track the last label we've seen
      lastExistingLabel = segmentLabel;
    }
    
    usedLabelsInConstruction.add(segmentLabel);
    
    final segment = GeoSegment2P.fromDependencies(
      id: segmentLabel, // In new system: ID = label
      label: segmentLabel,
      points: [normalized[i], normalized[i + 1]],
      color: color,
    );
    
    // Register element in elementToContainer map
    dagManager.registerElement(segmentLabel, ownerId);
    
    segments.add(segment);
  }

  final dependencies = normalized.map((point) => point.id).toSet().toList();

  return _PolyChainData<GeoSegment>(
    points: List<GeoPoint>.unmodifiable(normalized),
    elements: List<GeoSegment>.unmodifiable(segments),
    dependencies: List<String>.unmodifiable(dependencies),
  );
}

_PolyChainData<GeoSegment> _prepareClosedChain(
  String ownerId,
  String label,
  List<GeoPoint> input,
  Color color,
  DAGManager dagManager, {
  List<String>? existingElementLabels,
}) {
  if (input.length < 3) {
    throw ArgumentError('Polygon requires at least three points');
  }

  final normalized = List<GeoPoint>.from(input);
  if (normalized.first.id != normalized.last.id) {
    normalized.add(normalized.first);
  }

  final uniqueIds = normalized.map((point) => point.id).toSet();
  if (uniqueIds.length < 3) {
    throw ArgumentError('Polygon requires three unique vertices');
  }

  for (var i = 0; i < normalized.length - 1; i++) {
    if (normalized[i].id == normalized[i + 1].id) {
      throw ArgumentError('Consecutive points must be distinct');
    }
  }

  final segments = <GeoSegment>[];
  // Track labels used in this construction for sequential naming
  final usedLabelsInConstruction = <String>{};
  
  // Find the starting point for sequential labels
  // If we have existing labels, continue from the last one
  // Otherwise, start from 'a'
  String? lastExistingLabel;
  if (existingElementLabels != null && existingElementLabels.isNotEmpty) {
    lastExistingLabel = existingElementLabels.last;
    // Add all existing labels to used set
    usedLabelsInConstruction.addAll(existingElementLabels);
  }
  
  for (var i = 0; i < normalized.length - 1; i++) {
    // Use existing label if provided, otherwise generate sequential label
    final String segmentLabel;
    if (existingElementLabels != null && i < existingElementLabels.length) {
      segmentLabel = existingElementLabels[i];
      // Update lastExistingLabel to track the last label we've seen
      lastExistingLabel = segmentLabel;
    } else {
      // Generate next sequential label after the last label we've seen
      String startLabel;
      if (lastExistingLabel != null) {
        // Continue from last label we've seen (existing or newly generated)
        startLabel = _generateNextSequentialLowercase(lastExistingLabel);
      } else {
        // Start from 'a' if no existing labels
        startLabel = 'a';
      }
      
      // Find the first available label starting from startLabel
      String candidate = startLabel;
      int attempts = 0;
      String foundLabel = startLabel; // Initialize as fallback
      
      // Always check global uniqueness, but when continuing from existing labels,
      // the old container's labels should be unregistered before calling this function
      // so they're available for reuse and sequential naming works naturally
      while (attempts < 1000) {
        // Check if label is not used in this construction AND is globally unique
        if (!usedLabelsInConstruction.contains(candidate) &&
            LabelManager.isLabelUnique(
              dagManager, 
              candidate, 
              excludeContainerId: ownerId,
            )) {
          foundLabel = candidate;
          break;
        }
        // Try next sequential label
        candidate = _generateNextSequentialLowercase(candidate);
        attempts++;
      }
      
      // Fallback if we couldn't find a sequential label
      if (attempts >= 1000) {
        foundLabel = LabelManager.getNextAvailableLabel(
      dagManager,
      GeometryObjectType.line,
          excludeContainerId: ownerId,
        );
      }
      
      segmentLabel = foundLabel;
      // Update lastExistingLabel to track the last label we've seen
      lastExistingLabel = segmentLabel;
    }
    
    usedLabelsInConstruction.add(segmentLabel);
    
    final segment = GeoSegment2P.fromDependencies(
      id: segmentLabel, // In new system: ID = label
      label: segmentLabel,
      points: [normalized[i], normalized[i + 1]],
      color: color,
    );
    
    // Register element in elementToContainer map
    dagManager.registerElement(segmentLabel, ownerId);
    
    segments.add(segment);
  }

  final dependencies = normalized
      .sublist(0, normalized.length - 1)
      .map((point) => point.id)
      .toSet()
      .toList();

  return _PolyChainData<GeoSegment>(
    points: List<GeoPoint>.unmodifiable(normalized),
    elements: List<GeoSegment>.unmodifiable(segments),
    dependencies: List<String>.unmodifiable(dependencies),
  );
}

List<GeoPoint> _regularVerticesFromCenter({
  required String id,
  required String label,
  required GeoPoint center,
  required GeoPoint reference,
  required int sides,
  required DAGManager dagManager,
}) {
  if (sides < 3) {
    throw ArgumentError('Regular polygon requires at least three sides');
  }

  // Track labels used in this operation to prevent duplicates
  final usedLabels = <String>{};

  final centerPos = center.position;
  final refPos = reference.position;
  final radiusVector = refPos - centerPos;
  final radius = radiusVector.distance;
  if (radius == 0) {
    throw ArgumentError('Center and reference point must be distinct');
  }

  final angleStep = 2 * math.pi / sides;
  final startAngle = math.atan2(radiusVector.dy, radiusVector.dx);

  final vertices = <GeoPoint>[];
  for (var i = 0; i < sides; i++) {
    final angle = startAngle + i * angleStep;
    final x = centerPos.dx + radius * math.cos(angle);
    final y = centerPos.dy + radius * math.sin(angle);
    if (i == 0) {
      vertices.add(reference);
    } else {
      vertices.add(_computedVertex(id, label, i, x, y, dagManager, usedLabels));
    }
  }
  vertices.add(vertices.first);
  return List<GeoPoint>.unmodifiable(vertices);
}

List<GeoPoint> _regularVerticesFromSegment({
  required String id,
  required String label,
  required GeoSegment2P segment,
  required int sides,
  required DAGManager dagManager,
}) {
  if (sides < 3) {
    throw ArgumentError('Regular polygon requires at least three sides');
  }

  // Track labels used in this operation to prevent duplicates
  final usedLabels = <String>{};

  final start = segment.startPoint;
  final end = segment.endPoint;
  final startPos = start.position;
  final endPos = end.position;
  final edgeVector = endPos - startPos;
  final edgeLength = edgeVector.distance;
  if (edgeLength == 0) {
    throw ArgumentError('Base segment must have distinct endpoints');
  }

  final angleStep = 2 * math.pi / sides;
  final radius = edgeLength / (2 * math.sin(angleStep / 2));
  final midpoint = Offset(
    (startPos.dx + endPos.dx) / 2,
    (startPos.dy + endPos.dy) / 2,
  );
  final heightSquared = radius * radius - math.pow(edgeLength / 2, 2).toDouble();
  final height = heightSquared <= 0 ? 0.0 : math.sqrt(heightSquared);

  final normal = Offset(-edgeVector.dy, edgeVector.dx);
  final normalLength = normal.distance;
  if (normalLength == 0) {
    throw ArgumentError('Cannot compute orientation for the provided segment');
  }
  final unitNormal = Offset(normal.dx / normalLength, normal.dy / normalLength);
  final center = Offset(
    midpoint.dx + unitNormal.dx * height,
    midpoint.dy + unitNormal.dy * height,
  );

  final startAngle = math.atan2(startPos.dy - center.dy, startPos.dx - center.dx);

  final vertices = <GeoPoint>[];
  for (var i = 0; i < sides; i++) {
    final angle = startAngle + i * angleStep;
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);
    if (i == 0) {
      vertices.add(start);
    } else if (i == 1) {
      vertices.add(end);
    } else {
      vertices.add(_computedVertex(id, label, i, x, y, dagManager, usedLabels));
    }
  }
  vertices.add(vertices.first);
  return List<GeoPoint>.unmodifiable(vertices);
}

GeoPointer _computedVertex(
  String ownerId,
  String label,
  int index,
  double x,
  double y,
  DAGManager dagManager,
  Set<String>? usedLabels,
) {
  // Use LabelManager to get unique uppercase label for point
  // Track labels used in this operation to prevent duplicates
  final pointLabel = LabelManager.getNextAvailableLabel(
    dagManager,
    GeometryObjectType.point,
    usedReservedLabels: usedLabels,
  );
  
  // Track this label as used
  usedLabels?.add(pointLabel);
  
  return GeoPointer(
    id: pointLabel, // In new system: ID = label
    label: pointLabel,
    x: x,
    y: y,
  );
}

double _shoelaceArea(List<GeoPoint> vertices) {
  if (vertices.length < 4) {
    return 0.0;
  }

  var sum = 0.0;
  for (var i = 0; i < vertices.length - 1; i++) {
    final current = vertices[i].position;
    final next = vertices[i + 1].position;
    sum += current.dx * next.dy - current.dy * next.dx;
  }
  return sum.abs() / 2.0;
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

/// Generate next sequential lowercase label (a -> b -> c -> ... -> z -> aa -> ab -> ...)
String _generateNextSequentialLowercase(String current) {
  if (current.isEmpty) return 'a';

  // Single letter: a -> b, z -> aa
  if (current.length == 1) {
    final code = current.codeUnitAt(0);
    if (code >= 97 && code < 122) {
      // a-y -> b-z
      return String.fromCharCode(code + 1);
    } else if (code == 122) {
      // z -> aa
      return 'aa';
    }
  }

  // Multi-letter: increment last character, carry over if needed
  final chars = current.split('');
  int i = chars.length - 1;
  while (i >= 0) {
    final code = chars[i].codeUnitAt(0);
    if (code >= 97 && code < 122) {
      chars[i] = String.fromCharCode(code + 1);
      return chars.join();
    } else if (code == 122) {
      chars[i] = 'a';
      i--;
      if (i < 0) {
        // All z's, add another a at front
        return 'a${chars.join()}';
      }
    } else {
      break;
    }
  }

  // Fallback: just return next available
  return 'aa';
}
