part of '../geo_shapes_list.dart';

class GeoTriangle extends GeoPolygon {
  GeoTriangle({
    required super.id,
    required super.label,
    required List<GeoPoint> points,
    required DAGManager dagManager,
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
           dagManager,
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
    List<GeometryObject>? elementsAny,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
    List<String>? dependencies,
  }) {
    // Support both List<GeoSegment> and List<GeometryObject> for flexibility
    final elementsToUse = elements ?? (elementsAny?.cast<GeoSegment>());
    // If points are being changed, we need dagManager to regenerate labels
    if (points != null) {
      throw UnimplementedError(
        'GeoTriangle.copyWith cannot change points without DAGManager. Use fromDependencies instead.',
      );
    }

    // Allow element updates if:
    // 1. Same number of elements
    // 2. Same element IDs (only properties like visibility changed)
    // 3. No label regeneration needed
    _PolyChainData<GeoSegment> updatedChain;
    if (elementsToUse != null) {
      if (elementsToUse.length != this.elements.length) {
        throw UnimplementedError(
          'GeoTriangle.copyWith cannot change element count without DAGManager. Use fromDependencies instead.',
        );
      }

      // Verify all element IDs match (only properties changed)
      final elementIdsMatch = elementsToUse.every((newElement) {
        return this.elements.any((oldElement) => oldElement.id == newElement.id);
      });

      if (!elementIdsMatch) {
        throw UnimplementedError(
          'GeoTriangle.copyWith cannot change element IDs without DAGManager. Use fromDependencies instead.',
        );
      }

      // Get vertices from parent (GeoPolygon has uniqueVertices getter)
      final existingVertices = uniqueVertices;
      // Reconstruct normalized points (add first point at end for closed chain)
      final normalizedVertices = List<GeoPoint>.from(existingVertices);
      if (normalizedVertices.isNotEmpty && normalizedVertices.first.id != normalizedVertices.last.id) {
        normalizedVertices.add(normalizedVertices.first);
      }

      // Create new chain with updated elements
      updatedChain = _PolyChainData<GeoSegment>(
        points: List<GeoPoint>.unmodifiable(normalizedVertices),
        elements: List<GeoSegment>.unmodifiable(elementsToUse),
        dependencies: List<String>.unmodifiable(dependencies ?? this.dependencies),
      );
    } else {
      // No element changes - preserve existing elements
      final existingVertices = uniqueVertices;
      final normalizedVertices = List<GeoPoint>.from(existingVertices);
      if (normalizedVertices.isNotEmpty && normalizedVertices.first.id != normalizedVertices.last.id) {
        normalizedVertices.add(normalizedVertices.first);
      }

      updatedChain = _PolyChainData<GeoSegment>(
        points: List<GeoPoint>.unmodifiable(normalizedVertices),
        elements: List<GeoSegment>.unmodifiable(this.elements),
        dependencies: List<String>.unmodifiable(dependencies ?? this.dependencies),
      );
    }

    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoTriangle, style: style)
            : color != null
            ? _shapeStyleOverrides(type: GeoTriangle, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    // Use updated chain
    return GeoTriangle._fromChain(
      id: id ?? this.id,
      label: label ?? this.label,
      chain: updatedChain,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.purple,
      dependencyIds: dependencies ?? this.dependencies,
    );
  }

  // Private constructor that doesn't require dagManager (for copyWith)
  GeoTriangle._fromChain({
    required super.id,
    required super.label,
    required _PolyChainData<GeoSegment> chain,
    super.visible,
    super.style,
    super.styleOverrides,
    super.color = Colors.purple,
    super.dependencyIds,
  }) : super._fromChain(
         chain: chain,
       );

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

    // Note: fromJson doesn't have access to dagManager
    throw UnimplementedError(
      'GeoTriangle.fromJson requires DAGManager. Update decoder to pass dagManager.',
    );
  }
}
