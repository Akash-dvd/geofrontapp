part of '../geo_shapes_list.dart';

class GeoPolyLine extends GeoPolyArcBase<GeoSegment> {
  GeoPolyLine._fromChain({
    required super.id,
    required super.label,
    required _PolyChainData<GeoSegment> chain,
    super.visible,
    super.style,
    super.styleOverrides,
    Color super.color = Colors.orange,
  }) : _chain = chain,
       super(
         dependencies: chain.dependencies,
         elements: chain.elements,
         styleType: GeoPolyLine,
         isClosedLoop: false,
       );

  static GeoPolyLine fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    required DAGManager dagManager,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.orange,
    List<String>? existingElementLabels,
  }) {
    if (points.length < 2) {
      throw ArgumentError('GeoPolyLine requires at least two points');
    }

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i].id == points[i + 1].id) {
        throw ArgumentError('Consecutive points must be distinct');
      }
    }

    final baseChain = _prepareOpenChain(
      id, 
      label, 
      points, 
      color, 
      dagManager,
      existingElementLabels: existingElementLabels,
    );
    final dependencyIds = List<String>.unmodifiable(
      baseChain.points.map((point) => point.id),
    );

    final chain = _PolyChainData<GeoSegment>(
      points: baseChain.points,
      elements: baseChain.elements,
      dependencies: dependencyIds,
    );

    return GeoPolyLine._fromChain(
      id: id,
      label: label,
      chain: chain,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      color: color,
    );
  }

  factory GeoPolyLine({
    required String id,
    required String label,
    required List<GeoPoint> points,
    required DAGManager dagManager,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.orange,
  }) {
    return GeoPolyLine.fromDependencies(
      id: id,
      label: label,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      color: color,
      points: points,
      dagManager: dagManager,
    );
  }

  final _PolyChainData<GeoSegment> _chain;

  List<GeoPoint> get points => _chain.points;

  @override
  List<Object?> get props => [...super.props, points];

  @override
  bool allowElement(GeoSegment element) => true;

  @override
  String get type => 'polyLine';

  @override
  double area() => 0.0;

  @override
  GeoPolyLine copyWith({
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
        'GeoPolyLine.copyWith cannot change points without DAGManager. Use fromDependencies instead.',
      );
    }

    // Support both List<GeoSegment> and List<GeometryObject> for flexibility
    final elementsToUse = elements ?? (elementsAny?.cast<GeoSegment>());

    // Allow element updates if:
    // 1. Same number of elements
    // 2. Same element IDs (only properties like visibility changed)
    // 3. No label regeneration needed
    _PolyChainData<GeoSegment> updatedChain = _chain;
    if (elementsToUse != null) {
      if (elementsToUse.length != this.elements.length) {
        throw UnimplementedError(
          'GeoPolyLine.copyWith cannot change element count without DAGManager. Use fromDependencies instead.',
        );
      }

      // Verify all element IDs match (only properties changed)
      final elementIdsMatch = elementsToUse.every((newElement) {
        return this.elements.any((oldElement) => oldElement.id == newElement.id);
      });

      if (!elementIdsMatch) {
        throw UnimplementedError(
          'GeoPolyLine.copyWith cannot change element IDs without DAGManager. Use fromDependencies instead.',
        );
      }

      // Safe to update: create new chain with updated elements
      updatedChain = _PolyChainData<GeoSegment>(
        points: _chain.points,
        elements: List<GeoSegment>.unmodifiable(elementsToUse),
        dependencies: _chain.dependencies,
      );
    }

    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoPolyLine, style: style)
            : color != null
            ? _shapeStyleOverrides(type: GeoPolyLine, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    // Use updated chain if elements were changed, otherwise preserve existing chain
    return GeoPolyLine._fromChain(
      id: id ?? this.id,
      label: label ?? this.label,
      chain: updatedChain,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.orange,
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

    // Preserve existing element labels when rebuilding
    final existingElementLabels = elements.map((e) => e.id).toList();

    return GeoPolyLine.fromDependencies(
      id: id,
      label: label,
      points: orderedPoints,
      dagManager: dagManager,
      visible: visible,
      style: style,
      styleOverrides: styleOverrides.isEmpty ? null : styleOverrides,
      color: style.strokeColor,
      existingElementLabels: existingElementLabels,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final props = Map<String, dynamic>.from(
      (json['properties'] as Map<String, dynamic>? ?? const {}),
    );
    props['pointOrder'] = points
        .map((point) => point.id)
        .toList(growable: false);
    json['properties'] = props;
    return json;
  }

  static GeoPolyLine fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
    DAGManager dagManager,
  ) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final orderedIds =
        (props['pointOrder'] as List?)?.cast<String>() ??
        (json['dependencies'] as List?)?.cast<String>() ??
        const <String>[];

    if (orderedIds.length < 2) {
      throw FormatException(
        'GeoPolyLine requires at least two point references',
      );
    }

    final points = orderedIds.map(resolvePoint).toList(growable: false);
    final overrides = GeometryObject.extractStyleOverrides(json);

    return GeoPolyLine.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String,
      points: points,
      dagManager: dagManager,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: overrides,
    );
  }
}
