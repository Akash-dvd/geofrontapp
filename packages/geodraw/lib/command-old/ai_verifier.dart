/// AI batch command verifier - validates each command in a batch
library;

import '../tools/tool.dart';
import 'command_schema.dart';

/// Verifies AI batch commands - validates each command independently
class AIVerifier {
  /// Verify a single command from AI batch
  static ValidationResult verifyCommand(
    ToolType type,
    List<dynamic> arguments,
  ) {
    // Get schema for this command type
    final schema = CommandSchemaRegistry.getSchema(type);
    if (schema == null) {
      return ValidationResult.failure('Unknown command type: $type');
    }

    // Use schema's validation
    return schema.validate(arguments);
  }

  /// Verify an entire batch of commands
  /// Returns list of validation results (one per command)
  static List<ValidationResult> verifyBatch(
    List<({ToolType type, List<dynamic> args})> commands,
  ) {
    return commands.map((cmd) {
      return verifyCommand(cmd.type, cmd.args);
    }).toList();
  }

  /// Verify batch and return first error, or success if all valid
  static ValidationResult verifyBatchStrict(
    List<({ToolType type, List<dynamic> args})> commands,
  ) {
    for (int i = 0; i < commands.length; i++) {
      final cmd = commands[i];
      final result = verifyCommand(cmd.type, cmd.args);
      if (!result.isValid) {
        return ValidationResult.failure(
          'Command ${i + 1} (${cmd.type}): ${result.errors.join(', ')}',
        );
      }
    }
    return ValidationResult.success();
  }

  /// Get schema for a command type
  static CommandSchema? getSchema(ToolType type) {
    return CommandSchemaRegistry.getSchema(type);
  }
}
