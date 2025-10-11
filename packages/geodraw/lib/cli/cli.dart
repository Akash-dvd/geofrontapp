/// Command-line interface for geometric construction
library;

import '../tools/tool.dart';
import '../command/simple_executor.dart' show ExecutionResult;

export '../command/simple_executor.dart' show ExecutionResult;
export 'command_history.dart';
export 'cli_adapter.dart';

/// Represents a parsed CLI command
class Command {
  final ToolType? toolType; // Direct ToolType for validation
  final String name; // Keep original name for error messages
  final List<dynamic> arguments;
  final String originalInput;

  Command({
    this.toolType,
    required this.name,
    required this.arguments,
    required this.originalInput,
  });

  @override
  String toString() => 'Command($name, toolType: $toolType, args: $arguments)';
}

/// Record of a command execution
class CommandRecord {
  final String command;
  final ExecutionResult result;
  final DateTime timestamp;

  CommandRecord(this.command, this.result, this.timestamp);

  @override
  String toString() => '[$timestamp] $command -> ${result.message}';
}
