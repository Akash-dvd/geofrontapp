import 'cli.dart';

/// Parses command strings into Command objects
class CommandParser {
  /// Parse a command string
  Command? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Match: command(arg1, arg2, ...)
    final match = RegExp(r'^(\w+)\((.*)\)$').firstMatch(trimmed);
    
    if (match == null) {
      // Try simple command without parentheses
      return Command(
        name: trimmed,
        arguments: [],
        originalInput: input,
      );
    }

    final commandName = match.group(1)!;
    final argsString = match.group(2)!;

    final arguments = _parseArguments(argsString);

    return Command(
      name: commandName,
      arguments: arguments,
      originalInput: input,
    );
  }

  /// Parse argument list
  List<dynamic> _parseArguments(String argsString) {
    if (argsString.trim().isEmpty) return [];

    final args = <dynamic>[];
    final parts = argsString.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      
      // Try to parse as number
      final number = num.tryParse(trimmed);
      if (number != null) {
        args.add(number);
        continue;
      }

      // Try to parse as coordinate (x, y) - this is simplified
      if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
        final coordMatch = RegExp(r'\(([^,]+),([^)]+)\)').firstMatch(trimmed);
        if (coordMatch != null) {
          final x = num.tryParse(coordMatch.group(1)!.trim());
          final y = num.tryParse(coordMatch.group(2)!.trim());
          if (x != null && y != null) {
            args.add({'x': x, 'y': y});
            continue;
          }
        }
      }

      // Otherwise treat as string/identifier
      args.add(trimmed);
    }

    return args;
  }

  /// Validate command syntax
  bool validate(Command command) {
    // Basic validation
    return command.name.isNotEmpty;
  }
}
