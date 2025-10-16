/// Simple adapter that delegates execution to registered command definitions.
library;

import '../dag/dag_manager.dart';
import 'command_registry.dart';
import 'command_runtime.dart';

export 'command_runtime.dart' show ExecutionResult, CommandExecutionContext;

/// Executes registered commands by name using the shared registry.
class SimpleExecutor {
  final DAGManager dagManager;
  final CommandRegistry _registry;

  SimpleExecutor(this.dagManager) : _registry = dagManager.commandRegistry;

  Future<ExecutionResult> execute({
    required String commandName,
    required List<dynamic> arguments,
    String? customLabel,
  }) async {
    final definition = _registry.definitionByName(commandName);
    if (definition == null) {
      return ExecutionResult.error('Unknown command: $commandName');
    }

    final context = CommandExecutionContext(
      dagManager: dagManager,
      customLabel: customLabel,
    );

    return definition.run(context, arguments);
  }
}
