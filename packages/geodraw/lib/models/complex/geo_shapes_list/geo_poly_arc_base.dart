part of geo_shapes_list;

abstract class GeoPolyArcBase<T extends ComplexGeometryObject>
    extends UnionComplexObjectList<T> {
  GeoPolyArcBase({
    required super.id,
    required super.label,
    required super.dependencies,
    required List<T> elements,
    required this.isClosedLoop,
    required Type styleType,
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) : super(
          elements: elements,
          styleOverrides: _shapeStyleOverrides(
            type: styleType,
            style: style,
            overrides: styleOverrides,
            fallbackColor: color,
          ),
        ) {
    if (elements.isEmpty) {
      throw ArgumentError(
        '${styleType.toString()} requires at least one element',
      );
    }

    _validateElements(elements);
    _validateContinuity(elements);
  }

  final bool isClosedLoop;

  @protected
  bool allowElement(T element);

  List<GeoPoint> get orderedVertices {
    final result = <GeoPoint>[];
    if (elements.isEmpty) {
      return result;
    }

    result.add(elements.first.boundary.startPoint);
    for (final element in elements) {
      result.add(element.boundary.endPoint);
    }
    return result;
  }

  @override
  int get vertexCount {
    final vertices = orderedVertices;
    if (vertices.isEmpty) {
      return 0;
    }

    if (isClosedLoop && vertices.first.id == vertices.last.id) {
      return vertices.length - 1;
    }
    return vertices.length;
  }

  @override
  double perimeter() =>
      elements.fold(0.0, (sum, element) => sum + element.length());

  @override
  double area() => 0.0;

  void _validateElements(List<T> elements) {
    for (final element in elements) {
      if (!allowElement(element)) {
        throw ArgumentError(
          'Element of type ${element.runtimeType} is not supported in $runtimeType.',
        );
      }
    }
  }

  void _validateContinuity(List<T> elements) {
    for (var i = 0; i < elements.length - 1; i++) {
      final currentEnd = elements[i].boundary.endPoint.id;
      final nextStart = elements[i + 1].boundary.startPoint.id;
      if (currentEnd != nextStart) {
        throw ArgumentError(
          'Elements at indices $i and ${i + 1} do not share a common vertex.',
        );
      }
    }

    if (elements.isEmpty) {
      return;
    }

    final firstStart = elements.first.boundary.startPoint.id;
    final lastEnd = elements.last.boundary.endPoint.id;
    if (isClosedLoop) {
      if (firstStart != lastEnd) {
        throw ArgumentError(
          '$runtimeType requires the loop to close (first and last vertices must match).',
        );
      }
    } else if (firstStart == lastEnd) {
      throw ArgumentError(
        '$runtimeType expects an open chain with distinct endpoints.',
      );
    }
  }
}
