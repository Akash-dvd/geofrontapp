/// Canonical record for executed commands across adapters and tools.
library;

import '../dag/dag_manager.dart';
import '../../models/geometry_object.dart';

/// Captures canonical execution metadata for a command.
class CommandHistoryEntry {
  /// Identifier for the object produced by this command (if any).
  final String commandId;

  /// Canonical command name registered in the command registry.
  final String canonicalName;

  /// Arguments supplied to the command in execution order.
  final List<dynamic> arguments;

  /// Optional DAG history marker associated with the command execution.
  final HistoryMarker? historyMarker;

  /// Timestamp when the entry was recorded.
  final DateTime timestamp;

  CommandHistoryEntry({
    required this.commandId,
    required this.canonicalName,
    required List<dynamic> arguments,
    this.historyMarker,
    DateTime? timestamp,
  }) : arguments = List<dynamic>.unmodifiable(arguments),
       timestamp = timestamp ?? DateTime.now();

  /// Returns the canonical command string representation for display/logging.
  String asCommandString() {
    final buffer = StringBuffer()
      ..write(canonicalName)
      ..write('(');

    for (var i = 0; i < arguments.length; i++) {
      buffer.write(_formatArgument(arguments[i]));
      if (i < arguments.length - 1) {
        buffer.write(', ');
      }
    }

    buffer.write(')');
    return buffer.toString();
  }

  CommandHistoryEntry copyWith({
    String? commandId,
    String? canonicalName,
    List<dynamic>? arguments,
    HistoryMarker? historyMarker,
    DateTime? timestamp,
  }) {
    return CommandHistoryEntry(
      commandId: commandId ?? this.commandId,
      canonicalName: canonicalName ?? this.canonicalName,
      arguments: arguments ?? this.arguments,
      historyMarker: historyMarker ?? this.historyMarker,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static String _formatArgument(dynamic argument) {
    if (argument is GeometryObject) {
      return argument.label;
    }
    if (argument is String) {
      return argument;
    }
    if (argument is num) {
      return argument.toString();
    }
    return argument?.toString() ?? 'null';
  }
}
