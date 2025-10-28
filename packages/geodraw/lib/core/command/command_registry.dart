/// Registry for all command definitions
library;

import 'dart:collection';

import 'package:flutter/material.dart';

import 'command_definition.dart';
import 'command_schema.dart';
import 'command_runtime.dart';
import '../../models/geometry_object.dart';
import '../../models/simple/geo_point.dart';
import '../../models/simple/geo_line.dart';
import '../../models/simple/geo_circle.dart';
import '../../models/simple_lists/geo_tangent.dart';
import '../../models/complex/geo_shapes.dart';
import '../../models/text/canvas_text.dart';

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
  String _nextTextContent() => 'Text ${++_textLabelCounter}';
}
