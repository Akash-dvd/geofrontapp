part of geo_shapes_list;

abstract class GeoRegularPolygon extends GeoPolygon {
  GeoRegularPolygon._({
    required String id,
    required String label,
    required List<GeoPoint> vertices,
    required this.sides,
    required List<String> dependencies,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.brown,
  }) : super._fromChain(
          id: id,
          label: label,
          chain: _prepareClosedChain(id, label, vertices, color),
          visible: visible,
          style: style,
          styleOverrides: styleOverrides,
          color: color,
          dependencyIds: dependencies,
        ) {
    if (sides < 3) {
      throw ArgumentError('Regular polygon requires at least three sides');
    }
  }

  final int sides;
}

class GeoRegularPolygon2P extends GeoRegularPolygon {
  GeoRegularPolygon2P({
    required String id,
    required String label,
    required GeoPoint center,
    required GeoPoint reference,
    required int sides,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.deepPurple,
  }) : super._(
          id: id,
          label: label,
          vertices: _regularVerticesFromCenter(
            id: id,
            label: label,
            center: center,
            reference: reference,
            sides: sides,
          ),
          sides: sides,
          dependencies: [center.id, reference.id],
          visible: visible,
          style: style,
          styleOverrides: styleOverrides,
          color: color,
        );

  @override
  String get type => 'regularPolygonCenter';
}

class GeoRegularPolygonSegment extends GeoRegularPolygon {
  GeoRegularPolygonSegment({
    required String id,
    required String label,
    required GeoSegment2P baseSegment,
    required int sides,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.deepPurple,
  }) : super._(
          id: id,
          label: label,
          vertices: _regularVerticesFromSegment(
            id: id,
            label: label,
            segment: baseSegment,
            sides: sides,
          ),
          sides: sides,
          dependencies: List<String>.unmodifiable(
            <String>{baseSegment.id, ...baseSegment.dependencies}.toList(),
          ),
          visible: visible,
          style: style,
          styleOverrides: styleOverrides,
          color: color,
        );

  @override
  String get type => 'regularPolygonSegment';
}
