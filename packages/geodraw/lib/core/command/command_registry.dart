/// Registry for all command definitions
library;

import 'dart:collection';

import '../../tools/tool.dart';
import 'command_definition.dart';
import 'command_schema.dart';
import '../../models/simple/geo_point.dart';
import '../../models/simple/geo_line.dart';
import '../../models/simple/geo_circle.dart';

/// Stores command definitions and provides lookup by name or tool type
class CommandRegistry {
  CommandRegistry._internal() {
    _registerDefaults();
  }

  /// Shared registry used by default by DAG instances
  static final CommandRegistry standard = CommandRegistry._internal();

  final Map<String, CommandDefinition> _byName = HashMap();
  final Map<ToolType, CommandDefinition> _byType = HashMap();

  void _registerDefaults() {
    // Register core geometry constructors
    _register(
      CommandDefinition(
        name: 'point',
        toolType: ToolType.point,
        description: 'Create a free point at coordinates',
        schema: CommandSchema(
          description: 'Free point',
          createsObject: true,
          argumentTypes: [
            TypeConstraint.numeric(description: 'x-coordinate'),
            TypeConstraint.numeric(description: 'y-coordinate'),
          ],
          argumentHints: ['Enter x-coordinate', 'Enter y-coordinate'],
        ),
      ),
    );

    _register(
      CommandDefinition(
        name: 'line',
        toolType: ToolType.line,
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
          ],
          argumentHints: ['Select first point', 'Select second point'],
        ),
        aliases: const ['segment', 'lineSegment'],
      ),
    );

    _register(
      CommandDefinition(
        name: 'circle',
        toolType: ToolType.circle,
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
          ],
          argumentHints: ['Select center point', 'Select point on circle'],
        ),
      ),
    );

    _register(
      CommandDefinition(
        name: 'circle3',
        toolType: ToolType.circleThreePoints,
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
          ],
          argumentHints: [
            'Select first point',
            'Select second point',
            'Select third point',
          ],
        ),
      ),
    );

    _register(
      CommandDefinition(
        name: 'midpoint',
        toolType: ToolType.midpoint,
        description: 'Create midpoint of two points',
        schema: CommandSchema(
          description: 'Midpoint between two points',
          argumentTypes: [
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'First point',
            ),
            TypeConstraint.geometry(
              allowedTypes: {GeoPoint},
              description: 'Second point',
            ),
          ],
          argumentHints: ['Select first point', 'Select second point'],
        ),
      ),
    );

    _register(
      CommandDefinition(
        name: 'perpendicular',
        toolType: ToolType.perpendicular,
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
          ],
          argumentHints: ['Select reference line', 'Select point'],
        ),
      ),
    );

    _register(
      CommandDefinition(
        name: 'parallel',
        toolType: ToolType.parallel,
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
          ],
          argumentHints: ['Select reference line', 'Select point'],
        ),
      ),
    );

    _register(
      CommandDefinition(
        name: 'perpbisector',
        toolType: ToolType.perpBisector,
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
          ],
          argumentHints: ['Select first point', 'Select second point'],
        ),
      ),
    );

    _register(
      CommandDefinition(
        name: 'intersection',
        toolType: ToolType.intersection,
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
      ),
    );
  }

  void _register(CommandDefinition definition) {
    final canonicalName = definition.name.toLowerCase();
    _byName[canonicalName] = definition;
    _byType[definition.toolType] = definition;
    for (final alias in definition.aliases) {
      _byName[alias.toLowerCase()] = definition;
    }
  }

  CommandDefinition? definitionByName(String name) {
    return _byName[name.toLowerCase()];
  }

  CommandDefinition? definitionByType(ToolType type) => _byType[type];

  CommandSchema? schemaFor(ToolType type) => definitionByType(type)?.schema;

  Iterable<CommandDefinition> get allDefinitions => _byType.values;

  bool isSupported(ToolType type) => _byType.containsKey(type);

  bool isImplemented(ToolType type) {
    final def = definitionByType(type);
    return def?.implemented ?? false;
  }

  Iterable<String> commandNames() => _byName.keys;

  ToolType? toolTypeForName(String name) => definitionByName(name)?.toolType;

  String? canonicalNameForType(ToolType type) => definitionByType(type)?.name;
}
