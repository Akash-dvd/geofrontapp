part of '../geo_shapes_list.dart';

class GeoTriangle extends GeoPolygon {
  GeoTriangle({
    required super.id,
    required super.label,
    required List<GeoPoint> points,
    super.visible,
    super.style,
    super.styleOverrides,
    super.color = Colors.purple,
    List<String>? dependencies,
  }) : super._fromChain(
         chain: _prepareClosedChain(
           id,
           label,
           _validateTriangle(points),
           color,
         ),
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
            ? _shapeStyleOverrides(type: GeoTriangle, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    final nextPoints =
        points ??
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

  static GeoTriangle fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
  ) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final orderedIds =
        (props['pointOrder'] as List?)?.cast<String>() ??
        (json['dependencies'] as List?)?.cast<String>() ??
        const <String>[];

    if (orderedIds.length < 3) {
      throw FormatException('GeoTriangle requires three point references');
    }

    final points = orderedIds.map(resolvePoint).toList(growable: false);
    final overrides = GeometryObject.extractStyleOverrides(json);

    return GeoTriangle(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      points: points,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: overrides,
      color: Colors.purple,
      dependencies: (json['dependencies'] as List?)?.cast<String>(),
    );
  }
}
