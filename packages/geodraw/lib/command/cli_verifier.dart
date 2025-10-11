/// CLI argument verifier - validates all arguments at once
library;

import '../tools/tool.dart';
import 'command_schema.dart';

/// Verifies CLI command arguments all at once
class CLIVerifier {
  /// Verify a complete CLI command with all arguments
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

  /// Get schema for a command type
  static CommandSchema? getSchema(ToolType type) {
    return CommandSchemaRegistry.getSchema(type);
  }
}
