/// Simple AI wrapper - parse, validate, and execute batches
library;

import '../dag/dag_manager.dart';
import '../command/command_parser.dart';
import '../command/simple_executor.dart';

/// Thin wrapper: AI input → parse → validate → execute
/// AI provides batches of commands all at once, validates each independently
class AIAdapter {
  final DAGManager dagManager;
  final CommandParser parser;

  AIAdapter({required this.dagManager}) : parser = CommandParser(dagManager);

  /// Execute a batch of AI commands
  /// Validation happens inside parser for each command
  Future<List<ExecutionResult>> executeBatch(
    List<String> commandStrings,
  ) async {
    return await parser.parseAndExecuteBatch(commandStrings);
  }

  /// Execute a single AI command string
  /// Format: "command(arg1, arg2, ...)"
  /// Validation happens inside parser
  Future<ExecutionResult> executeCommand(String commandString) async {
    return await parser.parseAndExecute(commandString);
  }
}
