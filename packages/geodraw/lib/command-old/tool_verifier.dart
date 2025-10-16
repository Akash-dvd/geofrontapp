/// Tool palette argument verifier - validates arguments sequentially as they arrive
library;

import '../models/geometry_object.dart';
import '../tools/tool.dart';
import 'command_schema.dart';

/// Verifies tool arguments one at a time as user clicks
class ToolVerifier {
  final CommandSchema schema;
  final List<dynamic> _currentArgs = [];

  ToolVerifier(ToolType type)
    : schema =
          CommandSchemaRegistry.getSchema(type) ??
          (throw ArgumentError('No schema found for $type'));

  /// Check if the next argument is valid and add it
  /// Returns validation result with error message if invalid
  ValidationResult addArgument(dynamic arg) {
    // Check if we can accept more arguments
    if (!schema.canAcceptMore(_currentArgs)) {
      return ValidationResult.failure(
        'Command already has all required arguments',
      );
    }

    // Get expected type for this position
    final expectedType = schema.getNextArgumentType(_currentArgs);
    if (expectedType == null) {
      return ValidationResult.failure('No more arguments expected');
    }

    // Validate the argument type
    if (arg is GeometryObject) {
      if (!expectedType.accepts(arg.runtimeType)) {
        return ValidationResult.failure(
          'Expected ${expectedType.description}, got ${arg.runtimeType}',
        );
      }
    }
    // Primitives (numbers, strings) are accepted without validation

    // Add the argument
    _currentArgs.add(arg);
    return ValidationResult.success();
  }

  /// Check if command is complete (has all required arguments)
  bool get isComplete {
    final requiredCount = schema.argumentTypes
        .where((t) => !t.isOptional)
        .length;
    return _currentArgs.length >= requiredCount;
  }

  /// Get description of what's needed next
  String get nextArgumentDescription {
    if (isComplete) {
      return 'Click to confirm';
    }

    final nextType = schema.getNextArgumentType(_currentArgs);
    if (nextType == null) {
      return 'Command complete';
    }

    return 'Select ${nextType.description}';
  }

  /// Get the current arguments
  List<dynamic> get arguments => List.unmodifiable(_currentArgs);

  /// Reset the verifier
  void reset() {
    _currentArgs.clear();
  }
}
