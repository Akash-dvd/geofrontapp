part of '../geo_shapes_list.dart';

abstract class GeoRegularPolygon extends GeoPolygon {
  GeoRegularPolygon._({
    required super.id,
    required super.label,
    required List<GeoPoint> vertices,
    required this.sides,
    required List<String> dependencies,
    required DAGManager dagManager,
    super.visible,
    super.style,
    super.styleOverrides,
    super.color,
  }) : super._fromChain(
         chain: _prepareClosedChain(id, label, vertices, color, dagManager),
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
    required DAGManager dagManager,
  }) => _regularVerticesFromCenter(
    id: id,
    label: label,
    center: center,
    reference: reference,
    sides: sides,
    dagManager: dagManager,
  );

  static List<GeoPoint> verticesFromSegment({
    required String id,
    required String label,
    required GeoSegment2P segment,
    required int sides,
    required DAGManager dagManager,
  }) => _regularVerticesFromSegment(
    id: id,
    label: label,
    segment: segment,
    sides: sides,
    dagManager: dagManager,
  );
}

class GeoRegularPolygon2P extends GeoRegularPolygon {
  GeoRegularPolygon2P({
    required super.id,
    required super.label,
    required GeoPoint center,
    required GeoPoint reference,
    required super.sides,
    required DAGManager dagManager,
    super.visible,
    super.style,
    super.styleOverrides,
    super.color = Colors.deepPurple,
  }) : super._(
         vertices: GeoRegularPolygon.verticesFromCenter(
           id: id,
           label: label,
           center: center,
           reference: reference,
           sides: sides,
           dagManager: dagManager,
         ),
         dependencies: [center.id, reference.id],
         dagManager: dagManager,
       );

  static GeoRegularPolygon2P fromDependencies({
    required String id,
    required String label,
    required GeoPoint center,
    required GeoPoint reference,
    required int sides,
    required DAGManager dagManager,
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
    dagManager: dagManager,
    visible: visible,
    style: style,
    styleOverrides: styleOverrides,
    color: color,
  );

  @override
  String get type => 'regularPolygonCenter';

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager || dependencies.length < 2) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final centerObj = dagManager.getObject(dependencies[0]);
    final referenceObj = dagManager.getObject(dependencies[1]);
    
    if (centerObj is! GeoPoint || referenceObj is! GeoPoint) {
      return null;
    }

    return GeoRegularPolygon2P.fromDependencies(
      id: id,
      label: label,
      center: centerObj,
      reference: referenceObj,
      sides: sides,
      dagManager: dagManager,
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

    // Note: fromJson doesn't have access to dagManager
    throw UnimplementedError(
      'GeoRegularPolygon2P.fromJson requires DAGManager. Update decoder to pass dagManager.',
    );
  }
}

class GeoRegularPolygonSegment extends GeoRegularPolygon {
  GeoRegularPolygonSegment({
    required super.id,
    required super.label,
    required GeoSegment2P baseSegment,
    required super.sides,
    required DAGManager dagManager,
    super.visible,
    super.style,
    super.styleOverrides,
    super.color = Colors.deepPurple,
  }) : super._(
         vertices: GeoRegularPolygon.verticesFromSegment(
           id: id,
           label: label,
           segment: baseSegment,
           sides: sides,
           dagManager: dagManager,
         ),
         dependencies: _segmentDependencies(baseSegment),
         dagManager: dagManager,
       );

  static GeoRegularPolygonSegment fromDependencies({
    required String id,
    required String label,
    required GeoSegment2P baseSegment,
    required int sides,
    required DAGManager dagManager,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.deepPurple,
  }) => GeoRegularPolygonSegment(
    id: id,
    label: label,
    baseSegment: baseSegment,
    sides: sides,
    dagManager: dagManager,
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
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager || dependencies.isEmpty) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final baseSegmentObj = dagManager.getObject(baseSegmentId);
    if (baseSegmentObj is! GeoSegment2P) {
      return null;
    }

    return GeoRegularPolygonSegment.fromDependencies(
      id: id,
      label: label,
      baseSegment: baseSegmentObj,
      sides: sides,
      dagManager: dagManager,
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

    // Note: fromJson doesn't have access to dagManager
    throw UnimplementedError(
      'GeoRegularPolygonSegment.fromJson requires DAGManager. Update decoder to pass dagManager.',
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
