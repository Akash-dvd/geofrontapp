/// AI-powered natural language construction panel
library;

import 'package:flutter/material.dart';
import '../cli/command_executor.dart';
import '../dag/dag_manager.dart';
import '../ai/ai_service.dart';
import '../ai/command_validator.dart';

/// Panel for AI-powered natural language geometry construction
class AIPanel extends StatefulWidget {
  final AIService aiService;
  final CommandExecutor commandExecutor;
  final DAGManager dagManager;
  final VoidCallback? onConstructionComplete;

  const AIPanel({
    super.key,
    required this.aiService,
    required this.commandExecutor,
    required this.dagManager,
    this.onConstructionComplete,
  });

  @override
  State<AIPanel> createState() => _AIPanelState();
}

class _AIPanelState extends State<AIPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<String>? _generatedCommands;
  ValidationResult? _validationResult;
  bool _isLoading = false;
  String? _error;
  bool _isExecuting = false;
  List<String> _executionLog = [];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                'AI Construction',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Input field
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Describe your construction',
              hintText: 'e.g., "Draw an equilateral triangle with side length 5"',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.edit_note),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _controller.clear();
                          _generatedCommands = null;
                          _validationResult = null;
                          _error = null;
                          _executionLog = [];
                        });
                      },
                    )
                  : null,
            ),
            maxLines: 3,
            enabled: !_isLoading && !_isExecuting,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Generate button
          ElevatedButton.icon(
            onPressed: _controller.text.trim().isEmpty || _isLoading || _isExecuting
                ? null
                : _generateCommands,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high),
            label: Text(_isLoading ? 'Generating...' : 'Generate Commands'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          // Error message
          if (_error != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(),
          ],

          // Command preview
          if (_generatedCommands != null && _validationResult != null) ...[
            const SizedBox(height: 16),
            Expanded(child: _buildCommandPreview()),
          ],

          // Execution log
          if (_executionLog.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildExecutionLog(),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandPreview() {
    final validation = _validationResult!;
    final hasErrors = validation.hasErrors;
    final hasWarnings = validation.hasWarnings;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasErrors
                  ? Colors.red[50]
                  : hasWarnings
                      ? Colors.orange[50]
                      : Colors.green[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasErrors
                      ? Icons.error
                      : hasWarnings
                          ? Icons.warning
                          : Icons.check_circle,
                  color: hasErrors
                      ? Colors.red
                      : hasWarnings
                          ? Colors.orange
                          : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasErrors
                        ? 'Validation Failed (${validation.errors.length} errors)'
                        : hasWarnings
                            ? 'Validation Passed with ${validation.warnings.length} warnings'
                            : '${_generatedCommands!.length} Commands Ready',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!hasErrors && !_isExecuting)
                  ElevatedButton.icon(
                    onPressed: _executeCommands,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Execute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                if (_isExecuting)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),

          // Errors
          if (hasErrors) ...[
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Errors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...validation.errors.map((error) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          '• $error',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      )),
                ],
              ),
            ),
          ],

          // Warnings
          if (hasWarnings) ...[
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Warnings:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...validation.warnings.map((warning) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          '• $warning',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      )),
                ],
              ),
            ),
          ],

          // Command list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _generatedCommands!.length,
              itemBuilder: (context, index) {
                final command = _generatedCommands![index];
                final isValid = index < validation.validCommands.length;
                
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: isValid ? Colors.green : Colors.red,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  title: Text(
                    command,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isValid ? Colors.black : Colors.red,
                    ),
                  ),
                  trailing: isValid
                      ? const Icon(Icons.check, color: Colors.green, size: 16)
                      : const Icon(Icons.close, color: Colors.red, size: 16),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionLog() {
    return Card(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: const Text(
                'Execution Log',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _executionLog.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      _executionLog[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateCommands() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _generatedCommands = null;
      _validationResult = null;
      _executionLog = [];
    });

    try {
      // Generate commands from AI
      final response = await widget.aiService.generateCommands(
        _controller.text,
      );

      if (!response.isSuccess) {
        setState(() {
          _error = response.error;
        });
        return;
      }

      final commands = response.commands!;

      // Validate commands
      final validator = CommandValidator();
      final validation = validator.validate(commands);

      setState(() {
        _generatedCommands = commands;
        _validationResult = validation;
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _executeCommands() async {
    if (_validationResult == null || !_validationResult!.isValid) {
      return;
    }

    setState(() {
      _isExecuting = true;
      _executionLog = [];
    });

    try {
      final commands = _validationResult!.validCommands;
      
      for (int i = 0; i < commands.length; i++) {
        final command = commands[i];
        
        setState(() {
          _executionLog.add('Executing: ${command.originalInput}');
        });

        final result = await widget.commandExecutor.execute(command);

        setState(() {
          if (result.success) {
            _executionLog.add('  ✓ ${result.message}');
            if (result.objectId != null) {
              _executionLog.add('    Created: ${result.objectId}');
            }
          } else {
            _executionLog.add('  ✗ ${result.message}');
          }
        });

        // Small delay for visual feedback
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _executionLog.add('');
        _executionLog.add('Construction complete!');
      });

      // Notify completion
      widget.onConstructionComplete?.call();

      // Clear after successful execution
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _controller.clear();
            _generatedCommands = null;
            _validationResult = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _executionLog.add('');
        _executionLog.add('Error during execution: $e');
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }
}
