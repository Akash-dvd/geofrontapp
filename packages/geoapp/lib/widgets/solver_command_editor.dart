import 'package:flutter/material.dart';
import 'package:geodraw/geodraw.dart';

import '../models/solver_command_catalog.dart';

/// Editor widget for managing solver command lists with command + argument UI.
class SolverCommandListEditor extends StatelessWidget {
  const SolverCommandListEditor({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.catalog,
    required this.value,
    required this.onChanged,
    required this.dagManager,
  });

  final String title;
  final String emptyLabel;
  final List<SolverCommandDescriptor> catalog;
  final SolverCommandSet value;
  final ValueChanged<SolverCommandSet> onChanged;
  final DAGManager dagManager;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                MenuAnchor(
                  builder: (context, controller, _) {
                    return FilledButton.icon(
                      onPressed: () {
                        controller.open();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add command'),
                    );
                  },
                  menuChildren: catalog
                      .map(
                        (descriptor) => MenuItemButton(
                          onPressed: () {
                            final entry = SolverCommandEntry(
                              command: descriptor.id,
                              arguments: List.filled(
                                descriptor.arguments.length,
                                '',
                              ),
                            );
                            onChanged(value.add(entry));
                          },
                          child: Text(descriptor.label),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (value.entries.isEmpty)
              Text(
                emptyLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < value.entries.length; i++)
                    _SolverCommandCard(
                      entry: value.entries[i],
                      descriptor: SolverCommandCatalog.byId(
                        value.entries[i].command,
                      ),
                      allDescriptors: catalog,
                      onChanged: (updated) {
                        onChanged(value.replace(i, updated));
                      },
                      onRemove: () {
                        onChanged(value.removeAt(i));
                      },
                      dagManager: dagManager,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SolverCommandCard extends StatefulWidget {
  const _SolverCommandCard({
    required this.entry,
    required this.descriptor,
    required this.allDescriptors,
    required this.onChanged,
    required this.onRemove,
    required this.dagManager,
  });

  final SolverCommandEntry entry;
  final SolverCommandDescriptor? descriptor;
  final List<SolverCommandDescriptor> allDescriptors;
  final ValueChanged<SolverCommandEntry> onChanged;
  final VoidCallback onRemove;
  final DAGManager dagManager;

  @override
  State<_SolverCommandCard> createState() => _SolverCommandCardState();
}

class _SolverCommandCardState extends State<_SolverCommandCard> {
  late String _commandId;
  late List<TextEditingController> _argumentControllers;

  @override
  void initState() {
    super.initState();
    _commandId = widget.entry.command;
    _argumentControllers = _buildControllers(widget.descriptor);
  }

  @override
  void didUpdateWidget(covariant _SolverCommandCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry ||
        oldWidget.descriptor != widget.descriptor) {
      _commandId = widget.entry.command;
      _disposeControllers();
      _argumentControllers = _buildControllers(widget.descriptor);
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _argumentControllers) {
      controller.dispose();
    }
    _argumentControllers = const [];
  }

  List<TextEditingController> _buildControllers(
    SolverCommandDescriptor? descriptor,
  ) {
    final args = descriptor?.arguments.length ?? widget.entry.arguments.length;
    return List.generate(args, (index) {
      final value = index < widget.entry.arguments.length
          ? widget.entry.arguments[index]
          : '';
      return TextEditingController(text: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final descriptor = widget.descriptor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _commandId,
                      decoration: const InputDecoration(
                        labelText: 'Command',
                      ),
                      items: widget.allDescriptors
                          .map(
                            (descriptor) => DropdownMenuItem(
                              value: descriptor.id,
                              child: Text(descriptor.label),
                            ),
                          )
                          .toList(),
                      onChanged: (selected) {
                        if (selected == null) return;
                        final newDescriptor = SolverCommandCatalog.byId(selected);
                        setState(() {
                          _commandId = selected;
                          _disposeControllers();
                          _argumentControllers = _buildControllers(newDescriptor);
                        });
                        _emitChange(newDescriptor);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Remove command',
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              if (descriptor?.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  descriptor!.description!,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (descriptor != null && descriptor.arguments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (var index = 0;
                        index < descriptor.arguments.length;
                        index++)
                      SizedBox(
                        width: 240,
                        child: _ArgumentInput(
                          controller: _argumentControllers[index],
                          descriptor: descriptor.arguments[index],
                          dagManager: widget.dagManager,
                          onChanged: (value) {
                            _argumentControllers[index].text = value;
                            _emitChange(descriptor);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _emitChange(SolverCommandDescriptor? descriptor) {
    final argCount = descriptor?.arguments.length ?? _argumentControllers.length;
    final args = List<String>.generate(argCount, (index) {
      return index < _argumentControllers.length
          ? _argumentControllers[index].text.trim()
          : '';
    });

    widget.onChanged(
      SolverCommandEntry(
        command: _commandId,
        arguments: args,
      ),
    );
  }
}

class _ArgumentInput extends StatefulWidget {
  const _ArgumentInput({
    required this.controller,
    required this.descriptor,
    required this.dagManager,
    required this.onChanged,
  });

  final TextEditingController controller;
  final SolverArgumentDescriptor descriptor;
  final DAGManager dagManager;
  final ValueChanged<String> onChanged;

  @override
  State<_ArgumentInput> createState() => _ArgumentInputState();
}

class _ArgumentInputState extends State<_ArgumentInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  List<String> get _suggestions {
    final values = <String>{};
    for (final node in widget.dagManager.nodes.values) {
      final object = node.object;
      final label = object is GeometryObject && object.label.isNotEmpty
          ? object.label
          : object.id;

      switch (widget.descriptor.inputType) {
        case SolverArgumentInputType.point:
          if (object is GeoPoint) {
            values.add(label);
          }
          break;
        case SolverArgumentInputType.line:
          if (object is GeoLine) {
            values.add(label);
          }
          break;
        case SolverArgumentInputType.circle:
          if (object is GeoCircle) {
            values.add(label);
          }
          break;
        case SolverArgumentInputType.polygon:
          if (object is GeometryObject) {
            values.add(label);
          }
          break;
        case SolverArgumentInputType.object:
          values.add(label);
          break;
        default:
          break;
      }
    }

    return values.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.descriptor.inputType) {
      case SolverArgumentInputType.length:
      case SolverArgumentInputType.value:
      case SolverArgumentInputType.ratio:
      case SolverArgumentInputType.angle:
      case SolverArgumentInputType.area:
        return TextFormField(
          controller: _controller,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: widget.descriptor.label,
            hintText: widget.descriptor.hint,
          ),
          onChanged: widget.onChanged,
        );
      case SolverArgumentInputType.text:
        return TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.descriptor.label,
            hintText: widget.descriptor.hint,
          ),
          onChanged: widget.onChanged,
        );
      case SolverArgumentInputType.point:
      case SolverArgumentInputType.line:
      case SolverArgumentInputType.circle:
      case SolverArgumentInputType.object:
      case SolverArgumentInputType.polygon:
        final suggestions = _suggestions;
        return Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.toLowerCase();
            return suggestions.where(
              (option) => option.toLowerCase().contains(query),
            );
          },
          initialValue: TextEditingValue(text: _controller.text),
          onSelected: (value) {
            _controller.text = value;
            widget.onChanged(value);
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            textEditingController
              ..text = _controller.text
              ..selection = TextSelection.collapsed(
                offset: textEditingController.text.length,
              );
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.descriptor.label,
                hintText: widget.descriptor.hint,
              ),
              onChanged: widget.onChanged,
            );
          },
        );
    }
  }
}
