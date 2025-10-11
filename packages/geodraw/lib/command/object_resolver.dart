/// Lightweight utility to resolve string references to DAG objects
library;

import '../dag/dag_manager.dart';
import '../tools/tool.dart';

/// Simple resolver for converting string IDs/labels to objects
class ObjectResolver {
  final DAGManager dagManager;

  ObjectResolver(this.dagManager);

  /// Resolve a single reference (ID or label) to an object
  dynamic resolve(String reference) {
    // Try by ID first (faster)
    final byId = dagManager.getObject(reference);
    if (byId != null) return byId;

    // Try by label
    for (final node in dagManager.nodes.values) {
      if (node.object.label == reference) {
        return node.object;
      }
    }

    return null;
  }

  /// Resolve a list of arguments (keeps non-strings as-is)
  List<dynamic> resolveArguments(List<dynamic> arguments) {
    return arguments.map((arg) {
      if (arg is String) {
        final resolved = resolve(arg);
        return resolved ?? arg; // Keep string if not found
      }
      return arg; // Keep numbers, objects as-is
    }).toList();
  }

  /// Batch resolve multiple references
  List<dynamic> resolveAll(List<String> references) {
    return references.map((ref) => resolve(ref)).toList();
  }
}

/// Map command name strings to ToolType
class CommandNameMapper {
  /// Map a command name string to ToolType enum
  static ToolType? toToolType(String commandName) {
    return _commandMap[commandName.toLowerCase()];
  }

  /// Get command name from ToolType
  static String? fromToolType(ToolType type) {
    return _reverseMap[type];
  }

  /// Check if command name is valid
  static bool isValid(String commandName) {
    return _commandMap.containsKey(commandName.toLowerCase());
  }

  // Forward mapping: string → ToolType
  static final Map<String, ToolType> _commandMap = {
    'point': ToolType.point,
    'line': ToolType.line,
    'segment': ToolType.lineSegment,
    'circle': ToolType.circle,
    'circle3': ToolType.circleThreePoints,
    'midpoint': ToolType.midpoint,
    'mid': ToolType.midpoint,
    'perpendicular': ToolType.perpendicular,
    'perp': ToolType.perpendicular,
    'parallel': ToolType.parallel,
    'para': ToolType.parallel,
    'perpbisector': ToolType.perpBisector,
    'perpbis': ToolType.perpBisector,
    'intersection': ToolType.intersection,
    'intersect': ToolType.intersection,
  };

  // Reverse mapping: ToolType → canonical string
  static final Map<ToolType, String> _reverseMap = {
    ToolType.point: 'point',
    ToolType.line: 'line',
    ToolType.lineSegment: 'segment',
    ToolType.circle: 'circle',
    ToolType.circleThreePoints: 'circle3',
    ToolType.midpoint: 'midpoint',
    ToolType.perpendicular: 'perpendicular',
    ToolType.parallel: 'parallel',
    ToolType.perpBisector: 'perpbisector',
    ToolType.intersection: 'intersection',
  };
}
