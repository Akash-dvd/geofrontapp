/// Simple command parser for AI and CLI input
library;

import '../core/dag/dag_manager.dart';
import 'object_resolver.dart';
import '../core/command/simple_executor.dart';
import '../core/command/command_registry.dart';

/// Exception thrown when command parsing fails.
class CommandParserException implements Exception {
  final String message;

  CommandParserException(this.message);

  @override
  String toString() => message;
}

/// Parsed command data prior to execution.
class ParsedCommand {
  final String originalInput;
  final String canonicalName;
  final List<dynamic> arguments;

  ParsedCommand({
    required this.originalInput,
    required this.canonicalName,
    required List<dynamic> arguments,
  }) : arguments = List<dynamic>.unmodifiable(arguments);
}

/// Parse and execute commands from string input
class CommandParser {
  final DAGManager dagManager;
  final SimpleExecutor executor;
  final ObjectResolver resolver;

  final CommandRegistry _registry;

  CommandParser(this.dagManager)
    : _registry = dagManager.commandRegistry,
      executor = SimpleExecutor(dagManager),
      resolver = ObjectResolver(dagManager);

  /// Parse command string into canonical representation.
  ParsedCommand parse(String commandString) {
    final trimmed = commandString.trim();
    final match = RegExp(r'^(\w+)\((.*)\)$').firstMatch(trimmed);
    if (match == null) {
      throw CommandParserException(
        'Invalid format: $commandString. Use: command(arg1, arg2, ...)',
      );
    }

    final commandName = match.group(1)!.toLowerCase();
    final argsString = match.group(2)!;

    final definition = _registry.definitionByName(commandName);
    if (definition == null) {
      throw CommandParserException('Unknown command: $commandName');
    }

    final args = _parseAndResolveArgs(argsString);

    return ParsedCommand(
      originalInput: commandString,
      canonicalName: definition.name,
      arguments: args,
    );
  }

  /// Execute a pre-parsed command.
  Future<ExecutionResult> executeParsed(ParsedCommand command) async {
    return executor.execute(
      commandName: command.canonicalName,
      arguments: command.arguments,
    );
  }

  /// Parse and execute a command string
  /// Format: "command(arg1, arg2, ...)"
  /// Example: "line(A, B)" or "point(10, 20)"
  Future<ExecutionResult> parseAndExecute(String commandString) async {
    try {
      final parsed = parse(commandString);
      return await executeParsed(parsed);
    } on CommandParserException catch (e) {
      return ExecutionResult.error(e.message);
    } catch (e) {
      return ExecutionResult.error('Parse error: $e');
    }
  }

  /// Parse arguments from string
  List<dynamic> _parseAndResolveArgs(String argsString) {
    if (argsString.trim().isEmpty) return [];

    // Split by commas (respecting quotes and parentheses)
    final parts = _splitArguments(argsString);

    // Try parsing each part as number first, then resolve as object
    return parts.map((part) {
      // Try number
      final numValue = num.tryParse(part);
      if (numValue != null) return numValue;

      // Try object resolution (by ID or label)
      final resolved = resolver.resolve(part);
      if (resolved != null) return resolved;

      // Return as string if not found (will fail validation)
      return part;
    }).toList();
  }

  /// Split arguments by comma, respecting parentheses and quotes
  List<String> _splitArguments(String argsString) {
    final args = <String>[];
    final buffer = StringBuffer();
    int depth = 0;
    bool inQuotes = false;

    for (int i = 0; i < argsString.length; i++) {
      final char = argsString[i];

      if (char == '"' && (i == 0 || argsString[i - 1] != '\\')) {
        inQuotes = !inQuotes;
        buffer.write(char);
      } else if (!inQuotes) {
        if (char == '(' || char == '[' || char == '{') {
          depth++;
          buffer.write(char);
        } else if (char == ')' || char == ']' || char == '}') {
          depth--;
          buffer.write(char);
        } else if (char == ',' && depth == 0) {
          // Split here
          final arg = buffer.toString().trim();
          if (arg.isNotEmpty) args.add(arg);
          buffer.clear();
        } else {
          buffer.write(char);
        }
      } else {
        buffer.write(char);
      }
    }

    // Add last argument
    final last = buffer.toString().trim();
    if (last.isNotEmpty) args.add(last);

    return args;
  }

  /// Execute multiple commands in sequence
  Future<List<ExecutionResult>> parseAndExecuteBatch(
    List<String> commandStrings,
  ) async {
    final results = <ExecutionResult>[];

    for (final cmdString in commandStrings) {
      final result = await parseAndExecute(cmdString);
      results.add(result);

      // Stop on first error
      if (!result.success) break;
    }

    return results;
  }
}

