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
import '../../models/simple/geo_flex.dart';
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
            Multivector? projectedMultivector;
            Offset initialPosition;
            if (object is GeoPoint) {
              // Shouldn't happen (filtered out), but handle gracefully
              projectedMultivector = object.multivector;
              initialPosition = object.position;
            } else if (object is GeoLine) {
              // For lines, use a point on the line (e.g., closest to origin)
              final lineMv = object.multivector;
              // Project origin onto line
              final origin = constructFreePoint(0, 0);
              projectedMultivector = projectPointToLine(origin, lineMv);
              initialPosition = Offset(projectedMultivector.e1, projectedMultivector.e2);
            } else if (object is GeoCircle) {
              // For circles, use a point on the circle (e.g., rightmost point)
              final center = getCircleCenter(object.multivector);
              final centerInf = infForm(center);
              final radius = measureCircleRadius(object.multivector);
              // Project a point to the right of center onto the circle
              final rightPoint = constructFreePoint(centerInf.e1 + radius, centerInf.e2);
              projectedMultivector = projectPointToCircle(rightPoint, object.multivector);
              initialPosition = Offset(projectedMultivector.e1, projectedMultivector.e2);
            } else if (object is GeoSegment) {
              // Use midpoint of segment
              final start = object.startPoint.position;
              final end = object.endPoint.position;
              final midpoint = constructFreePoint(
                (start.dx + end.dx) / 2,
                (start.dy + end.dy) / 2,
              );
              projectedMultivector = projectPointToSegment(midpoint, object.boundary.boundary);
              initialPosition = Offset(projectedMultivector.e1, projectedMultivector.e2);
            } else if (object is GeoArc) {
              // Use midpoint of arc (approximate)
              final start = object.startPoint.position;
              final end = object.endPoint.position;
              final midpoint = constructFreePoint(
                (start.dx + end.dx) / 2,
                (start.dy + end.dy) / 2,
              );
              final counterClockwise = object.boundary.multivector.o >= 0;
              projectedMultivector = projectPointToArc(
                midpoint,
                object.boundary.multivector,
                object.startPoint.multivector,
                object.endPoint.multivector,
                counterClockwise,
              );
              if (projectedMultivector == null) {
                // Fallback to start point if projection fails
                projectedMultivector = object.startPoint.multivector;
                initialPosition = start;
              } else {
                initialPosition = Offset(projectedMultivector.e1, projectedMultivector.e2);
              }
              } else if (object is UnionGeometryObjectList) {
              // Use first element's position
              // Note: GenSimpleGeometryObjectList extends UnionGeometryObjectList, so this covers both
              if (object.elements.isNotEmpty) {
                final firstElement = object.elements.first;
                if (firstElement is GeoPoint) {
                  projectedMultivector = firstElement.multivector;
                  initialPosition = firstElement.position;
                } else {
                  // Fallback to center of bounds, then project onto union
                  final bounds = object.getBounds();
                  final centerPoint = constructFreePoint(bounds.center.dx, bounds.center.dy);
                  // Project onto the nearest element in the union
                  Multivector? bestProjection;
                  double bestDistance = double.infinity;
                  
                  for (final element in object.elements) {
                    Multivector? projection;
                    if (element is GeoLine) {
                      projection = projectPointToLine(centerPoint, element.multivector);
                    } else if (element is GeoCircle) {
                      projection = projectPointToCircle(centerPoint, element.multivector);
                    } else if (element is GeoSegment) {
                      projection = projectPointToSegment(centerPoint, element.boundary.boundary);
                    } else if (element is GeoArc) {
                      final counterClockwise = element.boundary.multivector.o >= 0;
                      projection = projectPointToArc(
                        centerPoint,
                        element.boundary.multivector,
                        element.startPoint.multivector,
                        element.endPoint.multivector,
                        counterClockwise,
                      );
                    }
                    
                    if (projection != null) {
                      final dist = distancePointToPoint(centerPoint, projection);
                      if (dist < bestDistance) {
                        bestDistance = dist;
                        bestProjection = projection;
                      }
                    }
                  }
                  
                  projectedMultivector = bestProjection ?? centerPoint;
                  initialPosition = Offset(projectedMultivector.e1, projectedMultivector.e2);
                }
              } else {
                return ExecutionResult.error('Union object has no elements');
              }
            } else {
              // Fallback to center of bounds
              final bounds = object.getBounds();
              projectedMultivector = constructFreePoint(bounds.center.dx, bounds.center.dy);
              initialPosition = bounds.center;
            }
            
            final label = providedLabel.isNotEmpty
                  ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.point,
                  );
            // Use withMultivector constructor to set the correct projected multivector
            final gliderPoint = GeoGliderPoint.withMultivector(
              id: label, // In new system: ID = label
              label: label,
              objectId: object.id,
              initialX: initialPosition.dx,
              initialY: initialPosition.dy,
              multivector: projectedMultivector,
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
              dagManager: context.dagManager,
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
              dagManager: context.dagManager,
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
              dagManager: context.dagManager,
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
            // Preserve existing element labels when extending
            final existingElementLabels = polygon.elements.map((e) => e.id).toList();
            
            next = GeoPolygon.fromDependencies(
              id: polygon.id,
              label: polygon.label,
              points: resolvedPoints,
              dagManager: context.dagManager,
              visible: polygon.visible,
              style: polygon.style,
              styleOverrides: polygon.styleOverrides,
              color: polygon.style.strokeColor,
              existingElementLabels: existingElementLabels,
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
              dagManager: context.dagManager,
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
            // Preserve existing element labels when extending
            final existingElementLabels = polyLine.elements.map((e) => e.id).toList();
            
            next = GeoPolyLine.fromDependencies(
              id: polyLine.id,
              label: polyLine.label,
              points: resolvedPoints,
              dagManager: context.dagManager,
              visible: polyLine.visible,
              style: polyLine.style,
              styleOverrides: polyLine.styleOverrides,
              color: polyLine.style.strokeColor,
              existingElementLabels: existingElementLabels,
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
              dagManager: context.dagManager,
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
              dagManager: context.dagManager,
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
        name: 'center',
        description: 'Find and draw the center of a circle',
        aliases: const ['circleCenter', 'centerOfCircle'],
        schema: CommandSchema(
          description: 'Center of circle',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoCircle},
              description: 'Circle',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select circle',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final circle = arguments[0] as GeoCircle;
          final providedLabel = arguments.length >= 2
              ? (arguments[1] as String).trim()
              : '';
          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.point,
                );
          
          final centerMv = constructPointFromCircle(circle.multivector);
          final center = GeoPointer(
            id: label, // In new system: ID = label
            label: label,
            x: centerMv.e1,
            y: centerMv.e2,
          );

          context.dagManager.addObject(center, [circle.id]);

          return ExecutionResult.successful(
            objectId: center.id,
            message: 'Created center ${center.label} of circle ${circle.label}',
            object: center,
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

          GeoTangentList tangent;
          try {
            tangent = GeoTangentList.constructFromObjects(
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

          final count = tangent.elements.length;
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

              final count = bisectors.elements.length;
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
                allowedTypes: {GeoLineInverse, GeoCircleInverse, GeoPointInverse},
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
          // Pattern 0: Object + existing inverse transform
          (context, arguments) async {
            final subject = arguments[0] as GeometryObject;
            final label = _extractTrailingLabel(arguments);
            final transform = arguments[1] as GeoTrans;

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

            final angleDegrees = angle.toDouble();
            final angleRadians = _degreesToRadians(angleDegrees);
            debugPrint('[RotateCommand] Angle: ${angleDegrees.toStringAsFixed(2)}° (${angleRadians.toStringAsFixed(6)} radians)');
            
            final transform = _createRotationTransform(
              context: context,
              center: center,
              angleRadians: angleRadians,
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

          // Create translation transform object (similar to rotate/dilate)
          final transform = _createTranslationTransform(
            context: context,
            fromPoint: startPoint,
            toPoint: endPoint,
          );

          // Use the transformation system to create transformed geometry
          final transformed = _createTransformedGeometry(
            context: context,
            subject: subject,
            transform: transform,
            providedLabel: label,
          );

          if (transformed == null) {
            return ExecutionResult.error(
              'Translate does not support transforming ${subject.runtimeType}.',
            );
          }

          context.dagManager.addObject(transformed, transformed.dependencies);

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
            // Handle GenSimpleGeometryObjectList × GenSimpleGeometryObjectList case first
            // (More specific than Union, so check before Union cases)
            if (sortedFirst is GenSimpleGeometryObjectList && 
                sortedSecond is GenSimpleGeometryObjectList) {
              intersection = GeoIntersection.simpleListWithSimpleList(
                id: containerLabel,
                label: containerLabel,
                simpleList1: sortedFirst,
                simpleList2: sortedSecond,
                dagManager: context.dagManager,
              );
            }
            // Handle GenSimpleGeometryObjectList × Union cases
            // Note: GenSimpleGeometryObjectList extends UnionGeometryObjectList, so we check for
            // non-GenSimpleGeometryObjectList UnionGeometryObjectList (like GeoPolygon, GeoPolyLine)
            else if (sortedFirst is GenSimpleGeometryObjectList && 
                     sortedSecond is UnionGeometryObjectList &&
                     !(sortedSecond is GenSimpleGeometryObjectList)) {
              intersection = GeoIntersection.simpleListWithUnion(
                id: containerLabel,
                label: containerLabel,
                simpleList: sortedFirst,
                union: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedFirst is UnionGeometryObjectList &&
                       !(sortedFirst is GenSimpleGeometryObjectList) &&
                       sortedSecond is GenSimpleGeometryObjectList) {
              intersection = GeoIntersection.simpleListWithUnion(
                id: containerLabel,
                label: containerLabel,
                simpleList: sortedSecond,
                union: sortedFirst,
                dagManager: context.dagManager,
              );
            }
            // Handle GenSimpleGeometryObjectList × Simple cases
            // Check before Union × Object to ensure correct routing
            else if (sortedFirst is GenSimpleGeometryObjectList && 
                     (sortedSecond is GeoLine || sortedSecond is GeoCircle || sortedSecond is GeoPoint)) {
              intersection = GeoIntersection.simpleListWithObject(
                id: containerLabel,
                label: containerLabel,
                simpleList: sortedFirst,
                other: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedSecond is GenSimpleGeometryObjectList && 
                       (sortedFirst is GeoLine || sortedFirst is GeoCircle || sortedFirst is GeoPoint)) {
              intersection = GeoIntersection.simpleListWithObject(
                id: containerLabel,
                label: containerLabel,
                simpleList: sortedSecond,
                other: sortedFirst,
                dagManager: context.dagManager,
              );
            }
            // Handle GenSimpleGeometryObjectList × Complex cases
            // Check before Union × Object to ensure correct routing
            else if (sortedFirst is GenSimpleGeometryObjectList && 
                     (sortedSecond is GeoSegment || sortedSecond is GeoArc)) {
              intersection = GeoIntersection.simpleListWithObject(
                id: containerLabel,
                label: containerLabel,
                simpleList: sortedFirst,
                other: sortedSecond,
                dagManager: context.dagManager,
              );
            } else if (sortedSecond is GenSimpleGeometryObjectList && 
                       (sortedFirst is GeoSegment || sortedFirst is GeoArc)) {
              intersection = GeoIntersection.simpleListWithObject(
                id: containerLabel,
                label: containerLabel,
                simpleList: sortedSecond,
                other: sortedFirst,
                dagManager: context.dagManager,
              );
            }
            // Handle Union × Union case
            // Use sorted order for consistent element IDs
            // Note: This catches UnionGeometryObjectList × UnionGeometryObjectList cases
            // that weren't already handled by GenSimpleGeometryObjectList checks above
            else if (sortedFirst is UnionGeometryObjectList && sortedSecond is UnionGeometryObjectList) {
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
            // Note: This catches UnionGeometryObjectList × Object cases that weren't
            // already handled by GenSimpleGeometryObjectList checks above
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

            final count = intersection.elements.length;
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
        name: 'geo3Flex',
        description: 'Create geometry through three flexible objects (GeoLine, GeoCircle, or GeoPoint) - returns point, line, or circle',
        aliases: const ['geo3Flexible', 'geometry3Flex', 'circle3Flex', 'circle3Flexible', 'circleThrough3Flex'],
        schema: CommandSchema(
          description: 'Geometry through three flexible objects',
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

          // Determine label type based on result (will be determined after construction)
          // For now, use a generic approach - the factory will determine the type
          final label = providedLabel.isNotEmpty
                ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.circle, // Default, will be adjusted if needed
                );
          
          final result = Geo3Flex.fromDependencies(
            id: label, // In new system: ID = label
            label: label,
            objects: [obj1, obj2, obj3],
          );

          if (result == null) {
            return ExecutionResult.error(
              'Cannot create geometry: the three objects result in infinity or invalid configuration.',
            );
          }

          context.dagManager.addObject(result, [obj1.id, obj2.id, obj3.id]);

          return ExecutionResult.successful(
            objectId: result.id,
            message: 'Created ${result.label}',
            object: result,
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
          final line = GeoLine2Sim.fromDependencies(
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

    // Triangle construction commands
    // 1. Incircle
    _register(
      CommandDefinition(
        name: 'incircle',
        description: 'Construct the incircle of a triangle from three vertices',
        aliases: const ['inCircle', 'incircle3'],
        schema: CommandSchema(
          description: 'Incircle of triangle',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'First vertex',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Second vertex',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Third vertex',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select first vertex',
            'Select second vertex',
            'Select third vertex',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final v1 = arguments[0] as GeoPoint;
          final v2 = arguments[1] as GeoPoint;
          final v3 = arguments[2] as GeoPoint;
          final providedLabel = arguments.length >= 4
              ? (arguments[3] as String).trim()
              : '';

          try {
            final label = providedLabel.isNotEmpty
                ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.circle,
                  );

            debugPrint('[IncircleCommand] Constructing incircle from vertices: ${v1.id}, ${v2.id}, ${v3.id}');
            
            final circle = GeoIncircle.fromDependencies(
              id: label,
              label: label,
              vertices: [v1, v2, v3],
            );

            if (circle == null) {
              debugPrint('[IncircleCommand] GeoIncircle.fromDependencies returned null');
              return ExecutionResult.error('Could not construct incircle from the given vertices');
            }

            debugPrint('[IncircleCommand] Created circle: ${circle.id}, multivector: ${circle.multivector}');
            context.dagManager.addObject(circle, [v1.id, v2.id, v3.id]);

            return ExecutionResult.successful(
              objectId: circle.id,
              message: 'Created ${circle.label}',
              object: circle,
            );
          } catch (e, stackTrace) {
            debugPrint('[IncircleCommand] Error: $e');
            debugPrint('[IncircleCommand] Stack trace: $stackTrace');
            return ExecutionResult.error(e.toString());
          }
        },
      ),
    );

    // 2. Excircle
    _register(
      CommandDefinition(
        name: 'excircle',
        description: 'Construct an excircle of a triangle from three vertices and a side',
        aliases: const ['exCircle', 'excircle3'],
        schema: CommandSchema(
          description: 'Excircle of triangle',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'First vertex',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Second vertex',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Third vertex',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoLine},
              description: 'Side of triangle',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select first vertex',
            'Select second vertex',
            'Select third vertex',
            'Select side',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final v1 = arguments[0] as GeoPoint;
          final v2 = arguments[1] as GeoPoint;
          final v3 = arguments[2] as GeoPoint;
          final side = arguments[3] as GeoLine;
          final providedLabel = arguments.length >= 5
              ? (arguments[4] as String).trim()
              : '';

          try {
            final label = providedLabel.isNotEmpty
                ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.circle,
                  );

            final circle = GeoExcircle.fromDependencies(
              id: label,
              label: label,
              vertices: [v1, v2, v3],
              side: side,
            );

            if (circle == null) {
              return ExecutionResult.error('Could not construct excircle from the given vertices and side');
            }

            context.dagManager.addObject(circle, [v1.id, v2.id, v3.id, side.id]);

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

    // 3. Orthocenter
    _register(
      CommandDefinition(
        name: 'orthocenter',
        description: 'Construct the orthocenter of a triangle from three vertices',
        aliases: const ['ortho', 'orthocenter3'],
        schema: CommandSchema(
          description: 'Orthocenter of triangle',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'First vertex',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Second vertex',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Third vertex',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select first vertex',
            'Select second vertex',
            'Select third vertex',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final v1 = arguments[0] as GeoPoint;
          final v2 = arguments[1] as GeoPoint;
          final v3 = arguments[2] as GeoPoint;
          final providedLabel = arguments.length >= 4
              ? (arguments[3] as String).trim()
              : '';

          try {
            final label = providedLabel.isNotEmpty
                ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.point,
                  );

            final point = GeoOrthocenter.fromDependencies(
              id: label,
              label: label,
              vertices: [v1, v2, v3],
            );

            context.dagManager.addObject(point, [v1.id, v2.id, v3.id]);

            return ExecutionResult.successful(
              objectId: point.id,
              message: 'Created ${point.label}',
              object: point,
            );
          } catch (e) {
            return ExecutionResult.error(e.toString());
          }
        },
      ),
    );

    // 4. Tangents
    _register(
      CommandDefinition(
        name: 'tangents',
        description: 'Construct tangents between two objects (point-point, point-circle, or circle-circle)',
        aliases: const ['tangent', 'tangentLines'],
        schema: CommandSchema(
          description: 'Tangents between two objects',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint, GeoCircle},
              description: 'First object',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint, GeoCircle},
              description: 'Second object',
            ),
            TypeConstraint.text(description: 'Label prefix', optional: true),
          ],
          argumentHints: [
            'Select first object (point or circle)',
            'Select second object (point or circle)',
            'Enter label prefix (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final obj1 = arguments[0] as SimpleGeometryObject;
          final obj2 = arguments[1] as SimpleGeometryObject;
          final providedLabelPrefix = arguments.length >= 3
              ? (arguments[2] as String).trim()
              : '';

          try {
            debugPrint('[TangentsCommand] Constructing tangents from ${obj1.runtimeType} (${obj1.id}) and ${obj2.runtimeType} (${obj2.id})');
            
            final label = providedLabelPrefix.isNotEmpty
                ? providedLabelPrefix
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.line,
                  );

            // Create GeoTangentList container
            final tangentList = GeoTangentList.constructFromObjects(
              id: label,
              label: label,
              first: obj1,
              second: obj2,
              dagManager: context.dagManager,
              visible: true,
            );

            context.dagManager.addObject(tangentList, [obj1.id, obj2.id]);
            debugPrint('[TangentsCommand] Created GeoTangentList ${tangentList.id} with ${tangentList.elements.length} tangent(s)');

            return ExecutionResult.successful(
              objectId: tangentList.id,
              message: 'Created ${tangentList.elements.length} tangent line(s)',
              object: tangentList,
            );
          } catch (e, stackTrace) {
            debugPrint('[TangentsCommand] Error: $e');
            debugPrint('[TangentsCommand] Stack trace: $stackTrace');
            return ExecutionResult.error(e.toString());
          }
        },
      ),
    );

    // 5. Polar
    _register(
      CommandDefinition(
        name: 'polar',
        description: 'Construct the polar line of a point with respect to a circle',
        aliases: const ['polarLine'],
        schema: CommandSchema(
          description: 'Polar line of point with respect to circle',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoCircle},
              description: 'Circle',
            ),
            TypeConstraint.text(description: 'Label', optional: true),
          ],
          argumentHints: [
            'Select point',
            'Select circle',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final point = arguments[0] as GeoPoint;
          final circle = arguments[1] as GeoCircle;
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

            final line = GeoPolarLine.fromDependencies(
              id: label,
              label: label,
              point: point,
              circle: circle,
            );

            context.dagManager.addObject(line, [point.id, circle.id]);

            return ExecutionResult.successful(
              objectId: line.id,
              message: 'Created ${line.label}',
              object: line,
            );
          } catch (e) {
            return ExecutionResult.error(e.toString());
          }
        },
      ),
    );

    // 6. aLCbc
    _register(
      CommandDefinition(
        name: 'alcbc',
        description: 'Apply aLCbc operation on three multivectors',
        aliases: const ['aLCbc', 'alc'],
        schema: CommandSchema(
          description: 'aLCbc operation',
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

          try {
            debugPrint('[alcbc Command] Starting execution with objects: ${obj1.id}, ${obj2.id}, ${obj3.id}');
            
            // Use GeoALCbc.fromDependencies to determine result type automatically
            // Output type is not known beforehand - can be point, line, circle, or infinity
            final label = providedLabel.isNotEmpty
                ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.line, // Default type, will be adjusted by GeoALCbc
                  );

            debugPrint('[alcbc Command] Generated label: $label');
            debugPrint('[alcbc Command] Calling GeoALCbc.fromDependencies...');
            
            final result = GeoALCbc.fromDependencies(
              id: label,
              label: label,
              objects: [obj1, obj2, obj3],
            );

            debugPrint('[alcbc Command] GeoALCbc.fromDependencies returned: ${result?.runtimeType} (${result?.id})');
            
            if (result == null) {
              debugPrint('[alcbc Command] ❌ Result is null - returning error');
              return ExecutionResult.error('aLCbc result is not a recognized geometry type');
            }

            debugPrint('[alcbc Command] Adding result to DAG: ${result.id}');
            context.dagManager.addObject(result, [obj1.id, obj2.id, obj3.id]);

            debugPrint('[alcbc Command] ✅ Successfully created ${result.label}');
            return ExecutionResult.successful(
              objectId: result.id,
              message: 'Created ${result.label}',
              object: result,
            );
          } catch (e, stackTrace) {
            debugPrint('[alcbc Command] ❌ Exception: $e');
            debugPrint('[alcbc Command] Stack trace: $stackTrace');
            return ExecutionResult.error(e.toString());
          }
        },
      ),
    );

    // Imaginary Circle (Icircle)
    _register(
      CommandDefinition(
        name: 'icircle',
        description: 'Construct an imaginary circle from two points',
        aliases: const ['iCircle', 'imaginaryCircle'],
        schema: CommandSchema(
          description: 'Imaginary circle from two points',
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

          try {
            final label = providedLabel.isNotEmpty
                ? providedLabel
                : LabelManager.getNextAvailableLabel(
                    context.dagManager,
                    GeometryObjectType.circle,
                  );

            final mv = constructImaginaryCircleFrom2Points(
              p1.multivector,
              p2.multivector,
            );

            if (mv == null) {
              return ExecutionResult.error('Could not construct imaginary circle from the given points');
            }

            final circle = GeoIcircle(
              id: label,
              label: label,
              dependencies: [p1.id, p2.id],
              multivector: mv,
            );

            context.dagManager.addObject(circle, [p1.id, p2.id]);

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

    // Union command
    _register(
      CommandDefinition(
        name: 'union',
        description: 'Create a union of simple or complex geometry objects',
        schema: CommandSchema(
          description: 'Union of objects',
          patterns: _unionObjectPatterns(),
          argumentHints: const [
            'Select first object',
            'Select additional objects',
            'Enter label (optional)',
          ],
        ),
        executor: (context, arguments) async {
          final rawArguments = List<dynamic>.from(arguments);
          String providedLabel = '';
          if (rawArguments.isNotEmpty && rawArguments.last is String) {
            providedLabel = (rawArguments.removeLast() as String).trim();
          }

          final objects = <GeometryObject>[];
          for (final arg in rawArguments) {
            if (arg is GeometryObject) {
              // If it's a UnionGeometryObjectList, add its children
              if (arg is UnionGeometryObjectList) {
                objects.addAll(arg.elements);
              } else {
                objects.add(arg);
              }
            }
          }

          if (objects.isEmpty) {
            return ExecutionResult.error(
              'Union requires at least one object',
            );
          }

          // Remove duplicates
          final uniqueObjects = <GeometryObject>[];
          final seenIds = <String>{};
          for (final obj in objects) {
            if (!seenIds.contains(obj.id)) {
              uniqueObjects.add(obj);
              seenIds.add(obj.id);
            }
          }

          final label = providedLabel.isNotEmpty
              ? providedLabel
              : LabelManager.getNextAvailableLabel(
                  context.dagManager,
                  GeometryObjectType.union,
                );

          final dependencies = uniqueObjects.map((obj) => obj.id).toList();
          final union = GeoUnion(
            id: label,
            label: label,
            dependencies: dependencies,
            elements: uniqueObjects,
          );

          context.dagManager.addObject(union, dependencies);

          return ExecutionResult.successful(
            objectId: union.id,
            message: 'Created union ${union.label} with ${uniqueObjects.length} object(s)',
            object: union,
          );
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

  List<List<TypeConstraint>> _unionObjectPatterns({int maxObjects = 20}) {
    final patterns = <List<TypeConstraint>>[];
    for (var objectCount = 1; objectCount <= maxObjects; objectCount++) {
      final pattern = <TypeConstraint>[];
      for (var i = 0; i < objectCount; i++) {
        pattern.add(
          TypeConstraint.geometry(
            allowedTypes: {GeometryObject}, // Accept any geometry object
            description: i == 0 ? 'First object' : 'Object ${i + 1}',
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

  GeoTrans? _resolveInverseTransform(
    CommandExecutionContext context,
    dynamic candidate,
  ) {
    // If already an inverse transform, return it
    if (candidate is GeoLineInverse || 
        candidate is GeoCircleInverse || 
        candidate is GeoPointInverse) {
      return candidate as GeoTrans;
    }

    if (candidate is GeoLine) {
      final operatorMv = constructLineReflectionOperator(candidate.multivector);
      return _registerLineInverseTransform(
        context: context,
        operator: operatorMv,
        dependencies: [candidate.id],
      );
    }

    if (candidate is GeoCircle) {
      final operatorMv = constructCircleReflectionOperator(
        candidate.multivector,
      );
      final radius = candidate.radius;
      return _registerCircleInverseTransform(
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
      return _registerPointInverseTransform(
        context: context,
        operator: operatorMv,
        dependencies: [candidate.id],
      );
    }

    return null;
  }

  GeoLineInverse _registerLineInverseTransform({
    required CommandExecutionContext context,
    required Multivector operator,
    required List<String> dependencies,
  }) {
    final label = LabelManager.getNextAvailableLabel(
      context.dagManager,
      GeometryObjectType.transform,
    );
    final inverse = GeoLineInverse(
      id: label,
      label: label,
      dependencies: dependencies,
      multivector: operator,
    );

    context.dagManager.addObject(inverse, dependencies);
    return inverse;
  }

  GeoCircleInverse _registerCircleInverseTransform({
    required CommandExecutionContext context,
    required Multivector operator,
    required List<String> dependencies,
    required double power,
  }) {
    final label = LabelManager.getNextAvailableLabel(
      context.dagManager,
      GeometryObjectType.transform,
    );
    final inverse = GeoCircleInverse(
      id: label,
      label: label,
      dependencies: dependencies,
      multivector: operator,
      power: power,
    );

    context.dagManager.addObject(inverse, dependencies);
    return inverse;
  }

  GeoPointInverse _registerPointInverseTransform({
    required CommandExecutionContext context,
    required Multivector operator,
    required List<String> dependencies,
  }) {
    final label = LabelManager.getNextAvailableLabel(
      context.dagManager,
      GeometryObjectType.transform,
    );
    final inverse = GeoPointInverse(
      id: label,
      label: label,
      dependencies: dependencies,
      multivector: operator,
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

  GeoTranslate _createTranslationTransform({
    required CommandExecutionContext context,
    required GeoPoint fromPoint,
    required GeoPoint toPoint,
  }) {
    // Calculate translation vector (dx, dy)
    final dx = toPoint.x - fromPoint.x;
    final dy = toPoint.y - fromPoint.y;

    // Construct translation operator
    final translator = constructTranslationOperator(dx, dy);
    
    final label = LabelManager.getNextAvailableLabel(
      context.dagManager,
      GeometryObjectType.transform,
    );
    final translate = GeoTranslate(
      id: label, // In new system: ID = label
      label: label,
      dependencies: [fromPoint.id, toPoint.id],
      multivector: translator,
      fromPointId: fromPoint.id,
      toPointId: toPoint.id,
    );

    context.dagManager.addObject(translate, [fromPoint.id, toPoint.id]);
    return translate;
  }

  GeometryObject? _createTransformedGeometry({
    required CommandExecutionContext context,
    required GeometryObject subject,
    required GeoTrans transform,
    required String providedLabel,
  }) {
    debugPrint('[Reflect Command] _createTransformedGeometry: subject=${subject.runtimeType} (${subject.id}), transform=${transform.runtimeType} (${transform.id})');
    
    final label = providedLabel.isNotEmpty
        ? providedLabel
        : LabelManager.getNextAvailableLabelForTransformation(
            context.dagManager,
            subject.label.isNotEmpty ? subject.label : subject.id,
          );

    // Use the centralized transformation engine
    final result = TransformationEngine.transform(
      source: subject,
      transform: transform,
      id: label,
      label: label,
      dependencies: [subject.id, transform.id],
      visible: subject.visible,
      styleOverrides: subject.styleOverrides,
    );

    // Handle special cases where transformation changes type
    // (e.g., GeoLine -> GeoTransCircle, GeoCircle -> GeoTransLine)
    if (subject is GeoLine && result is GeoTransCircle) {
      return GeoTransCircle(
        id: label,
        label: label,
        dependencies: [subject.id, transform.id],
        multivector: result.multivector,
        sourceObjectId: subject.id,
        transformId: transform.id,
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );
    }

    if (subject is GeoCircle && result is GeoTransLine) {
      return GeoTransLine(
        id: label,
        label: label,
        dependencies: [subject.id, transform.id],
        multivector: result.multivector,
        sourceObjectId: subject.id,
        transformId: transform.id,
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );
    }

    if (subject is GeoSegment && result is GeoTransArc) {
      return GeoTransArc(
        id: label,
        label: label,
        dependencies: [subject.id, transform.id],
        boundary: result.boundary,
        controlPoint: result.controlPoint,
        sourceObjectId: subject.id,
        transformId: transform.id,
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );
    }

    if (subject is GeoArc && result is GeoTransSegment) {
      return GeoTransSegment(
        id: label,
        label: label,
        dependencies: [subject.id, transform.id],
        boundary: result.boundary,
        sourceObjectId: subject.id,
        transformId: transform.id,
        visible: subject.visible,
        styleOverrides: subject.styleOverrides,
      );
    }

    return result;
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
