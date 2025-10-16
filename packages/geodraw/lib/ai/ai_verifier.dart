/// Verifier for AI-provided command batches
library;

import '../core/command/command_registry.dart';
import '../core/command/command_schema.dart';

class AIVerifier {
  final CommandRegistry _registry;

  AIVerifier({CommandRegistry? registry})
    : _registry = registry ?? CommandRegistry.standard;

  ValidationResult verifyCommand(String commandName, List<dynamic> arguments) {
    final schema = _registry.schemaForName(commandName);
    if (schema == null) {
      return ValidationResult.failure('Unknown command: $commandName');
    }
    return schema.validate(arguments);
  }

  List<ValidationResult> verifyBatch(
    List<({String commandName, List<dynamic> args})> commands,
  ) {
    return commands
        .map((cmd) => verifyCommand(cmd.commandName, cmd.args))
        .toList();
  }

  ValidationResult verifyBatchStrict(
    List<({String commandName, List<dynamic> args})> commands,
  ) {
    for (var i = 0; i < commands.length; i++) {
      final result = verifyCommand(commands[i].commandName, commands[i].args);
      if (!result.isValid) {
        final error = result.errors.join(', ');
        return ValidationResult.failure('Command ${i + 1}: $error');
      }
    }
    return ValidationResult.success();
  }

  CommandSchema? schemaFor(String commandName) =>
      _registry.schemaForName(commandName);
}
