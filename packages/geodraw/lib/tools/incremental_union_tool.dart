import 'dart:async';

import 'package:flutter/material.dart';

import '../core/command/command_history.dart';
import '../core/command/command_history_entry.dart';
import '../core/command/simple_executor.dart';
import '../core/dag/dag_manager.dart';
import '../models/complex/complex_geometry_object.dart';
import '../models/geometry_object.dart';
import '../models/simple/geo_point.dart';
import 'tool.dart';
import 'tool_verifier.dart';

abstract class IncrementalUnionTool<T extends UnionGeometryObjectList>
    with ToolCallbacksMixin implements Tool {
  IncrementalUnionTool({
    required this.dagManager,
    this.commandHistory,
    OnObjectCreated? onObjectCreated,
    OnObjectSelected? onObjectSelected,
    OnToolStateChanged? onToolStateChanged,
  }) : executor = SimpleExecutor(dagManager) {
    this.onObjectCreated = onObjectCreated;
    this.onObjectSelected = onObjectSelected;
    this.onToolStateChanged = onToolStateChanged;
  }

  final DAGManager dagManager;
  final SimpleExecutor executor;
  final CommandHistory? commandHistory;

  final List<dynamic> _inputs = <dynamic>[];
  T? _currentObject;
  String? _currentObjectId;
  HistoryMarker? _historyMarker;
  int _snapshotInputCount = 0;

  double get selectionThreshold => 15.0;
  String get createCommandName;
  String? get extendCommandName;
  bool get supportsExtension => extendCommandName != null;

  String get creatingMessage;
  String get extendingMessage;
  String creationSuccessMessage(T object);
  String extensionSuccessMessage(T object);
  String formatCreationFailure(String reason);
  String formatExtensionFailure(String reason);
  String get unresolvedInputMessage;

  bool isInitialInputComplete(List<dynamic> inputs);
  int extensionBatchSize(T object);
  List<dynamic> buildCreateArguments(List<dynamic> inputs);
  List<dynamic> buildExtendArguments(T object, List<dynamic> newInputs);
  List<dynamic>? resolveDependencies(List<String> dependencyIds);
  dynamic resolveInput(Offset position);
  String initialPrompt(int inputCount);
  String extensionPrompt(int newInputCount);
  String? validateNextInput(List<dynamic> currentInputs, dynamic candidate) =>
      null;

  /// Select an object directly (used when object is selected from menu/dropdown)
  /// This allows selecting pre-existing points for union construction
  void selectObject(GeometryObject object) {
    if (object is! GeoPoint) {
      notifyStateChanged('This tool requires point selection');
      return;
    }

    _startTransactionIfNeeded();

    final message = validateNextInput(_inputs, object);
    if (message != null) {
      notifyStateChanged(message);
      return;
    }

    _inputs.add(object);
    _evaluateInputs();
  }

  @override
  void handleInput(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }

    _startTransactionIfNeeded();

    dynamic candidate;
    try {
      candidate = resolveInput(event.position);
    } catch (error) {
      _rollbackTransaction(formatCreationFailure(error.toString()));
      return;
    }

    if (candidate == null) {
      _rollbackTransaction(unresolvedInputMessage);
      return;
    }

    final message = validateNextInput(_inputs, candidate);
    if (message != null) {
      notifyStateChanged(message);
      return;
    }

    _inputs.add(candidate);
    _evaluateInputs();
  }

  void _evaluateInputs() {
    if (_currentObject == null) {
      if (!isInitialInputComplete(_inputs)) {
        notifyStateChanged(initialPrompt(_inputs.length));
        return;
      }
      notifyStateChanged(creatingMessage);
      unawaited(_executeCreate());
      return;
    }

    if (!supportsExtension) {
      notifyStateChanged(extensionPrompt(0));
      return;
    }

    final dependencyCount = _currentObject!.dependencies.length;
    final delta = _inputs.length - dependencyCount;
    final requiredDelta = extensionBatchSize(_currentObject!);

    if (delta < requiredDelta) {
      notifyStateChanged(extensionPrompt(delta));
      return;
    }

    notifyStateChanged(extendingMessage);
    unawaited(_executeExtend(requiredDelta));
  }

  Future<void> _executeCreate() async {
    final args = buildCreateArguments(List<dynamic>.from(_inputs));
    try {
      _validateArguments(createCommandName, args);
    } on ArgumentError catch (error) {
      _rollbackTransaction(formatCreationFailure(error.message));
      return;
    }
    final marker = _historyMarker;

    final result = await executor.execute(
      commandName: createCommandName,
      arguments: args,
    );

    _recordHistory(createCommandName, args, result, marker);

    if (!result.success) {
      _rollbackTransaction(formatCreationFailure(result.message));
      return;
    }

    final created = _extractObject(result);
    if (created == null) {
      _rollbackTransaction(formatCreationFailure('Command returned no object'));
      return;
    }

    _currentObject = created;
    _currentObjectId = created.id;
    _syncInputsWithCurrentObject();
    _completeTransaction();
    notifyObjectCreated(created, created.dependencies);
    notifyStateChanged(creationSuccessMessage(created));
  }

  Future<void> _executeExtend(int requiredDelta) async {
    final shape = _currentObject;
    if (shape == null || !supportsExtension) {
      _rollbackTransaction(formatExtensionFailure('No object to extend'));
      return;
    }

    final newInputs = _inputs.sublist(
      _inputs.length - requiredDelta,
      _inputs.length,
    );
    final args = buildExtendArguments(shape, List<dynamic>.from(newInputs));
    try {
      _validateArguments(extendCommandName!, args);
    } on ArgumentError catch (error) {
      _rollbackTransaction(formatExtensionFailure(error.message));
      return;
    }
    final marker = _historyMarker;

    final result = await executor.execute(
      commandName: extendCommandName!,
      arguments: args,
    );

    _recordHistory(extendCommandName!, args, result, marker);

    if (!result.success) {
      _rollbackTransaction(formatExtensionFailure(result.message));
      return;
    }

    final updated = _extractObject(result);
    if (updated == null) {
      _rollbackTransaction(
        formatExtensionFailure('Command returned no object'),
      );
      return;
    }

    _currentObject = updated;
    _currentObjectId = updated.id;
    _syncInputsWithCurrentObject();
    _completeTransaction();
    notifyObjectSelected(updated.id);
    notifyStateChanged(extensionSuccessMessage(updated));
  }

  T? _extractObject(ExecutionResult result) {
    if (result.object is T) {
      return result.object as T;
    }

    final candidateId = result.objectId ?? _currentObjectId;
    if (candidateId == null) {
      return null;
    }

    final candidate = dagManager.getObject(candidateId);
    if (candidate is T) {
      return candidate;
    }
    return null;
  }

  void _syncInputsWithCurrentObject() {
    final shape = _currentObject;
    if (shape == null) {
      _inputs.clear();
      _snapshotInputCount = 0;
      return;
    }

    final resolved = resolveDependencies(shape.dependencies);
    if (resolved == null) {
      _inputs.clear();
      _snapshotInputCount = 0;
      return;
    }

    _inputs
      ..clear()
      ..addAll(resolved);
    _snapshotInputCount = _inputs.length;
  }

  void _startTransactionIfNeeded() {
    if (_historyMarker != null) {
      return;
    }
    _historyMarker = dagManager.markHistory();
    _snapshotInputCount = _inputs.length;
  }

  void _completeTransaction() {
    _historyMarker = null;
    _snapshotInputCount = _inputs.length;
  }

  void _rollbackTransaction(String message) {
    if (_historyMarker != null) {
      dagManager.rollbackToMarker(_historyMarker!);
      _historyMarker = null;
    }

    while (_inputs.length > _snapshotInputCount) {
      _inputs.removeLast();
    }

    if (_currentObjectId != null) {
      final candidate = dagManager.getObject(_currentObjectId!);
      if (candidate is T) {
        _currentObject = candidate;
        _syncInputsWithCurrentObject();
      } else {
        _currentObject = null;
        _inputs.clear();
        _snapshotInputCount = 0;
      }
    } else {
      _currentObject = null;
      _inputs.clear();
      _snapshotInputCount = 0;
    }

    notifyStateChanged(message);
  }

  void _recordHistory(
    String invokedCommand,
    List<dynamic> arguments,
    ExecutionResult result,
    HistoryMarker? marker,
  ) {
    if (commandHistory == null) {
      return;
    }

    final definition = dagManager.commandRegistry.definitionByName(
      invokedCommand,
    );
    final canonical = definition?.name ?? invokedCommand;
    final commandId =
        result.objectId ??
        '${canonical}_${DateTime.now().millisecondsSinceEpoch}';

    final entry = CommandHistoryEntry(
      commandId: commandId,
      canonicalName: canonical,
      arguments: arguments,
      historyMarker: marker,
    );

    commandHistory!.add(entry, result);
  }

  @override
  void reset() {
    if (_historyMarker != null) {
      dagManager.rollbackToMarker(_historyMarker!);
    }
    _historyMarker = null;
    _inputs.clear();
    _currentObject = null;
    _currentObjectId = null;
    _snapshotInputCount = 0;
    notifyStateChanged(stateDescription);
  }

  @override
  bool get isComplete => false;

  @override
  String get stateDescription {
    if (_currentObject == null) {
      return initialPrompt(_inputs.length);
    }
    final dependencyCount = _currentObject!.dependencies.length;
    final delta = _inputs.length - dependencyCount;
    return extensionPrompt(delta < 0 ? 0 : delta);
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
