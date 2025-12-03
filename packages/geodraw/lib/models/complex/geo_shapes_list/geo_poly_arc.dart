part of '../geo_shapes_list.dart';

class GeoPolyArc extends GeoPolyArcBase<GeoArc> {
  GeoPolyArc({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.elements,
    super.visible,
    super.style,
    super.styleOverrides,
    Color super.color = Colors.teal,
  }) : super(
         isClosedLoop: false,
         styleType: GeoPolyArc,
       );

  @override
  bool allowElement(GeoArc element) => true;

  @override
  String get type => 'polyArc';

  static GeoPolyArc fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.teal,
  }) {
    if (points.length < 3) {
      throw ArgumentError('GeoPolyArc requires at least three points');
    }
    if (points.length.isEven) {
      throw ArgumentError(
        'GeoPolyArc point count must be 3 + 2n; received ${points.length}',
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
          'GeoPolyArc cannot form an arc from collinear points '
          '${triple.map((p) => p.label).join(', ')}',
        );
      }

      arcs.add(arc);
    }

    final dependencyIds = points
        .map((point) => point.id)
        .toList(growable: false);

    return GeoPolyArc(
      id: id,
      label: label,
      dependencies: dependencyIds,
      elements: List<GeoArc>.unmodifiable(arcs),
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      color: color,
    );
  }

  @override
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
            ? _shapeStyleOverrides(type: GeoPolyArc, fallbackColor: color)
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

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dependencies.isEmpty) {
      return null;
    }

    final pointMap = <String, GeoPoint>{};
    for (final parent in parents.whereType<GeoPoint>()) {
      pointMap[parent.id] = parent;
    }

    final orderedPoints = <GeoPoint>[];
    for (final dependencyId in dependencies) {
      final point = pointMap[dependencyId];
      if (point == null) {
        return null;
      }
      orderedPoints.add(point);
    }

    if (orderedPoints.length != dependencies.length) {
      return null;
    }

    return GeoPolyArc.fromDependencies(
      id: id,
      label: label,
      points: orderedPoints,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
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

  static GeoPolyArc fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
  ) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final orderedIds =
        (props['pointOrder'] as List?)?.cast<String>() ??
        (json['dependencies'] as List?)?.cast<String>() ??
        const <String>[];

    if (orderedIds.length < 3 || orderedIds.length.isEven) {
      throw FormatException('GeoPolyArc requires 3 + 2n point references');
    }

    final points = orderedIds.map(resolvePoint).toList(growable: false);
    final overrides = GeometryObject.extractStyleOverrides(json);

    return GeoPolyArc.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      points: points,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: overrides,
      color: Colors.teal,
    );
  }
}
