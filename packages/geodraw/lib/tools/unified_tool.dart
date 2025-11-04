/// Unified tool base class using SimpleExecutor
library;

import 'package:flutter/material.dart';

import '../core/command/simple_executor.dart';
import 'tool_verifier.dart';
import '../core/command/command_history.dart';
import '../core/command/command_history_entry.dart';
import '../core/dag/dag_manager.dart';
import '../models/geometry_object.dart';
import 'tool.dart';

/// Base class for tools using direct execution with sequential validation
abstract class UnifiedTool with ToolCallbacksMixin implements Tool {
  final DAGManager dagManager;
  final SimpleExecutor executor;
  late final ToolVerifier verifier;
  HistoryMarker? _historyMarker;
  final CommandHistory? commandHistory;

  UnifiedTool({
    required this.dagManager,
    OnObjectCreated? onObjectCreated,
    OnObjectSelected? onObjectSelected,
    OnToolStateChanged? onToolStateChanged,
    this.commandHistory,
  }) : executor = SimpleExecutor(dagManager) {
    this.onObjectCreated = onObjectCreated;
    this.onObjectSelected = onObjectSelected;
    this.onToolStateChanged = onToolStateChanged;
    verifier = ToolVerifier(commandName, registry: dagManager.commandRegistry);
  }

  String get commandName;

  @override
  void handleInput(PointerEvent event) {
    if (event is PointerDownEvent) {
      _handleClick(event.position);
    }
  }

  void _ensureHistoryMarker() {
    if (_historyMarker == null && verifier.arguments.isEmpty) {
      _historyMarker = dagManager.markHistory();
    }
  }

  void _rollbackMarker() {
    if (_historyMarker != null) {
      dagManager.rollbackToMarker(_historyMarker!);
      _historyMarker = null;
    }
  }

  void _handleExecutionError(String message) {
    _rollbackMarker();
    verifier.reset();
    notifyStateChanged('Error: $message');
  }

  void _resetInternal({required bool rollback}) {
    if (rollback) {
      _rollbackMarker();
    } else {
      _historyMarker = null;
    }
    verifier.reset();
    notifyStateChanged(stateDescription);
  }

  void _handleClick(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint == null) {
      return;
    }

    _ensureHistoryMarker();

    final nearby = dagManager.proximitySearch(position, threshold: 15.0);
    GeometryObject? selectedObject;

    for (final obj in nearby) {
      if (nextConstraint.accepts(obj)) {
        selectedObject = obj;
        break;
      }
    }

    selectedObject ??= createObjectAtPosition(position);

    if (selectedObject != null) {
      _addArgument(selectedObject);
    }
  }

  void _addArgument(dynamic argument) {
    try {
      final result = verifier.addArgument(argument);
      if (!result.isValid) {
        notifyStateChanged('Error: ${result.errors.join(', ')}');
        return;
      }

      notifyStateChanged(verifier.nextArgumentDescription);

      if (verifier.isComplete) {
        _executeCommand();
      }
    } catch (e) {
      _handleExecutionError(e.toString());
    }
  }

  Future<void> _executeCommand() async {
    if (!verifier.isComplete) {
      return;
    }

    final argsSnapshot = List<dynamic>.from(verifier.arguments);
    final marker = _historyMarker;

    try {
      final result = await executor.execute(
        commandName: commandName,
        arguments: verifier.arguments,
      );

      final entry = _buildHistoryEntry(
        arguments: argsSnapshot,
        result: result,
        marker: marker,
      );

      if (result.success) {
        if (result.object is GeometryObject) {
          final geometry = result.object as GeometryObject;
          notifyObjectCreated(geometry, geometry.dependencies);
        }
        notifyStateChanged(result.message);
        _recordHistory(entry, result);
        _resetInternal(rollback: false);
      } else {
        _recordHistory(entry, result);
        _handleExecutionError(result.message);
      }
    } catch (e) {
      final message = 'Execution error: $e';
      final failure = ExecutionResult.error(message);
      final entry = _buildHistoryEntry(
        arguments: argsSnapshot,
        result: failure,
        marker: marker,
      );
      _recordHistory(entry, failure);
      _handleExecutionError(message);
    }
  }

  CommandHistoryEntry _buildHistoryEntry({
    required List<dynamic> arguments,
    required ExecutionResult result,
    HistoryMarker? marker,
  }) {
    final definition = dagManager.commandRegistry.definitionByName(commandName);
    final canonical = definition?.name ?? commandName;
    final commandId =
        result.objectId ??
        '${canonical}_${DateTime.now().millisecondsSinceEpoch}';

    return CommandHistoryEntry(
      commandId: commandId,
      canonicalName: canonical,
      arguments: arguments,
      historyMarker: marker,
    );
  }

  void _recordHistory(CommandHistoryEntry entry, ExecutionResult result) {
    commandHistory?.add(entry, result);
  }

  GeometryObject? createObjectAtPosition(Offset position) => null;

  @override
  void reset() {
    _resetInternal(rollback: true);
  }

  @override
  bool get isComplete => verifier.isComplete;

  @override
  String get stateDescription {
    if (verifier.arguments.isEmpty) {
      return 'Click to start ${name.toLowerCase()}';
    }
    return verifier.nextArgumentDescription;
  }
}
