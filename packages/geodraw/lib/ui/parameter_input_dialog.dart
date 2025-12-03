import 'package:flutter/material.dart';
import '../tools/staged_selection_tool.dart';

/// Dialog for requesting parameter input from user
/// Used by transformation tools (rotation, dilation, etc.)
Future<Map<String, dynamic>?> showParameterInputDialog(
  BuildContext context,
  String title,
  List<ParameterSpec> parameters,
) async {
  return await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => _ParameterInputDialog(
      title: title,
      parameters: parameters,
    ),
  );
}

class _ParameterInputDialog extends StatefulWidget {
  final String title;
  final List<ParameterSpec> parameters;

  const _ParameterInputDialog({
    required this.title,
    required this.parameters,
  });

  @override
  State<_ParameterInputDialog> createState() => _ParameterInputDialogState();
}

class _ParameterInputDialogState extends State<_ParameterInputDialog> {
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // For rotation tool: angle unit and direction
  bool _useDegrees = true;
  bool _clockwise = false;

  @override
  void initState() {
    super.initState();
    for (final param in widget.parameters) {
      _values[param.key] = param.defaultValue ?? _getDefaultValue(param.type);
      _controllers[param.key] = TextEditingController(
        text: _formatValue(_values[param.key], param.type),
      );
      _focusNodes[param.key] = FocusNode();
    }
    // Auto-focus first field
    if (_focusNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes.values.first.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  dynamic _getDefaultValue(ParameterType type) {
    switch (type) {
      case ParameterType.angle:
        return 90.0;
      case ParameterType.number:
        return 2.0;
      case ParameterType.text:
        return '';
      case ParameterType.boolean:
        return false;
    }
  }

  String _formatValue(dynamic value, ParameterType type) {
    if (value == null) return '';
    switch (type) {
      case ParameterType.angle:
      case ParameterType.number:
        return value.toString();
      case ParameterType.text:
        return value.toString();
      case ParameterType.boolean:
        return value.toString();
    }
  }

  bool _validateAndParse() {
    for (final param in widget.parameters) {
      final text = _controllers[param.key]!.text.trim();
      if (text.isEmpty) {
        _showError('${param.label} cannot be empty');
        return false;
      }

      switch (param.type) {
        case ParameterType.angle:
        case ParameterType.number:
          final value = double.tryParse(text);
          if (value == null) {
            _showError('${param.label} must be a valid number');
            return false;
          }
          _values[param.key] = value;
          break;
        case ParameterType.text:
          _values[param.key] = text;
          break;
        case ParameterType.boolean:
          _values[param.key] = text.toLowerCase() == 'true';
          break;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _submit() {
    if (!_validateAndParse()) {
      return;
    }

    // For rotation tool: apply unit conversion and direction
    if (widget.title.toLowerCase().contains('rotate')) {
      final angleKey = widget.parameters
          .firstWhere((p) => p.type == ParameterType.angle)
          .key;
      double angle = _values[angleKey] as double;

      // Convert to radians if needed
      if (_useDegrees) {
        angle = angle * (3.141592653589793 / 180.0);
      }

      // Apply clockwise direction (negative angle)
      if (_clockwise) {
        angle = -angle;
      }

      _values[angleKey] = angle;
    }

    Navigator.of(context).pop(_values);
  }

  void _cancel() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRotation = widget.title.toLowerCase().contains('rotate');

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...widget.parameters.map((param) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildParameterField(param, isRotation),
              );
            }),
            // Rotation-specific controls
            if (isRotation) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Angle Unit:',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Degrees'),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Radians'),
                        ),
                      ],
                      selected: {_useDegrees},
                      onSelectionChanged: (Set<bool> selected) {
                        setState(() {
                          _useDegrees = selected.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Direction:',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Counter-\nClockwise'),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Clockwise'),
                        ),
                      ],
                      selected: {_clockwise},
                      onSelectionChanged: (Set<bool> selected) {
                        setState(() {
                          _clockwise = selected.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildParameterField(ParameterSpec param, bool isRotation) {
    final theme = Theme.of(context);

    switch (param.type) {
      case ParameterType.angle:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              param.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers[param.key],
              focusNode: _focusNodes[param.key],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                hintText: param.hint ?? 'Enter ${param.label.toLowerCase()}',
                border: const OutlineInputBorder(),
                suffixText: isRotation && _useDegrees ? '°' : null,
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (param.hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  param.hint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        );

      case ParameterType.number:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              param.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers[param.key],
              focusNode: _focusNodes[param.key],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                hintText: param.hint ?? 'Enter ${param.label.toLowerCase()}',
                border: const OutlineInputBorder(),
                helperText: param.hint,
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (param.hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  param.hint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        );

      case ParameterType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              param.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers[param.key],
              focusNode: _focusNodes[param.key],
              decoration: InputDecoration(
                hintText: param.hint ?? 'Enter ${param.label.toLowerCase()}',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        );

      case ParameterType.boolean:
        return Row(
          children: [
            Expanded(
              child: Text(
                param.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: _values[param.key] as bool? ?? false,
              onChanged: (value) {
                setState(() {
                  _values[param.key] = value;
                });
              },
            ),
          ],
        );
    }
  }
}

