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
  final CommandExecutor executor;

  const CommandDefinition({
    required this.name,
    required this.schema,
    required this.executor,
    this.description = '',
    this.aliases = const [],
    this.category,
    this.implemented = true,
  });

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

    return executor(context, arguments);
  }
}
