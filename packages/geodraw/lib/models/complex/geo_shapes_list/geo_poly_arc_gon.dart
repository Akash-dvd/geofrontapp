part of '../geo_shapes_list.dart';

class GeoPolyArcGon<T extends ComplexGeometryObject> extends GeoPolyArcBase<T> {
  GeoPolyArcGon({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.elements,
    required super.styleType,
    super.visible,
    super.style,
    super.styleOverrides,
    Color super.color = Colors.indigo,
  }) : super(
         isClosedLoop: true,
       );

  @override
  bool allowElement(T element) => true;

  @override
  String get type => 'polyArcGon';

  static GeoPolyArcGon<GeoArc> fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    required DAGManager dagManager,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.indigo,
    List<String>? existingElementLabels,
  }) {
    if (points.length < 4) {
      throw ArgumentError('GeoPolyArcGon requires at least four points');
    }

    if (points.first.id != points.last.id) {
      throw ArgumentError(
        'GeoPolyArcGon requires the first and last point to match to form a loop',
      );
    }

    if (!points.length.isOdd) {
      throw ArgumentError(
        'GeoPolyArcGon expects an odd number of points (start + control/end pairs)',
      );
    }

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i].id == points[i + 1].id) {
        throw ArgumentError('Consecutive points must be distinct');
      }
    }

    final arcs = <GeoArc>[];
    int arcIndex = 0;
    // Track labels used in this construction for sequential naming
    final usedLabelsInConstruction = <String>{};
    String? lastExistingLabel;
    if (existingElementLabels != null && existingElementLabels.isNotEmpty) {
      lastExistingLabel = existingElementLabels.last;
      usedLabelsInConstruction.addAll(existingElementLabels);
    }
    
    for (var i = 0; i <= points.length - 3; i += 2) {
      final triple = <GeoPoint>[points[i], points[i + 1], points[i + 2]];
      
      // Use existing label if provided, otherwise generate sequential label
      final String arcLabel;
      if (existingElementLabels != null && arcIndex < existingElementLabels.length) {
        arcLabel = existingElementLabels[arcIndex];
      } else {
        // Generate next sequential label after the last existing label
        String startLabel;
        if (lastExistingLabel != null) {
          startLabel = _generateNextSequentialLowercase(lastExistingLabel);
        } else {
          startLabel = 'a';
        }
        
        // Find the first available label starting from startLabel
        String candidate = startLabel;
        int attempts = 0;
        String foundLabel = startLabel;
        
        while (attempts < 1000) {
          if (!usedLabelsInConstruction.contains(candidate) &&
              LabelManager.isLabelUnique(
                dagManager,
                candidate,
                excludeContainerId: id,
              )) {
            foundLabel = candidate;
            lastExistingLabel = candidate;
            break;
          }
          candidate = _generateNextSequentialLowercase(candidate);
          attempts++;
        }
        
        if (attempts >= 1000) {
          foundLabel = LabelManager.getNextAvailableLabel(
            dagManager,
            GeometryObjectType.arc,
            excludeContainerId: id,
          );
          lastExistingLabel = foundLabel;
        }
        
        arcLabel = foundLabel;
      }
      
      usedLabelsInConstruction.add(arcLabel);
      
      final arc = GeoArc3P.fromDependencies(
        id: arcLabel, // In new system: ID = label
        label: arcLabel,
        points: triple,
        style: style,
        styleOverrides: styleOverrides,
        color: color,
      );

      if (arc == null) {
        throw ArgumentError(
          'GeoPolyArcGon cannot form an arc from collinear points '
          '${triple.map((p) => p.label).join(', ')}',
        );
      }

      // Register element in elementToContainer map
      dagManager.registerElement(arcLabel, id);

      arcs.add(arc);
      arcIndex++;
    }

    if (arcs.isEmpty) {
      throw ArgumentError('GeoPolyArcGon requires at least one arc element');
    }

    final firstStart = arcs.first.boundary.startPoint.id;
    final lastEnd = arcs.last.boundary.endPoint.id;
    if (firstStart != lastEnd) {
      throw ArgumentError(
        'GeoPolyArcGon construction did not close the loop: '
        'start $firstStart does not match end $lastEnd',
      );
    }

    final dependencyIds = points
        .map((point) => point.id)
        .toList(growable: false);

    return GeoPolyArcGon<GeoArc>(
      id: id,
      label: label,
      dependencies: dependencyIds,
      elements: List<GeoArc>.unmodifiable(arcs),
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      color: color,
      styleType: GeoPolyArcGon,
    );
  }

  @override
  GeoPolyArcGon<T> copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    List<T>? elements,
    List<GeometryObject>? elementsAny,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) {
    // Support both List<T> and List<GeometryObject> for flexibility
    // Cast List<GeometryObject> to List<T> since elements are already the correct type
    final elementsToUse = elements ?? (elementsAny?.cast<T>());

    // Validate element updates if provided
    // Allow element updates if:
    // 1. Same number of elements
    // 2. Same element IDs (only properties like visibility changed)
    // 3. No structural changes
    if (elementsToUse != null) {
      if (elementsToUse.length != this.elements.length) {
        throw UnimplementedError(
          'GeoPolyArcGon.copyWith cannot change element count without DAGManager. Use fromDependencies instead.',
        );
      }

      // Verify all element IDs match (only properties changed)
      final elementIdsMatch = elementsToUse.every((newElement) {
        return this.elements.any((oldElement) => oldElement.id == newElement.id);
      });

      if (!elementIdsMatch) {
        throw UnimplementedError(
          'GeoPolyArcGon.copyWith cannot change element IDs without DAGManager. Use fromDependencies instead.',
        );
      }
    }

    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoPolyArcGon, style: style)
            : color != null
            ? _shapeStyleOverrides(type: GeoPolyArcGon, fallbackColor: color)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    return GeoPolyArcGon<T>(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      elements: elementsToUse ?? this.elements,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.indigo,
      styleType: GeoPolyArcGon,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager || dependencies.isEmpty || elements.isEmpty || elements.first is! GeoArc) {
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

    return GeoPolyArcGon.fromDependencies(
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
    props['pointOrder'] = List<String>.from(dependencies);
    json['properties'] = props;
    return json;
  }

  static GeoPolyArcGon<GeoArc> fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
    DAGManager dagManager,
  ) {
    final props = (json['properties'] as Map<String, dynamic>? ?? const {});
    final orderedIds =
        (props['pointOrder'] as List?)?.cast<String>() ??
        (json['dependencies'] as List?)?.cast<String>() ??
        const <String>[];

    if (orderedIds.length < 4) {
      throw FormatException(
        'GeoPolyArcGon requires at least four point references',
      );
    }
    final normalizedIds = List<String>.from(orderedIds);
    if (normalizedIds.isNotEmpty && normalizedIds.first != normalizedIds.last) {
      normalizedIds.add(normalizedIds.first);
    }
    if (!normalizedIds.length.isOdd) {
      throw FormatException(
        'GeoPolyArcGon expects an odd number of point references',
      );
    }

    final points = normalizedIds.map(resolvePoint).toList(growable: false);
    final overrides = GeometryObject.extractStyleOverrides(json);

    return GeoPolyArcGon.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String,
      points: points,
      dagManager: dagManager,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: overrides,
    );
  }
}
