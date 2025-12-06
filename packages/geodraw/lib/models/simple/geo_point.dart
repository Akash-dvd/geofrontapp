import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import '../../core/dag/dag_manager.dart';
import 'geo_line.dart';
import 'geo_circle.dart';
import '../complex/geo_shapes.dart';
import '../complex/complex_geometry_object.dart';

/// Abstract base class for all point types
abstract class GeoPoint extends SimpleGeometryObject {
  GeoPoint({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  });

  /// X coordinate derived from multivector
  double get x => multivector.e1;

  /// Y coordinate derived from multivector
  double get y => multivector.e2;

  Offset get position => Offset(x, y);

  @override
  void draw(Canvas canvas, Paint paint) {
    if (!visible) return;

    final effectiveStyle = style;
    final radius = effectiveStyle.pointRadius;
    
    // Check if paint has highlight colors (different from base style)
    final isHighlighted = paint.color != effectiveStyle.strokeColor ||
        (effectiveStyle.highlightStrokeColor != null &&
            paint.color == effectiveStyle.highlightStrokeColor);
    
    // Draw glow effect if highlighted and enabled
    if (isHighlighted && effectiveStyle.highlightUseGlow && effectiveStyle.highlightGlowRadius > 0) {
      final glowPaint = Paint()
        ..color = effectiveStyle.getEffectiveFillColor(true).withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, effectiveStyle.highlightGlowRadius);
      canvas.drawCircle(position, radius + effectiveStyle.highlightGlowRadius, glowPaint);
    }

    if (effectiveStyle.filled) {
      // Use highlight colors if paint indicates highlighting, otherwise use style
      final fillColor = isHighlighted && effectiveStyle.highlightFillColor != null
          ? effectiveStyle.highlightFillColor!
          : effectiveStyle.fillColor;
      final strokeColor = isHighlighted && effectiveStyle.highlightStrokeColor != null
          ? effectiveStyle.highlightStrokeColor!
          : effectiveStyle.strokeColor;
      // Use paint's strokeWidth (already includes 1.5x multiplier when selected)
      final strokeWidth = paint.strokeWidth;
      
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, radius, fillPaint);

      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(position, radius, strokePaint);
    } else {
      // Use highlight colors if paint indicates highlighting, otherwise use style
      final strokeColor = isHighlighted && effectiveStyle.highlightStrokeColor != null
          ? effectiveStyle.highlightStrokeColor!
          : effectiveStyle.strokeColor;
      // Use paint's strokeWidth (already includes 1.5x multiplier when selected)
      final strokeWidth = paint.strokeWidth;
      
      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(position, radius, strokePaint);
    }

    // Draw label
    if (label.isNotEmpty) {
      final labelColor = effectiveStyle.labelColor;
      final labelFontSize = effectiveStyle.labelFontSize;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: labelColor,
            fontSize: labelFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + radius + 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool contains(Offset position) {
    return distanceTo(position) <= style.pointRadius;
  }

  @override
  Rect getBounds() {
    return Rect.fromCircle(center: position, radius: style.pointRadius);
  }

  @override
  double distanceTo(Offset point) {
    // Convert the offset to a Multivector point
    final pointMv = constructFreePoint(point.dx, point.dy);
    // Use Multivector-based distance calculation
    return distancePointToPoint(multivector, pointMv);
  }

  @override
  bool intersects(SimpleGeometryObject other) {
    if (other is GeoPoint) {
      return distanceTo(other.position) < 0.001;
    }
    return other.intersects(this);
  }

  @override
  @override
  List<Object?> get props => [...super.props];
}

/// Free point that can be moved by the user
class GeoPointer extends GeoPoint {
  GeoPointer({
    required super.id,
    required super.label,
    required double x,
    required double y,
    super.visible,
    super.styleOverrides,
  }) : super(
         dependencies: [], // Free points have no dependencies
         multivector: constructFreePoint(x, y),
       );

  @override
  GeoPointer copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? x,
    double? y,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    // Recalculate multivector from x, y if provided
    final newX = x ?? this.x;
    final newY = y ?? this.y;
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoPointer(
      id: id ?? this.id,
      label: label ?? this.label,
      x: newX,
      y: newY,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoPointer';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'x': x, 'y': y};
    return json;
  }

  static GeoPointer fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final styleOverrides = _pointStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoPointer)
          .strokeColor,
    );
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final x = (props['x'] as num?)?.toDouble() ?? mv.e1;
    final y = (props['y'] as num?)?.toDouble() ?? mv.e2;

    return GeoPointer(
      id: json['id'] as String,
      label: json['label'] as String,
      x: x,
      y: y,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }
}

/// Midpoint between two points
class GeoMidpoint extends GeoPoint {
  GeoMidpoint({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 2 dependencies
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(dependencies.length == 2, 'Midpoint requires exactly 2 points');

  /// Calculate midpoint from two points
  static GeoMidpoint fromPoints({
    required String id,
    required String label,
    required GeoPoint p1,
    required GeoPoint p2,
    double size = 5.0,
    Color color = Colors.green,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    return fromDependencies(
      id: id,
      label: label,
      points: [p1, p2],
      visible: visible,
      style: style,
      styleOverrides: styleOverrides,
      fallbackColor: color,
      fallbackRadius: size,
    );
  }

  /// Construct a midpoint from a list of dependent points.
  static GeoMidpoint fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> points,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackRadius = 5.0,
    Color fallbackColor = Colors.green,
  }) {
    if (points.length != 2) {
      throw ArgumentError('GeoMidpoint requires exactly 2 point dependencies');
    }

    final mv = constructMidpoint(points[0].multivector, points[1].multivector);
    final normalizedOverrides = _pointStyleOverridesFromStyle(
      type: GeoMidpoint,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackRadius: fallbackRadius,
    );

    return GeoMidpoint(
      id: id,
      label: label,
      dependencies: points.map((p) => p.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoMidpoint copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? x,
    double? y,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoMidpoint(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoMidpoint';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'x': x, 'y': y};
    return json;
  }

  static GeoMidpoint fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance.resolveForType(GeoMidpoint);
    final styleOverrides = _pointStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoMidpoint(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager) {
      return null;
    }

    if (dependencies.length != 2) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final point1Obj = dagManager.getObject(dependencies[0]);
    final point2Obj = dagManager.getObject(dependencies[1]);
    
    if (point1Obj is! GeoPoint || point2Obj is! GeoPoint) {
      return null;
    }

    return GeoMidpoint.fromDependencies(
      id: id,
      label: label,
      points: [point1Obj, point2Obj],
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

/// Glider point that slides along a geometric object (line, circle, arc, segment, or union)
class GeoGliderPoint extends GeoPoint {
  GeoGliderPoint({
    required super.id,
    required super.label,
    required this.objectId,
    required double initialX,
    required double initialY,
    super.visible,
    super.styleOverrides,
  }) : _initialX = initialX,
       _initialY = initialY,
       super(
         dependencies: [objectId],
         multivector: constructFreePoint(initialX, initialY),
       );

  /// ID of the object this point glides on
  final String objectId;
  
  /// Initial position when the point was created (used for projection)
  final double _initialX;
  final double _initialY;

  @override
  GeoGliderPoint copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? x,
    double? y,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    String? objectId,
    double? initialX,
    double? initialY,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    final newObjectId = objectId ?? this.objectId;
    final newInitialX = initialX ?? _initialX;
    final newInitialY = initialY ?? _initialY;
    
    return GeoGliderPoint(
      id: id ?? this.id,
      label: label ?? this.label,
      objectId: newObjectId,
      initialX: newInitialX,
      initialY: newInitialY,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoGliderPoint';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'x': x,
      'y': y,
      'objectId': objectId,
      'initialX': _initialX,
      'initialY': _initialY,
    };
    return json;
  }

  static GeoGliderPoint fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? const {};
    final styleOverrides = _pointStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoGliderPoint)
          .strokeColor,
    );
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];
    
    final objectId = props['objectId'] as String? ?? 
                    (deps.isNotEmpty ? deps.first : '');
    final initialX = (props['initialX'] as num?)?.toDouble() ?? mv.e1;
    final initialY = (props['initialY'] as num?)?.toDouble() ?? mv.e2;

    return GeoGliderPoint(
      id: json['id'] as String,
      label: json['label'] as String,
      objectId: objectId,
      initialX: initialX,
      initialY: initialY,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final objectObj = dagManager.getObject(objectId);
    if (objectObj is! GeometryObject) {
      return null;
    }
    final object = objectObj;

    // Create a point multivector from the initial position
    final initialPoint = constructFreePoint(_initialX, _initialY);
    Multivector? projectedPoint;

    // Project point onto the object based on its type
    if (object is GeoLine) {
      projectedPoint = projectPointToLine(initialPoint, object.multivector);
    } else if (object is GeoCircle) {
      projectedPoint = projectPointToCircle(initialPoint, object.multivector);
    } else if (object is GeoSegment) {
      projectedPoint = projectPointToSegment(
        initialPoint,
        object.boundary.boundary,
      );
    } else if (object is GeoArc) {
      // Determine direction from circle orientation
      final counterClockwise = object.boundary.multivector.o >= 0;
      final proj = projectPointToArc(
        initialPoint,
        object.boundary.multivector,
        object.startPoint.multivector,
        object.endPoint.multivector,
        counterClockwise,
      );
      if (proj == null) {
        return null;
      }
      projectedPoint = proj;
    } else if (object is UnionGeometryObjectList) {
      // For union objects, find the nearest point across all elements
      projectedPoint = _projectPointToUnion(initialPoint, object);
      if (projectedPoint == null) {
        return null;
      }
    }

    if (projectedPoint == null) {
      return null;
    }

    return GeoGliderPoint(
      id: id,
      label: label,
      objectId: objectId,
      initialX: _initialX,
      initialY: _initialY,
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

/// Orthocenter of a triangle (intersection of three altitudes)
class GeoOrthocenter extends GeoPoint {
  GeoOrthocenter({
    required super.id,
    required super.label,
    required super.dependencies, // Should have exactly 3 dependencies
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         dependencies.length == 3,
         'GeoOrthocenter requires exactly 3 point dependencies',
       );

  /// Construct orthocenter from three vertices
  static GeoOrthocenter fromDependencies({
    required String id,
    required String label,
    required List<GeoPoint> vertices,
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
    double fallbackRadius = 5.0,
    Color fallbackColor = Colors.green,
  }) {
    if (vertices.length != 3) {
      throw ArgumentError('GeoOrthocenter requires exactly 3 vertex dependencies');
    }

    final mv = constructOrthocenterFrom3Vertices(
      vertices[0].multivector,
      vertices[1].multivector,
      vertices[2].multivector,
    );
    final normalizedOverrides = _pointStyleOverridesFromStyle(
      type: GeoOrthocenter,
      style: style,
      overrides: styleOverrides,
      fallbackColor: fallbackColor,
      fallbackRadius: fallbackRadius,
    );

    return GeoOrthocenter(
      id: id,
      label: label,
      dependencies: vertices.map((v) => v.id).toList(growable: false),
      multivector: mv,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  @override
  GeoOrthocenter copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    double? x,
    double? y,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoOrthocenter(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoOrthocenter';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {'x': x, 'y': y};
    return json;
  }

  static GeoOrthocenter fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final deps = (json['dependencies'] as List).cast<String>();
    final defaults = CanvasStyleDefaults.instance.resolveForType(GeoOrthocenter);
    final styleOverrides = _pointStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: defaults.strokeColor,
    );

    return GeoOrthocenter(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    if (dagManager is! DAGManager) {
      return null;
    }

    if (dependencies.length != 3) {
      return null;
    }

    // Use dagManager.getObject() - handles both regular objects and objects in containers
    final v1Obj = dagManager.getObject(dependencies[0]);
    final v2Obj = dagManager.getObject(dependencies[1]);
    final v3Obj = dagManager.getObject(dependencies[2]);
    
    if (v1Obj is! GeoPoint || v2Obj is! GeoPoint || v3Obj is! GeoPoint) {
      return null;
    }

    return GeoOrthocenter.fromDependencies(
      id: id,
      label: label,
      vertices: [v1Obj, v2Obj, v3Obj],
      visible: visible,
      styleOverrides: styleOverrides,
    );
  }
}

/// Generic constructed point with dependencies (for aLCbc results, etc.)
class GeoConstructedPoint extends GeoPoint {
  GeoConstructedPoint({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  });

  @override
  GeoConstructedPoint copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoConstructedPoint(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoConstructedPoint';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'x': x,
      'y': y,
    };
    return json;
  }

  static GeoConstructedPoint fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    final styleOverrides = _pointStyleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoConstructedPoint)
          .strokeColor,
    );
    final deps = (json['dependencies'] as List).cast<String>();

    return GeoConstructedPoint(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: mv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    // Constructed points typically don't rebuild from parents automatically
    // They are usually created directly from multivector calculations
    return null;
  }
}

/// Helper function to project a point onto a union object (finds nearest point across all elements)
Multivector? _projectPointToUnion(
    Multivector point,
    UnionGeometryObjectList union,
  ) {
    Multivector? bestProjection;
    double bestDistance = double.infinity;

    for (final element in union.elements) {
      Multivector? projection;
      
      if (element is GeoLine) {
        projection = projectPointToLine(point, element.multivector);
      } else if (element is GeoCircle) {
        projection = projectPointToCircle(point, element.multivector);
      } else if (element is GeoSegment) {
        projection = projectPointToSegment(
          point,
          element.boundary.boundary,
        );
      } else if (element is GeoArc) {
        final counterClockwise = element.boundary.multivector.o >= 0;
        projection = projectPointToArc(
          point,
          element.boundary.multivector,
          element.startPoint.multivector,
          element.endPoint.multivector,
          counterClockwise,
        );
      }

      if (projection != null) {
        final dist = distancePointToPoint(point, projection);
        if (dist < bestDistance) {
          bestDistance = dist;
          bestProjection = projection;
        }
      }
    }

    return bestProjection;
}

/// Helper functions for point style overrides
Map<String, dynamic>? _pointStyleOverridesFromStyle({
  required Type type,
  CanvasStyle? style,
  Map<String, dynamic>? overrides,
  Color? fallbackColor,
  double? fallbackRadius,
}) {
  if (overrides != null) {
    return Map<String, dynamic>.unmodifiable(overrides);
  }
  if (style != null) {
    final defaults = CanvasStyleDefaults.instance.resolveForType(type);
    return Map<String, dynamic>.unmodifiable(style.diff(defaults));
  }

  final inferred = <String, dynamic>{};

  if (fallbackColor != null) {
    inferred['strokeColor'] = CanvasStyle.colorToHex(fallbackColor);
  }
  if (fallbackRadius != null) {
    inferred['pointRadius'] = fallbackRadius;
  }

  if (inferred.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(inferred);
}

Map<String, dynamic>? _pointStyleOverridesFromJson(
  Map<String, dynamic> json, {
  Map<String, dynamic>? legacyProps,
  Color? fallbackColor,
}) {
  final existing = GeometryObject.extractStyleOverrides(json);
  if (existing != null) {
    return Map<String, dynamic>.unmodifiable(existing);
  }

  final overrides = <String, dynamic>{};

  final rawColor = json.containsKey('color') ? json['color'] : null;
  final parsedColor = GeometryObject.parseColor(rawColor) ?? fallbackColor;
  if (parsedColor != null) {
    overrides['strokeColor'] = CanvasStyle.colorToHex(parsedColor);
  }

  if (legacyProps != null) {
    final size = legacyProps['size'];
    if (size is num) {
      overrides['pointRadius'] = size.toDouble();
    }
  }

  if (overrides.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(overrides);
}
