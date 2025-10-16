/// Shared runtime primitives for executing geometric commands.
library;

import '../dag/dag_manager.dart';
import '../../models/geometry_object.dart';

/// Result of command execution across tools, CLI, and AI surfaces.
class ExecutionResult {
  final bool success;
  final String? objectId;
  final String message;
  final GeometryObject? object;

  const ExecutionResult._({
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

/// Execution context shared by all command surfaces.
class CommandExecutionContext {
  final DAGManager dagManager;
  final String? customLabel;

  CommandExecutionContext({required this.dagManager, this.customLabel});

  /// Generate a unique identifier using the DAG manager's generator.
  String generateId([String prefix = 'obj']) => dagManager.generateId(prefix);

  /// Resolve the label to use for a constructed object.
  /// Falls back to [fallback] when no custom label is provided.
  String resolveLabel(String Function() fallback) {
    final label = customLabel;
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return fallback();
  }
}
