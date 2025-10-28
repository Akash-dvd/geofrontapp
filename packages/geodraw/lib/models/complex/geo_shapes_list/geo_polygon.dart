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
  })  : _chain = chain,
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

  factory GeoPolygon({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.brown,
    List<String>? dependencyIds,
  }) {
    final chain = _prepareClosedChain(id, label, points, color);
    return GeoPolygon._fromChain(
      id: id,
      label: label,
      chain: chain,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      color: color,
      dependencyIds: dependencyIds,
    );
  }

  final _PolyChainData<GeoSegment> _chain;

  List<GeoPoint> get vertices => _chain.points;

  List<GeoPoint> get uniqueVertices =>
      _chain.points.sublist(0, _chain.points.length - 1);

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
                ? _shapeStyleOverrides(
                    type: GeoPolygon,
                    fallbackColor: color,
                  )
                : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    final nextId = id ?? this.id;
    final nextLabel = label ?? this.label;
    final nextColor = color ?? Colors.brown;
    final nextPoints = points ??
        (elements != null
            ? _segmentsToVertices(elements)
            : uniqueVertices);
    final chain = _prepareClosedChain(nextId, nextLabel, nextPoints, nextColor);

    return GeoPolygon._fromChain(
      id: nextId,
      label: nextLabel,
      chain: chain,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: nextColor,
      dependencyIds: dependencies ?? this.dependencies,
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
