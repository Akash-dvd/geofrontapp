part of geo_shapes_list;

class GeoTriangle extends GeoPolygon {
  GeoTriangle({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.purple,
    List<String>? dependencies,
  }) : super._fromChain(
          id: id,
          label: label,
          chain: _prepareClosedChain(
            id,
            label,
            _validateTriangle(points),
            color,
          ),
          visible: visible,
          style: style,
          styleOverrides: styleOverrides,
          color: color,
          dependencyIds: dependencies,
        );

  static List<GeoPoint> _validateTriangle(List<GeoPoint> points) {
    final unique = <String, GeoPoint>{};
    for (final point in points) {
      unique.putIfAbsent(point.id, () => point);
      if (unique.length == 3) {
        break;
      }
    }

    if (unique.length != 3) {
      throw ArgumentError('GeoTriangle requires exactly three distinct points');
    }
    return unique.values.toList(growable: false);
  }

  @override
  String get type => 'triangle';

  @override
  GeoTriangle copyWith({
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
            ? _shapeStyleOverrides(type: GeoTriangle, style: style)
            : color != null
                ? _shapeStyleOverrides(
                    type: GeoTriangle,
                    fallbackColor: color,
                  )
                : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    final nextPoints = points ??
        (elements != null ? _segmentsToVertices(elements) : uniqueVertices);

    return GeoTriangle(
      id: id ?? this.id,
      label: label ?? this.label,
      points: nextPoints,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.purple,
      dependencies: dependencies ?? this.dependencies,
    );
  }
}
