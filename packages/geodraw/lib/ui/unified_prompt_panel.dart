/// Unified prompt panel that toggles between CLI and AI modes
library;

import 'package:flutter/material.dart';
import '../cli/cli.dart';
import '../core/dag/dag_manager.dart';
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
  bool _hasInput = false;
  String _cliDraft = '';
  String _aiDraft = '';

  // CLI state
  String? _lastCliMessage;
  bool _lastCliSuccess = false;

  // AI state
  List<String>? _generatedCommands;
  bool _isLoadingAI = false;
  String? _aiError;
  bool _isExecuting = false;
  List<String> _executionLog = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleInputChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAiMode = _mode == PromptMode.ai;

    return Container(
      height: isAiMode ? widget.height : null,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[700]!, width: 1)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (isAiMode)
            Expanded(child: _buildAIView()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(bottom: BorderSide(color: Colors.grey[700]!, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            _mode == PromptMode.cli ? Icons.terminal : Icons.psychology,
            color: _mode == PromptMode.cli
                ? Colors.green[400]
                : Colors.purple[300],
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _mode == PromptMode.cli ? 'CLI' : 'AI',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),

          // Mode toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeButton(PromptMode.cli, 'CLI', Icons.terminal),
                _buildModeButton(PromptMode.ai, 'AI', Icons.psychology),
              ],
            ),
          ),

          const Spacer(),

          // Clear button
          IconButton(
            icon: const Icon(Icons.clear_all, size: 16),
            color: Colors.grey[400],
            tooltip: 'Clear',
            onPressed: () {
              setState(() {
                if (_mode == PromptMode.cli) {
                  _lastCliMessage = null;
                  _cliDraft = '';
                } else {
                  _generatedCommands = null;
                  _aiError = null;
                  _executionLog.clear();
                  _aiDraft = '';
                }
                _controller.clear();
                _hasInput = false;
              });
            },
          ),

          if (_mode == PromptMode.cli && _lastCliMessage != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: _lastCliMessage!,
                preferBelow: false,
                child: Icon(
                  _lastCliSuccess ? Icons.check_circle : Icons.error,
                  color: _lastCliSuccess
                      ? Colors.green[400]
                      : Colors.red[300],
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton(PromptMode mode, String label, IconData icon) {
    final isActive = _mode == mode;
    return InkWell(
      onTap: () {
        if (_mode == mode) {
          _focusNode.requestFocus();
          return;
        }

        setState(() {
          final currentText = _controller.text;
          if (_mode == PromptMode.cli) {
            _cliDraft = currentText;
          } else {
            _aiDraft = currentText;
          }

          _mode = mode;

          final nextText = mode == PromptMode.cli ? _cliDraft : _aiDraft;
          _controller
            ..text = nextText
            ..selection = TextSelection.collapsed(offset: nextText.length);
        });

        _focusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey[700] : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIView() {
    if (_aiError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 32),
              const SizedBox(height: 8),
              Text(
                _aiError!,
                style: TextStyle(color: Colors.red[300], fontSize: 12),
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
            color: Colors.grey[600],
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
                color: Colors.grey[300],
              ),
            ),
          );
        } else {
          final logIndex = index - _generatedCommands!.length - 1;
          if (logIndex < 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.grey[700]),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              _executionLog[logIndex],
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildInputArea() {
    final bool submitDisabled = !_hasInput || _isLoadingAI || _isExecuting;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(top: BorderSide(color: Colors.grey[700]!, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _mode == PromptMode.cli
                    ? 'Enter command... (e.g., point(0, 0))'
                    : 'Describe construction... (e.g., equilateral triangle)',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              maxLines: _mode == PromptMode.ai ? 2 : 1,
              onSubmitted: _mode == PromptMode.cli ? _executeCLICommand : null,
              enabled: !_isLoadingAI && !_isExecuting,
            ),
          ),
          if (_isLoadingAI || _isExecuting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _mode == PromptMode.cli ? Icons.send : Icons.auto_fix_high,
                size: 18,
              ),
              color: _mode == PromptMode.cli
                  ? Colors.green[400]
                  : Colors.purple[300],
              tooltip: _mode == PromptMode.cli ? 'Execute' : 'Generate',
              onPressed: submitDisabled
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
              color: Colors.green[400],
              tooltip: 'Execute commands',
              onPressed: _executeAICommands,
            ),
        ],
      ),
    );
  }

  Future<void> _executeCLICommand(String command) async {
    if (command.trim().isEmpty || widget.cliExecutor == null || _isExecuting) {
      return;
    }

    setState(() {
      _isExecuting = true;
    });

    try {
      // Use executeString which directly parses and executes
      final result = await widget.cliExecutor!.executeString(command);

      setState(() {
        final suffix = result.objectId != null
            ? ' (Created: ${result.objectId})'
            : '';
        _lastCliMessage = '${result.message}$suffix';
        _lastCliSuccess = result.success;
      });

      if (result.success) {
        widget.onConstructionComplete?.call();
      }
    } catch (e) {
      setState(() {
        _lastCliMessage = 'Error: $e';
        _lastCliSuccess = false;
      });
    } finally {
      setState(() {
        _isExecuting = false;
        _cliDraft = '';

        if (_mode == PromptMode.cli) {
          _controller.clear();
          _hasInput = false;
        }
      });
      if (_mode == PromptMode.cli) {
        _focusNode.requestFocus();
      }
    }
  }

  Future<void> _generateAICommands() async {
    if (widget.aiService == null || widget.aiAdapter == null) {
      debugPrint(
        'UnifiedPromptPanel: AI service or adapter not configured; prompt ignored.',
      );
      return;
    }

    final prompt = _controller.text.trim();
    debugPrint('UnifiedPromptPanel: Submitting AI prompt => "$prompt"');

    setState(() {
      _isLoadingAI = true;
      _aiError = null;
      _generatedCommands = null;
      _executionLog = [];
    });

    try {
      // Use context-aware method to include existing objects, labels, and canvas info
      final response = await widget.aiService!.generateCommandsWithContext(
        prompt,
        widget.dagManager,
      );

      if (!response.isSuccess) {
        debugPrint(
          'UnifiedPromptPanel: AI response error => ${response.error}',
        );
        setState(() {
          _aiError = response.error ?? 'Failed to generate commands';
        });
        return;
      }

      setState(() {
        _generatedCommands = response.commands;
      });

      debugPrint(
        'UnifiedPromptPanel: AI generated ${response.commands?.length ?? 0} commands.',
      );
      if (response.commands != null && response.commands!.isNotEmpty) {
        for (var i = 0; i < response.commands!.length; i++) {
          debugPrint('UnifiedPromptPanel: [${i + 1}] ${response.commands![i]}');
        }
        debugPrint('UnifiedPromptPanel: Use the play button to execute these commands.');
      }

      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint('UnifiedPromptPanel: AI prompt execution threw $e');
      debugPrint('UnifiedPromptPanel stack: $stackTrace');
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
      debugPrint(
        'UnifiedPromptPanel: Executing ${_generatedCommands!.length} AI commands...',
      );
      final results = await widget.aiAdapter!.executeBatch(_generatedCommands!);

      var allSucceeded = true;
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final commandText = _generatedCommands![i];

        setState(() {
          if (result.success) {
            _executionLog.add('✓ $commandText');
          } else {
            _executionLog.add('✗ $commandText: ${result.message}');
          }
        });

        debugPrint(
          'UnifiedPromptPanel: Command ${i + 1}/${_generatedCommands!.length} ${result.success ? 'succeeded' : 'failed'} => $commandText',
        );

        if (!result.success) {
          allSucceeded = false;
          debugPrint('UnifiedPromptPanel: Failure message => ${result.message}');
          debugPrint('UnifiedPromptPanel: Halting execution after failure.');
          break;
        }
      }

      if (allSucceeded) {
        setState(() {
          _executionLog.add('');
          _executionLog.add('Construction complete!');
        });
        debugPrint('UnifiedPromptPanel: AI execution complete.');
        widget.onConstructionComplete?.call();
      } else {
        debugPrint('UnifiedPromptPanel: AI execution halted before completion.');
      }

      // Clear after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _controller.clear();
            _generatedCommands = null;
            _aiDraft = '';
            _hasInput = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _executionLog.add('');
        _executionLog.add('Error: $e');
      });
      debugPrint('UnifiedPromptPanel: Executing AI commands failed => $e');
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

  void _handleInputChanged() {
    final text = _controller.text;
    if (_mode == PromptMode.cli) {
      _cliDraft = text;
    } else {
      _aiDraft = text;
    }

    final hasInput = text.trim().isNotEmpty;
    if (hasInput == _hasInput) {
      return;
    }

    setState(() {
      _hasInput = hasInput;
    });
  }
}
