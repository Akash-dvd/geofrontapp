/// Command-line interface for geometric construction
library;

export 'command_parser.dart';
export 'command_executor.dart';
export 'command_history.dart';

/// Represents a parsed command
class Command {
  final String name;
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

/// Result of command execution
class ExecutionResult {
  final bool success;
  final String? objectId;
  final String message;
  final dynamic data;

  ExecutionResult({
    required this.success,
    this.objectId,
    required this.message,
    this.data,
  });

  factory ExecutionResult.successful({
    String? objectId,
    required String message,
    dynamic data,
  }) {
    return ExecutionResult(
      success: true,
      objectId: objectId,
      message: message,
      data: data,
    );
  }

  factory ExecutionResult.error(String message) {
    return ExecutionResult(
      success: false,
      message: message,
    );
  }

  @override
  String toString() => success ? 'Success: $message' : 'Error: $message';
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
