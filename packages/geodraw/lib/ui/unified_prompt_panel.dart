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
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[700]!, width: 1)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _mode == PromptMode.cli ? _buildCLIView() : _buildAIView(),
          ),
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

  Widget _buildModeButton(PromptMode mode, String label, IconData icon) {
    final isActive = _mode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _mode = mode;
          _controller.clear();
          _focusNode.requestFocus();
        });
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

  Widget _buildCLIView() {
    if (_cliOutput.isEmpty) {
      return Center(
        child: Text(
          'Enter a command below (e.g., point(0, 0), line(A, B))',
          style: TextStyle(
            color: Colors.grey[600],
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
                  ? Colors.red[300]
                  : isSuccess
                  ? Colors.green[300]
                  : Colors.grey[300],
            ),
          ),
        );
      },
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
              color: Colors.green[400],
              tooltip: 'Execute commands',
              onPressed: _executeAICommands,
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
