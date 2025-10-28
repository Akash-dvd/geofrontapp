part of geo_shapes_list;

class GeoPolyLine extends GeoPolyArcBase<GeoSegment> {
  GeoPolyLine._fromChain({
    required String id,
    required String label,
    required _PolyChainData<GeoSegment> chain,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.orange,
  })  : _chain = chain,
        super(
          id: id,
          label: label,
          dependencies: chain.dependencies,
          elements: chain.elements,
          visible: visible,
          style: style,
          styleOverrides: styleOverrides,
          color: color,
          styleType: GeoPolyLine,
          isClosedLoop: false,
        );

  factory GeoPolyLine({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.orange,
  }) {
    final chain = _prepareOpenChain(id, label, points, color);
    return GeoPolyLine._fromChain(
      id: id,
      label: label,
      chain: chain,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      color: color,
    );
  }

  final _PolyChainData<GeoSegment> _chain;

  List<GeoPoint> get points => _chain.points;

  @override
  bool allowElement(GeoSegment element) => true;

  @override
  String get type => 'polyLine';

  @override
  double area() => 0.0;

  GeoPolyLine copyWith({
    String? id,
    String? label,
    List<GeoPoint>? points,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
    List<String>? dependencies,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoPolyLine, style: style)
            : color != null
                ? _shapeStyleOverrides(
                    type: GeoPolyLine,
                    fallbackColor: color,
                  )
                : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    final nextId = id ?? this.id;
    final nextLabel = label ?? this.label;
    final nextColor = color ?? Colors.orange;
    final nextPoints = points ?? _chain.points;
    final chain = _prepareOpenChain(nextId, nextLabel, nextPoints, nextColor);

    return GeoPolyLine._fromChain(
      id: nextId,
      label: nextLabel,
      chain: chain,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: nextColor,
    );
  }
}
