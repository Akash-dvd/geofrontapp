import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../simple/geo_point.dart';
import 'complex_geometry_object.dart';

/// Circular arc between two points following a counter-clockwise sweep
class GeoArc extends ComplexGeometryObject {
  GeoArc({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.boundary,
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.orange,
  }) : super(
         styleOverrides: _shapeStyleOverrides(
           type: GeoArc,
           style: style,
           overrides: styleOverrides,
           fallbackColor: color,
         ),
       );

  static const double _angleEpsilon = 1e-6;
  static const double _twoPi = math.pi * 2;
  static const double _orientationNormalizationTolerance = 1e-9;

  double get _orientationSign {
    final orientation = multivector.o;
    if (orientation == 0) {
      return 1.0;
    }
    return orientation.sign;
  }

  Offset get _center {
    final orientation = multivector.o;
    if (orientation.abs() <= _orientationNormalizationTolerance) {
      return Offset(multivector.e1, multivector.e2);
    }
    return Offset(multivector.e1 / orientation, multivector.e2 / orientation);
  }


  double get _radius => (startPoint.position - _center).distance;

  double get _startAngle => _angleFor(startPoint.position);
  double get _endAngle => _angleFor(endPoint.position);

  double get _counterClockwiseSweepAngle {
    final sweep = _normalizeAngle(_endAngle - _startAngle);
    return sweep <= _angleEpsilon ? _twoPi : sweep;
  }

  double get _clockwiseSweepAngle {
    final sweep = _normalizeAngle(_startAngle - _endAngle);
    return sweep <= _angleEpsilon ? _twoPi : sweep;
  }

  double get _sweepAngle {
    final orientation = _orientationSign;
    if (orientation >= 0) {
      return _counterClockwiseSweepAngle;
    }
    return -_clockwiseSweepAngle;
  }

  double get _sweepMagnitude => _sweepAngle.abs();

  @override
  String get type => 'arc';

  @override
  void draw(Canvas canvas, Paint paint) {
    if (!visible) return;


    final effectiveStyle = style;
    final center = _center;
    final radius = _radius;
    if (radius <= 0) {
      return;
    }

    final arcPaint = Paint()
      ..color = effectiveStyle.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveStyle.strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    // Respect the orientation encoded in the multivector's o component.
    canvas.drawArc(rect, -_startAngle, -_sweepAngle, false, arcPaint);
  }

  @override
  bool contains(Offset position) {
    final center = _center;
    final radius = _radius;
    if (radius <= 0) {
      return false;
    }

    final distanceFromCenter = (position - center).distance;
    final radialDelta = (distanceFromCenter - radius).abs();
    final tolerance = style.strokeWidth + 4.0;
    if (radialDelta > tolerance) {
      return false;
    }

    final angle = _angleFor(position);
    return _isAngleWithinSweep(angle, inclusive: true);
  }

  @override
  Rect getBounds() {
    final center = _center;
    final radius = _radius;
    if (radius <= 0) {
      return Rect.fromCircle(center: center, radius: 0);
    }

    if ((_sweepMagnitude - _twoPi).abs() <= _angleEpsilon) {
      return Rect.fromCircle(center: center, radius: radius);
    }

    final points = <Offset>[startPoint.position, endPoint.position];
    const cardinalAngles = <double>[
      0.0,
      math.pi / 2,
      math.pi,
      3 * math.pi / 2,
    ];

    for (final candidate in cardinalAngles) {
      if (_isAngleWithinSweep(candidate, inclusive: false)) {
        points.add(_pointOnCircle(candidate));
      }
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;

    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
    }

    final strokePadding = style.strokeWidth;
    return Rect.fromLTRB(
      minX - strokePadding,
      minY - strokePadding,
      maxX + strokePadding,
      maxY + strokePadding,
    );
  }

  @override
  double distanceTo(Offset point) {
    final center = _center;
    final radius = _radius;
    if (radius <= 0) {
      return (point - center).distance;
    }

    final angle = _angleFor(point);

    if (_isAngleWithinSweep(angle, inclusive: true)) {
      final radialDistance = (point - center).distance;
      return (radialDistance - radius).abs();
    }

    final startDistance = (point - startPoint.position).distance;
    final endDistance = (point - endPoint.position).distance;
    return math.min(startDistance, endDistance);
  }

  @override
  double length() {
    final radius = _radius;
    if (radius <= 0) {
      return 0.0;
    }
    return radius * _sweepMagnitude;
  }

  @override
  GeoArc copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    ComplexGeometryBoundary? boundary,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoArc, style: style)
            : color != null
                ? _shapeStyleOverrides(
                    type: GeoArc,
                    fallbackColor: color,
                  )
                : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;
    return GeoArc(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      boundary: boundary ?? this.boundary,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.orange,
    );
  }

  double _angleFor(Offset point) {
    final vector = point - _center;
    return math.atan2(-vector.dy, vector.dx);
  }

  static double _normalizeAngle(double angle) {
    final wrapped = angle % _twoPi;
    if (wrapped < 0) {
      return wrapped + _twoPi;
    }
    return wrapped;
  }

  bool _isAngleWithinSweep(double angle, {required bool inclusive}) {
    if ((_sweepMagnitude - _twoPi).abs() <= _angleEpsilon) {
      return true;
    }

    final sweep = _sweepAngle;
    if (sweep >= 0) {
      final offset = _normalizeAngle(angle - _startAngle);
      if (inclusive) {
        return offset <= sweep + _angleEpsilon;
      }
      return offset > _angleEpsilon && offset < sweep + _angleEpsilon;
    }

    final offset = _normalizeAngle(_startAngle - angle);
    final magnitude = -sweep;
    if (inclusive) {
      return offset <= magnitude + _angleEpsilon;
    }
    return offset > _angleEpsilon && offset < magnitude + _angleEpsilon;
  }

  Offset _pointOnCircle(double angle) {
    final center = _center;
    final radius = _radius;
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy - radius * math.sin(angle);
    return Offset(x, y);
  }

}

/// Circular arc defined by three points (start, through, end)
class GeoArc3P extends GeoArc {
  GeoArc3P({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.boundary,
    super.visible,
    super.style,
    super.styleOverrides,
    super.color,
  }) : assert(
         dependencies.length == 3,
         'GeoArc3P requires exactly 3 point dependencies',
       );

  String get throughPointId => dependencies[1];

  static const double _collinearTolerance = 1e-6;

  /// Construct an arc through three points.
  static GeoArc3P? fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    Multivector? multivectorOverride,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.orange,
  }) {
    if (points.length != 3) {
      throw ArgumentError('GeoArc3P requires exactly 3 point dependencies');
    }

    final p1 = points[0];
    final p2 = points[1];
    final p3 = points[2];

    final orientation =
        (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x);
    if (orientation.abs() < _collinearTolerance) {
      return null;
    }

    final mv =
        multivectorOverride != null && !multivectorOverride.isZero()
            ? multivectorOverride
            : constructCircleThrough3PointsSigned(
            // : constructCircleThrough3Points(
                p1.multivector,
                p2.multivector,
                p3.multivector,
              );

    // Helpful when tweaking arc orientation; logs whenever the arc recomputes.
    // Uses print instead of debugPrint so it still appears in release builds.
    // ignore: avoid_print
    // print(
    //   'GeoArc3P mv -> id=$id label=$label o=${mv.o.toStringAsFixed(6)} e1=${mv.e1.toStringAsFixed(6)} e2=${mv.e2.toStringAsFixed(6)} O=${mv.O.toStringAsFixed(6)}',
    // );

    final overrides = _shapeStyleOverrides(
      type: GeoArc3P,
      style: style,
      overrides: styleOverrides,
      fallbackColor: color,
    );

    return GeoArc3P(
      id: id,
      label: label,
      dependencies: List<String>.unmodifiable([p1.id, p2.id, p3.id]),
      boundary: ComplexGeometryBoundary(
        startPoint: p1,
        endPoint: p3,
        multivector: mv,
      ),
      visible: visible,
      styleOverrides: overrides,
      color: color,
    );
  }

  @override
  GeoArc3P copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    ComplexGeometryBoundary? boundary,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoArc3P, style: style)
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    return GeoArc3P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      boundary: boundary ?? this.boundary,
      visible: visible ?? this.visible,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.orange,
    );
  }

  @override
  String get type => 'GeoArc3P';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final properties = Map<String, dynamic>.from(
      (json['properties'] as Map<String, dynamic>? ?? const {}),
    );
    properties['throughPointId'] = throughPointId;
    json['properties'] = properties;
    return json;
  }

  static GeoArc3P fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
  ) {
    final dependencies =
        (json['dependencies'] as List<dynamic>).cast<String>();
    if (dependencies.length != 3) {
      throw FormatException('GeoArc3P requires exactly 3 dependencies');
    }

    final start = resolvePoint(dependencies[0]);
    final through = resolvePoint(dependencies[1]);
    final end = resolvePoint(dependencies[2]);

    final properties =
        (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv =
        SimpleGeometryObject.decodeMultivector(properties['multivector']);

    final arc = GeoArc3P.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      points: [start, through, end],
      multivectorOverride: mv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: GeometryObject.extractStyleOverrides(json),
    );

    if (arc == null) {
      throw StateError('Cannot decode GeoArc3P: points are collinear');
    }

    return arc;
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents) {
    final byId = <String, GeoPoint>{};
    for (final parent in parents.whereType<GeoPoint>()) {
      byId[parent.id] = parent;
    }

    final ordered = dependencies
        .map((id) => byId[id])
        .whereType<GeoPoint>()
        .toList(growable: false);

    // print("##################");
    if (ordered.length != 3) {
      return null;
    }

    return GeoArc3P.fromDependencies(
      id: id,
      label: label,
      points: ordered,
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

/// Segment between two points
class GeoSegment extends ComplexGeometryObject {
  GeoSegment({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.boundary,
    super.visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.blue,
  }) : super(
         styleOverrides: _shapeStyleOverrides(
           type: GeoSegment,
           style: style,
           overrides: styleOverrides,
           fallbackColor: color,
         ),
       );

  static const double _distanceEpsilon = 1e-9;

  bool get usesDirectSweep => _computeUsesDirectSweep();

  @override
  String get type => 'segment';

  @override
  void draw(Canvas canvas, Paint paint) {
    if (!visible) return;

    final start = startPoint.position;
    final end = endPoint.position;
    if (start == end) {
      return;
    }

    final effectiveStyle = style;
  final rotatedPointMv = _computeRotatedEndpoint();
  final signedDistance =
    _orientationSignedDistance(rotatedPoint: rotatedPointMv);
  final directSweep = _shouldUseDirectSweep(signedDistance);
  final rotatedPointOffset = rotatedPointMv != null
    ? Offset(rotatedPointMv.e1, rotatedPointMv.e2)
    : null;

    final segmentPaint = Paint()
      ..color = effectiveStyle.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveStyle.strokeWidth
      ..strokeCap = StrokeCap.round;

    if (!directSweep) {
      final segments = _computeComplementarySegments(canvas, start, end);
      if (segments.isNotEmpty) {
        for (final segment in segments) {
          final from = segment.$1;
          final to = segment.$2;
          if (_squaredDistance(from, to) <=
              _distanceEpsilon * _distanceEpsilon) {
            continue;
          }
          canvas.drawLine(from, to, segmentPaint);
        }
        if (rotatedPointOffset != null) {
          _drawRotatedReferencePoint(
            canvas,
            rotatedPointOffset,
            effectiveStyle,
          );
        }
        return;
      }
    }

    canvas.drawLine(start, end, segmentPaint);
    if (rotatedPointOffset != null) {
      _drawRotatedReferencePoint(canvas, rotatedPointOffset, effectiveStyle);
    }
  }

  @override
  bool contains(Offset position) {
    final signedDistance = _orientationSignedDistance();
    final directSweep = _shouldUseDirectSweep(signedDistance);
    if (!directSweep) {
      return false;
    }

    final start = startPoint.position;
    final end = endPoint.position;
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared <= _distanceEpsilon) {
      final tolerance = style.strokeWidth + 4.0;
      return (position - start).distance <= tolerance;
    }

    final toPoint = position - start;
    final projection =
        (toPoint.dx * segment.dx + toPoint.dy * segment.dy) / lengthSquared;
    if (projection < 0 || projection > 1) {
      return false;
    }

    final nearest = Offset(
      start.dx + projection * segment.dx,
      start.dy + projection * segment.dy,
    );
    final tolerance = style.strokeWidth + 4.0;
    return (position - nearest).distance <= tolerance;
  }

  @override
  Rect getBounds() {
    final start = startPoint.position;
    final end = endPoint.position;
    final strokePadding = style.strokeWidth;
    return Rect.fromPoints(start, end).inflate(strokePadding);
  }

  @override
  double distanceTo(Offset point) {
    final signedDistance = _orientationSignedDistance();
    final directSweep = _shouldUseDirectSweep(signedDistance);
    if (!directSweep) {
      return double.infinity;
    }

    final start = startPoint.position;
    final end = endPoint.position;
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared <= _distanceEpsilon) {
      return (point - start).distance;
    }

    final toPoint = point - start;
    final projection =
        (toPoint.dx * segment.dx + toPoint.dy * segment.dy) / lengthSquared;

    if (projection < 0) {
      return (point - start).distance;
    }
    if (projection > 1) {
      return (point - end).distance;
    }

    final nearest = Offset(
      start.dx + projection * segment.dx,
      start.dy + projection * segment.dy,
    );
    return (point - nearest).distance;
  }

  @override
  double length() {
    final start = startPoint.position;
    final end = endPoint.position;
    final signedDistance = _orientationSignedDistance();
    final directSweep = _shouldUseDirectSweep(signedDistance);
    if (!directSweep) {
      return double.infinity;
    }
    return (end - start).distance;
  }

  @override
  GeoSegment copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    ComplexGeometryBoundary? boundary,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoSegment, style: style)
            : color != null
            ? _shapeStyleOverrides(
                type: GeoSegment,
                fallbackColor: color,
              )
            : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;
    return GeoSegment(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      boundary: boundary ?? this.boundary,
      visible: visible ?? this.visible,
      style: style,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.blue,
    );
  }

  bool _computeUsesDirectSweep() {
    return _shouldUseDirectSweep(_orientationSignedDistance());
  }

  double? _orientationSignedDistance({Multivector? rotatedPoint}) {
    if (multivector.isZero() || !multivector.isLine()) {
      return null;
    }

    try {
      final reference = rotatedPoint ?? _computeRotatedEndpoint();
      if (reference == null) {
        return null;
      }

      final signedDistance = distancePointToLine(
        reference,
        multivector,
      );

      if (!signedDistance.isFinite) {
        return null;
      }

      return signedDistance;
    } catch (_) {
      return null;
    }
  }

  Multivector? _computeRotatedEndpoint() {
    if (multivector.isZero() || !multivector.isLine()) {
      return null;
    }
    final start = startPoint.position;
    final end = endPoint.position;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    if (dx.abs() <= _distanceEpsilon && dy.abs() <= _distanceEpsilon) {
      return null;
    }

    final rotatedOffset = Offset(start.dx + dy, start.dy - dx);
    return constructFreePoint(rotatedOffset.dx, rotatedOffset.dy);
  }

  void _drawRotatedReferencePoint(
    Canvas canvas,
    Offset position,
    CanvasStyle effectiveStyle,
  ) {
    
    final markerRadius = math.max(3.0, effectiveStyle.strokeWidth * 1.2);

    final markerFill = Paint()
      ..color = effectiveStyle.strokeColor.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, markerRadius, markerFill);

    final markerStroke = Paint()
      ..color = effectiveStyle.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, effectiveStyle.strokeWidth * 0.6);
    canvas.drawCircle(position, markerRadius, markerStroke);
  }

  bool _shouldUseDirectSweep(double? signedDistance) {
    if (signedDistance == null || !signedDistance.isFinite) {
      return true;
    }
    if (signedDistance.abs() <= _distanceEpsilon) {
      return true;
    }
    return signedDistance > 0;
  }

  List<(Offset, Offset)> _computeComplementarySegments(
    Canvas canvas,
    Offset start,
    Offset end,
  ) {
    final clipRect = _determineClipRect(canvas);
    final intersections = _lineRectangleIntersections(clipRect);
    if (intersections.length < 2) {
      return const <(Offset, Offset)>[];
    }

    final baseVector = end - start;
    final segmentLengthSquared =
        baseVector.dx * baseVector.dx + baseVector.dy * baseVector.dy;
    if (segmentLengthSquared <= _distanceEpsilon * _distanceEpsilon) {
      return const <(Offset, Offset)>[];
    }

    final segmentLength = math.sqrt(segmentLengthSquared);
    final direction = Offset(
      baseVector.dx / segmentLength,
      baseVector.dy / segmentLength,
    );

    final segments = <(Offset, Offset)>[];

    final projections = intersections
        .map(
          (point) {
            final relative = point - start;
            final projection =
                direction.dx * relative.dx + direction.dy * relative.dy;
            return (projection, point);
          },
        )
        .toList(growable: false);

    projections.sort((a, b) => a.$1.compareTo(b.$1));

    Offset? beforePoint;
    double beforeProjection = double.negativeInfinity;
    Offset? afterPoint;
    double afterProjection = double.infinity;

    for (final entry in projections) {
      final projection = entry.$1;
      final point = entry.$2;

      if (projection < -_distanceEpsilon) {
        if (projection > beforeProjection) {
          beforeProjection = projection;
          beforePoint = point;
        }
      } else if (projection > segmentLength + _distanceEpsilon) {
        if (projection < afterProjection) {
          afterProjection = projection;
          afterPoint = point;
        }
      }
    }

    beforePoint ??= projections.first.$2;
    afterPoint ??= projections.last.$2;

    if (_squaredDistance(beforePoint, start) >
        _distanceEpsilon * _distanceEpsilon) {
      segments.add((beforePoint, start));
    }

    if (_squaredDistance(end, afterPoint) >
        _distanceEpsilon * _distanceEpsilon) {
      segments.add((end, afterPoint));
    }

    return segments;
  }

  List<Offset> _lineRectangleIntersections(Rect rect) {
    const double tolerance = 1e-9;
    final double a = multivector.e1;
    final double b = multivector.e2;
    final double c = -multivector.O;

    bool within(double value, double min, double max) {
      return value >= min - tolerance && value <= max + tolerance;
    }

    void addCandidate(List<Offset> target, double x, double y) {
      if (!x.isFinite || !y.isFinite) {
        return;
      }
      if (!within(x, rect.left, rect.right) ||
          !within(y, rect.top, rect.bottom)) {
        return;
      }
      final candidate = Offset(x, y);
      for (final existing in target) {
        final dx = existing.dx - candidate.dx;
        final dy = existing.dy - candidate.dy;
        if (dx * dx + dy * dy <= tolerance * tolerance) {
          return;
        }
      }
      target.add(candidate);
    }

    final intersections = <Offset>[];

    if (b.abs() > tolerance) {
      addCandidate(intersections, rect.left, -(a * rect.left + c) / b);
      addCandidate(intersections, rect.right, -(a * rect.right + c) / b);
    }

    if (a.abs() > tolerance) {
      addCandidate(intersections, -(b * rect.top + c) / a, rect.top);
      addCandidate(intersections, -(b * rect.bottom + c) / a, rect.bottom);
    }

    return intersections;
  }

  Rect _determineClipRect(Canvas canvas) {
    try {
      final rect = canvas.getLocalClipBounds();
      if (rect.isFinite && !rect.isEmpty) {
        return rect;
      }
    } catch (_) {
      // Fallback below
    }
    return const Rect.fromLTRB(-10000, -10000, 10000, 10000);
  }

  double _squaredDistance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return dx * dx + dy * dy;
  }
}

/// Segment defined by two points
class GeoSegment2P extends GeoSegment {
  GeoSegment2P({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.boundary,
    super.visible,
    super.style,
    super.styleOverrides,
    super.color,
  }) : assert(
         dependencies.length == 2 ,
         'GeoSegment2P requires exactly 2 point dependencies',
       );

  static GeoSegment2P fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    Multivector? multivectorOverride,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color color = Colors.blue,
  }) {
    if (points.length != 2) {
      throw ArgumentError('GeoSegment2P requires exactly 2 point dependencies');
    }

  final p1 = points[0];
  final p2 = points[1];
  final p1Pos = p1.position;
  final p2Pos = p2.position;

  final computedMv = p1.position == p2.position
    ? Multivector.zero()
    : constructLineFrom2Points(
      p1.multivector,
      p2.multivector,
      );

    final mv =
        multivectorOverride != null && !multivectorOverride.isZero()
            ? multivectorOverride
            : computedMv;

    // Debug output to help track ordering while points are dragged.
    // ignore: avoid_print
    print(
      'GeoSegment2P order -> p1:${p1.label}(${p1.id}) '
      'at (${p1Pos.dx.toStringAsFixed(3)}, ${p1Pos.dy.toStringAsFixed(3)}) '
      'p2:${p2.label}(${p2.id}) '
      'at (${p2Pos.dx.toStringAsFixed(3)}, ${p2Pos.dy.toStringAsFixed(3)}) '
      'mv[o=${mv.o.toStringAsFixed(6)}, e1=${mv.e1.toStringAsFixed(6)}, '
      'e2=${mv.e2.toStringAsFixed(6)}, O=${mv.O.toStringAsFixed(6)}]',
    );

    final overrides = _shapeStyleOverrides(
      type: GeoSegment2P,
      style: style,
      overrides: styleOverrides,
      fallbackColor: color,
    );

    return GeoSegment2P(
      id: id,
      label: label,
      dependencies: List<String>.unmodifiable([p1.id, p2.id]),
      boundary: ComplexGeometryBoundary(
        startPoint: p1,
        endPoint: p2,
        multivector: mv,
      ),
      visible: visible,
      styleOverrides: overrides,
      color: color,
    );
  }

  @override
  GeoSegment2P copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    ComplexGeometryBoundary? boundary,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    Color? color,
  }) {
    final candidateOverrides =
        styleOverrides ??
        (style != null
            ? _shapeStyleOverrides(type: GeoSegment2P, style: style)
            : color != null
                ? _shapeStyleOverrides(
                    type: GeoSegment2P,
                    fallbackColor: color,
                  )
                : null);
    final resolvedOverrides = candidateOverrides ?? this.styleOverrides;

    return GeoSegment2P(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      boundary: boundary ?? this.boundary,
      visible: visible ?? this.visible,
      styleOverrides: resolvedOverrides,
      color: color ?? Colors.blue,
    );
  }

  @override
  String get type => 'GeoSegment2P';

  static GeoSegment2P fromJson(
    Map<String, dynamic> json,
    GeoPoint Function(String id) resolvePoint,
  ) {
    final dependencies =
        (json['dependencies'] as List<dynamic>).cast<String>();
    if (dependencies.length != 2) {
      throw FormatException('GeoSegment2P requires exactly 2 dependencies');
    }

    final start = resolvePoint(dependencies[0]);
    final end = resolvePoint(dependencies[1]);

    final properties =
        (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv =
        SimpleGeometryObject.decodeMultivector(properties['multivector']);

    return GeoSegment2P.fromDependencies(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      points: [start, end],
      multivectorOverride: mv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: GeometryObject.extractStyleOverrides(json),
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents) {
    final byId = <String, GeoPoint>{};
    for (final parent in parents.whereType<GeoPoint>()) {
      byId[parent.id] = parent;
    }

    final ordered = dependencies
        .map((id) => byId[id])
        .whereType<GeoPoint>()
        .toList(growable: false);

    if (ordered.length != 2) {
      return null;
    }

    final p1 = ordered[0];
    final p2 = ordered[1];

    final recomputed = p1.position == p2.position
      ? Multivector.zero()
      : constructLineFrom2Points(p1.multivector, p2.multivector);

    final previous = boundary.multivector;
    final resolved = _alignLineOrientation(recomputed, previous);

    return GeoSegment2P.fromDependencies(
      id: id,
      label: label,
      points: ordered,
      multivectorOverride: resolved,
      visible: visible,
      styleOverrides: styleOverrides,
  color: style.strokeColor,
    );
  }
}

Multivector _alignLineOrientation(Multivector candidate, Multivector template) {
  if (candidate.isZero() || template.isZero()) {
    return candidate;
  }

  // Lines store coefficients in e1, e2, and O. Flipping sign reverses orientation.
  final dot = candidate.e1 * template.e1 + candidate.e2 * template.e2;
  if (dot < 0) {
    return candidate.scalarMultiply(-1);
  }
  return candidate;
}

Map<String, dynamic>? _shapeStyleOverrides({
  required Type type,
  CanvasStyle? style,
  Map<String, dynamic>? overrides,
  Color? fallbackColor,
}) {
  if (overrides != null) {
    return Map<String, dynamic>.unmodifiable(overrides);
  }

  if (style != null) {
    final defaults = CanvasStyleDefaults.instance.resolveForType(type);
    final diff = style.diff(defaults);
    if (diff.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.unmodifiable(diff);
  }

  if (fallbackColor != null) {
    final defaults = CanvasStyleDefaults.instance.resolveForType(type);
    if (fallbackColor.value != defaults.strokeColor.value) {
      return Map<String, dynamic>.unmodifiable({
        'strokeColor': CanvasStyle.colorToHex(fallbackColor),
      });
    }
  }

  return null;
}
