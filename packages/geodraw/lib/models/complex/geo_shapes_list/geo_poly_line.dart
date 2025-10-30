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
  }) : _chain = chain,
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

  static GeoPolyLine fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.orange,
  }) {
    if (points.length < 2) {
      throw ArgumentError('GeoPolyLine requires at least two points');
    }

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i].id == points[i + 1].id) {
        throw ArgumentError('Consecutive points must be distinct');
      }
    }

    final baseChain = _prepareOpenChain(id, label, points, color);
    final dependencyIds = List<String>.unmodifiable(
      baseChain.points.map((point) => point.id),
    );

    final chain = _PolyChainData<GeoSegment>(
      points: baseChain.points,
      elements: baseChain.elements,
      dependencies: dependencyIds,
    );

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

  factory GeoPolyLine({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.orange,
  }) {
    return GeoPolyLine.fromDependencies(
      id: id,
      label: label,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      color: color,
      points: points,
    );
  }

  final _PolyChainData<GeoSegment> _chain;

  List<GeoPoint> get points => _chain.points;

  @override
  List<Object?> get props => [...super.props, points];

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
            ? _shapeStyleOverrides(type: GeoPolyLine, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    final nextId = id ?? this.id;
    final nextLabel = label ?? this.label;
    final nextColor = color ?? Colors.orange;
    final nextPoints = points ?? _chain.points;
    return GeoPolyLine.fromDependencies(
      id: nextId,
      label: nextLabel,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: nextColor,
      points: nextPoints,
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

    return GeoPolyLine.fromDependencies(
      id: id,
      label: label,
      points: orderedPoints,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides.isEmpty ? null : styleOverrides,
      color: style.strokeColor,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final props = Map<String, dynamic>.from(
      (json['properties'] as Map<String, dynamic>? ?? const {}),
    );
    props['pointOrder'] = points
        .map((point) => point.id)
        .toList(growable: false);
    json['properties'] = props;
    return json;
  }

  static GeoPolyLine fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
  ) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final orderedIds =
        (props['pointOrder'] as List?)?.cast<String>() ??
        (json['dependencies'] as List?)?.cast<String>() ??
        const <String>[];

    if (orderedIds.length < 2) {
      throw FormatException(
        'GeoPolyLine requires at least two point references',
      );
    }

    final points = orderedIds.map(resolvePoint).toList(growable: false);
    final overrides = GeometryObject.extractStyleOverrides(json);

    return GeoPolyLine.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      points: points,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: overrides,
      color: Colors.orange,
    );
  }
}
