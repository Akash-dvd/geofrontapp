/// Registry for all command definitions
library;

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import 'command_definition.dart';
import 'command_schema.dart';
import 'command_runtime.dart';
import '../../models/geometry_object.dart';
import '../../models/simple/geo_point.dart';
import '../../models/simple/geo_line.dart';
import '../../models/simple/geo_circle.dart';
import '../../models/simple/geo_trans.dart';
import '../../models/simple/geo_transformed_simple.dart';
import '../../models/simple_lists/geo_tangent.dart';
import '../../models/complex/complex_geometry_object.dart';
import '../../models/complex/geo_shapes.dart';
import '../../models/complex/geo_shapes_list.dart';
import '../../models/complex/geo_transformed_complex.dart';
import '../../models/text/canvas_text.dart';
import '../../models/transforms/transformation_engine.dart';

/// Stores command definitions and provides lookup by name
class CommandRegistry {
  CommandRegistry._internal() {
    _registerDefaults();
  }

  /// Shared registry used by default by DAG instances
  static final CommandRegistry standard = CommandRegistry._internal();

  final Map<String, CommandDefinition> _byName = HashMap();
  final LinkedHashSet<CommandDefinition> _definitions =
      LinkedHashSet<CommandDefinition>.identity();

  int _pointLabelCounter = 0;
  int _lineLabelCounter = 0;
  int _segmentLabelCounter = 0;
  int _circleLabelCounter = 0;
  int _circleThreeLabelCounter = 0;
  int _arcThreeLabelCounter = 0;
  int _midpointLabelCounter = 0;
  int _perpendicularLabelCounter = 0;
  int _parallelLabelCounter = 0;
  int _perpBisectorLabelCounter = 0;
  int _tangentLabelCounter = 0;
  int _textLabelCounter = 0;
  int _inverseLabelCounter = 0;
  int _rotateLabelCounter = 0;
  int _dilateLabelCounter = 0;
  int _unionLabelCounter = 0;
  int _polyArcLabelCounter = 0;
  int _polygonLabelCounter = 0;
  int _polyLineLabelCounter = 0;
  int _polyArcGonLabelCounter = 0;

  void _registerDefaults() {
    // Register core geometry constructors
    _register(
      CommandDefinition(
        name: 'point',
        description: 'Create a free point at coordinates',
        schema: CommandSchema(
          description: 'Free point',
          argumentTypes: [
            TypeConstraint.numeric(description: 'x-coordinate'),
            TypeConstraint.numeric(description: 'y-coordinate'),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Enter x-coordinate',
            'Enter y-coordinate',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final x = (arguments[0] as num).toDouble();
          final y = (arguments[1] as num).toDouble();
          final providedLabel = arguments.length >= 3 && arguments[2] is String
              ? (arguments[2] as String).trim()
              : '';
          final point = GeoPointer(
            id: context.generateId('point'),
            label: providedLabel.isNotEmpty
                ? providedLabel
                : context.resolveLabel(_nextPointLabel),
            x: x,
            y: y,
          );

          context.dagManager.addObject(point, []);

          return ExecutionResult.successful(
            objectId: point.id,
            message: 'Created ${point.label}',
            object: point,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'text',
        description: 'Place a text annotation on the canvas',
        schema: CommandSchema(
          description: 'Text annotation',
          argumentTypes: [
            TypeConstraint.numeric(description: 'x-coordinate'),
            TypeConstraint.numeric(description: 'y-coordinate'),
            TypeConstraint.text(description: 'Text content', optional: true),
          ],
          argumentHints: [
            'Enter x-coordinate',
            'Enter y-coordinate',
            'Enter text to display (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final x = (arguments[0] as num).toDouble();
          final y = (arguments[1] as num).toDouble();
          final providedText = arguments.length >= 3 && arguments[2] is String
              ? (arguments[2] as String).trim()
              : '';
          final textContent = providedText.isNotEmpty
              ? providedText
              : context.resolveLabel(_nextTextContent);

          final text = CanvasText(
            id: context.generateId('text'),
            text: textContent,
            position: Offset(x, y),
          );

          context.dagManager.addObject(text, []);

          return ExecutionResult.successful(
            objectId: text.id,
            message: 'Placed "$textContent"',
            object: text,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'line',
        description: 'Create a line through two points',
        schema: CommandSchema(
          description: 'Line through points',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'First point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Second point',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select first point',
            'Select second point',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final p1 = arguments[0] as GeoPoint;
          final p2 = arguments[1] as GeoPoint;
          final providedLabel = arguments.length >= 3 && arguments[2] is String
              ? (arguments[2] as String).trim()
              : '';
          final line = GeoLine2P.fromDependencies(
            id: context.generateId('line'),
            label: providedLabel.isNotEmpty
                ? providedLabel
                : context.resolveLabel(_nextLineLabel),
            points: [p1, p2],
          );

          context.dagManager.addObject(line, [p1.id, p2.id]);

          return ExecutionResult.successful(
            objectId: line.id,
            message: 'Created ${line.label}',
            object: line,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'segment',
        description: 'Create a segment between two points',
        schema: CommandSchema(
          description: 'Segment through two points',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'First point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Second point',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select first point',
            'Select second point',
            'Enter label (optional)',
          ],
        ),
        aliases: const ['lineSegment'],
        executor: (context, arguments) async {
          final p1 = arguments[0] as GeoPoint;
          final p2 = arguments[1] as GeoPoint;
          final providedLabel = arguments.length >= 3 && arguments[2] is String
              ? (arguments[2] as String).trim()
              : '';

          final segment = GeoSegment2P.fromDependencies(
            id: context.generateId('segment'),
            label: providedLabel.isNotEmpty
                ? providedLabel
                : context.resolveLabel(_nextSegmentLabel),
            points: [p1, p2],
          );

          context.dagManager.addObject(segment, [p1.id, p2.id]);

          return ExecutionResult.successful(
            objectId: segment.id,
            message: 'Created ${segment.label}',
            object: segment,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'circle',
        description: 'Create a circle with center and point',
        schema: CommandSchema(
          description: 'Circle with center and point',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Center point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Point on circumference',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select center point',
            'Select point on circle',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final center = arguments[0] as GeoPoint;
          final pointOnCircle = arguments[1] as GeoPoint;
          final providedLabel = arguments.length >= 3 && arguments[2] is String
              ? (arguments[2] as String).trim()
              : '';
          final circle = GeoCircle2P.fromDependencies(
            id: context.generateId('circle'),
            label: providedLabel.isNotEmpty
                ? providedLabel
                : context.resolveLabel(_nextCircleLabel),
            points: [center, pointOnCircle],
          );

          context.dagManager.addObject(circle, [center.id, pointOnCircle.id]);

          return ExecutionResult.successful(
            objectId: circle.id,
            message: 'Created ${circle.label}',
            object: circle,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'circle3',
        description: 'Create a circle through three points',
        aliases: const ['circleThrough3', 'circumcircle'],
        schema: CommandSchema(
          description: 'Circle through three points',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'First point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Second point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Third point',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select first point',
            'Select second point',
            'Select third point',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final p1 = arguments[0] as GeoPoint;
          final p2 = arguments[1] as GeoPoint;
          final p3 = arguments[2] as GeoPoint;
          final providedLabel = arguments.length >= 4 && arguments[3] is String
              ? (arguments[3] as String).trim()
              : '';
          final circle = GeoCircle3P.fromDependencies(
            id: context.generateId('circle'),
            label: providedLabel.isNotEmpty
                ? providedLabel
                : context.resolveLabel(_nextCircleThreeLabel),
            points: [p1, p2, p3],
          );

          if (circle == null) {
            return ExecutionResult.error(
              'Cannot create circle: points are collinear',
            );
          }

          context.dagManager.addObject(circle, [p1.id, p2.id, p3.id]);

          return ExecutionResult.successful(
            objectId: circle.id,
            message: 'Created ${circle.label}',
            object: circle,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'arc3',
        description: 'Create a circular arc through three points',
        aliases: const ['circularArc', 'arcThrough3'],
        schema: CommandSchema(
          description: 'Arc through three points',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Start point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Through point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'End point',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select start point',
            'Select through point',
            'Select end point',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final p1 = arguments[0] as GeoPoint;
          final p2 = arguments[1] as GeoPoint;
          final p3 = arguments[2] as GeoPoint;
          final providedLabel = arguments.length >= 4 && arguments[3] is String
              ? (arguments[3] as String).trim()
              : '';

          final arc = GeoArc3P.fromDependencies(
            id: context.generateId('arc'),
            label: providedLabel.isNotEmpty
                ? providedLabel
                : context.resolveLabel(_nextArcThreeLabel),
            points: [p1, p2, p3],
          );

          if (arc == null) {
            return ExecutionResult.error(
              'Cannot create arc: points are collinear',
            );
          }

          context.dagManager.addObject(arc, [p1.id, p2.id, p3.id]);

          return ExecutionResult.successful(
            objectId: arc.id,
            message: 'Created ${arc.label}',
            object: arc,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'polyarc',
        description: 'Create a chain of arcs through sequential points',
        aliases: const ['polyArc'],
        schema: CommandSchema(
          description: 'Poly-arc chain',
          patterns: _polyArcPointPatterns(),
          argumentHints: const [
            'Select start point',
            'Select control point',
            'Select end point',
            'Select control point',
            'Select end point',
            'Select control point',
            'Select end point',
            'Select control point',
            'Select end point',
            'Select control point',
            'Select end point',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          if (arguments.length < 3) {
            return ExecutionResult.error(
              'Poly-arc requires at least three points',
            );
          }

          final rawArguments = List<dynamic>.from(arguments);
          String providedLabel = '';
          if (rawArguments.isNotEmpty && rawArguments.last is String) {
            providedLabel = (rawArguments.removeLast() as String).trim();
          }

          final points = <GeoPoint>[];
          for (final argument in rawArguments) {
            if (argument is! GeoPoint) {
              return ExecutionResult.error(
                'Poly-arc expects only point arguments',
              );
            }
            points.add(argument);
          }

          if (points.length < 3) {
            return ExecutionResult.error(
              'Poly-arc requires at least three points',
            );
          }

          if (points.length.isEven) {
            return ExecutionResult.error(
              'Poly-arc point count must be 3 + 2n; received ${points.length}',
            );
          }

          GeoPolyArc polyArc;
          try {
            polyArc = GeoPolyArc.fromDependencies(
              id: context.generateId('poly_arc'),
              label: providedLabel.isNotEmpty
                  ? providedLabel
                  : context.resolveLabel(_nextPolyArcLabel),
              points: points,
            );
          } on ArgumentError catch (error) {
            final message = error.message is String
                ? error.message as String
                : error.toString();
            return ExecutionResult.error(message);
          }

          context.dagManager.addObject(polyArc, polyArc.dependencies);

          return ExecutionResult.successful(
            objectId: polyArc.id,
            message: 'Created ${polyArc.label}',
            object: polyArc,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'extendpolyarc',
        description: 'Extend an existing poly-arc with another arc',
        aliases: const ['extendPolyArc'],
        schema: CommandSchema(
          description: 'Extend poly-arc',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPolyArc},
              description: 'Poly-arc to extend',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Control point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'End point',
            ),
          ],
          argumentHints: const [
            'Select poly-arc to extend',
            'Select control point',
            'Select end point',
          ],
        ),
        executor: (context, arguments) async {
          final polyArc = arguments[0] as GeoPolyArc;
          final controlPoint = arguments[1] as GeoPoint;
          final endPoint = arguments[2] as GeoPoint;

          final resolvedPoints = <GeoPoint>[];
          for (final dependencyId in polyArc.dependencies) {
            final candidate = context.dagManager.getObject(dependencyId);
            if (candidate is GeoPoint) {
              resolvedPoints.add(candidate);
              continue;
            }
            return ExecutionResult.error(
              'Unable to resolve point dependency $dependencyId',
            );
          }

          resolvedPoints.addAll([controlPoint, endPoint]);

          GeoPolyArc next;
          try {
            next = GeoPolyArc.fromDependencies(
              id: polyArc.id,
              label: polyArc.label,
              points: resolvedPoints,
              visible: polyArc.visible,
              style: polyArc.style,
              styleOverrides: polyArc.styleOverrides,
              color: polyArc.style.strokeColor,
            );
          } on ArgumentError catch (error) {
            final message = error.message is String
                ? error.message as String
                : error.toString();
            return ExecutionResult.error(message);
          }

          context.dagManager.replaceObjectWithDependencies(
            polyArc.id,
            next,
            next.dependencies,
          );

          return ExecutionResult.successful(
            objectId: next.id,
            message: 'Extended ${polyArc.label}',
            object: next,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'polygon',
        description: 'Create a polygon from sequential vertices',
        schema: CommandSchema(
          description: 'Polygon from vertices',
          patterns: _polygonPointPatterns(),
          argumentHints: const [
            'Select first vertex',
            'Select second vertex',
            'Select third vertex',
            'Select additional vertices',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          if (arguments.length < 3) {
            return ExecutionResult.error(
              'Polygon requires at least three points',
            );
          }

          final rawArguments = List<dynamic>.from(arguments);
          String providedLabel = '';
          if (rawArguments.isNotEmpty && rawArguments.last is String) {
            providedLabel = (rawArguments.removeLast() as String).trim();
          }

          final points = <GeoPoint>[];
          for (final argument in rawArguments) {
            if (argument is! GeoPoint) {
              return ExecutionResult.error(
                'Polygon expects only point arguments',
              );
            }
            points.add(argument);
          }

          if (points.length < 3) {
            return ExecutionResult.error(
              'Polygon requires at least three points',
            );
          }

          GeoPolygon polygon;
          try {
            polygon = GeoPolygon.fromDependencies(
              id: context.generateId('polygon'),
              label: providedLabel.isNotEmpty
                  ? providedLabel
                  : context.resolveLabel(_nextPolygonLabel),
              points: points,
            );
          } on ArgumentError catch (error) {
            final message = error.message is String
                ? error.message as String
                : error.toString();
            return ExecutionResult.error(message);
          }

          context.dagManager.addObject(polygon, polygon.dependencies);

          return ExecutionResult.successful(
            objectId: polygon.id,
            message: 'Created ${polygon.label}',
            object: polygon,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'extendpolygon',
        description: 'Extend an existing polygon with another vertex',
        aliases: const ['extendPolygon'],
        schema: CommandSchema(
          description: 'Extend polygon',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPolygon},
              description: 'Polygon to extend',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'New vertex',
            ),
          ],
          argumentHints: const [
            'Select polygon to extend',
            'Select new vertex',
          ],
        ),
        executor: (context, arguments) async {
          final polygon = arguments[0] as GeoPolygon;
          final newVertex = arguments[1] as GeoPoint;

          final resolvedPoints = <GeoPoint>[];
          for (final dependencyId in polygon.dependencies) {
            final candidate = context.dagManager.getObject(dependencyId);
            if (candidate is GeoPoint) {
              resolvedPoints.add(candidate);
              continue;
            }
            return ExecutionResult.error(
              'Unable to resolve point dependency $dependencyId',
            );
          }

          resolvedPoints.add(newVertex);

          GeoPolygon next;
          try {
            next = GeoPolygon.fromDependencies(
              id: polygon.id,
              label: polygon.label,
              points: resolvedPoints,
              visible: polygon.visible,
              style: polygon.style,
              styleOverrides: polygon.styleOverrides,
              color: polygon.style.strokeColor,
            );
          } on ArgumentError catch (error) {
            final message = error.message is String
                ? error.message as String
                : error.toString();
            return ExecutionResult.error(message);
          }

          context.dagManager.replaceObjectWithDependencies(
            polygon.id,
            next,
            next.dependencies,
          );

          return ExecutionResult.successful(
            objectId: next.id,
            message: 'Extended ${polygon.label}',
            object: next,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'polyline',
        description: 'Create a polyline from sequential points',
        aliases: const ['polyLine'],
        schema: CommandSchema(
          description: 'Polyline from points',
          patterns: _polyLinePointPatterns(),
          argumentHints: const [
            'Select start point',
            'Select second point',
            'Select additional points',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          if (arguments.length < 2) {
            return ExecutionResult.error(
              'Polyline requires at least two points',
            );
          }

          final rawArguments = List<dynamic>.from(arguments);
          String providedLabel = '';
          if (rawArguments.isNotEmpty && rawArguments.last is String) {
            providedLabel = (rawArguments.removeLast() as String).trim();
          }

          final points = <GeoPoint>[];
          for (final argument in rawArguments) {
            if (argument is! GeoPoint) {
              return ExecutionResult.error(
                'Polyline expects only point arguments',
              );
            }
            points.add(argument);
          }

          if (points.length < 2) {
            return ExecutionResult.error(
              'Polyline requires at least two points',
            );
          }

          GeoPolyLine polyLine;
          try {
            polyLine = GeoPolyLine.fromDependencies(
              id: context.generateId('polyline'),
              label: providedLabel.isNotEmpty
                  ? providedLabel
                  : context.resolveLabel(_nextPolyLineLabel),
              points: points,
            );
          } on ArgumentError catch (error) {
            final message = error.message is String
                ? error.message as String
                : error.toString();
            return ExecutionResult.error(message);
          }

          context.dagManager.addObject(polyLine, polyLine.dependencies);

          return ExecutionResult.successful(
            objectId: polyLine.id,
            message: 'Created ${polyLine.label}',
            object: polyLine,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'extendpolyline',
        description: 'Extend an existing polyline with another point',
        aliases: const ['extendPolyLine'],
        schema: CommandSchema(
          description: 'Extend polyline',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPolyLine},
              description: 'Polyline to extend',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'New point',
            ),
          ],
          argumentHints: const [
            'Select polyline to extend',
            'Select new point',
          ],
        ),
        executor: (context, arguments) async {
          final polyLine = arguments[0] as GeoPolyLine;
          final newPoint = arguments[1] as GeoPoint;

          final resolvedPoints = <GeoPoint>[];
          for (final dependencyId in polyLine.dependencies) {
            final candidate = context.dagManager.getObject(dependencyId);
            if (candidate is GeoPoint) {
              resolvedPoints.add(candidate);
              continue;
            }
            return ExecutionResult.error(
              'Unable to resolve point dependency $dependencyId',
            );
          }

          resolvedPoints.add(newPoint);

          GeoPolyLine next;
          try {
            next = GeoPolyLine.fromDependencies(
              id: polyLine.id,
              label: polyLine.label,
              points: resolvedPoints,
              visible: polyLine.visible,
              style: polyLine.style,
              styleOverrides: polyLine.styleOverrides,
              color: polyLine.style.strokeColor,
            );
          } on ArgumentError catch (error) {
            final message = error.message is String
                ? error.message as String
                : error.toString();
            return ExecutionResult.error(message);
          }

          context.dagManager.replaceObjectWithDependencies(
            polyLine.id,
            next,
            next.dependencies,
          );

          return ExecutionResult.successful(
            objectId: next.id,
            message: 'Extended ${polyLine.label}',
            object: next,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'polyarcgon',
        description: 'Create a closed poly-arc from sequential points',
        aliases: const ['polyArcGon'],
        schema: CommandSchema(
          description: 'Closed poly-arc chain',
          patterns: _polyArcGonPointPatterns(),
          argumentHints: const [
            'Select start point',
            'Select control point',
            'Select end point',
            'Select control point',
            'Select end point (close to start)',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          if (arguments.length < 4) {
            return ExecutionResult.error(
              'Poly-arc-gon requires at least four points',
            );
          }

          final rawArguments = List<dynamic>.from(arguments);
          String providedLabel = '';
          if (rawArguments.isNotEmpty && rawArguments.last is String) {
            providedLabel = (rawArguments.removeLast() as String).trim();
          }

          final points = <GeoPoint>[];
          for (final argument in rawArguments) {
            if (argument is! GeoPoint) {
              return ExecutionResult.error(
                'Poly-arc-gon expects only point arguments',
              );
            }
            points.add(argument);
          }

          if (points.length < 4) {
            return ExecutionResult.error(
              'Poly-arc-gon requires at least four points',
            );
          }

          if (!points.length.isOdd) {
            return ExecutionResult.error(
              'Poly-arc-gon point count must be odd; received ${points.length}',
            );
          }

          GeoPolyArcGon<GeoArc> polyArcGon;
          try {
            polyArcGon = GeoPolyArcGon.fromDependencies(
              id: context.generateId('polyarcgon'),
              label: providedLabel.isNotEmpty
                  ? providedLabel
                  : context.resolveLabel(_nextPolyArcGonLabel),
              points: points,
            );
          } on ArgumentError catch (error) {
            final message = error.message is String
                ? error.message as String
                : error.toString();
            return ExecutionResult.error(message);
          }

          context.dagManager.addObject(polyArcGon, polyArcGon.dependencies);

          return ExecutionResult.successful(
            objectId: polyArcGon.id,
            message: 'Created ${polyArcGon.label}',
            object: polyArcGon,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'extendpolyarcgon',
        description: 'Extend an existing poly-arc-gon with another arc',
        aliases: const ['extendPolyArcGon'],
        schema: CommandSchema(
          description: 'Extend poly-arc-gon',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPolyArcGon},
              description: 'Poly-arc-gon to extend',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Control point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'End point (close to start)',
            ),
          ],
          argumentHints: const [
            'Select poly-arc-gon to extend',
            'Select control point',
            'Select end point',
          ],
        ),
        executor: (context, arguments) async {
          final polyArcGon = arguments[0] as GeoPolyArcGon;
          final controlPoint = arguments[1] as GeoPoint;
          final endPoint = arguments[2] as GeoPoint;

          final resolvedPoints = <GeoPoint>[];
          for (final dependencyId in polyArcGon.dependencies) {
            final candidate = context.dagManager.getObject(dependencyId);
            if (candidate is GeoPoint) {
              resolvedPoints.add(candidate);
              continue;
            }
            return ExecutionResult.error(
              'Unable to resolve point dependency $dependencyId',
            );
          }

          if (resolvedPoints.isEmpty) {
            return ExecutionResult.error(
              'Cannot resolve dependencies for poly-arc-gon',
            );
          }

          resolvedPoints.removeLast();
          resolvedPoints.addAll([controlPoint, endPoint]);

          GeoPolyArcGon<GeoArc> next;
          try {
            next = GeoPolyArcGon.fromDependencies(
              id: polyArcGon.id,
              label: polyArcGon.label,
              points: resolvedPoints,
              visible: polyArcGon.visible,
              style: polyArcGon.style,
              styleOverrides: polyArcGon.styleOverrides,
              color: polyArcGon.style.strokeColor,
            );
          } on ArgumentError catch (error) {
            final message = error.message is String
                ? error.message as String
                : error.toString();
            return ExecutionResult.error(message);
          }

          context.dagManager.replaceObjectWithDependencies(
            polyArcGon.id,
            next,
            next.dependencies,
          );

          return ExecutionResult.successful(
            objectId: next.id,
            message: 'Extended ${polyArcGon.label}',
            object: next,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'midpoint',
        description: 'Create midpoint from points or a segment',
        schema: CommandSchema(
          description: 'Midpoint between two points or a segment',
          patterns: [
            [
              TypeConstraint.geometry(
                allowedTypes: {GeoPoint},
                description: 'First point',
              ),
              TypeConstraint.geometry(
                allowedTypes: {GeoPoint},
                description: 'Second point',
              ),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
            [
              TypeConstraint.geometry(
                allowedTypes: {GeoSegment},
                description: 'Segment reference',
              ),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
          ],
        ),
        executor: (context, arguments) async {
          if (arguments.isEmpty) {
            return ExecutionResult.error('Midpoint requires geometry input');
          }

          GeoPoint p1;
          GeoPoint p2;

          String extractLabel(int index) {
            if (arguments.length > index && arguments[index] is String) {
              return (arguments[index] as String).trim();
            }
            return '';
          }

          String providedLabel = '';

          if (arguments[0] is GeoSegment) {
            final segment = arguments[0] as GeoSegment;
            providedLabel = extractLabel(1);

            GeoPoint resolveSegmentPoint(int index, GeoPoint fallback) {
              if (segment.dependencies.length > index) {
                final candidate = context.dagManager.getObject(
                  segment.dependencies[index],
                );
                if (candidate is GeoPoint) {
                  return candidate;
                }
              }
              return fallback;
            }

            p1 = resolveSegmentPoint(0, segment.startPoint);
            p2 = resolveSegmentPoint(1, segment.endPoint);
          } else {
            p1 = arguments[0] as GeoPoint;
            p2 = arguments[1] as GeoPoint;
            providedLabel = extractLabel(2);
          }

          if (p1.id == p2.id) {
            return ExecutionResult.error(
              'Midpoint requires two distinct points',
            );
          }

          final midpoint = GeoMidpoint.fromDependencies(
            id: context.generateId('midpoint'),
            label: providedLabel.isNotEmpty
                ? providedLabel
                : context.resolveLabel(_nextMidpointLabel),
            points: [p1, p2],
          );

          context.dagManager.addObject(midpoint, [p1.id, p2.id]);

          return ExecutionResult.successful(
            objectId: midpoint.id,
            message: 'Created ${midpoint.label}',
            object: midpoint,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'perpendicular',
        description: 'Create perpendicular line through a point',
        aliases: const ['perp'],
        schema: CommandSchema(
          description: 'Perpendicular line',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoLine},
              description: 'Reference line',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Point on perpendicular line',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select reference line',
            'Select point',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final reference = arguments[0] as GeoLine;
          final point = arguments[1] as GeoPoint;
          final providedLabel = arguments.length >= 3 && arguments[2] is String
              ? (arguments[2] as String).trim()
              : '';
          final perpendicular = GeoPerpendicularLine.fromDependencies(
            id: context.generateId('line'),
            label: providedLabel.isNotEmpty
                ? providedLabel
                : context.resolveLabel(_nextPerpendicularLabel),
            dependencies: [reference, point],
          );

          context.dagManager.addObject(perpendicular, [reference.id, point.id]);

          return ExecutionResult.successful(
            objectId: perpendicular.id,
            message: 'Created ${perpendicular.label}',
            object: perpendicular,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'parallel',
        description: 'Create parallel line through a point',
        aliases: const ['para'],
        schema: CommandSchema(
          description: 'Parallel line',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoLine},
              description: 'Reference line',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Point on parallel line',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select reference line',
            'Select point',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final reference = arguments[0] as GeoLine;
          final point = arguments[1] as GeoPoint;
          final providedLabel = arguments.length >= 3 && arguments[2] is String
              ? (arguments[2] as String).trim()
              : '';
          final parallel = GeoParallelLine.fromDependencies(
            id: context.generateId('line'),
            label: providedLabel.isNotEmpty
                ? providedLabel
                : context.resolveLabel(_nextParallelLabel),
            dependencies: [reference, point],
          );

          context.dagManager.addObject(parallel, [reference.id, point.id]);

          return ExecutionResult.successful(
            objectId: parallel.id,
            message: 'Created ${parallel.label}',
            object: parallel,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'perpbisector',
        description: 'Create perpendicular bisector of segment',
        aliases: const ['perpbis'],
        schema: CommandSchema(
          description: 'Perpendicular bisector',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'First point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Second point',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select first point',
            'Select second point',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final p1 = arguments[0] as GeoPoint;
          final p2 = arguments[1] as GeoPoint;
          final providedLabel = arguments.length >= 3 && arguments[2] is String
              ? (arguments[2] as String).trim()
              : '';
          final bisector = GeoPerpendicularBisector.fromDependencies(
            id: context.generateId('line'),
            label: providedLabel.isNotEmpty
                ? providedLabel
                : context.resolveLabel(_nextPerpBisectorLabel),
            points: [p1, p2],
          );

          context.dagManager.addObject(bisector, [p1.id, p2.id]);

          return ExecutionResult.successful(
            objectId: bisector.id,
            message: 'Created ${bisector.label}',
            object: bisector,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'tangent',
        description:
            'Construct tangent lines between a point and a circle or between two circles',
        schema: CommandSchema(
          description: 'Tangent lines',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint, GeoCircle},
              description: 'First object',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint, GeoCircle},
              description: 'Second object',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select point or circle',
            'Select point or circle',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final first = arguments[0] as GeometryObject;
          final second = arguments[1] as GeometryObject;
          final providedLabel = arguments.length >= 3 && arguments[2] is String
              ? (arguments[2] as String).trim()
              : '';
          final label = providedLabel.isNotEmpty
              ? providedLabel
              : context.resolveLabel(_nextTangentLabel);

          GeoTangent tangent;
          try {
            tangent = GeoTangent.constructFromObjects(
              id: context.generateId('tangent'),
              label: label,
              first: first,
              second: second,
            );
          } on ArgumentError catch (e) {
            final message = e.message;
            return ExecutionResult.error(
              message is String && message.isNotEmpty ? message : e.toString(),
            );
          }

          context.dagManager.addObject(tangent, tangent.dependencies);

          final count = tangent.objects.length;
          final message = count == 0
              ? 'Created ${tangent.label} (no tangents yet)'
              : 'Created ${tangent.label} with $count tangent${count == 1 ? '' : 's'}';

          return ExecutionResult.successful(
            objectId: tangent.id,
            message: message,
            object: tangent,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'reflect',
        description: 'Reflect an object about a mirror line, circle, or point',
        schema: CommandSchema(
          description: 'Reflect object using inversion',
          patterns: <List<TypeConstraint>>[
            <TypeConstraint>[
              TypeConstraint.geometry(
                allowedTypes: {
                  SimpleGeometryObject,
                  GeoSegment,
                  GeoArc,
                  UnionGeometryObjectList,
                },
                description: 'Object to transform',
              ),
              TypeConstraint.geometry(
                allowedTypes: {GeoInverse},
                description: 'Existing reflection transform',
              ),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
            <TypeConstraint>[
              TypeConstraint.geometry(
                allowedTypes: {
                  SimpleGeometryObject,
                  GeoSegment,
                  GeoArc,
                  UnionGeometryObjectList,
                },
                description: 'Object to transform',
              ),
              TypeConstraint.geometry(
                allowedTypes: {GeoLine, GeoCircle, GeoPoint},
                description: 'Mirror line/circle/point',
              ),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
          ],
          argumentHints: [
            'Select object to reflect',
            'Select mirror or transform',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final subject = arguments[0] as GeometryObject;
          final label = _extractTrailingLabel(arguments);
          final transform = _resolveInverseTransform(context, arguments[1]);
          if (transform == null) {
            return ExecutionResult.error(
              'Reflect requires a mirror line, circle, point, or existing GeoInverse transform.',
            );
          }

          final transformed = _createTransformedGeometry(
            context: context,
            subject: subject,
            transform: transform,
            providedLabel: label,
          );

          if (transformed == null) {
            return ExecutionResult.error(
              'Reflect does not support transforming ${subject.runtimeType}.',
            );
          }

          context.dagManager.addObject(transformed, transformed.dependencies);

          return ExecutionResult.successful(
            objectId: transformed.id,
            message:
                'Reflected ${_displayName(subject)} to ${_displayName(transformed)}',
            object: transformed,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'rotate',
        description: 'Rotate an object around a center by an angle (degrees)',
        schema: CommandSchema(
          description: 'Rotate object',
          patterns: <List<TypeConstraint>>[
            <TypeConstraint>[
              TypeConstraint.geometry(
                allowedTypes: {
                  SimpleGeometryObject,
                  GeoSegment,
                  GeoArc,
                  UnionGeometryObjectList,
                },
                description: 'Object to transform',
              ),
              TypeConstraint.geometry(
                allowedTypes: {GeoRotate},
                description: 'Existing rotation transform',
              ),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
            <TypeConstraint>[
              TypeConstraint.geometry(
                allowedTypes: {
                  SimpleGeometryObject,
                  GeoSegment,
                  GeoArc,
                  UnionGeometryObjectList,
                },
                description: 'Object to transform',
              ),
              TypeConstraint.geometry(
                allowedTypes: {GeoPoint},
                description: 'Center of rotation',
              ),
              TypeConstraint.numeric(description: 'Angle in degrees'),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
          ],
          argumentHints: [
            'Select object to rotate',
            'Select center or rotation transform',
            'Enter angle in degrees (skip if using transform)',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final subject = arguments[0] as GeometryObject;
          final label = _extractTrailingLabel(arguments);

          GeoRotate transform;
          if (arguments[1] is GeoRotate) {
            transform = arguments[1] as GeoRotate;
          } else {
            final center = arguments[1] as GeoPoint;
            final angle = arguments[2] as num;
            transform = _createRotationTransform(
              context: context,
              center: center,
              angleRadians: _degreesToRadians(angle.toDouble()),
            );
          }

          final transformed = _createTransformedGeometry(
            context: context,
            subject: subject,
            transform: transform,
            providedLabel: label,
          );

          if (transformed == null) {
            return ExecutionResult.error(
              'Rotate does not support transforming ${subject.runtimeType}.',
            );
          }

          context.dagManager.addObject(transformed, transformed.dependencies);

          return ExecutionResult.successful(
            objectId: transformed.id,
            message:
                'Rotated ${_displayName(subject)} to ${_displayName(transformed)}',
            object: transformed,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'dilate',
        description: 'Scale an object from a center by a factor',
        schema: CommandSchema(
          description: 'Dilate object',
          patterns: <List<TypeConstraint>>[
            <TypeConstraint>[
              TypeConstraint.geometry(
                allowedTypes: {
                  SimpleGeometryObject,
                  GeoSegment,
                  GeoArc,
                  UnionGeometryObjectList,
                },
                description: 'Object to transform',
              ),
              TypeConstraint.geometry(
                allowedTypes: {GeoDilate},
                description: 'Existing dilation transform',
              ),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
            <TypeConstraint>[
              TypeConstraint.geometry(
                allowedTypes: {
                  SimpleGeometryObject,
                  GeoSegment,
                  GeoArc,
                  UnionGeometryObjectList,
                },
                description: 'Object to transform',
              ),
              TypeConstraint.geometry(
                allowedTypes: {GeoPoint},
                description: 'Center of dilation',
              ),
              TypeConstraint.numeric(description: 'Scale factor'),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
          ],
          argumentHints: [
            'Select object to dilate',
            'Select center or dilation transform',
            'Enter scale factor (skip if using transform)',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final subject = arguments[0] as GeometryObject;
          final label = _extractTrailingLabel(arguments);

          GeoDilate transform;
          if (arguments[1] is GeoDilate) {
            transform = arguments[1] as GeoDilate;
          } else {
            final center = arguments[1] as GeoPoint;
            final factor = arguments[2] as num;
            transform = _createDilateTransform(
              context: context,
              center: center,
              factor: factor.toDouble(),
            );
          }

          final transformed = _createTransformedGeometry(
            context: context,
            subject: subject,
            transform: transform,
            providedLabel: label,
          );

          if (transformed == null) {
            return ExecutionResult.error(
              'Dilate does not support transforming ${subject.runtimeType}.',
            );
          }

          context.dagManager.addObject(transformed, transformed.dependencies);

          return ExecutionResult.successful(
            objectId: transformed.id,
            message:
                'Dilated ${_displayName(subject)} to ${_displayName(transformed)}',
            object: transformed,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'translate',
        description: 'Translate an object by a vector defined by a segment',
        schema: CommandSchema(
          description: 'Translate object',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {
                SimpleGeometryObject,
                GeoSegment,
                GeoArc,
                UnionGeometryObjectList,
              },
              description: 'Object to translate',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoSegment},
              description: 'Segment defining translation vector',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select object to translate',
            'Select segment (defines vector)',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final subject = arguments[0] as GeometryObject;
          final segment = arguments[1] as GeoSegment;
          final label = _extractTrailingLabel(arguments);

          // Get the two endpoints of the segment from dependencies
          if (segment.dependencies.length < 2) {
            return ExecutionResult.error(
              'Segment must have at least 2 dependencies',
            );
          }

          final startPoint = context.dagManager.getObject(segment.dependencies[0]);
          final endPoint = context.dagManager.getObject(segment.dependencies[1]);

          if (startPoint == null || endPoint == null) {
            return ExecutionResult.error(
              'Unable to resolve segment endpoints',
            );
          }

          if (startPoint is! GeoPoint || endPoint is! GeoPoint) {
            return ExecutionResult.error(
              'Segment endpoints must be points',
            );
          }

          // Calculate translation vector
          final dx = endPoint.x - startPoint.x;
          final dy = endPoint.y - startPoint.y;

          // Create translated object
          final transformed = TransformationEngine.translate(
            subject,
            dx,
            dy,
            newLabel: label.isNotEmpty
                ? label
                : '${subject.label}\'',
            newId: context.generateId('translate'),
            dependencies: [subject.id, segment.id],
          );

          context.dagManager.addObject(
            transformed,
            [subject.id, segment.id],
          );

          return ExecutionResult.successful(
            message: 'Translated ${_displayName(subject)} by vector from ${_displayName(startPoint)} to ${_displayName(endPoint)}',
            object: transformed,
          );
        },
      ),
    );

    _register(
      CommandDefinition(
        name: 'intersection',
        description: 'Find intersection of simple objects',
        schema: CommandSchema(
          description: 'Intersection',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoLine, GeoCircle, GeoPoint},
              description: 'First object',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoLine, GeoCircle, GeoPoint},
              description: 'Second object',
            ),
          ],
          argumentHints: ['Select first object', 'Select second object'],
        ),
        implemented: false,
        executor: (context, arguments) async {
          return ExecutionResult.error('Intersection is not implemented');
        },
      ),
    );
  }

  List<List<TypeConstraint>> _polyArcPointPatterns({int maxSegments = 8}) {
    final patterns = <List<TypeConstraint>>[];
    for (var segmentIndex = 0; segmentIndex < maxSegments; segmentIndex++) {
      final pointCount = 3 + (segmentIndex * 2);
      final pattern = <TypeConstraint>[];
      for (var i = 0; i < pointCount; i++) {
        late final String description;
        if (i == 0) {
          description = 'Start point';
        } else if (i.isOdd) {
          description = 'Control point';
        } else {
          description = 'End point';
        }
        pattern.add(
          TypeConstraint.geometry(
            allowedTypes: {GeoPoint},
            description: description,
          ),
        );
      }
      pattern.add(TypeConstraint.text(description: 'Label', optional: true));
      patterns.add(List<TypeConstraint>.unmodifiable(pattern));
    }
    return List<List<TypeConstraint>>.unmodifiable(patterns);
  }

  List<List<TypeConstraint>> _polygonPointPatterns({int maxVertices = 20}) {
    final patterns = <List<TypeConstraint>>[];
    for (var vertexCount = 3; vertexCount <= maxVertices; vertexCount++) {
      final pattern = <TypeConstraint>[];
      for (var i = 0; i < vertexCount; i++) {
        pattern.add(
          TypeConstraint.geometry(
            allowedTypes: {GeoPoint},
            description: i == 0 ? 'First vertex' : 'Vertex ${i + 1}',
          ),
        );
      }
      pattern.add(TypeConstraint.text(description: 'Label', optional: true));
      patterns.add(List<TypeConstraint>.unmodifiable(pattern));
    }
    return List<List<TypeConstraint>>.unmodifiable(patterns);
  }

  List<List<TypeConstraint>> _polyLinePointPatterns({int maxVertices = 20}) {
    final patterns = <List<TypeConstraint>>[];
    for (var vertexCount = 2; vertexCount <= maxVertices; vertexCount++) {
      final pattern = <TypeConstraint>[];
      for (var i = 0; i < vertexCount; i++) {
        pattern.add(
          TypeConstraint.geometry(
            allowedTypes: {GeoPoint},
            description: i == 0 ? 'Start point' : 'Point ${i + 1}',
          ),
        );
      }
      pattern.add(TypeConstraint.text(description: 'Label', optional: true));
      patterns.add(List<TypeConstraint>.unmodifiable(pattern));
    }
    return List<List<TypeConstraint>>.unmodifiable(patterns);
  }

  List<List<TypeConstraint>> _polyArcGonPointPatterns({int maxSegments = 8}) {
    final patterns = <List<TypeConstraint>>[];
    for (var segmentIndex = 1; segmentIndex < maxSegments; segmentIndex++) {
      final pointCount = 3 + (segmentIndex * 2);
      final pattern = <TypeConstraint>[];
      for (var i = 0; i < pointCount; i++) {
        late final String description;
        if (i == 0) {
          description = 'Start point';
        } else if (i.isOdd) {
          description = 'Control point';
        } else {
          description = 'End point';
        }
        pattern.add(
          TypeConstraint.geometry(
            allowedTypes: {GeoPoint},
            description: description,
          ),
        );
      }
      pattern.add(TypeConstraint.text(description: 'Label', optional: true));
      patterns.add(List<TypeConstraint>.unmodifiable(pattern));
    }
    return List<List<TypeConstraint>>.unmodifiable(patterns);
  }

  String _extractTrailingLabel(List<dynamic> arguments) {
    if (arguments.isNotEmpty && arguments.last is String) {
      return (arguments.last as String).trim();
    }
    return '';
  }

  String _displayName(GeometryObject object) {
    return object.label.isNotEmpty ? object.label : object.id;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

  GeoInverse? _resolveInverseTransform(
    CommandExecutionContext context,
    dynamic candidate,
  ) {
    if (candidate is GeoInverse) {
      return candidate;
    }

    if (candidate is GeoLine) {
      final operatorMv = constructLineReflectionOperator(candidate.multivector);
      return _registerInverseTransform(
        context: context,
        operator: operatorMv,
        dependencies: [candidate.id],
        power: 1,
      );
    }

    if (candidate is GeoCircle) {
      final operatorMv = constructCircleReflectionOperator(
        candidate.multivector,
      );
      final radius = candidate.radius;
      return _registerInverseTransform(
        context: context,
        operator: operatorMv,
        dependencies: [candidate.id],
        power: radius * radius,
      );
    }

    if (candidate is GeoPoint) {
      final operatorMv = constructPointReflectionOperator(
        candidate.multivector,
      );
      return _registerInverseTransform(
        context: context,
        operator: operatorMv,
        dependencies: [candidate.id],
        power: 1,
      );
    }

    return null;
  }

  GeoInverse _registerInverseTransform({
    required CommandExecutionContext context,
    required Multivector operator,
    required List<String> dependencies,
    double power = 1,
  }) {
    final inverse = GeoInverse(
      id: context.generateId('inverse'),
      label: _nextInverseLabel(),
      dependencies: dependencies,
      multivector: operator,
      centerPointId: '',
      power: power,
    );

    context.dagManager.addObject(inverse, dependencies);
    return inverse;
  }

  GeoRotate _createRotationTransform({
    required CommandExecutionContext context,
    required GeoPoint center,
    required double angleRadians,
  }) {
    final rotor = constructRotationOperator(center.multivector, angleRadians);
    final rotate = GeoRotate(
      id: context.generateId('rotate'),
      label: _nextRotateLabel(),
      dependencies: [center.id],
      multivector: rotor,
      centerPointId: center.id,
      angle: angleRadians,
    );

    context.dagManager.addObject(rotate, [center.id]);
    return rotate;
  }

  GeoDilate _createDilateTransform({
    required CommandExecutionContext context,
    required GeoPoint center,
    required double factor,
  }) {
    final dilator = constructDilationOperator(center.multivector, factor);
    final dilate = GeoDilate(
      id: context.generateId('dilate'),
      label: _nextDilateLabel(),
      dependencies: [center.id],
      multivector: dilator,
      centerPointId: center.id,
      factor: factor,
    );

    context.dagManager.addObject(dilate, [center.id]);
    return dilate;
  }

  GeometryObject? _createTransformedGeometry({
    required CommandExecutionContext context,
    required GeometryObject subject,
    required GeoTrans transform,
    required String providedLabel,
  }) {
    if (subject is GeoPoint) {
      final result = TransformationEngine.transformSimple(
        source: subject,
        transform: transform,
      );

      if (result.kind != SimpleTransformKind.point) {
        return null;
      }

      final label = _resolveLabel(context, providedLabel, _nextPointLabel);
      return GeoTransPoint(
        id: context.generateId('point'),
        label: label,
        dependencies: [subject.id, transform.id],
        multivector: result.multivector,
        sourcePointId: subject.id,
        transformId: transform.id,
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );
    }

    if (subject is GeoLine) {
      final result = TransformationEngine.transformSimple(
        source: subject,
        transform: transform,
      );

      switch (result.kind) {
        case SimpleTransformKind.line:
          final label = _resolveLabel(context, providedLabel, _nextLineLabel);
          return GeoTransLine(
            id: context.generateId('line'),
            label: label,
            dependencies: [subject.id, transform.id],
            multivector: result.multivector,
            sourceObjectId: subject.id,
            transformId: transform.id,
            visible: subject.visible,
            styleOverrides: subject.styleOverrides,
          );
        case SimpleTransformKind.circle:
          final label = _resolveLabel(context, providedLabel, _nextCircleLabel);
          return GeoTransCircle(
            id: context.generateId('circle'),
            label: label,
            dependencies: [subject.id, transform.id],
            multivector: result.multivector,
            sourceObjectId: subject.id,
            transformId: transform.id,
            visible: subject.visible,
            styleOverrides: subject.styleOverrides,
          );
        default:
          return null;
      }
    }

    if (subject is GeoCircle) {
      final result = TransformationEngine.transformSimple(
        source: subject,
        transform: transform,
      );

      switch (result.kind) {
        case SimpleTransformKind.circle:
          final label = _resolveLabel(context, providedLabel, _nextCircleLabel);
          return GeoTransCircle(
            id: context.generateId('circle'),
            label: label,
            dependencies: [subject.id, transform.id],
            multivector: result.multivector,
            sourceObjectId: subject.id,
            transformId: transform.id,
            visible: subject.visible,
            styleOverrides: subject.styleOverrides,
          );
        case SimpleTransformKind.line:
          final label = _resolveLabel(context, providedLabel, _nextLineLabel);
          return GeoTransLine(
            id: context.generateId('line'),
            label: label,
            dependencies: [subject.id, transform.id],
            multivector: result.multivector,
            sourceObjectId: subject.id,
            transformId: transform.id,
            visible: subject.visible,
            styleOverrides: subject.styleOverrides,
          );
        default:
          return null;
      }
    }

    if (subject is GeoSegment) {
      final result = TransformationEngine.transformComplex(
        source: subject,
        transform: transform,
      );

      switch (result.kind) {
        case ComplexTransformKind.segment:
          final label = _resolveLabel(
            context,
            providedLabel,
            _nextSegmentLabel,
          );
          return GeoTransSegment(
            id: context.generateId('segment'),
            label: label,
            dependencies: [subject.id, transform.id],
            boundary: result.boundary,
            sourceObjectId: subject.id,
            transformId: transform.id,
            visible: subject.visible,
            styleOverrides: subject.styleOverrides,
          );
        case ComplexTransformKind.arc:
          final label = _resolveLabel(
            context,
            providedLabel,
            _nextArcThreeLabel,
          );
          return GeoTransArc(
            id: context.generateId('arc'),
            label: label,
            dependencies: [subject.id, transform.id],
            boundary: result.boundary,
            controlPoint: result.controlPoint,
            sourceObjectId: subject.id,
            transformId: transform.id,
            visible: subject.visible,
            styleOverrides: subject.styleOverrides,
          );
        case ComplexTransformKind.unknown:
          return null;
      }
    }

    if (subject is GeoArc) {
      final result = TransformationEngine.transformComplex(
        source: subject,
        transform: transform,
      );

      switch (result.kind) {
        case ComplexTransformKind.arc:
          final label = _resolveLabel(
            context,
            providedLabel,
            _nextArcThreeLabel,
          );
          return GeoTransArc(
            id: context.generateId('arc'),
            label: label,
            dependencies: [subject.id, transform.id],
            boundary: result.boundary,
            controlPoint: result.controlPoint,
            sourceObjectId: subject.id,
            transformId: transform.id,
            visible: subject.visible,
            styleOverrides: subject.styleOverrides,
          );
        case ComplexTransformKind.segment:
          final label = _resolveLabel(
            context,
            providedLabel,
            _nextSegmentLabel,
          );
          return GeoTransSegment(
            id: context.generateId('segment'),
            label: label,
            dependencies: [subject.id, transform.id],
            boundary: result.boundary,
            sourceObjectId: subject.id,
            transformId: transform.id,
            visible: subject.visible,
            styleOverrides: subject.styleOverrides,
          );
        case ComplexTransformKind.unknown:
          return null;
      }
    }

    if (subject is UnionGeometryObjectList) {
      final label = _resolveLabel(context, providedLabel, _nextUnionLabel);
      final elements = _transformUnionElements(subject, transform);
      return GeoTransUnionGeometryObjectList(
        id: context.generateId('union'),
        label: label,
        dependencies: [subject.id, transform.id],
        elements: elements,
        sourceObjectId: subject.id,
        transformId: transform.id,
        vertexCountValue: subject.vertexCount,
        areaValue: subject.area(),
        perimeterValue: subject.perimeter(),
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );
    }

    return null;
  }

  List<GeometryObject> _transformUnionElements(
    UnionGeometryObjectList source,
    GeoTrans transform,
  ) {
    final transformedElements = <GeometryObject>[];

    for (final element in source.elements.cast<GeometryObject>()) {
      if (element is SimpleGeometryObject) {
        final simpleResult = TransformationEngine.transformSimple(
          source: element,
          transform: transform,
        );

        switch (simpleResult.kind) {
          case SimpleTransformKind.point:
            transformedElements.add(
              GeoTransPoint(
                id: '${element.id}_${transform.id}_point',
                label: element.label,
                dependencies: element.dependencies,
                multivector: simpleResult.multivector,
                sourcePointId: element.id,
                transformId: transform.id,
                visible: element.visible,
                styleOverrides: element.styleOverrides,
              ),
            );
            break;
          default:
            transformedElements.add(element);
        }
        continue;
      }

      if (element is GeoSegment || element is GeoArc) {
        final complexResult = TransformationEngine.transformComplex(
          source: element as ComplexGeometryObject,
          transform: transform,
        );
        final transformedId = '${element.id}_${transform.id}_trans';

        switch (complexResult.kind) {
          case ComplexTransformKind.segment:
            transformedElements.add(
              GeoTransSegment(
                id: transformedId,
                label: element.label,
                dependencies: null,
                boundary: complexResult.boundary,
                sourceObjectId: element.id,
                transformId: transform.id,
                visible: element.visible,
                styleOverrides: element.styleOverrides,
              ),
            );
            break;
          case ComplexTransformKind.arc:
            transformedElements.add(
              GeoTransArc(
                id: transformedId,
                label: element.label,
                dependencies: null,
                boundary: complexResult.boundary,
                controlPoint: complexResult.controlPoint,
                sourceObjectId: element.id,
                transformId: transform.id,
                visible: element.visible,
                styleOverrides: element.styleOverrides,
              ),
            );
            break;
          case ComplexTransformKind.unknown:
            transformedElements.add(element);
            break;
        }
        continue;
      }

      transformedElements.add(element);
    }

    return transformedElements;
  }

  String _resolveLabel(
    CommandExecutionContext context,
    String providedLabel,
    String Function() fallback,
  ) {
    final trimmed = providedLabel.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return context.resolveLabel(fallback);
  }

  void _register(CommandDefinition definition) {
    final canonicalName = definition.name.toLowerCase();
    _byName[canonicalName] = definition;
    _definitions.add(definition);
    for (final alias in definition.aliases) {
      _byName[alias.toLowerCase()] = definition;
    }
  }

  CommandDefinition? definitionByName(String name) {
    return _byName[name.toLowerCase()];
  }

  Iterable<String> commandNames() => _byName.keys;

  Iterable<CommandDefinition> get allDefinitions =>
      UnmodifiableListView(_definitions);

  CommandSchema? schemaForName(String name) => definitionByName(name)?.schema;

  bool isImplemented(String name) =>
      definitionByName(name)?.implemented ?? false;

  String _nextPointLabel() => 'P${++_pointLabelCounter}';
  String _nextLineLabel() => 'L${++_lineLabelCounter}';
  String _nextSegmentLabel() => 'S${++_segmentLabelCounter}';
  String _nextCircleLabel() => 'C${++_circleLabelCounter}';
  String _nextCircleThreeLabel() => 'C3-${++_circleThreeLabelCounter}';
  String _nextArcThreeLabel() => 'Arc${++_arcThreeLabelCounter}';
  String _nextMidpointLabel() => 'M${++_midpointLabelCounter}';
  String _nextPerpendicularLabel() => 'Perp${++_perpendicularLabelCounter}';
  String _nextParallelLabel() => 'Par${++_parallelLabelCounter}';
  String _nextPerpBisectorLabel() => 'Bis${++_perpBisectorLabelCounter}';
  String _nextTangentLabel() => 'Tan${++_tangentLabelCounter}';
  String _nextInverseLabel() => 'Inv${++_inverseLabelCounter}';
  String _nextRotateLabel() => 'Rot${++_rotateLabelCounter}';
  String _nextDilateLabel() => 'Dil${++_dilateLabelCounter}';
  String _nextUnionLabel() => 'U${++_unionLabelCounter}';
  String _nextTextContent() => 'Text ${++_textLabelCounter}';
  String _nextPolyArcLabel() => 'PolyArc${++_polyArcLabelCounter}';
  String _nextPolygonLabel() => 'Polygon${++_polygonLabelCounter}';
  String _nextPolyLineLabel() => 'PolyLine${++_polyLineLabelCounter}';
  String _nextPolyArcGonLabel() => 'PolyArcGon${++_polyArcGonLabelCounter}';
}
