part of geo_shapes_list;

class GeoPolyArcGon<T extends ComplexGeometryObject> extends GeoPolyArcBase<T> {
  GeoPolyArcGon({
    required super.id,
    required super.label,
    required super.dependencies,
    required List<T> elements,
    required Type styleType,
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.indigo,
  }) : super(
         elements: elements,
         isClosedLoop: true,
         style: style,
         styleOverrides: styleOverrides,
         color: color,
         styleType: styleType,
       );

  @override
  bool allowElement(T element) => true;

  @override
  String get type => 'polyArcGon';

  static GeoPolyArcGon<GeoArc> fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.indigo,
  }) {
    if (points.length < 4) {
      throw ArgumentError('GeoPolyArcGon requires at least four points');
    }

    if (points.first.id != points.last.id) {
      throw ArgumentError(
        'GeoPolyArcGon requires the first and last point to match to form a loop',
      );
    }

    if (!points.length.isOdd) {
      throw ArgumentError(
        'GeoPolyArcGon expects an odd number of points (start + control/end pairs)',
      );
    }

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i].id == points[i + 1].id) {
        throw ArgumentError('Consecutive points must be distinct');
      }
    }

    final arcs = <GeoArc>[];
    for (var i = 0; i <= points.length - 3; i += 2) {
      final triple = <GeoPoint>[points[i], points[i + 1], points[i + 2]];
      final arc = GeoArc3P.fromDependencies(
        id: '${id}_arc_${arcs.length}',
        label: '${label}_arc_${arcs.length + 1}',
        points: triple,
        style: style,
        styleOverrides: styleOverrides,
        color: color,
      );

      if (arc == null) {
        throw ArgumentError(
          'GeoPolyArcGon cannot form an arc from collinear points '
          '${triple.map((p) => p.label).join(', ')}',
        );
      }

      arcs.add(arc);
    }

    if (arcs.isEmpty) {
      throw ArgumentError('GeoPolyArcGon requires at least one arc element');
    }

    final firstStart = arcs.first.boundary.startPoint.id;
    final lastEnd = arcs.last.boundary.endPoint.id;
    if (firstStart != lastEnd) {
      throw ArgumentError(
        'GeoPolyArcGon construction did not close the loop: '
        'start $firstStart does not match end $lastEnd',
      );
    }

    final dependencyIds = points
        .map((point) => point.id)
        .toList(growable: false);

    return GeoPolyArcGon<GeoArc>(
      id: id,
      label: label,
      dependencies: dependencyIds,
      elements: List<GeoArc>.unmodifiable(arcs),
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      color: color,
      styleType: GeoPolyArcGon,
    );
  }

  GeoPolyArcGon<T> copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<T>? elements,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoPolyArcGon, style: style)
            : color != null
            ? _shapeStyleOverrides(type: GeoPolyArcGon, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    return GeoPolyArcGon<T>(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      elements: elements ?? this.elements,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.indigo,
      styleType: GeoPolyArcGon,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents) {
    if (dependencies.isEmpty || elements.isEmpty || elements.first is! GeoArc) {
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

    return GeoPolyArcGon.fromDependencies(
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
    props['pointOrder'] = List<String>.from(dependencies);
    json['properties'] = props;
    return json;
  }

  static GeoPolyArcGon<GeoArc> fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
  ) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final orderedIds =
        (props['pointOrder'] as List?)?.cast<String>() ??
        (json['dependencies'] as List?)?.cast<String>() ??
        const <String>[];

    if (orderedIds.length < 4) {
      throw FormatException(
        'GeoPolyArcGon requires at least four point references',
      );
    }
    final normalizedIds = List<String>.from(orderedIds);
    if (normalizedIds.isNotEmpty && normalizedIds.first != normalizedIds.last) {
      normalizedIds.add(normalizedIds.first);
    }
    if (!normalizedIds.length.isOdd) {
      throw FormatException(
        'GeoPolyArcGon expects an odd number of point references',
      );
    }

    final points = normalizedIds.map(resolvePoint).toList(growable: false);

    final overrides = GeometryObject.extractStyleOverrides(json);

    return GeoPolyArcGon.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      points: points,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: overrides,
      color: Colors.indigo,
    );
  }
}
