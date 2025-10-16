/// Verifier for AI-provided command batches
library;

import '../../tools/tool.dart';
import 'command_registry.dart';
import 'command_schema.dart';

class AIVerifier {
  final CommandRegistry _registry;

  AIVerifier({CommandRegistry? registry})
    : _registry = registry ?? CommandRegistry.standard;

  ValidationResult verifyCommand(ToolType type, List<dynamic> arguments) {
    final schema = _registry.schemaFor(type);
    if (schema == null) {
      return ValidationResult.failure('Unknown command type: $type');
    }
    return schema.validate(arguments);
  }

  List<ValidationResult> verifyBatch(
    List<({ToolType type, List<dynamic> args})> commands,
  ) {
    return commands.map((cmd) => verifyCommand(cmd.type, cmd.args)).toList();
  }

  ValidationResult verifyBatchStrict(
    List<({ToolType type, List<dynamic> args})> commands,
  ) {
    for (var i = 0; i < commands.length; i++) {
      final result = verifyCommand(commands[i].type, commands[i].args);
      if (!result.isValid) {
        final error = result.errors.join(', ');
        return ValidationResult.failure('Command ${i + 1}: $error');
      }
    }
    return ValidationResult.success();
  }

  CommandSchema? schemaFor(ToolType type) => _registry.schemaFor(type);
}
