/// Simple CLI wrapper - just parse and execute
library;

import '../cli/cli.dart';
import '../core/dag/dag_manager.dart';
import '../core/command/command_parser.dart' as cmd;
import '../core/command/simple_executor.dart' as executor;
// import '../core/command/cli_verifier.dart';
import 'cli_verifier.dart';
import '../core/command/command_registry.dart';
import '../core/command/command_history_entry.dart';

/// Thin wrapper: CLI input → validate → parse → execute
class CLIAdapter {
  final DAGManager dagManager;
  final cmd.CommandParser parser;
  final CLIVerifier verifier;
  final CommandRegistry _registry;

  CLIAdapter({required this.dagManager})
    : parser = cmd.CommandParser(dagManager),
      verifier = CLIVerifier(registry: dagManager.commandRegistry),
      _registry = dagManager.commandRegistry;

  CommandRegistry get registry => _registry;

  /// Parse CLI command → validate → execute
  Future<ExecutionResult> executeCommand(Command cliCommand) async {
    try {
      final definition = _registry.definitionByName(cliCommand.name);
      if (definition == null) {
        return ExecutionResult.error('Unknown command: ${cliCommand.name}');
      }

      // 2. Verify all arguments at once (CLI provides complete command)
      final validation = verifier.verifyCommand(
        definition.name,
        cliCommand.arguments,
      );

      if (!validation.isValid) {
        return ExecutionResult.error(
          'Validation failed: ${validation.errors.join(', ')}',
        );
      }

      // 3. Use parser to execute - convert Command to command string format
      final commandString = _toCommandString(
        definition.name,
        cliCommand.arguments,
      );
      final result = await parser.parseAndExecute(commandString);

      // 4. Convert result format
      return _convertResult(result);
    } catch (e) {
      return ExecutionResult.error(e.toString());
    }
  }

  /// Convert CLI Command to command string format
  String _toCommandString(String canonicalName, List<dynamic> arguments) {
    final argsString = arguments
        .map((arg) {
          if (arg is String) return '"$arg"';
          return arg.toString();
        })
        .join(', ');
    return '$canonicalName($argsString)';
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
      final canonical =
          adapter.registry.definitionByName(command.name)?.name ?? command.name;
      final entry = _buildEntry(
        commandName: canonical,
        arguments: command.arguments,
        objectId: result.objectId,
      );
      history.add(entry, result);
      return result;
    } catch (e) {
      final errorResult = ExecutionResult.error(e.toString());
      final canonical =
          adapter.registry.definitionByName(command.name)?.name ?? command.name;
      final entry = _buildEntry(
        commandName: canonical,
        arguments: command.arguments,
        objectId: 'error',
      );
      history.add(entry, errorResult);
      return errorResult;
    }
  }

  /// Execute from command string
  Future<ExecutionResult> executeString(String commandString) async {
    try {
      final parsed = adapter.parser.parse(commandString);
      final coreResult = await adapter.parser.executeParsed(parsed);
      final converted = adapter._convertResult(coreResult);

      final entry = CommandHistoryEntry(
        commandId: converted.objectId ?? parsed.canonicalName,
        canonicalName: parsed.canonicalName,
        arguments: parsed.arguments,
      );

      history.add(entry, converted);
      return converted;
    } on cmd.CommandParserException catch (e) {
      final coreError = executor.ExecutionResult.error(e.message);
      final converted = adapter._convertResult(coreError);
      final entry = CommandHistoryEntry(
        commandId: 'error',
        canonicalName: _extractName(commandString),
        arguments: const [],
      );
      history.add(entry, converted);
      return converted;
    } catch (e) {
      final coreError = executor.ExecutionResult.error(e.toString());
      final converted = adapter._convertResult(coreError);
      final entry = CommandHistoryEntry(
        commandId: 'error',
        canonicalName: _extractName(commandString),
        arguments: const [],
      );
      history.add(entry, converted);
      return converted;
    }
  }

  CommandHistoryEntry _buildEntry({
    required String commandName,
    required List<dynamic> arguments,
    String? objectId,
  }) {
    final canonical = commandName;

    return CommandHistoryEntry(
      commandId: objectId ?? canonical,
      canonicalName: canonical,
      arguments: arguments,
    );
  }

  static String _extractName(String commandString) {
    final trimmed = commandString.trim();
    final idx = trimmed.indexOf('(');
    if (idx <= 0) {
      return trimmed.isEmpty ? 'unknown' : trimmed;
    }
    return trimmed.substring(0, idx).trim();
  }
}
