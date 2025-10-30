part of geo_shapes_list;

class GeoPolygon extends GeoPolyArcGon<GeoSegment> {
  GeoPolygon._fromChain({
    required String id,
    required String label,
    required _PolyChainData<GeoSegment> chain,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.brown,
    List<String>? dependencyIds,
  }) : _chain = chain,
       super(
         id: id,
         label: label,
         dependencies: dependencyIds ?? chain.dependencies,
         elements: chain.elements,
         visible: visible,
         style: style,
         styleOverrides: styleOverrides,
         color: color,
         styleType: GeoPolygon,
       );

  static GeoPolygon fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.brown,
    List<String>? dependencyIds,
  }) {
    if (points.length < 3) {
      throw ArgumentError('GeoPolygon requires at least three unique points');
    }

    final normalized = List<GeoPoint>.from(points);
    if (normalized.first.id != normalized.last.id) {
      normalized.add(normalized.first);
    }

    final uniqueIds = normalized.map((point) => point.id).toSet();
    if (uniqueIds.length < 3) {
      throw ArgumentError('GeoPolygon requires three distinct vertices');
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
          id: '${id}_edge_$i',
          label: '${label}_edge_${i + 1}',
          points: [normalized[i], normalized[i + 1]],
          color: color,
        ),
      );
    }

    final dependenciesList =
        dependencyIds ??
        normalized
            .sublist(0, normalized.length - 1)
            .map((point) => point.id)
            .toList(growable: false);

    final chain = _PolyChainData<GeoSegment>(
      points: List<GeoPoint>.unmodifiable(normalized),
      elements: List<GeoSegment>.unmodifiable(segments),
      dependencies: List<String>.unmodifiable(dependenciesList),
    );

    return GeoPolygon._fromChain(
      id: id,
      label: label,
      chain: chain,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      color: color,
      dependencyIds: dependenciesList,
    );
  }

  factory GeoPolygon({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.brown,
    List<String>? dependencyIds,
  }) => GeoPolygon.fromDependencies(
    id: id,
    label: label,
    points: points,
    visible: visible,
    style: style,
    styleOverrides: styleOverrides,
    color: color,
    dependencyIds: dependencyIds,
  );

  final _PolyChainData<GeoSegment> _chain;

  List<GeoPoint> get vertices => _chain.points;

  List<GeoPoint> get uniqueVertices =>
      _chain.points.sublist(0, _chain.points.length - 1);

  @override
  List<Object?> get props => [...super.props, uniqueVertices];

  @override
  bool allowElement(GeoSegment element) => true;

  @override
  String get type => 'polygon';

  @override
  int get vertexCount => _chain.points.length - 1;

  @override
  double area() => _shoelaceArea(_chain.points);

  bool isConvex() => false;

  bool isClosed() => true;

  @override
  GeoPolygon copyWith({
    String? id,
    String? label,
    List<GeoPoint>? points,
    List<GeoSegment>? elements,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
    List<String>? dependencies,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoPolygon, style: style)
            : color != null
            ? _shapeStyleOverrides(type: GeoPolygon, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    final nextId = id ?? this.id;
    final nextLabel = label ?? this.label;
    final nextColor = color ?? Colors.brown;
    final nextPoints =
        points ??
        (elements != null ? _segmentsToVertices(elements) : uniqueVertices);

    final deps = dependencies ?? this.dependencies;

    return GeoPolygon.fromDependencies(
      id: nextId,
      label: nextLabel,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: nextColor,
      points: nextPoints,
      dependencyIds: deps,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents) {
    if (dependencies.isEmpty) {
      return null;
    }

    final pointMap = <String, GeoPoint>{};
    for (final parent in parents.whereType<GeoPoint>()) {
      pointMap[parent.id] = parent;
    }

    final orderedPoints = <GeoPoint>[];
    for (final depId in dependencies) {
      final point = pointMap[depId];
      if (point == null) {
        return null;
      }
      orderedPoints.add(point);
    }

    if (orderedPoints.length != dependencies.length) {
      return null;
    }

    orderedPoints.add(orderedPoints.first);

    return GeoPolygon.fromDependencies(
      id: id,
      label: label,
      points: orderedPoints,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides.isEmpty ? null : styleOverrides,
      color: style.strokeColor,
      dependencyIds: dependencies,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final props = Map<String, dynamic>.from(
      (json['properties'] as Map<String, dynamic>? ?? const {}),
    );
    props['pointOrder'] = _chain.points
        .map((point) => point.id)
        .toList(growable: false);
    json['properties'] = props;
    return json;
  }

  static GeoPolygon fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
  ) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final orderedIds =
        (props['pointOrder'] as List?)?.cast<String>() ??
        (json['dependencies'] as List?)?.cast<String>() ??
        const <String>[];

    if (orderedIds.length < 3) {
      throw FormatException(
        'GeoPolygon requires at least three point references',
      );
    }

    final points = orderedIds.map(resolvePoint).toList(growable: false);
    final overrides = GeometryObject.extractStyleOverrides(json);
    final dependencyIds = (json['dependencies'] as List?)?.cast<String>();

    return GeoPolygon.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      points: points,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: overrides,
      color: Colors.brown,
      dependencyIds: dependencyIds,
    );
  }
}

List<GeoPoint> _segmentsToVertices(List<GeoSegment> segments) {
  if (segments.isEmpty) {
    return const [];
  }
  final vertices = <GeoPoint>[];
  vertices.add(segments.first.boundary.startPoint);
  for (final segment in segments) {
    vertices.add(segment.boundary.endPoint);
  }
  return vertices;
}
