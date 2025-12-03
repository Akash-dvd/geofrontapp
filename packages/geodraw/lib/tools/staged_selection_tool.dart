import 'dart:async';

import 'package:flutter/material.dart';

import '../core/command/command_history.dart';
import '../core/command/simple_executor.dart';
import '../core/dag/dag_manager.dart';
import '../models/geometry_object.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_circle.dart';
import 'tool.dart';
import 'tool_verifier.dart';

/// Callback for requesting parameter input from user
typedef OnParameterRequest = Future<Map<String, dynamic>?> Function(
  String title,
  List<ParameterSpec> parameters,
);

/// Specification for a parameter input
class ParameterSpec {
  final String key;
  final String label;
  final ParameterType type;
  final dynamic defaultValue;
  final String? hint;

  const ParameterSpec({
    required this.key,
    required this.label,
    required this.type,
    this.defaultValue,
    this.hint,
  });
}

/// Types of parameters that can be requested
enum ParameterType {
  angle,
  number,
  text,
  boolean,
}

/// Base class for tools that require multiple selection steps
abstract class StagedSelectionTool with ToolCallbacksMixin implements Tool {
  StagedSelectionTool({
    required this.dagManager,
    this.commandHistory,
    OnObjectCreated? onObjectCreated,
    OnObjectSelected? onObjectSelected,
    OnToolStateChanged? onToolStateChanged,
    this.onParameterRequest,
  }) : executor = SimpleExecutor(dagManager) {
    this.onObjectCreated = onObjectCreated;
    this.onObjectSelected = onObjectSelected;
    this.onToolStateChanged = onToolStateChanged;
  }

  final DAGManager dagManager;
  final SimpleExecutor executor;
  final CommandHistory? commandHistory;
  final OnParameterRequest? onParameterRequest;

  final List<GeometryObject> _selectedObjects = <GeometryObject>[];
  int _currentStage = 0;

  double get selectionThreshold => 15.0;

  /// Get currently selected objects (for UI highlighting)
  List<GeometryObject> get selectedObjects => List.unmodifiable(_selectedObjects);

  /// Command name to execute
  String get commandName;

  /// Number of selection stages required
  int get totalStages;

  /// Type constraints for each stage (what type of object can be selected)
  List<Set<Type>> get stageTypeConstraints;

  /// Prompt message for each stage
  String stagePrompt(int stage);

  /// Optional: Get parameter specifications (for rotation, dilation, etc.)
  List<ParameterSpec> get parameterSpecs => const [];

  /// Build command arguments from selected objects and parameters
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  );

  /// Success message after execution
  String successMessage(GeometryObject result);

  /// Failure message
  String failureMessage(String reason);

  @override
  void handleInput(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }

    debugPrint('[${name}] handleInput: position=${event.position}, currentStage=$_currentStage, selectedCount=${_selectedObjects.length}');

    final candidate = _resolveObjectAt(event.position);

    if (candidate == null) {
      debugPrint('[${name}] No object found at position ${event.position}');
      notifyStateChanged('No object found at that location');
      return;
    }

    debugPrint('[${name}] Found candidate: ${candidate.runtimeType} (id: ${candidate.id}, label: ${candidate.label})');

    // Check if candidate matches current stage constraints
    final constraints = stageTypeConstraints[_currentStage];
    debugPrint('[${name}] Stage $_currentStage constraints: ${constraints.map((t) => t.toString()).join(', ')}');
    
    if (!_matchesConstraints(candidate, constraints)) {
      final expectedTypes = constraints.map((t) => t.toString()).join(' or ');
      debugPrint('[${name}] ❌ Constraint mismatch: ${candidate.runtimeType} does not match $expectedTypes');
      notifyStateChanged('Please select $expectedTypes');
      return;
    }

    debugPrint('[${name}] ✅ Constraint match! Adding ${candidate.runtimeType} to selection');
    _selectedObjects.add(candidate);
    
    // Notify that object was selected (for highlighting)
    notifyObjectSelected(candidate.id);
    debugPrint('[${name}] Notified object selected: ${candidate.id}');
    
    _currentStage++;
    debugPrint('[${name}] Advanced to stage $_currentStage');

    if (_currentStage < totalStages) {
      // More stages needed
      final prompt = stagePrompt(_currentStage);
      debugPrint('[${name}] More stages needed. Prompt: $prompt');
      notifyStateChanged(prompt);
    } else {
      // All stages complete, proceed to execution
      debugPrint('[${name}] All stages complete! Executing transformation...');
      _executeTransformation();
    }
  }

  GeometryObject? _resolveObjectAt(Offset position) {
    debugPrint('[${name}] Resolving object at position: $position (threshold: $selectionThreshold)');
    final nearby = dagManager.proximitySearch(
      position,
      threshold: selectionThreshold,
    );
    debugPrint('[${name}] Proximity search found ${nearby.length} objects nearby');
    if (nearby.isNotEmpty) {
      for (var i = 0; i < nearby.length; i++) {
        debugPrint('[${name}]   [$i] ${nearby[i].runtimeType} (id: ${nearby[i].id}, label: ${nearby[i].label})');
      }
    }
    return nearby.isNotEmpty ? nearby.first : null;
  }

  bool _matchesConstraints(GeometryObject object, Set<Type> constraints) {
    if (constraints.isEmpty) {
      debugPrint('[${name}] Constraints empty, accepting any object');
      return true;
    }
    // Use 'is' check to support subclasses (e.g., GeoCircle2P is GeoCircle)
    final matches = constraints.any((type) {
      // Direct type match
      if (object.runtimeType == type) {
        debugPrint('[${name}]   Direct type match: ${object.runtimeType} == $type');
        return true;
      }
      
      // Check if object is instance of constraint type (for subclasses)
      // We need to check against known base types
      if (type == GeoPoint && object is GeoPoint) {
        debugPrint('[${name}]   Instance check: ${object.runtimeType} is GeoPoint');
        return true;
      }
      if (type == GeoLine && object is GeoLine) {
        debugPrint('[${name}]   Instance check: ${object.runtimeType} is GeoLine');
        return true;
      }
      if (type == GeoCircle && object is GeoCircle) {
        debugPrint('[${name}]   Instance check: ${object.runtimeType} is GeoCircle');
        return true;
      }
      
      // For other types, check runtime type
      return false;
    });
    debugPrint('[${name}] Constraint check: ${object.runtimeType} matches constraints=$matches');
    return matches;
  }

  Future<void> _executeTransformation() async {
    debugPrint('[${name}] ========== EXECUTING TRANSFORMATION ==========');
    debugPrint('[${name}] Selected objects (${_selectedObjects.length}):');
    for (var i = 0; i < _selectedObjects.length; i++) {
      debugPrint('[${name}]   [$i] ${_selectedObjects[i].runtimeType} (id: ${_selectedObjects[i].id}, label: ${_selectedObjects[i].label})');
    }
    debugPrint('[${name}] Command: $commandName');
    debugPrint('[${name}] Parameter specs: ${parameterSpecs.length}');
    
    Map<String, dynamic>? parameters;

    // Request parameters if needed
    if (parameterSpecs.isNotEmpty && onParameterRequest != null) {
      debugPrint('[${name}] Requesting parameters...');
      parameters = await onParameterRequest!(
        name,
        parameterSpecs,
      );

      if (parameters == null) {
        debugPrint('[${name}] User cancelled parameter input');
        // User cancelled
        reset();
        notifyStateChanged('Transformation cancelled');
        return;
      }
      debugPrint('[${name}] Parameters received: $parameters');
    }

    notifyStateChanged('Applying transformation...');
    debugPrint('[${name}] Building arguments...');

    final args = buildArguments(_selectedObjects, parameters);
    try {
      _validateArguments(commandName, args);
    } on ArgumentError catch (error) {
      notifyStateChanged('Invalid arguments: ${error.message}');
      reset();
      return;
    }
    debugPrint('[${name}] Arguments built (${args.length}):');
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg is GeometryObject) {
        debugPrint('[${name}]   [$i] ${arg.runtimeType} (id: ${arg.id}, label: ${arg.label})');
      } else {
        debugPrint('[${name}]   [$i] ${arg.runtimeType}: $arg');
      }
    }

    debugPrint('[${name}] Executing command: $commandName with ${args.length} arguments');
    final result = await executor.execute(
      commandName: commandName,
      arguments: args,
    );

    debugPrint('[${name}] Execution result: success=${result.success}, message=${result.message}');
    if (result.object != null) {
      debugPrint('[${name}] Result object: ${result.object.runtimeType} (id: ${(result.object as GeometryObject?)?.id})');
    }

    if (!result.success) {
      debugPrint('[${name}] ❌ Execution failed: ${result.message}');
      notifyStateChanged(failureMessage(result.message));
      
      // Clear selections and reset
      for (var i = 0; i < _selectedObjects.length; i++) {
        notifyObjectSelected(''); // Clear highlight
      }
      _selectedObjects.clear();
      _currentStage = 0;
      notifyStateChanged(stateDescription);
      return;
    }

    if (result.object is GeometryObject) {
      final createdObject = result.object as GeometryObject;
      debugPrint('[${name}] ✅ Success! Created ${createdObject.runtimeType} (id: ${createdObject.id}, label: ${createdObject.label})');
      debugPrint('[${name}] Dependencies: ${createdObject.dependencies}');
      debugPrint('[${name}] Calling notifyObjectCreated callback...');
      debugPrint('[${name}] onObjectCreated callback is ${onObjectCreated != null ? "set" : "null"}');
      notifyObjectCreated(
        createdObject,
        createdObject.dependencies,
      );
      debugPrint('[${name}] notifyObjectCreated called');
      notifyStateChanged(successMessage(createdObject));
    } else {
      debugPrint('[${name}] ✅ Success! (no geometry object returned)');
      notifyStateChanged('Transformation completed');
    }

    // Clear selections and reset
    debugPrint('[${name}] Clearing selections and resetting...');
    for (var i = 0; i < _selectedObjects.length; i++) {
      onObjectSelected?.call(''); // Clear highlight
    }
    _selectedObjects.clear();
    _currentStage = 0;
    notifyStateChanged(stateDescription);
    debugPrint('[${name}] ========== TRANSFORMATION COMPLETE ==========');
  }

  @override
  void reset() {
    debugPrint('[${name}] ========== RESETTING TOOL ==========');
    debugPrint('[${name}] Tool: $name');
    debugPrint('[${name}] Total stages: $totalStages');
    debugPrint('[${name}] Command: $commandName');
    debugPrint('[${name}] Current stage before reset: $_currentStage');
    debugPrint('[${name}] Selected objects before reset: ${_selectedObjects.length}');
    for (var i = 0; i < totalStages; i++) {
      final constraints = stageTypeConstraints[i];
      debugPrint('[${name}]   Stage $i: ${constraints.isEmpty ? "any object" : constraints.map((t) => t.toString()).join(", ")}');
    }
    
    // Clear selection highlights
    for (var i = 0; i < _selectedObjects.length; i++) {
      notifyObjectSelected(''); // Clear highlight by sending empty string
    }
    
    _selectedObjects.clear();
    _currentStage = 0;
    notifyStateChanged(stateDescription);
    debugPrint('[${name}] Tool reset complete. Current stage: $_currentStage, Prompt: ${stateDescription}');
    debugPrint('[${name}] ======================================');
  }

  @override
  bool get isComplete => false;

  @override
  String get stateDescription {
    if (_currentStage == 0) {
      return stagePrompt(0);
    }
    return stagePrompt(_currentStage);
  }
  void _validateArguments(String command, List<dynamic> args) {
    final verifier = ToolVerifier(
      command,
      registry: dagManager.commandRegistry,
    );
    for (final arg in args) {
      final result = verifier.addArgument(arg);
      if (!result.isValid) {
        throw ArgumentError(result.errors.join(', '));
      }
    }
    if (!verifier.isComplete) {
      throw ArgumentError('Command "$command" is missing required arguments');
    }
  }
}

