import 'package:flutter/material.dart';
import '../cli/command_parser.dart';
import '../cli/command_executor.dart';
import '../dag/dag_manager.dart';

/// Panel for command-line interface interaction
class CLIPanel extends StatefulWidget {
  final DAGManager dagManager;
  final CommandExecutor commandExecutor;
  final double height;

  const CLIPanel({
    super.key,
    required this.dagManager,
    required this.commandExecutor,
    this.height = 200,
  });

  @override
  State<CLIPanel> createState() => _CLIPanelState();
}

class _CLIPanelState extends State<CLIPanel> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _output = [];
  final ScrollController _scrollController = ScrollController();

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
        border: Border(
          top: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, color: Colors.green[400], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Command Line',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 16),
                  color: Colors.grey[400],
                  tooltip: 'Clear output',
                  onPressed: () {
                    setState(() {
                      _output.clear();
                    });
                  },
                ),
              ],
            ),
          ),

          // Output area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _output.length,
              itemBuilder: (context, index) {
                final line = _output[index];
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
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                top: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '> ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.green[400],
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: _executeCommand,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, size: 18),
                  color: Colors.green[400],
                  tooltip: 'Execute',
                  onPressed: () => _executeCommand(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeCommand(String command) async {
    if (command.trim().isEmpty) return;

    // Add command to output
    setState(() {
      _output.add('> $command');
    });

    try {
      // Parse and execute
      final parser = CommandParser();
      final parsed = parser.parse(command);
      
      if (parsed == null) {
        setState(() {
          _output.add('[ERROR] Invalid command syntax');
        });
        return;
      }
      
      final result = await widget.commandExecutor.execute(parsed);

      // Add result to output
      setState(() {
        if (result.success) {
          _output.add('[OK] ${result.message}');
          if (result.objectId != null) {
            _output.add('    Created: ${result.objectId}');
          }
        } else {
          _output.add('[ERROR] ${result.message}');
        }
      });
    } catch (e) {
      setState(() {
        _output.add('[ERROR] $e');
      });
    }

    // Clear input
    _controller.clear();
    _focusNode.requestFocus();

    // Scroll to bottom
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
