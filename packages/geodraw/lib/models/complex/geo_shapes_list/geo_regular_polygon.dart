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

  @override
  List<Object?> get props => [...super.props, sides];

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final props = Map<String, dynamic>.from(
      (json['properties'] as Map<String, dynamic>? ?? const {}),
    );
    props['sides'] = sides;
    json['properties'] = props;
    return json;
  }

  static List<GeoPoint> verticesFromCenter({
    required String id,
    required String label,
    required GeoPoint center,
    required GeoPoint reference,
    required int sides,
  }) => _regularVerticesFromCenter(
    id: id,
    label: label,
    center: center,
    reference: reference,
    sides: sides,
  );

  static List<GeoPoint> verticesFromSegment({
    required String id,
    required String label,
    required GeoSegment2P segment,
    required int sides,
  }) => _regularVerticesFromSegment(
    id: id,
    label: label,
    segment: segment,
    sides: sides,
  );
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
         vertices: GeoRegularPolygon.verticesFromCenter(
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

  static GeoRegularPolygon2P fromDependencies({
    required String id,
    required String label,
    required GeoPoint center,
    required GeoPoint reference,
    required int sides,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.deepPurple,
  }) => GeoRegularPolygon2P(
    id: id,
    label: label,
    center: center,
    reference: reference,
    sides: sides,
    visible: visible,
    style: style,
    styleOverrides: styleOverrides,
    color: color,
  );

  @override
  String get type => 'regularPolygonCenter';

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents) {
    if (dependencies.length < 2) {
      return null;
    }

    final pointMap = <String, GeoPoint>{};
    for (final parent in parents.whereType<GeoPoint>()) {
      pointMap[parent.id] = parent;
    }

    final center = pointMap[dependencies[0]];
    final reference = pointMap[dependencies[1]];
    if (center == null || reference == null) {
      return null;
    }

    return GeoRegularPolygon2P.fromDependencies(
      id: id,
      label: label,
      center: center,
      reference: reference,
      sides: sides,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides.isEmpty ? null : styleOverrides,
      color: style.strokeColor,
    );
  }

  static GeoRegularPolygon2P fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
  ) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final sides = (props['sides'] as num?)?.toInt() ?? 0;
    if (sides < 3) {
      throw FormatException(
        'GeoRegularPolygon2P requires at least three sides',
      );
    }

    final dependencies =
        (json['dependencies'] as List?)?.cast<String>() ?? const <String>[];
    if (dependencies.length < 2) {
      throw FormatException(
        'GeoRegularPolygon2P requires center and reference point',
      );
    }

    final center = resolvePoint(dependencies[0]);
    final reference = resolvePoint(dependencies[1]);
    final overrides = GeometryObject.extractStyleOverrides(json);

    return GeoRegularPolygon2P.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      center: center,
      reference: reference,
      sides: sides,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: overrides,
      color: Colors.deepPurple,
    );
  }
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
         vertices: GeoRegularPolygon.verticesFromSegment(
           id: id,
           label: label,
           segment: baseSegment,
           sides: sides,
         ),
         sides: sides,
         dependencies: _segmentDependencies(baseSegment),
         visible: visible,
         style: style,
         styleOverrides: styleOverrides,
         color: color,
       );

  static GeoRegularPolygonSegment fromDependencies({
    required String id,
    required String label,
    required GeoSegment2P baseSegment,
    required int sides,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.deepPurple,
  }) => GeoRegularPolygonSegment(
    id: id,
    label: label,
    baseSegment: baseSegment,
    sides: sides,
    visible: visible,
    style: style,
    styleOverrides: styleOverrides,
    color: color,
  );

  @override
  String get type => 'regularPolygonSegment';

  String get baseSegmentId => dependencies.isEmpty ? '' : dependencies.first;

  @override
  List<Object?> get props => [...super.props, baseSegmentId];

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents) {
    if (dependencies.length < 3) {
      return null;
    }

    GeoSegment2P? baseSegment;
    for (final parent in parents.whereType<GeoSegment2P>()) {
      if (parent.id == baseSegmentId) {
        baseSegment = parent;
        break;
      }
    }

    if (baseSegment == null) {
      return null;
    }

    return GeoRegularPolygonSegment.fromDependencies(
      id: id,
      label: label,
      baseSegment: baseSegment,
      sides: sides,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides.isEmpty ? null : styleOverrides,
      color: style.strokeColor,
    );
  }

  static GeoRegularPolygonSegment fromJson(
    Map<String, dynamic> json,
    GeoSegment2P Function(String id) resolveSegment,
  ) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final sides = (props['sides'] as num?)?.toInt() ?? 0;
    if (sides < 3) {
      throw FormatException(
        'GeoRegularPolygonSegment requires at least three sides',
      );
    }

    final dependencies =
        (json['dependencies'] as List?)?.cast<String>() ?? const <String>[];
    if (dependencies.isEmpty) {
      throw FormatException(
        'GeoRegularPolygonSegment requires base segment dependency',
      );
    }

    final baseSegment = resolveSegment(dependencies.first);
    final overrides = GeometryObject.extractStyleOverrides(json);

    return GeoRegularPolygonSegment.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      baseSegment: baseSegment,
      sides: sides,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: overrides,
      color: Colors.deepPurple,
    );
  }
}

List<String> _segmentDependencies(GeoSegment2P segment) {
  final ordered = <String>[];
  final seen = <String>{};

  void add(String value) {
    if (seen.add(value)) {
      ordered.add(value);
    }
  }

  add(segment.id);
  for (final dep in segment.dependencies) {
    add(dep);
  }

  return List<String>.unmodifiable(ordered);
}
