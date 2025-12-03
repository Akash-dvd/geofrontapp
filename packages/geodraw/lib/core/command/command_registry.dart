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
import '../../models/transforms/geo_trans.dart';
import '../../models/simple/geo_transformed_simple.dart';
import '../../models/simple_lists/geo_tangent.dart';
import '../../models/simple_lists/geo_angle_bisector.dart';
import '../../models/simple_lists/geo_intersection.dart';
import '../../models/complex/complex_geometry_object.dart';
import '../../models/complex/geo_shapes.dart';
import '../../models/complex/geo_shapes_list.dart';
import '../../models/complex/geo_transformed_complex.dart';
import '../../models/text/canvas_text.dart';
import '../../models/transforms/transformation_engine.dart';
import '../label_manager.dart';

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

  void _registerDefaults() {
    // Register core geometry constructors
    _register(
      CommandDefinition(
        name: 'point',
        description: 'Create a free point at coordinates or a glider point on an object',
        schema: CommandSchema(
          description: 'Point (free or glider)',
          patterns: [
            // Pattern 0: Free point with coordinates
            [
              TypeConstraint.numeric(description: 'x-coordinate'),
              TypeConstraint.numeric(description: 'y-coordinate'),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
            // Pattern 1: Glider point on an object
            [
              TypeConstraint.geometry(
                allowedTypes: {
                  GeoLine,
                  GeoCircle,
                  GeoSegment,
                  GeoArc,
                  UnionGeometryObjectList,
                  GenSimpleGeometryObjectList,
                },
                description: 'Object to glide on',
              ),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
          ],
          argumentHints: [
            'Enter x-coordinate or select object',
            'Enter y-coordinate or enter label (optional)',
            'Enter label (optional)',
          ],
        ),
        patternExecutors: [
          // Pattern 0: Free point (x, y)
          (context, arguments) async {
            final x = (arguments[0] as num).toDouble();
            final y = (arguments[1] as num).toDouble();
            final providedLabel = arguments.length >= 3
                ? (arguments[2] as String).trim()
                : '';
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.point,
                  );
            final point = GeoPointer(
              id: label, // In new system: ID = label for user-friendly access
              label: label,
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
          // Pattern 1: Glider point on object
          (context, arguments) async {
            final object = arguments[0] as GeometryObject;
            final providedLabel = arguments.length >= 2
                ? (arguments[1] as String).trim()
                : '';
            
            // Get the object's position for initial placement
            Offset initialPosition;
            if (object is GeoPoint) {
              // Shouldn't happen (filtered out), but handle gracefully
              initialPosition = object.position;
            } else if (object is GeoLine) {
              // For lines, use a point on the line (e.g., closest to origin)
              final lineMv = object.multivector;
              // Project origin onto line
              final origin = constructFreePoint(0, 0);
              final projected = projectPointToLine(origin, lineMv);
              initialPosition = Offset(projected.e1, projected.e2);
            } else if (object is GeoCircle) {
              // For circles, use a point on the circle (e.g., rightmost point)
              final center = getCircleCenter(object.multivector);
              final radius = measureCircleRadius(object.multivector);
              initialPosition = Offset(center.e1 + radius, center.e2);
            } else if (object is GeoSegment) {
              // Use midpoint of segment
              final start = object.startPoint.position;
              final end = object.endPoint.position;
              initialPosition = Offset(
                (start.dx + end.dx) / 2,
                (start.dy + end.dy) / 2,
              );
            } else if (object is GeoArc) {
              // Use midpoint of arc (approximate)
              final start = object.startPoint.position;
              final end = object.endPoint.position;
              initialPosition = Offset(
                (start.dx + end.dx) / 2,
                (start.dy + end.dy) / 2,
              );
            } else if (object is UnionGeometryObjectList) {
              // Use first element's position
              if (object.elements.isNotEmpty) {
                final firstElement = object.elements.first;
                if (firstElement is GeoPoint) {
                  initialPosition = firstElement.position;
                } else {
                  // Fallback to center of bounds
                  final bounds = object.getBounds();
                  initialPosition = bounds.center;
                }
              } else {
                return ExecutionResult.error('Union object has no elements');
              }
            } else if (object is GenSimpleGeometryObjectList) {
              // Use first element's position
              if (object.objects.isNotEmpty) {
                final firstElement = object.objects.first;
                if (firstElement is GeoPoint) {
                  initialPosition = firstElement.position;
                } else {
                  // Fallback to center of bounds
                  final bounds = object.getBounds();
                  initialPosition = bounds.center;
                }
              } else {
                return ExecutionResult.error('List object has no elements');
              }
            } else {
              // Fallback to center of bounds
              final bounds = object.getBounds();
              initialPosition = bounds.center;
            }
            
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.point,
                  );
            final gliderPoint = GeoGliderPoint(
              id: label, // In new system: ID = label
              label: label,
              objectId: object.id,
              initialX: initialPosition.dx,
              initialY: initialPosition.dy,
            );

            context.dagManager.addObject(gliderPoint, [object.id]);

            return ExecutionResult.successful(
              objectId: gliderPoint.id,
              message: 'Created glider point ${gliderPoint.label} on ${object.runtimeType}',
              object: gliderPoint,
            );
          },
        ],
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
          final providedText = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';
          // Text labels can be custom content, so use provided text or generate a simple label
          final textContent = providedText.isNotEmpty
              ? providedText
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.text,
                );

          final text = CanvasText(
            id: context.generateId('text'), // Text objects keep generated IDs
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
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';
          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.line,
                );
          final line = GeoLine2P.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
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
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';

          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.line,
                );
          final segment = GeoSegment2P.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
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
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';
          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.circle,
                );
          final circle = GeoCircle2P.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
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
          final providedLabel = arguments.length >= 4
              ? (arguments[3] as String).trim()
              : '';
          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.circle,
                );
          final circle = GeoCircle3P.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
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
          final providedLabel = arguments.length >= 4
              ? (arguments[3] as String).trim()
              : '';

          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.arc,
                );
          final arc = GeoArc3P.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
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
          final rawArguments = List<dynamic>.from(arguments);
          String providedLabel = '';
          if (rawArguments.isNotEmpty && rawArguments.last is String) {
            providedLabel = (rawArguments.removeLast() as String).trim();
          }

          final points = rawArguments.cast<GeoPoint>().toList();

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
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.polyArc,
                  );
            polyArc = GeoPolyArc.fromDependencies(
              id: label, // In new system: ID = label
              label: label,
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
          final rawArguments = List<dynamic>.from(arguments);
          String providedLabel = '';
          if (rawArguments.isNotEmpty && rawArguments.last is String) {
            providedLabel = (rawArguments.removeLast() as String).trim();
          }

          final points = rawArguments.cast<GeoPoint>().toList();

          if (points.length < 3) {
            return ExecutionResult.error(
              'Polygon requires at least three points',
            );
          }

          GeoPolygon polygon;
          try {
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.polygon,
                  );
            polygon = GeoPolygon.fromDependencies(
              id: label, // In new system: ID = label
              label: label,
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
          final rawArguments = List<dynamic>.from(arguments);
          String providedLabel = '';
          if (rawArguments.isNotEmpty && rawArguments.last is String) {
            providedLabel = (rawArguments.removeLast() as String).trim();
          }

          final points = rawArguments.cast<GeoPoint>().toList();

          if (points.length < 2) {
            return ExecutionResult.error(
              'Polyline requires at least two points',
            );
          }

          GeoPolyLine polyLine;
          try {
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.polyLine,
                  );
            polyLine = GeoPolyLine.fromDependencies(
              id: label, // In new system: ID = label
              label: label,
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
          final rawArguments = List<dynamic>.from(arguments);
          String providedLabel = '';
          if (rawArguments.isNotEmpty && rawArguments.last is String) {
            providedLabel = (rawArguments.removeLast() as String).trim();
          }

          final points = rawArguments.cast<GeoPoint>().toList();

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
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.polyArcGon,
                  );
            polyArcGon = GeoPolyArcGon.fromDependencies(
              id: label, // In new system: ID = label
              label: label,
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
        patternExecutors: [
          // Pattern 0: Two points
          (context, arguments) async {
            final providedLabel = arguments.length >= 3
                ? (arguments[2] as String).trim()
                : '';
            final p1 = arguments[0] as GeoPoint;
            final p2 = arguments[1] as GeoPoint;

            if (p1.id == p2.id) {
              return ExecutionResult.error(
                'Midpoint requires two distinct points',
              );
            }

            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.point,
                  );
            final midpoint = GeoMidpoint.fromDependencies(
              id: label, // In new system: ID = label
              label: label,
              points: [p1, p2],
            );

            context.dagManager.addObject(midpoint, [p1.id, p2.id]);

            return ExecutionResult.successful(
              objectId: midpoint.id,
              message: 'Created ${midpoint.label}',
              object: midpoint,
            );
          },

          // Pattern 1: Segment reference
          (context, arguments) async {
            final segment = arguments[0] as GeoSegment;
            final providedLabel = arguments.length >= 2
                ? (arguments[1] as String).trim()
                : '';

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

            final p1 = resolveSegmentPoint(0, segment.startPoint);
            final p2 = resolveSegmentPoint(1, segment.endPoint);

            if (p1.id == p2.id) {
              return ExecutionResult.error(
                'Midpoint requires two distinct points',
              );
            }

            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.point,
                  );
            final midpoint = GeoMidpoint.fromDependencies(
              id: label, // In new system: ID = label
              label: label,
              points: [p1, p2],
            );

            context.dagManager.addObject(midpoint, [p1.id, p2.id]);

            return ExecutionResult.successful(
              objectId: midpoint.id,
              message: 'Created ${midpoint.label}',
              object: midpoint,
            );
          },
        ],
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
              allowedTypes: {GeoPoint},
              description: 'Point on perpendicular line',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoLine},
              description: 'Reference line',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select point',
            'Select reference line',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final point = arguments[0] as GeoPoint;
          final reference = arguments[1] as GeoLine;
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';
          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.line,
                );
          final perpendicular = GeoPerpendicularLine.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
            dependencies: [point, reference],
          );

          context.dagManager.addObject(perpendicular, [point.id, reference.id]);

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
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';
          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.line,
                );
          final parallel = GeoParallelLine.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
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
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';
          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.line,
                );
          final bisector = GeoPerpendicularBisector.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
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
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';
          // Get container label (SL1, SL2, etc.) if no label provided
          final containerLabel = providedLabel.isNotEmpty
              ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.simpleList,
                );

          GeoTangent tangent;
          try {
            tangent = GeoTangent.constructFromObjects(
              id: containerLabel,
              label: containerLabel,
              first: first,
              second: second,
              dagManager: context.dagManager,
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
        name: 'anglebisector',
        description:
            'Construct angle bisector from three points (vertex at middle) or two lines',
        schema: CommandSchema(
          description: 'Angle bisector',
          patterns: [
            [
              TypeConstraint.geometry(
                allowedTypes: {GeoPoint},
                description: 'First point',
              ),
              TypeConstraint.geometry(
                allowedTypes: {GeoPoint},
                description: 'Vertex point (middle)',
              ),
              TypeConstraint.geometry(
                allowedTypes: {GeoPoint},
                description: 'Second point',
              ),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
            [
              TypeConstraint.geometry(
                allowedTypes: {GeoLine},
                description: 'First line',
              ),
              TypeConstraint.geometry(
                allowedTypes: {GeoLine},
                description: 'Second line',
              ),
              TypeConstraint.text(description: 'Label', optional: true),
            ],
          ],
          argumentHints: [
            'Select three points (or two lines) for angle bisector',
          ],
        ),
        patternExecutors: [
          // Pattern 0: Three points (vertex at middle)
          (context, arguments) async {
            final providedLabel = arguments.length >= 4
                ? (arguments[3] as String).trim()
                : '';
            // GeoAngleBisector3P is a single line, use lowercase labels
            final label = providedLabel.isNotEmpty
                ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.line,
                  );

            final p1 = arguments[0] as GeoPoint;
            final vertex = arguments[1] as GeoPoint;
            final p2 = arguments[2] as GeoPoint;

            try {
              final bisector = GeoAngleBisector3P.fromDependencies(
                id: label,
                label: label,
                dependencies: [p1, vertex, p2],
              );

              context.dagManager.addObject(bisector, bisector.dependencies);

              return ExecutionResult.successful(
                objectId: bisector.id,
                message: 'Created angle bisector ${bisector.label}',
                object: bisector,
              );
            } on ArgumentError catch (e) {
              return ExecutionResult.error(e.message);
            }
          },

          // Pattern 1: Two lines (returns list of 2 bisectors)
          (context, arguments) async {
            final providedLabel = arguments.length >= 3
                ? (arguments[2] as String).trim()
                : '';
            // Get container label (SL1, SL2, etc.) if no label provided
            final containerLabel = providedLabel.isNotEmpty
                ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.simpleList,
                  );

            final line1 = arguments[0] as GeoLine;
            final line2 = arguments[1] as GeoLine;

            try {
              final bisectors = GeoAngleBisector2L.constructFromLines(
                id: containerLabel,
                label: containerLabel,
                line1: line1,
                line2: line2,
                dagManager: context.dagManager,
              );

              context.dagManager.addObject(bisectors, bisectors.dependencies);

              final count = bisectors.objects.length;
              final message = count == 0
                  ? 'Created ${bisectors.label} (no bisectors yet)'
                  : 'Created ${bisectors.label} with $count bisector${count == 1 ? '' : 's'}';

              return ExecutionResult.successful(
                objectId: bisectors.id,
                message: message,
                object: bisectors,
              );
            } on ArgumentError catch (e) {
              return ExecutionResult.error(e.message);
            }
          },
        ],
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
        patternExecutors: [
          // Pattern 0: Object + existing GeoInverse transform
          (context, arguments) async {
            final subject = arguments[0] as GeometryObject;
            final label = _extractTrailingLabel(arguments);
            final transform = arguments[1] as GeoInverse;

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

          // Pattern 1: Object + mirror line/circle/point
          (context, arguments) async {
            debugPrint('[Reflect Command] Pattern 1: Object + mirror');
            final subject = arguments[0] as GeometryObject;
            final mirror = arguments[1] as GeometryObject;
            debugPrint('[Reflect Command] Subject: ${subject.runtimeType} (${subject.id})');
            debugPrint('[Reflect Command] Mirror: ${mirror.runtimeType} (${mirror.id})');
            
            final label = _extractTrailingLabel(arguments);
            debugPrint('[Reflect Command] Resolving inverse transform from mirror...');
            final transform = _resolveInverseTransform(context, arguments[1]);
            if (transform == null) {
              debugPrint('[Reflect Command] ❌ Failed to resolve inverse transform');
              return ExecutionResult.error(
                'Reflect requires a mirror line, circle, or point.',
              );
            }
            debugPrint('[Reflect Command] ✅ Resolved transform: ${transform.runtimeType} (${transform.id})');

            debugPrint('[Reflect Command] Creating transformed geometry...');
            final transformed = _createTransformedGeometry(
              context: context,
              subject: subject,
              transform: transform,
              providedLabel: label,
            );

            debugPrint('[Reflect Command] Transformed result: ${transformed?.runtimeType}');
            if (transformed == null) {
              debugPrint('[Reflect Command] ❌ Transformation returned null for ${subject.runtimeType}');
              return ExecutionResult.error(
                'Reflect does not support transforming ${subject.runtimeType}.',
              );
            }
            debugPrint('[Reflect Command] ✅ Transformation successful: ${transformed.runtimeType} (${transformed.id})');
            debugPrint('[Reflect Command] Adding object to DAG: ${transformed.id} with dependencies: ${transformed.dependencies}');
            context.dagManager.addObject(transformed, transformed.dependencies);
            debugPrint('[Reflect Command] Object added to DAG. Checking if object exists in DAG...');
            final dagObject = context.dagManager.getObject(transformed.id);
            debugPrint('[Reflect Command] Object in DAG: ${dagObject != null ? "YES (${dagObject.runtimeType})" : "NO"}');

            return ExecutionResult.successful(
              objectId: transformed.id,
              message:
                  'Reflected ${_displayName(subject)} to ${_displayName(transformed)}',
              object: transformed,
            );
          },
        ],
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
                allowedTypes: {GeoPoint, GeoCircle},
                description: 'Center of rotation (point or circle)',
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
        patternExecutors: [
          // Pattern 0: Object + existing GeoRotate transform
          (context, arguments) async {
            final subject = arguments[0] as GeometryObject;
            final label = _extractTrailingLabel(arguments);
            final transform = arguments[1] as GeoRotate;

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

          // Pattern 1: Object + center point/circle + angle
          (context, arguments) async {
            final subject = arguments[0] as GeometryObject;
            final label = _extractTrailingLabel(arguments);
            final centerArg = arguments[1] as GeometryObject;
            final angle = arguments[2] as num;

            // Extract center point from argument (could be GeoPoint or GeoCircle)
            GeoPoint center;
            if (centerArg is GeoCircle) {
              // Extract center from circle
              final centerMv = getCircleCenter(centerArg.multivector);
              center = GeoPointer(
                id: '${centerArg.id}_center',
                label: '${centerArg.label}_center',
                x: centerMv.e1,
                y: centerMv.e2,
              );
            } else if (centerArg is GeoPoint) {
              center = centerArg;
            } else {
              return ExecutionResult.error(
                'Center must be a point or circle, got ${centerArg.runtimeType}',
              );
            }

            final transform = _createRotationTransform(
              context: context,
              center: center,
              angleRadians: _degreesToRadians(angle.toDouble()),
            );

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
        ],
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
        patternExecutors: [
          // Pattern 0: Object + existing GeoDilate transform
          (context, arguments) async {
            final subject = arguments[0] as GeometryObject;
            final label = _extractTrailingLabel(arguments);
            final transform = arguments[1] as GeoDilate;

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

          // Pattern 1: Object + center point/circle + scale factor
          (context, arguments) async {
            final subject = arguments[0] as GeometryObject;
            final label = _extractTrailingLabel(arguments);
            final centerArg = arguments[1] as GeometryObject;
            final factor = arguments[2] as num;

            // Extract center point from argument (could be GeoPoint or GeoCircle)
            GeoPoint center;
            if (centerArg is GeoCircle) {
              // Extract center from circle
              final centerMv = getCircleCenter(centerArg.multivector);
              center = GeoPointer(
                id: '${centerArg.id}_center',
                label: '${centerArg.label}_center',
                x: centerMv.e1,
                y: centerMv.e2,
              );
            } else if (centerArg is GeoPoint) {
              center = centerArg;
            } else {
              return ExecutionResult.error(
                'Center must be a point or circle, got ${centerArg.runtimeType}',
              );
            }

            final transform = _createDilateTransform(
              context: context,
              center: center,
              factor: factor.toDouble(),
            );

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
        ],
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

          // Create translated object with apostrophe suffix
          final transformedLabel = label.isNotEmpty
              ? label
              : LabelManager.getNextAvailableLabelForTransformation(
                  context.dagManager,
                  subject.label.isNotEmpty ? subject.label : subject.id,
                );
          final transformed = TransformationEngine.translate(
            subject,
            dx,
            dy,
            newLabel: transformedLabel,
            newId: transformedLabel, // In new system: ID = label
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
        description: 'Find intersection of geometry objects (lines, circles, segments, arcs, unions)',
        schema: CommandSchema(
          description: 'Intersection',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {
                GeoLine,
                GeoCircle,
                GeoPoint,
                GeoSegment,
                GeoArc,
                UnionGeometryObjectList,
              },
              description: 'First object',
            ),
            TypeConstraint.geometry(
              allowedTypes: {
                GeoLine,
                GeoCircle,
                GeoPoint,
                GeoSegment,
                GeoArc,
                UnionGeometryObjectList,
              },
              description: 'Second object',
            ),
          ],
          argumentHints: ['Select first object', 'Select second object'],
        ),
        executor: (context, arguments) async {
          // Sort parents by ID for stable element ID generation
          final first = arguments[0] as GeometryObject;
          final second = arguments[1] as GeometryObject;
          final sorted = [first, second]..sort((a, b) => a.id.compareTo(b.id));
          final sortedFirst = sorted[0];
          final sortedSecond = sorted[1];
          
        debugPrint(
          '[IntersectionCommand] Received ${first.runtimeType} (${first.id}) and ${second.runtimeType} (${second.id})',
        );
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';
          // Get container label (SL1, SL2, etc.) if no label provided
          final containerLabel = providedLabel.isNotEmpty
              ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.simpleList,
                );

          GeoIntersection intersection;

          try {
            // Handle Union × Union case first
            // Use sorted order for consistent element IDs
            if (sortedFirst is UnionGeometryObjectList && sortedSecond is UnionGeometryObjectList) {
              intersection = GeoIntersection.unionWithUnion(
                id: containerLabel,
                label: containerLabel,
                union1: sortedFirst,
                union2: sortedSecond,
                dagManager: context.dagManager,
              );
            }
            // Handle Union × Object cases
            // Use sorted order for consistent element IDs
            else if (sortedFirst is UnionGeometryObjectList) {
              intersection = GeoIntersection.unionWithObject(
                id: containerLabel,
                label: containerLabel,
                union: sortedFirst,
                other: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedSecond is UnionGeometryObjectList) {
              intersection = GeoIntersection.unionWithObject(
                id: containerLabel,
                label: containerLabel,
                union: sortedSecond,
                other: sortedFirst,
                dagManager: context.dagManager,
              );
            }
            // Handle Simple × Simple cases
            // Use sorted order for consistent element IDs
            else if (sortedFirst is GeoLine && sortedSecond is GeoLine) {
              final lineIntersection = GeoIntersection.lineLine(
                id: containerLabel,
                label: containerLabel,
                line1: sortedFirst,
                line2: sortedSecond,
                dagManager: context.dagManager,
              );
              if (lineIntersection == null) {
                return ExecutionResult.error(
                  'Lines are parallel - no intersection found',
                );
              }
              intersection = lineIntersection;
            } else if (sortedFirst is GeoLine && sortedSecond is GeoCircle) {
              intersection = GeoIntersection.lineCircle(
                id: containerLabel,
                label: containerLabel,
                line: sortedFirst,
                circle: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoCircle && sortedSecond is GeoLine) {
              // Reverse order: circle comes first after sorting by ID
              intersection = GeoIntersection.lineCircle(
                id: containerLabel,
                label: containerLabel,
                line: sortedSecond,
                circle: sortedFirst,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoCircle && sortedSecond is GeoCircle) {
              intersection = GeoIntersection.circleCircle(
                id: containerLabel,
                label: containerLabel,
                circle1: sortedFirst,
                circle2: sortedSecond,
                dagManager: context.dagManager,
              );
            }
            // Handle Simple × Complex cases
            // Use sorted order for consistent element IDs
            else if (sortedFirst is GeoLine && sortedSecond is GeoSegment) {
              intersection = GeoIntersection.lineSegment(
                id: containerLabel,
                label: containerLabel,
                line: sortedFirst,
                segment: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoSegment && sortedSecond is GeoLine) {
              intersection = GeoIntersection.lineSegment(
                id: containerLabel,
                label: containerLabel,
                line: sortedSecond,
                segment: sortedFirst,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoLine && sortedSecond is GeoArc) {
              intersection = GeoIntersection.lineArc(
                id: containerLabel,
                label: containerLabel,
                line: sortedFirst,
                arc: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoArc && sortedSecond is GeoLine) {
              intersection = GeoIntersection.lineArc(
                id: containerLabel,
                label: containerLabel,
                line: sortedSecond,
                arc: sortedFirst,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoCircle && sortedSecond is GeoSegment) {
              intersection = GeoIntersection.circleSegment(
                id: containerLabel,
                label: containerLabel,
                circle: sortedFirst,
                segment: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoSegment && sortedSecond is GeoCircle) {
              intersection = GeoIntersection.circleSegment(
                id: containerLabel,
                label: containerLabel,
                circle: sortedSecond,
                segment: sortedFirst,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoCircle && sortedSecond is GeoArc) {
              intersection = GeoIntersection.circleArc(
                id: containerLabel,
                label: containerLabel,
                circle: sortedFirst,
                arc: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoArc && sortedSecond is GeoCircle) {
              intersection = GeoIntersection.circleArc(
                id: containerLabel,
                label: containerLabel,
                circle: sortedSecond,
                arc: sortedFirst,
                dagManager: context.dagManager,
              );
            }
            // Handle Complex × Complex cases
            // Use sorted order for consistent element IDs
            else if (sortedFirst is GeoSegment && sortedSecond is GeoSegment) {
              intersection = GeoIntersection.segmentSegment(
                id: containerLabel,
                label: containerLabel,
                segment1: sortedFirst,
                segment2: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoSegment && sortedSecond is GeoArc) {
              intersection = GeoIntersection.segmentArc(
                id: containerLabel,
                label: containerLabel,
                segment: sortedFirst,
                arc: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoArc && sortedSecond is GeoSegment) {
              intersection = GeoIntersection.segmentArc(
                id: containerLabel,
                label: containerLabel,
                segment: sortedSecond,
                arc: sortedFirst,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is GeoArc && sortedSecond is GeoArc) {
              intersection = GeoIntersection.arcArc(
                id: containerLabel,
                label: containerLabel,
                arc1: sortedFirst,
                arc2: sortedSecond,
                dagManager: context.dagManager,
              );
            } else {
              return ExecutionResult.error(
                'Intersection not supported for ${sortedFirst.runtimeType} and ${sortedSecond.runtimeType}',
              );
            }

            context.dagManager.addObject(intersection, intersection.dependencies);

            final count = intersection.objects.length;
            final message = count == 0
                ? 'Created ${intersection.label} (no intersections found)'
                : 'Created ${intersection.label} with $count intersection${count == 1 ? '' : 's'}';

            return ExecutionResult.successful(
              objectId: intersection.id,
              message: message,
              object: intersection,
            );
          } on ArgumentError catch (e) {
            return ExecutionResult.error(e.message);
          } catch (e) {
            return ExecutionResult.error('Intersection calculation failed: $e');
          }
        },
      ),
    );

    // ========================================================================
    // FLEXIBLE COMMANDS (L3) - Relaxed type constraints
    // ========================================================================

    // 1. Flexible circle from center and point
    _register(
      CommandDefinition(
        name: 'circleFlex',
        description: 'Create a circle with flexible center and point (center: point/circle, point: point/circle)',
        aliases: const ['circleFlexible', 'circle2'],
        schema: CommandSchema(
          description: 'Circle with flexible arguments',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {SimpleGeometryObject},
              description: 'Center (point or circle)',
            ),
            TypeConstraint.geometry(
              allowedTypes: {SimpleGeometryObject},
              description: 'Point on circle (point or circle, not line)',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select center (point or circle)',
            'Select point on circle (point or circle)',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final centerObj = arguments[0] as SimpleGeometryObject;
          final pointObj = arguments[1] as SimpleGeometryObject;
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';

          try {
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.circle,
                  );
            final circle = GeoCircleFlex.fromDependencies(
              id: label, // In new system: ID = label
              label: label,
              objects: [centerObj, pointObj],
            );

            context.dagManager.addObject(circle, [centerObj.id, pointObj.id]);

            return ExecutionResult.successful(
              objectId: circle.id,
              message: 'Created ${circle.label}',
              object: circle,
            );
          } catch (e) {
            return ExecutionResult.error(e.toString());
          }
        },
      ),
    );

    // 2. Flexible circle through three objects
    _register(
      CommandDefinition(
        name: 'circle3Flex',
        description: 'Create a circle through three flexible objects (any SimpleGeometryObject)',
        aliases: const ['circle3Flexible', 'circleThrough3Flex'],
        schema: CommandSchema(
          description: 'Circle through three flexible objects',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {SimpleGeometryObject},
              description: 'First object',
            ),
            TypeConstraint.geometry(
              allowedTypes: {SimpleGeometryObject},
              description: 'Second object',
            ),
            TypeConstraint.geometry(
              allowedTypes: {SimpleGeometryObject},
              description: 'Third object',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select first object',
            'Select second object',
            'Select third object',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final obj1 = arguments[0] as SimpleGeometryObject;
          final obj2 = arguments[1] as SimpleGeometryObject;
          final obj3 = arguments[2] as SimpleGeometryObject;
          final providedLabel = arguments.length >= 4
              ? (arguments[3] as String).trim()
              : '';

          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.circle,
                );
          final circle = GeoCircle3Flex.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
            objects: [obj1, obj2, obj3],
          );

          if (circle == null) {
            return ExecutionResult.error(
              'Cannot create circle: the three objects are collinear.',
            );
          }

          context.dagManager.addObject(circle, [obj1.id, obj2.id, obj3.id]);

          return ExecutionResult.successful(
            objectId: circle.id,
            message: 'Created ${circle.label}',
            object: circle,
          );
        },
      ),
    );

    // 3. Flexible line through two objects
    _register(
      CommandDefinition(
        name: 'lineFlex',
        description: 'Create a line through two flexible objects (any SimpleGeometryObject)',
        aliases: const ['lineFlexible', 'line2'],
        schema: CommandSchema(
          description: 'Line through two flexible objects',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {SimpleGeometryObject},
              description: 'First object',
            ),
            TypeConstraint.geometry(
              allowedTypes: {SimpleGeometryObject},
              description: 'Second object',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select first object',
            'Select second object',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final obj1 = arguments[0] as SimpleGeometryObject;
          final obj2 = arguments[1] as SimpleGeometryObject;
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';

          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.line,
                );
          final line = GeoLineFlex.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
            objects: [obj1, obj2],
          );

          context.dagManager.addObject(line, [obj1.id, obj2.id]);

          return ExecutionResult.successful(
            objectId: line.id,
            message: 'Created ${line.label}',
            object: line,
          );
        },
      ),
    );

    // 4. Flexible perpendicular bisector (both can be circle or point, not line)
    _register(
      CommandDefinition(
        name: 'perpbisectorFlex',
        description: 'Create perpendicular bisector with flexible arguments (circle or point, not line)',
        aliases: const ['perpbisFlex', 'perpbisectorFlexible'],
        schema: CommandSchema(
          description: 'Perpendicular bisector with flexible arguments',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {SimpleGeometryObject},
              description: 'First object (point or circle, not line)',
            ),
            TypeConstraint.geometry(
              allowedTypes: {SimpleGeometryObject},
              description: 'Second object (point or circle, not line)',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select first object (point or circle)',
            'Select second object (point or circle)',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final obj1 = arguments[0] as SimpleGeometryObject;
          final obj2 = arguments[1] as SimpleGeometryObject;
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';

          try {
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.line,
                  );
            final bisector = GeoPerpendicularBisectorFlex.fromDependencies(
              id: label, // In new system: ID = label
              label: label,
              objects: [obj1, obj2],
            );

            context.dagManager.addObject(bisector, [obj1.id, obj2.id]);

            return ExecutionResult.successful(
              objectId: bisector.id,
              message: 'Created ${bisector.label}',
              object: bisector,
            );
          } catch (e) {
            return ExecutionResult.error(e.toString());
          }
        },
      ),
    );

    // 5. Flexible perpendicular line (point can be circle or point)
    _register(
      CommandDefinition(
        name: 'perpendicularFlex',
        description: 'Create perpendicular line with flexible point (point or circle)',
        aliases: const ['perpFlex', 'perpendicularFlexible'],
        schema: CommandSchema(
          description: 'Perpendicular line with flexible point',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint, GeoCircle},
              description: 'Point on perpendicular (point or circle)',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoLine},
              description: 'Reference line',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select point (point or circle)',
            'Select reference line',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final pointObj = arguments[0] as SimpleGeometryObject;
          final reference = arguments[1] as GeoLine;
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';

          try {
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.line,
                  );
            final perpendicular = GeoPerpendicularLineFlex.fromDependencies(
              id: label, // In new system: ID = label
              label: label,
              dependencies: [pointObj, reference],
            );

            context.dagManager.addObject(perpendicular, [pointObj.id, reference.id]);

            return ExecutionResult.successful(
              objectId: perpendicular.id,
              message: 'Created ${perpendicular.label}',
              object: perpendicular,
            );
          } catch (e) {
            return ExecutionResult.error(e.toString());
          }
        },
      ),
    );

    // 6. Flexible parallel line (point can be circle or point)
    _register(
      CommandDefinition(
        name: 'parallelFlex',
        description: 'Create parallel line with flexible point (point or circle)',
        aliases: const ['paraFlex', 'parallelFlexible'],
        schema: CommandSchema(
          description: 'Parallel line with flexible point',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoLine},
              description: 'Reference line',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint, GeoCircle},
              description: 'Point on parallel (point or circle)',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select reference line',
            'Select point (point or circle)',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final reference = arguments[0] as GeoLine;
          final pointObj = arguments[1] as SimpleGeometryObject;
          final providedLabel = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';

          try {
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.line,
                  );
            final parallel = GeoParallelLineFlex.fromDependencies(
              id: label, // In new system: ID = label
              label: label,
              dependencies: [reference, pointObj],
            );

            context.dagManager.addObject(parallel, [reference.id, pointObj.id]);

            return ExecutionResult.successful(
              objectId: parallel.id,
              message: 'Created ${parallel.label}',
              object: parallel,
            );
          } catch (e) {
            return ExecutionResult.error(e.toString());
          }
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
    final label = LabelManager.getNextAvailableLabel(
      context.dagManager,
      GeometryObjectType.transform,
    );
    final inverse = GeoInverse(
      id: label, // In new system: ID = label
      label: label,
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
    final label = LabelManager.getNextAvailableLabel(
      context.dagManager,
      GeometryObjectType.transform,
    );
    final rotate = GeoRotate(
      id: label, // In new system: ID = label
      label: label,
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
    final label = LabelManager.getNextAvailableLabel(
      context.dagManager,
      GeometryObjectType.transform,
    );
    final dilate = GeoDilate(
      id: label, // In new system: ID = label
      label: label,
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
    debugPrint('[Reflect Command] _createTransformedGeometry: subject=${subject.runtimeType} (${subject.id}), transform=${transform.runtimeType} (${transform.id})');
    
    if (subject is GeoPoint) {
      debugPrint('[Reflect Command] Subject is GeoPoint, transforming...');
      final label = providedLabel.isNotEmpty
          ? providedLabel
          : LabelManager.getNextAvailableLabelForTransformation(
              context.dagManager,
              subject.label.isNotEmpty ? subject.label : subject.id,
            );
      final result = TransformationEngine.transformSimple(
        source: subject,
        transform: transform,
        id: label, // In new system: ID = label (with apostrophe for transformed)
        label: label,
        dependencies: [subject.id, transform.id],
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );

      debugPrint('[Reflect Command] Transformation result: ${result?.runtimeType}');
      if (result is GeoTransPoint) {
        debugPrint('[Reflect Command] ✅ Successfully created GeoTransPoint');
        return result;
      }
      debugPrint('[Reflect Command] ❌ Point transformation did not produce GeoTransPoint, returning null');
      return null;
    }

    if (subject is GeoLine) {
      final label = providedLabel.isNotEmpty
          ? providedLabel
          : LabelManager.getNextAvailableLabelForTransformation(
              context.dagManager,
              subject.label.isNotEmpty ? subject.label : subject.id,
            );
      final result = TransformationEngine.transformSimple(
        source: subject,
        transform: transform,
        id: label, // In new system: ID = label (with apostrophe for transformed)
        label: label,
        dependencies: [subject.id, transform.id],
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );

      if (result is GeoTransLine) {
        return result;
      }
      if (result is GeoTransCircle) {
        final circleLabel = providedLabel.isNotEmpty
            ? providedLabel
            : LabelManager.getNextAvailableLabelForTransformation(
                context.dagManager,
                subject.label.isNotEmpty ? subject.label : subject.id,
              );
        return GeoTransCircle(
          id: circleLabel, // In new system: ID = label
          label: circleLabel,
          dependencies: [subject.id, transform.id],
          multivector: result.multivector,
          sourceObjectId: subject.id,
          transformId: transform.id,
          visible: subject.visible,
          styleOverrides: subject.styleOverrides,
        );
      }
      return null;
    }

    if (subject is GeoCircle) {
      final label = providedLabel.isNotEmpty
          ? providedLabel
          : LabelManager.getNextAvailableLabelForTransformation(
              context.dagManager,
              subject.label.isNotEmpty ? subject.label : subject.id,
            );
      final result = TransformationEngine.transformSimple(
        source: subject,
        transform: transform,
        id: label, // In new system: ID = label (with apostrophe for transformed)
        label: label,
        dependencies: [subject.id, transform.id],
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );

      if (result is GeoTransCircle) {
        return result;
      }
      if (result is GeoTransLine) {
        final lineLabel = providedLabel.isNotEmpty
            ? providedLabel
            : LabelManager.getNextAvailableLabelForTransformation(
                context.dagManager,
                subject.label.isNotEmpty ? subject.label : subject.id,
              );
        return GeoTransLine(
          id: lineLabel, // In new system: ID = label
          label: lineLabel,
          dependencies: [subject.id, transform.id],
          multivector: result.multivector,
          sourceObjectId: subject.id,
          transformId: transform.id,
          visible: subject.visible,
          styleOverrides: subject.styleOverrides,
        );
      }
      return null;
    }

    if (subject is GeoSegment) {
      final label = providedLabel.isNotEmpty
          ? providedLabel
          : LabelManager.getNextAvailableLabelForTransformation(
              context.dagManager,
              subject.label.isNotEmpty ? subject.label : subject.id,
      );
      final result = TransformationEngine.transformComplex(
        source: subject,
        transform: transform,
        id: label, // In new system: ID = label (with apostrophe for transformed)
        label: label,
        dependencies: [subject.id, transform.id],
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );

      if (result is GeoTransSegment) {
        return result;
      }
      if (result is GeoTransArc) {
        final arcLabel = providedLabel.isNotEmpty
            ? providedLabel
            : LabelManager.getNextAvailableLabelForTransformation(
                context.dagManager,
                subject.label.isNotEmpty ? subject.label : subject.id,
        );
        return GeoTransArc(
          id: arcLabel, // In new system: ID = label
          label: arcLabel,
          dependencies: [subject.id, transform.id],
          boundary: result.boundary,
          controlPoint: result.controlPoint,
          sourceObjectId: subject.id,
          transformId: transform.id,
          visible: subject.visible,
          styleOverrides: subject.styleOverrides,
        );
      }
      return null;
    }

    if (subject is GeoArc) {
      final label = providedLabel.isNotEmpty
          ? providedLabel
          : LabelManager.getNextAvailableLabelForTransformation(
              context.dagManager,
              subject.label.isNotEmpty ? subject.label : subject.id,
      );
      final result = TransformationEngine.transformComplex(
        source: subject,
        transform: transform,
        id: label, // In new system: ID = label (with apostrophe for transformed)
        label: label,
        dependencies: [subject.id, transform.id],
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );

      if (result is GeoTransArc) {
        return result;
      }
      if (result is GeoTransSegment) {
        final segmentLabel = providedLabel.isNotEmpty
            ? providedLabel
            : LabelManager.getNextAvailableLabelForTransformation(
                context.dagManager,
                subject.label.isNotEmpty ? subject.label : subject.id,
        );
        return GeoTransSegment(
          id: segmentLabel, // In new system: ID = label
          label: segmentLabel,
          dependencies: [subject.id, transform.id],
          boundary: result.boundary,
          sourceObjectId: subject.id,
          transformId: transform.id,
          visible: subject.visible,
          styleOverrides: subject.styleOverrides,
        );
      }
      return null;
    }

    if (subject is UnionGeometryObjectList) {
      final label = providedLabel.isNotEmpty
          ? providedLabel
          : LabelManager.getNextAvailableLabelForTransformation(
              context.dagManager,
              subject.label.isNotEmpty ? subject.label : subject.id,
            );
      final elements = _transformUnionElements(subject, transform);
      return GeoTransUnionGeometryObjectList(
        id: label, // In new system: ID = label (with apostrophe for transformed)
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
          id: '${element.id}_${transform.id}_point',
          label: element.label,
          dependencies: element.dependencies,
          visible: element.visible,
          styleOverrides: element.styleOverrides,
        );

        if (simpleResult != null) {
          transformedElements.add(simpleResult);
        } else {
          transformedElements.add(element);
        }
        continue;
      }

      if (element is GeoSegment || element is GeoArc) {
        final transformedId = '${element.id}_${transform.id}_trans';
        final complexResult = TransformationEngine.transformComplex(
          source: element as ComplexGeometryObject,
          transform: transform,
          id: transformedId,
          label: element.label,
          dependencies: element.dependencies,
          visible: element.visible,
          styleOverrides: element.styleOverrides,
        );

        if (complexResult != null) {
          transformedElements.add(complexResult);
        } else {
          transformedElements.add(element);
        }
        continue;
      }

      transformedElements.add(element);
    }

    return transformedElements;
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
}
