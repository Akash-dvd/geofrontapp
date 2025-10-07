import '../dag/dag_manager.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_circle.dart';
import 'cli.dart';

/// Executes parsed commands
class CommandExecutor {
  final DAGManager dagManager;
  final CommandHistory history;

  int _objectCounter = 0;

  CommandExecutor({
    required this.dagManager,
    CommandHistory? history,
  }) : history = history ?? CommandHistory();

  /// Execute a command
  Future<ExecutionResult> execute(Command command) async {
    try {
      final result = await _executeCommand(command);
      history.add(command.originalInput, result);
      return result;
    } catch (e) {
      final errorResult = ExecutionResult.error(e.toString());
      history.add(command.originalInput, errorResult);
      return errorResult;
    }
  }

  /// Execute command by name
  Future<ExecutionResult> _executeCommand(Command command) async {
    switch (command.name.toLowerCase()) {
      case 'point':
        return _executePoint(command);
      case 'line':
        return _executeLine(command);
      case 'circle':
        return _executeCircle(command);
      case 'midpoint':
        return _executeMidpoint(command);
      case 'clear':
        return _executeClear();
      case 'list':
        return _executeList();
      default:
        throw ArgumentError('Unknown command: ${command.name}');
    }
  }

  /// Execute point command: point(x, y) or point(x, y, label)
  ExecutionResult _executePoint(Command command) {
    if (command.arguments.length < 2) {
      throw ArgumentError('point requires at least 2 arguments: x, y, [label]');
    }

    final x = (command.arguments[0] as num).toDouble();
    final y = (command.arguments[1] as num).toDouble();
    final label = command.arguments.length > 2
        ? command.arguments[2].toString()
        : _generateLabel('P');

    final point = GeoPointer(
      id: _generateId('point'),
      label: label,
      x: x,
      y: y,
    );

    dagManager.addObject(point, []);
    
    return ExecutionResult.successful(
      objectId: point.id,
      message: 'Created point $label at ($x, $y)',
      data: point,
    );
  }

  /// Execute line command: line(point1_id, point2_id) or line(point1_id, point2_id, label)
  ExecutionResult _executeLine(Command command) {
    if (command.arguments.length < 2) {
      throw ArgumentError('line requires 2 point IDs or labels');
    }

    final p1Id = command.arguments[0].toString();
    final p2Id = command.arguments[1].toString();
    
    final p1 = _findObject(p1Id) as GeoPoint?;
    final p2 = _findObject(p2Id) as GeoPoint?;

    if (p1 == null) throw ArgumentError('Point not found: $p1Id');
    if (p2 == null) throw ArgumentError('Point not found: $p2Id');

    final label = command.arguments.length > 2
        ? command.arguments[2].toString()
        : _generateLabel('l');

    final line = GeoLine2P.fromPoints(
      id: _generateId('line'),
      label: label,
      p1: p1,
      p2: p2,
    );

    dagManager.addObject(line, [p1.id, p2.id]);
    
    return ExecutionResult.successful(
      objectId: line.id,
      message: 'Created line $label through ${p1.label} and ${p2.label}',
      data: line,
    );
  }

  /// Execute circle command: circle(center_id, point_id) or circle(center_id, radius)
  ExecutionResult _executeCircle(Command command) {
    if (command.arguments.length < 2) {
      throw ArgumentError('circle requires center point and either point or radius');
    }

    final centerId = command.arguments[0].toString();
    final center = _findObject(centerId) as GeoPoint?;

    if (center == null) throw ArgumentError('Center point not found: $centerId');

    final label = command.arguments.length > 2
        ? command.arguments[2].toString()
        : _generateLabel('c');

    // Check if second argument is a number (radius) or point ID
    if (command.arguments[1] is num) {
      final radius = (command.arguments[1] as num).toDouble();
      
      // Create temporary point for radius
      final tempPoint = GeoPointer(
        id: _generateId('temp'),
        label: 'temp',
        x: center.x + radius,
        y: center.y,
      );
      
      final circle = GeoCircle2P.fromPoints(
        id: _generateId('circle'),
        label: label,
        center: center,
        pointOnCircle: tempPoint,
      );

      dagManager.addObject(circle, [center.id]);
      
      return ExecutionResult.successful(
        objectId: circle.id,
        message: 'Created circle $label with center ${center.label} and radius $radius',
        data: circle,
      );
    } else {
      final pointId = command.arguments[1].toString();
      final point = _findObject(pointId) as GeoPoint?;

      if (point == null) throw ArgumentError('Point not found: $pointId');

      final circle = GeoCircle2P.fromPoints(
        id: _generateId('circle'),
        label: label,
        center: center,
        pointOnCircle: point,
      );

      dagManager.addObject(circle, [center.id, point.id]);
      
      return ExecutionResult.successful(
        objectId: circle.id,
        message: 'Created circle $label with center ${center.label} through ${point.label}',
        data: circle,
      );
    }
  }

  /// Execute midpoint command: midpoint(point1_id, point2_id, [label])
  ExecutionResult _executeMidpoint(Command command) {
    if (command.arguments.length < 2) {
      throw ArgumentError('midpoint requires 2 point IDs');
    }

    final p1Id = command.arguments[0].toString();
    final p2Id = command.arguments[1].toString();
    
    final p1 = _findObject(p1Id) as GeoPoint?;
    final p2 = _findObject(p2Id) as GeoPoint?;

    if (p1 == null) throw ArgumentError('Point not found: $p1Id');
    if (p2 == null) throw ArgumentError('Point not found: $p2Id');

    final label = command.arguments.length > 2
        ? command.arguments[2].toString()
        : _generateLabel('M');

    final midpoint = GeoMidpoint.fromPoints(
      id: _generateId('midpoint'),
      label: label,
      p1: p1,
      p2: p2,
    );

    dagManager.addObject(midpoint, [p1.id, p2.id]);
    
    return ExecutionResult.successful(
      objectId: midpoint.id,
      message: 'Created midpoint $label between ${p1.label} and ${p2.label}',
      data: midpoint,
    );
  }

  /// Execute clear command
  ExecutionResult _executeClear() {
    final count = dagManager.nodeCount;
    dagManager.clear();
    return ExecutionResult.successful(
      message: 'Cleared $count objects',
    );
  }

  /// Execute list command
  ExecutionResult _executeList() {
    final objects = dagManager.nodes.values
        .map((node) => '${node.object.label} (${node.object.runtimeType})')
        .join(', ');
    
    return ExecutionResult.successful(
      message: 'Objects (${dagManager.nodeCount}): $objects',
      data: dagManager.nodes.values.toList(),
    );
  }

  /// Find object by ID or label
  dynamic _findObject(String idOrLabel) {
    // Try by ID first
    final obj = dagManager.getObject(idOrLabel);
    if (obj != null) return obj;

    // Try by label
    for (final node in dagManager.nodes.values) {
      if (node.object.label == idOrLabel) {
        return node.object;
      }
    }

    return null;
  }

  /// Generate unique ID
  String _generateId(String prefix) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_objectCounter++}';
  }

  /// Generate label
  int _labelCounter = 0;
  String _generateLabel(String prefix) {
    return '$prefix${++_labelCounter}';
  }
}
