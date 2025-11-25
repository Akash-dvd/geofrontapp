import 'command_history_entry.dart';
import 'simple_executor.dart';

/// Captures a history entry paired with its execution result.
class CommandHistoryRecord {
  final CommandHistoryEntry entry;
  final ExecutionResult result;
  final DateTime timestamp;

  CommandHistoryRecord({
    required this.entry,
    required this.result,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Canonical command string representation.
  String get command => entry.asCommandString();
}

/// Manages command history for undo/redo and recall.
class CommandHistory {
  final List<CommandHistoryRecord> _history = [];
  int _currentIndex = -1;
  static const int maxHistory = 100;

  /// Add a command to history.
  ///
  /// Accepts either a fully constructed [CommandHistoryEntry] or a raw
  /// command string (legacy callers). Raw commands are normalized to the
  /// canonical command format before storage.
  void add(dynamic entryOrCommand, ExecutionResult result) {
    late final CommandHistoryEntry entry;
    if (entryOrCommand is CommandHistoryEntry) {
      entry = entryOrCommand;
    } else if (entryOrCommand is String) {
      entry = _fromCommandString(entryOrCommand);
    } else {
      throw ArgumentError(
        'Unsupported history entry type: ${entryOrCommand.runtimeType}',
      );
    }

    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    _history.add(CommandHistoryRecord(entry: entry, result: result));
    _currentIndex++;

    if (_history.length > maxHistory) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  /// Get previous command in history as canonical command string.
  String? previous() {
    if (_history.isEmpty) return null;
    if (_currentIndex > 0) {
      _currentIndex--;
    }
    return _currentIndex >= 0 && _currentIndex < _history.length
        ? _history[_currentIndex].command
        : null;
  }

  /// Get next command in history as canonical command string.
  String? next() {
    if (_history.isEmpty) return null;
    if (_currentIndex < _history.length - 1) {
      _currentIndex++;
    }
    return _currentIndex >= 0 && _currentIndex < _history.length
        ? _history[_currentIndex].command
        : null;
  }

  /// Expose recent commands (up to 10) as canonical strings.
  List<String> get recentCommands =>
      _history.reversed.take(10).map((r) => r.command).toList();

  /// All recorded history entries.
  List<CommandHistoryRecord> get allHistory => List.unmodifiable(_history);

  /// Commands that executed successfully.
  List<CommandHistoryRecord> get successfulCommands =>
      _history.where((r) => r.result.success).toList();

  /// Commands that failed during execution.
  List<CommandHistoryRecord> get failedCommands =>
      _history.where((r) => !r.result.success).toList();

  /// Clear history state.
  void clear() {
    _history.clear();
    _currentIndex = -1;
  }

  /// History size.
  int get length => _history.length;

  /// Whether there are zero history entries.
  bool get isEmpty => _history.isEmpty;

  /// Retrieve record at index.
  CommandHistoryRecord? at(int index) {
    if (index >= 0 && index < _history.length) {
      return _history[index];
    }
    return null;
  }

  CommandHistoryEntry _fromCommandString(String command) {
    final trimmed = command.trim();
    final parenIndex = trimmed.indexOf('(');
    final canonicalName = parenIndex >= 0
        ? trimmed.substring(0, parenIndex).trim()
        : trimmed;
    final argsSection = parenIndex >= 0 && trimmed.endsWith(')')
        ? trimmed.substring(parenIndex + 1, trimmed.length - 1)
        : '';
    final args = argsSection.isEmpty
        ? <dynamic>[]
        : argsSection.split(',').map((part) => part.trim()).toList();

    return CommandHistoryEntry(
      commandId: '${canonicalName}_${DateTime.now().millisecondsSinceEpoch}',
      canonicalName: canonicalName.isEmpty ? 'unknown' : canonicalName,
      arguments: args,
    );
  }
}

