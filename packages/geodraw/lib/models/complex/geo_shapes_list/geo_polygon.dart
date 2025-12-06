part of '../geo_shapes_list.dart';

class GeoPolygon extends GeoPolyArcGon<GeoSegment> {
  GeoPolygon._fromChain({
    required super.id,
    required super.label,
    required _PolyChainData<GeoSegment> chain,
    super.visible,
    super.style,
    super.styleOverrides,
    super.color = Colors.brown,
    List<String>? dependencyIds,
  }) : _chain = chain,
       super(
         dependencies: dependencyIds ?? chain.dependencies,
         elements: chain.elements,
         styleType: GeoPolygon,
       );

  static GeoPolygon fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    required DAGManager dagManager,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.brown,
    List<String>? dependencyIds,
    List<String>? existingElementLabels,
  }) {
    if (points.length < 3) {
      throw ArgumentError('GeoPolygon requires at least three unique points');
    }

    final normalized = List<GeoPoint>.from(points);
    if (normalized.first.id != normalized.last.id) {
      normalized.add(normalized.first);
    }

    final uniqueIds = normalized.map((point) => point.id).toSet();
    if (uniqueIds.length < 3) {
      throw ArgumentError('GeoPolygon requires three distinct vertices');
    }

    for (var i = 0; i < normalized.length - 1; i++) {
      if (normalized[i].id == normalized[i + 1].id) {
        throw ArgumentError('Consecutive points must be distinct');
      }
    }

    final dependenciesList =
        dependencyIds ??
        normalized
            .sublist(0, normalized.length - 1)
            .map((point) => point.id)
            .toList(growable: false);

    // Use helper function which now uses LabelManager
    final chain = _prepareClosedChain(
      id, 
      label, 
      normalized, 
      color, 
      dagManager,
      existingElementLabels: existingElementLabels,
    );

    return GeoPolygon._fromChain(
      id: id,
      label: label,
      chain: chain,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      color: color,
      dependencyIds: dependenciesList,
    );
  }

  factory GeoPolygon({
    required String id,
    required String label,
    required List<GeoPoint> points,
    required DAGManager dagManager,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.brown,
    List<String>? dependencyIds,
  }) => GeoPolygon.fromDependencies(
    id: id,
    label: label,
    points: points,
    dagManager: dagManager,
    visible: visible,
    style: style,
    styleOverrides: styleOverrides,
    color: color,
    dependencyIds: dependencyIds,
  );

  final _PolyChainData<GeoSegment> _chain;

  List<GeoPoint> get vertices => _chain.points;

  List<GeoPoint> get uniqueVertices =>
      _chain.points.sublist(0, _chain.points.length - 1);

  @override
  List<Object?> get props => [...super.props, uniqueVertices];

  @override
  bool allowElement(GeoSegment element) => true;

  @override
  String get type => 'polygon';

  @override
  int get vertexCount => _chain.points.length - 1;

  @override
  double area() => _shoelaceArea(_chain.points);

  bool isConvex() => false;

  bool isClosed() => true;

  @override
  GeoPolygon copyWith({
    String? id,
    String? label,
    List<GeoPoint>? points,
    List<GeoSegment>? elements,
    List<GeometryObject>? elementsAny,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
    List<String>? dependencies,
  }) {
    // If points are being changed, we need dagManager to regenerate labels
    if (points != null) {
      throw UnimplementedError(
        'GeoPolygon.copyWith cannot change points without DAGManager. Use fromDependencies instead.',
      );
    }

    // Support both List<GeoSegment> and List<GeometryObject> for flexibility
    // Cast List<GeometryObject> to List<GeoSegment> since elements are already the correct type
    final elementsToUse = elements ?? (elementsAny?.cast<GeoSegment>());

    // Allow element updates if:
    // 1. Same number of elements
    // 2. Same element IDs (only properties like visibility changed)
    // 3. No label regeneration needed
    _PolyChainData<GeoSegment> updatedChain = _chain;
    if (elementsToUse != null) {
      if (elementsToUse.length != this.elements.length) {
        throw UnimplementedError(
          'GeoPolygon.copyWith cannot change element count without DAGManager. Use fromDependencies instead.',
        );
      }

      // Verify all element IDs match (only properties changed)
      final elementIdsMatch = elementsToUse.every((newElement) {
        return this.elements.any((oldElement) => oldElement.id == newElement.id);
      });

      if (!elementIdsMatch) {
        throw UnimplementedError(
          'GeoPolygon.copyWith cannot change element IDs without DAGManager. Use fromDependencies instead.',
        );
      }

      // Safe to update: create new chain with updated elements
      // Elements are already GeoSegment type, just ensure type safety
      updatedChain = _PolyChainData<GeoSegment>(
        points: _chain.points,
        elements: List<GeoSegment>.unmodifiable(elementsToUse),
        dependencies: _chain.dependencies,
      );
    }

    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoPolygon, style: style)
            : color != null
            ? _shapeStyleOverrides(type: GeoPolygon, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    // Use updated chain if elements were changed, otherwise preserve existing chain
    return GeoPolygon._fromChain(
      id: id ?? this.id,
      label: label ?? this.label,
      chain: updatedChain,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.brown,
      dependencyIds: dependencies ?? this.dependencies,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager || dependencies.isEmpty) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final orderedPoints = <GeoPoint>[];
    for (final depId in dependencies) {
      final obj = dagManager.getObject(depId);
      if (obj is! GeoPoint) {
        return null;
      }
      orderedPoints.add(obj);
    }

    orderedPoints.add(orderedPoints.first);

    // Preserve existing element labels when rebuilding
    final existingElementLabels = elements.map((e) => e.id).toList();

    return GeoPolygon.fromDependencies(
      id: id,
      label: label,
      points: orderedPoints,
      dagManager: dagManager,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides.isEmpty ? null : styleOverrides,
      color: style.strokeColor,
      dependencyIds: dependencies,
      existingElementLabels: existingElementLabels,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final props = Map<String, dynamic>.from(
      (json['properties'] as Map<String, dynamic>? ?? const {}),
    );
    props['pointOrder'] = _chain.points
        .map((point) => point.id)
        .toList(growable: false);
    json['properties'] = props;
    return json;
  }

  static GeoPolygon fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
    DAGManager dagManager,
  ) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final orderedIds =
        (props['pointOrder'] as List?)?.cast<String>() ??
        (json['dependencies'] as List?)?.cast<String>() ??
        const <String>[];

    if (orderedIds.length < 3) {
      throw FormatException(
        'GeoPolygon requires at least three point references',
      );
    }

    final points = orderedIds.map(resolvePoint).toList(growable: false);
    final overrides = GeometryObject.extractStyleOverrides(json);
    final dependencyIds = (json['dependencies'] as List?)?.cast<String>();

    return GeoPolygon.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String,
      points: points,
      dagManager: dagManager,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: overrides,
      dependencyIds: dependencyIds,
    );
  }
}

List<GeoPoint> _segmentsToVertices(List<GeoSegment> segments) {
  if (segments.isEmpty) {
    return const [];
  }
  final vertices = <GeoPoint>[];
  vertices.add(segments.first.boundary.startPoint);
  for (final segment in segments) {
    vertices.add(segment.boundary.endPoint);
  }
  return vertices;
}
