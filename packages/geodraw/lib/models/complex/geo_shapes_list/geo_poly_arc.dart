part of geo_shapes_list;

class GeoPolyArc extends GeoPolyArcBase<GeoArc> {
  GeoPolyArc({
    required super.id,
    required super.label,
    required super.dependencies,
    required List<GeoArc> elements,
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.teal,
  }) : super(
          elements: elements,
          isClosedLoop: false,
          style: style,
          styleOverrides: styleOverrides,
          color: color,
          styleType: GeoPolyArc,
        );

  @override
  bool allowElement(GeoArc element) => true;

  @override
  String get type => 'polyArc';

  GeoPolyArc copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<GeoArc>? elements,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoPolyArc, style: style)
            : color != null
                ? _shapeStyleOverrides(
                    type: GeoPolyArc,
                    fallbackColor: color,
                  )
                : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    return GeoPolyArc(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      elements: elements ?? this.elements,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.teal,
    );
  }
}
