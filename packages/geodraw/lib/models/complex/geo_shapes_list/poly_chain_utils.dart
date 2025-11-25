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
) {
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
  for (var i = 0; i < normalized.length - 1; i++) {
    segments.add(
      GeoSegment2P.fromDependencies(
        id: '${ownerId}_edge_$i',
        label: '${label}_edge_${i + 1}',
        points: [normalized[i], normalized[i + 1]],
        color: color,
      ),
    );
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
) {
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
  for (var i = 0; i < normalized.length - 1; i++) {
    segments.add(
      GeoSegment2P.fromDependencies(
        id: '${ownerId}_edge_$i',
        label: '${label}_edge_${i + 1}',
        points: [normalized[i], normalized[i + 1]],
        color: color,
      ),
    );
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
}) {
  if (sides < 3) {
    throw ArgumentError('Regular polygon requires at least three sides');
  }

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
      vertices.add(_computedVertex(id, label, i, x, y));
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
}) {
  if (sides < 3) {
    throw ArgumentError('Regular polygon requires at least three sides');
  }

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
      vertices.add(_computedVertex(id, label, i, x, y));
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
) {
  return GeoPointer(
    id: '${ownerId}_v$index',
    label: '${label}_V$index',
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
