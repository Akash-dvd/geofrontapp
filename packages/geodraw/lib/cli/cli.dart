/// Command-line interface for geometric construction
library;

export '../core/command/simple_executor.dart' show ExecutionResult;
export 'command_history.dart';
export 'cli_adapter.dart';

/// Represents a parsed CLI command
class Command {
  final String name; // Keep original name for error messages
  final List<dynamic> arguments;
  final String originalInput;

  Command({
    required this.name,
    required this.arguments,
    required this.originalInput,
  });

  @override
  String toString() => 'Command($name, args: $arguments)';
}
