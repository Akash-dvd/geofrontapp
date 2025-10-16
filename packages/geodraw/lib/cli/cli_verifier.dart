/// Verifier for CLI commands (validates complete command inputs)
library;

import '../core/command/command_registry.dart';
import '../core/command/command_schema.dart';

class CLIVerifier {
  final CommandRegistry _registry;

  CLIVerifier({CommandRegistry? registry})
    : _registry = registry ?? CommandRegistry.standard;

  ValidationResult verifyCommand(String commandName, List<dynamic> arguments) {
    final schema = _registry.schemaForName(commandName);
    if (schema == null) {
      return ValidationResult.failure('Unknown command: $commandName');
    }
    return schema.validate(arguments);
  }

  CommandSchema? schemaFor(String commandName) =>
      _registry.schemaForName(commandName);
}
