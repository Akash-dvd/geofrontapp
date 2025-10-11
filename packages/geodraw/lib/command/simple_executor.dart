/// Simple, direct command executor - no unnecessary wrappers
library;

import '../dag/dag_manager.dart';
import '../models/geometry_object.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_circle.dart';
import '../tools/tool.dart';

/// Result of command execution
class ExecutionResult {
  final bool success;
  final String? objectId;
  final String message;
  final GeometryObject? object;

  ExecutionResult._({
    required this.success,
    this.objectId,
    required this.message,
    this.object,
  });

  factory ExecutionResult.successful({
    String? objectId,
    required String message,
    GeometryObject? object,
  }) {
    return ExecutionResult._(
      success: true,
      objectId: objectId,
      message: message,
      object: object,
    );
  }

  factory ExecutionResult.error(String message) {
    return ExecutionResult._(success: false, message: message);
  }

  @override
  String toString() => success ? 'Success: $message' : 'Error: $message';
}

/// Internal result of geometry construction
class _ConstructionResult {
  final GeometryObject object;
  final List<String> dependencies;

  _ConstructionResult(this.object, this.dependencies);
}

/// Simple executor that directly calls geometry class constructors
/// No wrappers, no indirection - just parse → construct → add to DAG
class SimpleExecutor {
  final DAGManager dagManager;

  int _objectCounter = 0;
  int _labelCounter = 0;

  SimpleExecutor(this.dagManager);

  /// Execute a command directly
  /// Arguments should already be resolved (strings → objects)
  Future<ExecutionResult> execute({
    required ToolType type,
    required List<dynamic> arguments,
    String? customLabel,
  }) async {
    try {
      // Validate argument types based on command
      final validation = _validateArguments(type, arguments);
      if (!validation.success) {
        return validation;
      }

      // Generate ID and label
      final id = _generateId(type.name);
      final label = customLabel ?? _generateLabel(type);

      // Call appropriate factory method
      final result = _constructGeometry(type, id, label, arguments);

      // Add to DAG
      dagManager.addObject(result.object, result.dependencies);

      return ExecutionResult.successful(
        objectId: result.object.id,
        message: 'Created ${result.object.label}',
        object: result.object,
      );
    } catch (e) {
      return ExecutionResult.error('Execution failed: $e');
    }
  }

  /// Construct geometry object by calling appropriate factory
  _ConstructionResult _constructGeometry(
    ToolType type,
    String id,
    String label,
    List<dynamic> args,
  ) {
    return switch (type) {
      // Point: x, y
      ToolType.point => () {
        final x = (args[0] as num).toDouble();
        final y = (args[1] as num).toDouble();
        final point = GeoPointer(id: id, label: label, x: x, y: y);
        return _ConstructionResult(point, []);
      }(),

      // Line: p1, p2
      ToolType.line => () {
        final p1 = args[0] as GeoPoint;
        final p2 = args[1] as GeoPoint;
        final line = GeoLine2P.fromPoints(id: id, label: label, p1: p1, p2: p2);
        return _ConstructionResult(line, [p1.id, p2.id]);
      }(),

      // Circle: center, pointOnCircle
      ToolType.circle => () {
        final center = args[0] as GeoPoint;
        final pointOnCircle = args[1] as GeoPoint;
        final circle = GeoCircle2P.fromPoints(
          id: id,
          label: label,
          center: center,
          pointOnCircle: pointOnCircle,
        );
        return _ConstructionResult(circle, [center.id, pointOnCircle.id]);
      }(),

      // Circle through 3 points: p1, p2, p3
      ToolType.circleThreePoints => () {
        final p1 = args[0] as GeoPoint;
        final p2 = args[1] as GeoPoint;
        final p3 = args[2] as GeoPoint;
        final circle = GeoCircle3P.fromPoints(
          id: id,
          label: label,
          p1: p1,
          p2: p2,
          p3: p3,
        );
        if (circle == null) {
          throw ArgumentError('Cannot create circle: points are collinear');
        }
        return _ConstructionResult(circle, [p1.id, p2.id, p3.id]);
      }(),

      // Midpoint: p1, p2
      ToolType.midpoint => () {
        final p1 = args[0] as GeoPoint;
        final p2 = args[1] as GeoPoint;
        final midpoint = GeoMidpoint.fromPoints(
          id: id,
          label: label,
          p1: p1,
          p2: p2,
        );
        return _ConstructionResult(midpoint, [p1.id, p2.id]);
      }(),

      // Perpendicular: line, point
      ToolType.perpendicular => () {
        final line = args[0] as GeoLine;
        final point = args[1] as GeoPoint;
        final perpLine = GeoPerpendicularLine.fromLine(
          id: id,
          label: label,
          line: line,
          point: point,
        );
        return _ConstructionResult(perpLine, [line.id, point.id]);
      }(),

      // Parallel: line, point
      ToolType.parallel => () {
        final line = args[0] as GeoLine;
        final point = args[1] as GeoPoint;
        final parallelLine = GeoParallelLine.fromLine(
          id: id,
          label: label,
          line: line,
          point: point,
        );
        return _ConstructionResult(parallelLine, [line.id, point.id]);
      }(),

      // Perpendicular bisector: p1, p2
      ToolType.perpBisector => () {
        final p1 = args[0] as GeoPoint;
        final p2 = args[1] as GeoPoint;
        final perpBisector = GeoPerpendicularBisector.fromPoints(
          id: id,
          label: label,
          p1: p1,
          p2: p2,
        );
        return _ConstructionResult(perpBisector, [p1.id, p2.id]);
      }(),

      // Not yet implemented
      ToolType.intersection => throw UnimplementedError(
        'Intersection not yet implemented',
      ),

      // Unknown
      _ => throw ArgumentError('Command type $type not supported'),
    };
  }

  /// Validate arguments for a command type
  ExecutionResult _validateArguments(ToolType type, List<dynamic> arguments) {
    // Basic validation - can be expanded
    final expectedCounts = {
      ToolType.point: 2, // x, y
      ToolType.line: 2, // p1, p2
      ToolType.circle: 2, // center, pointOnCircle
      ToolType.circleThreePoints: 3, // p1, p2, p3
      ToolType.midpoint: 2, // p1, p2
      ToolType.perpendicular: 2, // line, point
      ToolType.parallel: 2, // line, point
      ToolType.perpBisector: 2, // p1, p2
    };

    final expected = expectedCounts[type];
    if (expected != null && arguments.length != expected) {
      return ExecutionResult.error(
        'Expected $expected arguments for ${type.name}, got ${arguments.length}',
      );
    }

    return ExecutionResult.successful(message: 'Valid');
  }

  /// Generate unique ID
  String _generateId(String prefix) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_objectCounter++}';
  }

  /// Generate label based on type
  String _generateLabel(ToolType type) {
    final prefix = switch (type) {
      ToolType.point => 'P',
      ToolType.midpoint => 'M',
      ToolType.line ||
      ToolType.perpendicular ||
      ToolType.parallel ||
      ToolType.perpBisector => 'l',
      ToolType.circle || ToolType.circleThreePoints => 'c',
      _ => 'O',
    };

    // For uppercase single letters, use alphabet
    if (prefix.length == 1 && prefix.toUpperCase() == prefix) {
      const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      if (_labelCounter < 26) {
        return letters[_labelCounter++];
      }
    }

    return '$prefix${++_labelCounter}';
  }

  /// Reset counters (for testing)
  void resetCounters() {
    _objectCounter = 0;
    _labelCounter = 0;
  }
}
