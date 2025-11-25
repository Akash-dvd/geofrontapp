/// Command-line interface for geometric construction
library;

export '../core/command/simple_executor.dart' show ExecutionResult;
export '../core/command/command_history.dart';
export 'cli_adapter.dart';
export 'command_parser.dart';
export 'object_resolver.dart';

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
