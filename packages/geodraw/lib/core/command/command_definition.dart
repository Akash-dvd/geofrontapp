/// Command definitions linking tool types to command schemas
library;

import '../../tools/tool.dart';
import 'command_schema.dart';

/// High level metadata about a command/tool pairing
class CommandDefinition {
  final String name;
  final ToolType toolType;
  final CommandSchema schema;
  final bool createsObject;
  final String description;
  final List<String> aliases;
  final String? category;
  final bool implemented;

  const CommandDefinition({
    required this.name,
    required this.toolType,
    required this.schema,
    this.createsObject = true,
    this.description = '',
    this.aliases = const [],
    this.category,
    this.implemented = true,
  });
}
