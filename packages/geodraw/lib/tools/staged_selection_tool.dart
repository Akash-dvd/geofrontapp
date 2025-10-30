import 'dart:async';

import 'package:flutter/material.dart';

import '../core/command/command_history.dart';
import '../core/command/simple_executor.dart';
import '../core/dag/dag_manager.dart';
import '../models/geometry_object.dart';
import 'tool.dart';

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
abstract class StagedSelectionTool implements Tool {
  StagedSelectionTool({
    required this.dagManager,
    this.commandHistory,
    this.onObjectCreated,
    this.onObjectSelected,
    this.onToolStateChanged,
    this.onParameterRequest,
  }) : executor = SimpleExecutor(dagManager);

  final DAGManager dagManager;
  final SimpleExecutor executor;
  final CommandHistory? commandHistory;
  final OnObjectCreated? onObjectCreated;
  final OnObjectSelected? onObjectSelected;
  final OnToolStateChanged? onToolStateChanged;
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

  void notifyStateChanged(String state) {
    onToolStateChanged?.call(state);
  }

  @override
  void handleInput(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }

    final candidate = _resolveObjectAt(event.position);

    if (candidate == null) {
      notifyStateChanged('No object found at that location');
      return;
    }

    // Check if candidate matches current stage constraints
    final constraints = stageTypeConstraints[_currentStage];
    if (!_matchesConstraints(candidate, constraints)) {
      final expectedTypes = constraints.map((t) => t.toString()).join(' or ');
      notifyStateChanged('Please select $expectedTypes');
      return;
    }

    _selectedObjects.add(candidate);
    
    // Notify that object was selected (for highlighting)
    onObjectSelected?.call(candidate.id);
    
    _currentStage++;

    if (_currentStage < totalStages) {
      // More stages needed
      notifyStateChanged(stagePrompt(_currentStage));
    } else {
      // All stages complete, proceed to execution
      _executeTransformation();
    }
  }

  GeometryObject? _resolveObjectAt(Offset position) {
    final nearby = dagManager.proximitySearch(
      position,
      threshold: selectionThreshold,
    );
    return nearby.isNotEmpty ? nearby.first : null;
  }

  bool _matchesConstraints(GeometryObject object, Set<Type> constraints) {
    if (constraints.isEmpty) return true;
    return constraints.any((type) => object.runtimeType == type);
  }

  Future<void> _executeTransformation() async {
    Map<String, dynamic>? parameters;

    // Request parameters if needed
    if (parameterSpecs.isNotEmpty && onParameterRequest != null) {
      parameters = await onParameterRequest!(
        name,
        parameterSpecs,
      );

      if (parameters == null) {
        // User cancelled
        reset();
        notifyStateChanged('Transformation cancelled');
        return;
      }
    }

    notifyStateChanged('Applying transformation...');

    final args = buildArguments(_selectedObjects, parameters);

    final result = await executor.execute(
      commandName: commandName,
      arguments: args,
    );

    if (!result.success) {
      notifyStateChanged(failureMessage(result.message));
      
      // Clear selections and reset
      for (var i = 0; i < _selectedObjects.length; i++) {
        onObjectSelected?.call(''); // Clear highlight
      }
      _selectedObjects.clear();
      _currentStage = 0;
      notifyStateChanged(stateDescription);
      return;
    }

    if (result.object is GeometryObject) {
      onObjectCreated?.call(
        result.object as GeometryObject,
        (result.object as GeometryObject).dependencies,
      );
      notifyStateChanged(successMessage(result.object as GeometryObject));
    } else {
      notifyStateChanged('Transformation completed');
    }

    // Clear selections and reset
    for (var i = 0; i < _selectedObjects.length; i++) {
      onObjectSelected?.call(''); // Clear highlight
    }
    _selectedObjects.clear();
    _currentStage = 0;
    notifyStateChanged(stateDescription);
  }

  @override
  void reset() {
    // Clear selection highlights
    for (var i = 0; i < _selectedObjects.length; i++) {
      onObjectSelected?.call(''); // Clear highlight by sending empty string
    }
    
    _selectedObjects.clear();
    _currentStage = 0;
    notifyStateChanged(stateDescription);
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
}

