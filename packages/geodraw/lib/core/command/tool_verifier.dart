/// Verifier for tool-driven sequential argument collection
library;

import '../../tools/tool.dart';
import 'command_registry.dart';
import 'command_schema.dart';
import 'command_definition.dart';

class ToolVerifier {
  final CommandDefinition definition;
  final CommandSchema schema;
  final List<dynamic> _currentArgs = [];

  ToolVerifier(ToolType type, {CommandRegistry? registry})
    : definition =
          (registry ?? CommandRegistry.standard).definitionByType(type) ??
          (throw ArgumentError('No command definition found for $type')),
      schema =
          (registry ?? CommandRegistry.standard).schemaFor(type) ??
          (throw ArgumentError('No schema registered for $type'));

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
