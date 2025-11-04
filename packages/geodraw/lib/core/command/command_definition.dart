/// Command definitions linking schemas with execution logic.
library;

import 'command_schema.dart';
import 'command_runtime.dart';

typedef CommandExecutor =
    Future<ExecutionResult> Function(
      CommandExecutionContext context,
      List<dynamic> arguments,
    );

/// High level metadata about a command and its execution contract.
class CommandDefinition {
  final String name;
  final CommandSchema schema;
  final String description;
  final List<String> aliases;
  final String? category;
  final bool implemented;
  
  /// Single executor for all patterns (backward compatibility)
  final CommandExecutor? executor;
  
  /// Pattern-specific executors (one per pattern in schema)
  final List<CommandExecutor>? patternExecutors;

  CommandDefinition({
    required this.name,
    required this.schema,
    this.executor,
    this.patternExecutors,
    this.description = '',
    this.aliases = const [],
    this.category,
    this.implemented = true,
  }) : assert(
    (executor != null) != (patternExecutors != null),
    'Provide either executor or patternExecutors, not both.',
  ), assert(
    patternExecutors == null ||
        patternExecutors.length == schema.argumentPatterns.length,
    'patternExecutors length must match schema patterns length.',
  );

  Future<ExecutionResult> run(
    CommandExecutionContext context,
    List<dynamic> arguments,
  ) async {
    final validation = schema.validate(arguments);
    if (!validation.isValid) {
      final error = validation.errors.join(', ');
      return ExecutionResult.error('Validation failed: $error');
    }

    if (!implemented) {
      return ExecutionResult.error('$name is not implemented yet');
    }

    // Route to pattern-specific executor if available
    if (patternExecutors != null && validation.matchedPatternIndex != null) {
      final patternIndex = validation.matchedPatternIndex!;
      if (patternIndex >= 0 && patternIndex < patternExecutors!.length) {
        return patternExecutors![patternIndex](context, arguments);
      }
    }

    // Fallback to single executor (backward compatibility)
    if (executor != null) {
      return executor!(context, arguments);
    }

    return ExecutionResult.error('No executor defined for command: $name');
  }
}
