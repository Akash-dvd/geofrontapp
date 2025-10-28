part of geo_shapes_list;

class GeoPolyArcGon<T extends ComplexGeometryObject>
    extends GeoPolyArcBase<T> {
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
                ? _shapeStyleOverrides(
                    type: GeoPolyArcGon,
                    fallbackColor: color,
                  )
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
}
