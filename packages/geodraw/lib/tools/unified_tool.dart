/// Unified tool base class using SimpleExecutor
library;

import 'package:flutter/material.dart';
import '../dag/dag_manager.dart';
import '../models/geometry_object.dart';
import '../command/simple_executor.dart';
import '../command/tool_verifier.dart';
import 'tool.dart';

/// Base class for tools using direct execution with sequential validation
abstract class UnifiedTool implements Tool {
  final DAGManager dagManager;
  final SimpleExecutor executor;
  late final ToolVerifier verifier;

  final OnObjectCreated? onObjectCreated;
  final OnObjectSelected? onObjectSelected;
  final OnToolStateChanged? onToolStateChanged;

  UnifiedTool({
    required this.dagManager,
    this.onObjectCreated,
    this.onObjectSelected,
    this.onToolStateChanged,
  }) : executor = SimpleExecutor(dagManager) {
    verifier = ToolVerifier(type);
  }

  @override
  void handleInput(PointerEvent event) {
    if (event is PointerDownEvent) {
      _handleClick(event.position);
    }
  }

  /// Handle a click at the given position
  void _handleClick(Offset position) {
    // Get what type we need next from verifier
    final nextType = verifier.schema.getNextArgumentType(verifier.arguments);
    if (nextType == null) {
      return; // Already complete
    }

    // Try to find an existing object at the click position
    final nearby = dagManager.proximitySearch(position, threshold: 15.0);
    GeometryObject? selectedObject;

    // Find an object that matches the expected type
    for (final obj in nearby) {
      if (nextType.accepts(obj.runtimeType)) {
        selectedObject = obj;
        break;
      }
    }

    // If no suitable object found, try to create one
    selectedObject ??= createObjectAtPosition(position);

    if (selectedObject != null) {
      _addArgument(selectedObject);
    }
  }

  /// Add an argument with validation
  void _addArgument(dynamic argument) {
    try {
      // Validate and add argument using verifier
      final result = verifier.addArgument(argument);

      if (!result.isValid) {
        notifyStateChanged('Error: ${result.errors.join(', ')}');
        return;
      }

      // Update state with what's needed next
      notifyStateChanged(verifier.nextArgumentDescription);

      // Execute if complete
      if (verifier.isComplete) {
        _executeCommand();
      }
    } catch (e) {
      notifyStateChanged('Error: $e');
    }
  }

  /// Execute the completed command
  Future<void> _executeCommand() async {
    if (!verifier.isComplete) {
      return; // Not complete yet
    }

    try {
      final result = await executor.execute(
        type: type,
        arguments: verifier.arguments,
      );

      if (result.success) {
        // Notify about created object
        if (result.object != null) {
          onObjectCreated?.call(result.object!, result.object!.dependencies);
        }
        notifyStateChanged(result.message);
      } else {
        notifyStateChanged('Error: ${result.message}');
      }
    } catch (e) {
      notifyStateChanged('Execution error: $e');
    } finally {
      // Reset for next operation
      reset();
    }
  }

  /// Create an object at the given position if appropriate
  /// Returns null if this tool can't create objects for the expected type
  /// Subclasses should override this to create appropriate objects
  GeometryObject? createObjectAtPosition(Offset position) {
    return null; // Default: don't create objects
  }

  @override
  void reset() {
    verifier.reset();
    notifyStateChanged(stateDescription);
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

  /// Notify that tool state changed
  void notifyStateChanged(String state) {
    onToolStateChanged?.call(state);
  }
}
