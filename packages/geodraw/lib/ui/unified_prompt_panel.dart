/// Unified prompt panel that toggles between CLI and AI modes
library;

import 'package:flutter/material.dart';
import '../cli/cli.dart';
import '../dag/dag_manager.dart';
import '../ai/ai_service.dart';
import '../ai/ai_adapter.dart';

enum PromptMode { cli, ai }

/// Unified prompt panel with mode toggle for CLI and AI input
class UnifiedPromptPanel extends StatefulWidget {
  final DAGManager dagManager;
  final UnifiedCLIExecutor? cliExecutor;
  final AIService? aiService;
  final AIAdapter? aiAdapter;
  final VoidCallback? onConstructionComplete;
  final double height;

  const UnifiedPromptPanel({
    super.key,
    required this.dagManager,
    this.cliExecutor,
    this.aiService,
    this.aiAdapter,
    this.onConstructionComplete,
    this.height = 200,
  });

  @override
  State<UnifiedPromptPanel> createState() => _UnifiedPromptPanelState();
}

class _UnifiedPromptPanelState extends State<UnifiedPromptPanel> {
  PromptMode _mode = PromptMode.cli;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // CLI state
  final List<String> _cliOutput = [];

  // AI state
  List<String>? _generatedCommands;
  bool _isLoadingAI = false;
  String? _aiError;
  bool _isExecuting = false;
  List<String> _executionLog = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;
    final surfaceVariant = theme.colorScheme.surfaceVariant;
    final borderColor = theme.dividerColor;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.height),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderBar(
              theme,
              accent,
              onSurface,
              surfaceVariant,
              borderColor,
            ),
            Expanded(
              child: _mode == PromptMode.cli
                  ? _buildCLIView(theme, onSurface, accent)
                  : _buildAIView(theme, onSurface, accent, borderColor),
            ),
            _buildPromptBar(
              theme,
              accent,
              surface,
              borderColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    ThemeData theme,
    Color accent,
    Color onSurface,
    PromptMode mode,
    String label,
    IconData icon,
  ) {
    final isActive = _mode == mode;
    final inactiveColor = onSurface.withOpacity(0.6);
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        setState(() {
          _mode = mode;
          _controller.clear();
          _focusNode.requestFocus();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? accent.withOpacity(0.18) : Colors.transparent,

            Widget _buildHeaderBar(
              ThemeData theme,
              Color accent,
              Color onSurface,
              Color surfaceVariant,
              Color borderColor,
            ) {
              final canClearCLI = _mode == PromptMode.cli && _cliOutput.isNotEmpty;
              final canClearAI = _mode == PromptMode.ai &&
                  (_generatedCommands != null ||
                      _executionLog.isNotEmpty ||
                      _aiError != null);
              final inactiveAccent = onSurface.withOpacity(0.6);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: surfaceVariant,
                  border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeButton(
                            theme,
                            accent,
                            onSurface,
                            PromptMode.cli,
                            'CLI',
                            Icons.terminal,
                          ),
                          _buildModeButton(
                            theme,
                            accent,
                            onSurface,
                            PromptMode.ai,
                            'AI',
                            Icons.psychology,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.clear_all, size: 18),
                      color: canClearCLI || canClearAI ? accent : inactiveAccent,
                      tooltip: 'Clear',
                      onPressed: canClearCLI || canClearAI
                          ? () {
                              setState(() {
                                if (_mode == PromptMode.cli) {
                                  _cliOutput.clear();
                                } else {
                                  _generatedCommands = null;
                                  _aiError = null;
                                  _executionLog.clear();
                                }
                                _controller.clear();
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              );
            }
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? accent : inactiveColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? accent : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCLIView(ThemeData theme, Color onSurface, Color accent) {
    final muted = onSurface.withOpacity(0.6);
    final success = accent;
    final error = theme.colorScheme.error;

    if (_cliOutput.isEmpty) {
      return Center(
        child: Text(
          'Enter a command below (e.g., point(0, 0), line(A, B))',
          style: TextStyle(
            color: muted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _cliOutput.length,
      itemBuilder: (context, index) {
        final line = _cliOutput[index];
        final isError = line.startsWith('[ERROR]');
        final isSuccess = line.startsWith('[OK]');

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: isError
                  ? error.withOpacity(0.75)
                  : isSuccess
                  ? success
                  : onSurface.withOpacity(0.85),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAIView(
    ThemeData theme,
    Color onSurface,
    Color accent,
    Color borderColor,
  ) {
    final muted = onSurface.withOpacity(0.6);

    if (_aiError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _aiError!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_generatedCommands == null) {
      return Center(
        child: Text(
          'Describe your construction in natural language\n(e.g., "Draw an equilateral triangle with side 5")',
          style: TextStyle(
            color: muted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount:
          _generatedCommands!.length +
          (_executionLog.isNotEmpty ? _executionLog.length + 1 : 0),
      itemBuilder: (context, index) {
        if (index < _generatedCommands!.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${index + 1}. ${_generatedCommands![index]}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: onSurface.withOpacity(0.85),
              ),
            ),
          );
        } else {
          final logIndex = index - _generatedCommands!.length - 1;
          if (logIndex < 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: borderColor),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              _executionLog[logIndex],
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: muted,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildControlPanel(
    ThemeData theme,
    Color accent,
    Color surface,
    Color surfaceVariant,
    Color borderColor,
  ) {
    final onSurface = theme.colorScheme.onSurface;
    final hintColor = onSurface.withOpacity(0.5);
    final inactiveAccent = onSurface.withOpacity(0.6);
    final sendIcon = _mode == PromptMode.cli ? Icons.send : Icons.auto_fix_high;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceVariant,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeButton(
                  theme,
                  accent,
                  onSurface,
                  PromptMode.cli,
                  'CLI',
                  Icons.terminal,
                ),
                _buildModeButton(
                  theme,
                  accent,
                  onSurface,
                  PromptMode.ai,
                  'AI',
                  Icons.psychology,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _mode == PromptMode.cli ? '> ' : 'AI',
            style: TextStyle(
              fontFamily: _mode == PromptMode.cli ? 'monospace' : null,
              color: _mode == PromptMode.cli ? accent : inactiveAccent,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(
                fontFamily: _mode == PromptMode.cli ? 'monospace' : null,
                color: onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: _mode == PromptMode.cli
                    ? 'Enter command... (e.g., point(0, 0))'
                    : 'Describe construction... (e.g., equilateral triangle)',
                hintStyle: TextStyle(color: hintColor, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
              ),
              maxLines: _mode == PromptMode.ai ? 2 : 1,
              onSubmitted: _mode == PromptMode.cli ? _executeCLICommand : null,
              enabled: !_isLoadingAI && !_isExecuting,
            ),
          ),
          if (_isLoadingAI || _isExecuting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(sendIcon, size: 18),
              color: accent,
              tooltip: _mode == PromptMode.cli ? 'Execute' : 'Generate',
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : (_mode == PromptMode.cli
                        ? () => _executeCLICommand(_controller.text)
                        : _generateAICommands),
            ),
          if (_mode == PromptMode.ai &&
              _generatedCommands != null &&
              !_isExecuting)
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 18),
              color: accent,
              tooltip: 'Execute commands',
              onPressed: _executeAICommands,
            ),
          IconButton(
            icon: const Icon(Icons.clear_all, size: 18),
            color: inactiveAccent,
            tooltip: 'Clear',
            onPressed:
                _controller.text.trim().isEmpty &&
                    (_mode == PromptMode.cli
                        ? _cliOutput.isEmpty
                        : _generatedCommands == null &&
                              _executionLog.isEmpty &&
                              _aiError == null)
                ? null
                : () {
                    setState(() {
                      if (_mode == PromptMode.cli) {
                        _cliOutput.clear();
                      } else {
                        _generatedCommands = null;
                        _aiError = null;
                        _executionLog.clear();
                      }
                      _controller.clear();
                    });
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _executeCLICommand(String command) async {
    if (command.trim().isEmpty || widget.cliExecutor == null) return;

    setState(() {
      _cliOutput.add('> $command');
    });

    try {
      // Use executeString which directly parses and executes
      final result = await widget.cliExecutor!.executeString(command);

      setState(() {
        if (result.success) {
          _cliOutput.add('[OK] ${result.message}');
          if (result.objectId != null) {
            _cliOutput.add('    Created: ${result.objectId}');
          }
        } else {
          _cliOutput.add('[ERROR] ${result.message}');
        }
      });
    } catch (e) {
      setState(() {
        _cliOutput.add('[ERROR] $e');
      });
    }

    _controller.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  Future<void> _generateAICommands() async {
    if (widget.aiService == null || widget.aiAdapter == null) return;

    setState(() {
      _isLoadingAI = true;
      _aiError = null;
      _generatedCommands = null;
      _executionLog = [];
    });

    try {
      final response = await widget.aiService!.generateCommands(
        _controller.text,
      );

      if (!response.isSuccess) {
        setState(() {
          _aiError = response.error ?? 'Failed to generate commands';
        });
        return;
      }

      setState(() {
        _generatedCommands = response.commands;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _aiError = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoadingAI = false;
      });
    }
  }

  Future<void> _executeAICommands() async {
    if (_generatedCommands == null || widget.aiAdapter == null) return;

    setState(() {
      _isExecuting = true;
      _executionLog = [];
    });

    try {
      final results = await widget.aiAdapter!.executeBatch(_generatedCommands!);

      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        setState(() {
          if (result.success) {
            _executionLog.add('✓ ${_generatedCommands![i]}');
          } else {
            _executionLog.add('✗ ${_generatedCommands![i]}: ${result.message}');
          }
        });
      }

      setState(() {
        _executionLog.add('');
        _executionLog.add('Construction complete!');
      });

      widget.onConstructionComplete?.call();

      // Clear after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _controller.clear();
            _generatedCommands = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _executionLog.add('');
        _executionLog.add('Error: $e');
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

/// Simple CommandParser for CLI mode
class CommandParser {
  Command? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final match = RegExp(r'^(\w+)\((.*)\)$').firstMatch(trimmed);
    if (match == null) {
      return Command(name: trimmed, arguments: [], originalInput: input);
    }

    final commandName = match.group(1)!;
    final argsString = match.group(2)!;
    final arguments = _parseArguments(argsString);

    return Command(
      name: commandName,
      arguments: arguments,
      originalInput: input,
    );
  }

  List<dynamic> _parseArguments(String argsString) {
    if (argsString.trim().isEmpty) return [];

    final args = <dynamic>[];
    final parts = argsString.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      final number = num.tryParse(trimmed);
      if (number != null) {
        args.add(number);
      } else {
        args.add(trimmed);
      }
    }

    return args;
  }
}
