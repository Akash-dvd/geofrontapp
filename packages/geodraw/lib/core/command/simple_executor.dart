/// Simple, direct command executor built on the DAG manager
library;

import '../dag/dag_manager.dart';
import '../../tools/tool.dart';
import '../../models/geometry_object.dart';
import '../../models/simple/geo_point.dart';
import '../../models/simple/geo_line.dart';
import '../../models/simple/geo_circle.dart';
import 'command_registry.dart';

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

class _ConstructionResult {
  final GeometryObject object;
  final List<String> dependencies;

  _ConstructionResult(this.object, this.dependencies);
}

/// Executes geometry commands by invoking constructors and mutating the DAG
class SimpleExecutor {
  final DAGManager dagManager;
  final CommandRegistry _registry;

  int _objectCounter = 0;
  int _labelCounter = 0;

  SimpleExecutor(this.dagManager) : _registry = dagManager.commandRegistry;

  Future<ExecutionResult> execute({
    required ToolType type,
    required List<dynamic> arguments,
    String? customLabel,
  }) async {
    final definition = _registry.definitionByType(type);
    if (definition == null) {
      return ExecutionResult.error('Unsupported command type: $type');
    }

    final schema = definition.schema;
    final validation = schema.validate(arguments);
    if (!validation.isValid) {
      final error = validation.errors.join(', ');
      return ExecutionResult.error('Validation failed: $error');
    }

    if (!_registry.isImplemented(type)) {
      return ExecutionResult.error('${definition.name} is not implemented yet');
    }

    try {
      final id = _generateId(type.name);
      final label = customLabel ?? _generateLabel(type);
      final construction = _constructGeometry(type, id, label, arguments);

      dagManager.addObject(construction.object, construction.dependencies);

      return ExecutionResult.successful(
        objectId: construction.object.id,
        message: 'Created ${construction.object.label}',
        object: construction.object,
      );
    } catch (e) {
      return ExecutionResult.error('Execution failed: $e');
    }
  }

  _ConstructionResult _constructGeometry(
    ToolType type,
    String id,
    String label,
    List<dynamic> args,
  ) {
    switch (type) {
      case ToolType.point:
        final x = (args[0] as num).toDouble();
        final y = (args[1] as num).toDouble();
        final point = GeoPointer(id: id, label: label, x: x, y: y);
        return _ConstructionResult(point, []);
      case ToolType.line:
        final p1 = args[0] as GeoPoint;
        final p2 = args[1] as GeoPoint;
        final line = GeoLine2P.fromPoints(id: id, label: label, p1: p1, p2: p2);
        return _ConstructionResult(line, [p1.id, p2.id]);
      case ToolType.circle:
        final center = args[0] as GeoPoint;
        final pointOnCircle = args[1] as GeoPoint;
        final circle = GeoCircle2P.fromPoints(
          id: id,
          label: label,
          center: center,
          pointOnCircle: pointOnCircle,
        );
        return _ConstructionResult(circle, [center.id, pointOnCircle.id]);
      case ToolType.circleThreePoints:
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
      case ToolType.midpoint:
        final p1 = args[0] as GeoPoint;
        final p2 = args[1] as GeoPoint;
        final midpoint = GeoMidpoint.fromPoints(
          id: id,
          label: label,
          p1: p1,
          p2: p2,
        );
        return _ConstructionResult(midpoint, [p1.id, p2.id]);
      case ToolType.perpendicular:
        final line = args[0] as GeoLine;
        final point = args[1] as GeoPoint;
        final perpLine = GeoPerpendicularLine.fromLine(
          id: id,
          label: label,
          line: line,
          point: point,
        );
        return _ConstructionResult(perpLine, [line.id, point.id]);
      case ToolType.parallel:
        final line = args[0] as GeoLine;
        final point = args[1] as GeoPoint;
        final parallelLine = GeoParallelLine.fromLine(
          id: id,
          label: label,
          line: line,
          point: point,
        );
        return _ConstructionResult(parallelLine, [line.id, point.id]);
      case ToolType.perpBisector:
        final p1 = args[0] as GeoPoint;
        final p2 = args[1] as GeoPoint;
        final perpBisector = GeoPerpendicularBisector.fromPoints(
          id: id,
          label: label,
          p1: p1,
          p2: p2,
        );
        return _ConstructionResult(perpBisector, [p1.id, p2.id]);
      case ToolType.intersection:
        throw UnimplementedError('Intersection not implemented yet');
      default:
        throw ArgumentError('Command type $type not supported');
    }
  }

  String _generateId(String prefix) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_objectCounter++}';
  }

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

    if (prefix.length == 1 && prefix.toUpperCase() == prefix) {
      const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      if (_labelCounter < letters.length) {
        return letters[_labelCounter++];
      }
    }

    return '$prefix${++_labelCounter}';
  }

  void resetCounters() {
    _objectCounter = 0;
    _labelCounter = 0;
  }
}
