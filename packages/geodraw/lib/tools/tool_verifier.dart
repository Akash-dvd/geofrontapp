/// Verifier for tool-driven sequential argument collection
library;

import '../core/command/command_definition.dart';
import '../core/command/command_registry.dart';
import '../core/command/command_schema.dart';

class ToolVerifier {
  final CommandDefinition definition;
  final CommandSchema schema;
  final List<dynamic> _currentArgs = [];

  factory ToolVerifier(String commandName, {CommandRegistry? registry}) {
    final reg = registry ?? CommandRegistry.standard;
    final definition = reg.definitionByName(commandName);
    if (definition == null) {
      throw ArgumentError('No command definition found for $commandName');
    }
    return ToolVerifier._(definition);
  }

  ToolVerifier._(this.definition) : schema = definition.schema;

  ValidationResult addArgument(dynamic arg) {
    if (!schema.canAcceptMore(_currentArgs)) {
      return ValidationResult.failure(
        'Command already has all required arguments',
      );
    }

    final constraint = schema.nextConstraint(_currentArgs);
    if (constraint == null) {
      return ValidationResult.failure('No more arguments expected');
    }

    if (!constraint.accepts(arg)) {
      return ValidationResult.failure(
        'Expected ${constraint.description}, got ${arg.runtimeType}',
      );
    }

    _currentArgs.add(arg);
    return ValidationResult.success();
  }

  bool get isComplete {
    final requiredCount = schema.argumentTypes
        .where((c) => !c.isOptional)
        .length;
    return _currentArgs.length >= requiredCount;
  }

  String get nextArgumentDescription => schema.describeNext(_currentArgs);

  List<dynamic> get arguments => List.unmodifiable(_currentArgs);

  void reset() {
    _currentArgs.clear();
  }
}
