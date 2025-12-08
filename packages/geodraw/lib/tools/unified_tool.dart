/// Unified tool base class using SimpleExecutor
library;

import 'package:flutter/material.dart';

import '../core/command/simple_executor.dart';
import 'tool_verifier.dart';
import '../core/command/command_history.dart';
import '../core/command/command_history_entry.dart';
import '../core/dag/dag_manager.dart';
import '../models/geometry_object.dart';
import '../models/complex/complex_geometry_object.dart';
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

  /// Select an object directly (used when object is selected from menu/dropdown)
  /// This bypasses proximity search and directly adds the object as an argument
  void selectObject(GeometryObject object) {
    debugPrint('[UnifiedTool] selectObject: Called with ${object.runtimeType} (${object.id}, label: ${object.label})');
    debugPrint('[UnifiedTool] selectObject: Current arguments: ${verifier.arguments.length}');
    for (var i = 0; i < verifier.arguments.length; i++) {
      final arg = verifier.arguments[i];
      debugPrint('[UnifiedTool] selectObject:   Arg[$i]: ${arg.runtimeType} (${arg is GeometryObject ? arg.id : 'non-geometry'})');
    }
    
    // Check if command is already complete - if so, don't allow more selections
    if (verifier.isComplete) {
      debugPrint('[UnifiedTool] selectObject: Command is already complete, ignoring selection');
      return;
    }
    
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint == null) {
      debugPrint('[UnifiedTool] selectObject: No next constraint available (command may be complete)');
      return;
    }

    debugPrint('[UnifiedTool] selectObject: Next constraint: ${nextConstraint.description}');
    debugPrint('[UnifiedTool] selectObject: Constraint allowedTypes: ${nextConstraint.allowedTypes}');
    
    _ensureHistoryMarker();

    // Validate that the object matches the constraint
    debugPrint('[UnifiedTool] selectObject: Checking if object matches constraint...');
    final acceptsResult = nextConstraint.accepts(object);
    debugPrint('[UnifiedTool] selectObject: Constraint.accepts() returned: $acceptsResult');
    
    if (!acceptsResult) {
      debugPrint('[UnifiedTool] selectObject: Object ${object.runtimeType} (${object.id}) rejected by constraint: ${nextConstraint.description}');
      debugPrint('[UnifiedTool] selectObject: Constraint allowedTypes: ${nextConstraint.allowedTypes}');
      debugPrint('[UnifiedTool] selectObject: Object is UnionGeometryObjectList: ${object is UnionGeometryObjectList}');
      if (object is UnionGeometryObjectList) {
        debugPrint('[UnifiedTool] selectObject: UnionGeometryObjectList type: ${object.runtimeType}');
      }
      notifyStateChanged('Invalid selection: expected ${nextConstraint.description}');
      return;
    }

    debugPrint('[UnifiedTool] selectObject: Object ${object.runtimeType} (${object.id}) accepted, adding to arguments');
    // Object is valid - highlight it and add to argument queue
    notifyObjectSelected(object.id);
    _addArgument(object);
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
    // Clear any selection highlights
    notifyObjectSelected('');
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

    // First, try to find a valid existing object that matches the constraint
    for (final obj in nearby) {
      if (nextConstraint.accepts(obj)) {
        selectedObject = obj;
        break;
      }
    }

    // If no valid object found, try to create one
    if (selectedObject == null) {
      final created = createObjectAtPosition(position);
      // Validate created object against constraint before using it
      if (created != null && nextConstraint.accepts(created)) {
        selectedObject = created;
      }
    }

    // Only highlight and add if we have a valid object that matches the constraint
    if (selectedObject != null) {
      // Object is valid - highlight it and add to argument queue
      notifyObjectSelected(selectedObject.id);
      _addArgument(selectedObject);
    } else {
      // Invalid object selected - don't highlight, don't add to queue
      notifyStateChanged('Invalid selection: expected ${nextConstraint.description}');
    }
  }

  void _addArgument(dynamic argument) {
    try {
      debugPrint('[UnifiedTool] _addArgument: Adding ${argument.runtimeType} (${argument is GeometryObject ? argument.id : 'non-geometry'})');
      debugPrint('[UnifiedTool] _addArgument: Current arguments count: ${verifier.arguments.length}');
      final result = verifier.addArgument(argument);
      debugPrint('[UnifiedTool] _addArgument: Result isValid: ${result.isValid}');
      if (!result.isValid) {
        debugPrint('[UnifiedTool] _addArgument: Validation errors: ${result.errors.join(', ')}');
        notifyStateChanged('Error: ${result.errors.join(', ')}');
        return;
      }

      debugPrint('[UnifiedTool] _addArgument: Argument added successfully. New count: ${verifier.arguments.length}');
      debugPrint('[UnifiedTool] _addArgument: Is complete: ${verifier.isComplete}');
      notifyStateChanged(verifier.nextArgumentDescription);

      if (verifier.isComplete) {
        debugPrint('[UnifiedTool] _addArgument: Command is complete, executing...');
        _executeCommand();
      }
    } catch (e, stackTrace) {
      debugPrint('[UnifiedTool] _addArgument: Exception: $e');
      debugPrint('[UnifiedTool] _addArgument: Stack trace: $stackTrace');
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
      debugPrint('[UnifiedTool] _executeCommand: Executing $commandName with ${verifier.arguments.length} arguments');
      final result = await executor.execute(
        commandName: commandName,
        arguments: verifier.arguments,
      );

      debugPrint('[UnifiedTool] _executeCommand: Result - success=${result.success}, message="${result.message}", object=${result.object?.runtimeType}');

      final entry = _buildHistoryEntry(
        arguments: argsSnapshot,
        result: result,
        marker: marker,
      );

      if (result.success) {
        if (result.object is GeometryObject) {
          final geometry = result.object as GeometryObject;
          debugPrint('[UnifiedTool] _executeCommand: Notifying object created: ${geometry.id}');
          notifyObjectCreated(geometry, geometry.dependencies);
        } else {
          debugPrint('[UnifiedTool] _executeCommand: Result object is not a GeometryObject: ${result.object?.runtimeType}');
        }
        notifyStateChanged(result.message);
        _recordHistory(entry, result);
        // Clear selection highlights after successful execution
        notifyObjectSelected('');
        _resetInternal(rollback: false);
      } else {
        debugPrint('[UnifiedTool] _executeCommand: ❌ Execution failed: ${result.message}');
        _recordHistory(entry, result);
        // Clear selection highlights on error
        notifyObjectSelected('');
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
      // Clear selection highlights on exception
      notifyObjectSelected('');
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
