/// Verifier for CLI commands (validates complete command inputs)
library;

import '../../tools/tool.dart';
import 'command_registry.dart';
import 'command_schema.dart';

class CLIVerifier {
  final CommandRegistry _registry;

  CLIVerifier({CommandRegistry? registry})
    : _registry = registry ?? CommandRegistry.standard;

  ValidationResult verifyCommand(ToolType type, List<dynamic> arguments) {
    final schema = _registry.schemaFor(type);
    if (schema == null) {
      return ValidationResult.failure('Unknown command type: $type');
    }
    return schema.validate(arguments);
  }

  CommandSchema? schemaFor(ToolType type) => _registry.schemaFor(type);
}
