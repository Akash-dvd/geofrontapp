/// Simple CLI wrapper - just parse and execute
library;

import '../cli/cli.dart';
import '../dag/dag_manager.dart';
import '../command/command_parser.dart' as cmd;
import '../command/simple_executor.dart' as executor;
import '../command/cli_verifier.dart';

/// Thin wrapper: CLI input → validate → parse → execute
class CLIAdapter {
  final DAGManager dagManager;
  final cmd.CommandParser parser;

  CLIAdapter({required this.dagManager})
    : parser = cmd.CommandParser(dagManager);

  /// Parse CLI command → validate → execute
  Future<ExecutionResult> executeCommand(Command cliCommand) async {
    try {
      // 1. Check if command is valid (parser already mapped to ToolType)
      if (cliCommand.toolType == null) {
        return ExecutionResult.error('Unknown command: ${cliCommand.name}');
      }

      // 2. Verify all arguments at once (CLI provides complete command)
      final validation = CLIVerifier.verifyCommand(
        cliCommand.toolType!,
        cliCommand.arguments,
      );

      if (!validation.isValid) {
        return ExecutionResult.error(
          'Validation failed: ${validation.errors.join(', ')}',
        );
      }

      // 3. Use parser to execute - convert Command to command string format
      final commandString = _toCommandString(cliCommand);
      final result = await parser.parseAndExecute(commandString);

      // 4. Convert result format
      return _convertResult(result);
    } catch (e) {
      return ExecutionResult.error(e.toString());
    }
  }

  /// Convert CLI Command to command string format
  String _toCommandString(Command cmd) {
    final argsString = cmd.arguments
        .map((arg) {
          if (arg is String) return '"$arg"';
          return arg.toString();
        })
        .join(', ');
    return '${cmd.name}($argsString)';
  }

  /// Convert SimpleExecutor's ExecutionResult to CLI's ExecutionResult
  ExecutionResult _convertResult(executor.ExecutionResult result) {
    if (result.success) {
      return ExecutionResult.successful(
        objectId: result.objectId,
        message: result.message,
        object: result.object,
      );
    } else {
      return ExecutionResult.error(result.message);
    }
  }
}

/// Extended CommandExecutor that uses the unified system
class UnifiedCLIExecutor {
  final CLIAdapter adapter;
  final CommandHistory history;

  UnifiedCLIExecutor({required DAGManager dagManager, CommandHistory? history})
    : adapter = CLIAdapter(dagManager: dagManager),
      history = history ?? CommandHistory();

  /// Execute a command (maintains backwards compatibility)
  Future<ExecutionResult> execute(Command command) async {
    try {
      final result = await adapter.executeCommand(command);
      history.add(command.originalInput, result);
      return result;
    } catch (e) {
      final errorResult = ExecutionResult.error(e.toString());
      history.add(command.originalInput, errorResult);
      return errorResult;
    }
  }

  /// Execute from command string
  Future<ExecutionResult> executeString(String commandString) async {
    final parser = cmd.CommandParser(adapter.dagManager);
    return await parser.parseAndExecute(commandString);
  }
}
