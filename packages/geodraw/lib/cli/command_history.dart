import 'cli.dart';

/// Manages command history for undo/redo and recall
class CommandHistory {
  final List<CommandRecord> _history = [];
  int _currentIndex = -1;
  static const int maxHistory = 100;

  /// Add a command to history
  void add(String command, ExecutionResult result) {
    // Remove any redo history
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    _history.add(CommandRecord(command, result, DateTime.now()));
    _currentIndex++;

    // Limit history size
    if (_history.length > maxHistory) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  /// Get previous command in history
  String? previous() {
    if (_history.isEmpty) return null;
    if (_currentIndex > 0) {
      _currentIndex--;
    }
    return _currentIndex >= 0 && _currentIndex < _history.length
        ? _history[_currentIndex].command
        : null;
  }

  /// Get next command in history
  String? next() {
    if (_history.isEmpty) return null;
    if (_currentIndex < _history.length - 1) {
      _currentIndex++;
    }
    return _currentIndex >= 0 && _currentIndex < _history.length
        ? _history[_currentIndex].command
        : null;
  }

  /// Get recent commands
  List<String> get recentCommands =>
      _history.reversed.take(10).map((r) => r.command).toList();

  /// Get all history
  List<CommandRecord> get allHistory => List.unmodifiable(_history);

  /// Get successful commands
  List<CommandRecord> get successfulCommands =>
      _history.where((r) => r.result.success).toList();

  /// Get failed commands
  List<CommandRecord> get failedCommands =>
      _history.where((r) => !r.result.success).toList();

  /// Clear history
  void clear() {
    _history.clear();
    _currentIndex = -1;
  }

  /// Get history size
  int get length => _history.length;

  /// Check if history is empty
  bool get isEmpty => _history.isEmpty;

  /// Get command at index
  CommandRecord? at(int index) {
    if (index >= 0 && index < _history.length) {
      return _history[index];
    }
    return null;
  }
}
