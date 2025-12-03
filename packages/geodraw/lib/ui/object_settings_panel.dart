import 'package:flutter/material.dart';
import '../models/geometry_object.dart';
import '../models/canvas_style.dart';
import '../core/dag/dag_manager.dart';
import '../core/label_manager.dart';
import '../models/simple/geo_point.dart';

/// Right-side settings panel for editing object properties
class ObjectSettingsPanel extends StatelessWidget {
  final GeometryObject object;
  final DAGManager dagManager;
  final ValueChanged<GeometryObject> onObjectUpdated;
  final VoidCallback onClose;

  const ObjectSettingsPanel({
    super.key,
    required this.object,
    required this.dagManager,
    required this.onObjectUpdated,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Wrap in error boundary to catch any widget errors
    return Material(
      color: Colors.transparent,
      child: Builder(
        builder: (context) {
          try {
            final style = object.style;

            return Container(
              width: 350,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  left: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ) ?? const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              object.label.isEmpty ? object.id : object.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ) ?? TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Label Section
                  _SectionHeader(title: 'Label'),
                  const SizedBox(height: 8),
                  _LabelEditor(
                    object: object,
                    dagManager: dagManager,
                    onLabelChanged: (newLabel) {
                      // Check if this is an element (not a direct DAG node)
                      final containerId = dagManager.getContainerForElement(object.id);
                      if (containerId != null) {
                        // This is an element - need to update element ID
                        _handleElementIdChange(
                          dagManager: dagManager,
                          object: object,
                          newLabel: newLabel,
                          containerId: containerId,
                          onObjectUpdated: onObjectUpdated,
                        );
                      } else {
                        // Regular DAG node - just update label
                        final updated = object.copyWith(label: newLabel);
                        onObjectUpdated(updated);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Colors Section
                  _SectionHeader(title: 'Colors'),
                  const SizedBox(height: 8),
                  _ColorEditor(
                    style: style,
                    onStyleChanged: (newStyle) {
                      final updated = object.copyWith(style: newStyle);
                      onObjectUpdated(updated);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Stroke Section
                  _SectionHeader(title: 'Stroke'),
                  const SizedBox(height: 8),
                  _StrokeEditor(
                    style: style,
                    object: object,
                    onStyleChanged: (newStyle) {
                      final updated = object.copyWith(style: newStyle);
                      onObjectUpdated(updated);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Fill Section
                  _SectionHeader(title: 'Fill'),
                  const SizedBox(height: 8),
                  _FillEditor(
                    style: style,
                    onStyleChanged: (newStyle) {
                      final updated = object.copyWith(style: newStyle);
                      onObjectUpdated(updated);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Point Properties (if applicable)
                  if (object.runtimeType.toString().contains('Point'))
                    ...[
                      _SectionHeader(title: 'Point Properties'),
                      const SizedBox(height: 8),
                      _PointRadiusEditor(
                        style: style,
                        onStyleChanged: (newStyle) {
                          final updated = object.copyWith(style: newStyle);
                          onObjectUpdated(updated);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                  // Label Appearance
                  _SectionHeader(title: 'Label Appearance'),
                  const SizedBox(height: 8),
                  _LabelAppearanceEditor(
                    style: style,
                    onStyleChanged: (newStyle) {
                      final updated = object.copyWith(style: newStyle);
                      onObjectUpdated(updated);
                    },
                  ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
          } catch (e) {
            // Error fallback UI
            return Container(
              width: 350,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  left: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Settings',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ) ?? const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onClose,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading settings',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.toString(),
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

/// Handle element ID change (when renaming an element)
void _handleElementIdChange({
  required DAGManager dagManager,
  required GeometryObject object,
  required String newLabel,
  required String containerId,
  required ValueChanged<GeometryObject> onObjectUpdated,
}) {
  // If label is empty, auto-assign a new unique label
  final finalLabel = newLabel.isEmpty
      ? LabelManager.getNextAvailableLabel(
          dagManager,
          object is GeoPoint ? GeometryObjectType.point : GeometryObjectType.line,
        )
      : newLabel;

  // Validate uniqueness
  if (!LabelManager.isLabelUnique(dagManager, finalLabel, excludeId: object.id)) {
    // Label conflict - this should be caught by validation, but handle gracefully
    return;
  }

  // Create updated element with new ID
  final updatedElement = object.copyWith(
    id: finalLabel, // In new system: ID = label
    label: finalLabel,
  );

  // Update element ID in DAGManager (this handles all dependency updates)
  dagManager.updateElementId(
    oldElementId: object.id,
    newElementId: finalLabel,
    updatedElement: updatedElement,
  );

  // Notify UI of the update
  onObjectUpdated(updatedElement);
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _LabelEditor extends StatefulWidget {
  final GeometryObject object;
  final DAGManager dagManager;
  final ValueChanged<String> onLabelChanged;

  const _LabelEditor({
    required this.object,
    required this.dagManager,
    required this.onLabelChanged,
  });

  @override
  State<_LabelEditor> createState() => _LabelEditorState();
}

class _LabelEditorState extends State<_LabelEditor> {
  late TextEditingController _controller;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    // For elements: show ID (which is the label) as editable
    // For containers: show label
    final displayText = widget.dagManager.getContainerForElement(widget.object.id) != null
        ? widget.object.id // Element: ID = label
        : widget.object.label; // Container: use label
    _controller = TextEditingController(text: displayText);
    _controller.addListener(_validateLabel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateLabel() {
    final newLabel = _controller.text.trim();
    if (newLabel.isEmpty) {
      setState(() => _isValid = true);
      return;
    }

    // Use LabelManager to check global uniqueness (nodes AND elements)
    final isUnique = LabelManager.isLabelUnique(
      widget.dagManager,
      newLabel,
      excludeId: widget.object.id,
    );

    setState(() => _isValid = isUnique);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.dagManager.getContainerForElement(widget.object.id) != null
                ? 'Element ID (Label)'
                : 'Label',
            hintText: widget.dagManager.getContainerForElement(widget.object.id) != null
                ? 'Enter element ID (will auto-assign if empty)'
                : 'Enter label (empty to hide)',
            errorText: _isValid ? null : 'Label already exists',
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            if (_isValid) {
              widget.onLabelChanged(value.trim());
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Switch(
              value: widget.object.label.isNotEmpty,
              onChanged: (value) {
                _controller.text = value ? widget.object.id : '';
                if (value) {
                  widget.onLabelChanged(widget.object.id);
                } else {
                  widget.onLabelChanged('');
                }
              },
            ),
            const Text('Show Label'),
          ],
        ),
      ],
    );
  }
}

class _ColorEditor extends StatelessWidget {
  final CanvasStyle style;
  final ValueChanged<CanvasStyle> onStyleChanged;

  const _ColorEditor({
    required this.style,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorPalette = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.grey,
      Colors.black,
      Colors.white,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stroke Color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colorPalette.map((color) {
            final isSelected = color.value == style.strokeColor.value;
            return GestureDetector(
              onTap: () => onStyleChanged(style.copyWith(strokeColor: color)),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: _getContrastColor(color),
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

class _StrokeEditor extends StatelessWidget {
  final CanvasStyle style;
  final GeometryObject object;
  final ValueChanged<CanvasStyle> onStyleChanged;

  const _StrokeEditor({
    required this.style,
    required this.object,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLine = object.runtimeType.toString().contains('Line');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line Pattern (only for lines)
        if (isLine) ...[
          const Text('Line Pattern'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'solid',
                label: Text('Solid'),
                icon: Icon(Icons.remove, size: 16),
              ),
              ButtonSegment(
                value: 'dashed',
                label: Text('Dashed'),
                icon: Icon(Icons.drag_handle, size: 16),
              ),
              ButtonSegment(
                value: 'dotted',
                label: Text('Dotted'),
                icon: Icon(Icons.more_horiz, size: 16),
              ),
            ],
            selected: {style.linePattern},
            onSelectionChanged: (Set<String> selection) {
              if (selection.isNotEmpty) {
                onStyleChanged(
                  style.copyWith(linePattern: selection.first),
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // Stroke Width
        Text('Stroke Width: ${style.strokeWidth.toStringAsFixed(1)}'),
        Slider(
          value: style.strokeWidth,
          min: 0.5,
          max: 10.0,
          divisions: 19,
          label: style.strokeWidth.toStringAsFixed(1),
          onChanged: (value) {
            onStyleChanged(style.copyWith(strokeWidth: value));
          },
        ),
      ],
    );
  }
}

class _FillEditor extends StatelessWidget {
  final CanvasStyle style;
  final ValueChanged<CanvasStyle> onStyleChanged;

  const _FillEditor({
    required this.style,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorPalette = [
      Colors.red.withOpacity(0.5),
      Colors.orange.withOpacity(0.5),
      Colors.yellow.withOpacity(0.5),
      Colors.green.withOpacity(0.5),
      Colors.blue.withOpacity(0.5),
      Colors.indigo.withOpacity(0.5),
      Colors.purple.withOpacity(0.5),
      Colors.pink.withOpacity(0.5),
      Colors.brown.withOpacity(0.5),
      Colors.grey.withOpacity(0.5),
      Colors.transparent,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: style.filled,
              onChanged: (value) {
                onStyleChanged(style.copyWith(filled: value));
              },
            ),
            const Text('Filled'),
          ],
        ),
        if (style.filled) ...[
          const SizedBox(height: 16),
          const Text('Fill Color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colorPalette.map((color) {
              final isSelected = color.value == style.fillColor.value;
              return GestureDetector(
                onTap: () => onStyleChanged(style.copyWith(fillColor: color)),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Fill Opacity: ${(style.fillColor.opacity * 100).toInt()}%'),
          Slider(
            value: style.fillColor.opacity,
            onChanged: (value) {
              onStyleChanged(
                style.copyWith(
                  fillColor: style.fillColor.withOpacity(value),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _PointRadiusEditor extends StatelessWidget {
  final CanvasStyle style;
  final ValueChanged<CanvasStyle> onStyleChanged;

  const _PointRadiusEditor({
    required this.style,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Point Radius: ${style.pointRadius.toStringAsFixed(1)}'),
        Slider(
          value: style.pointRadius,
          min: 2.0,
          max: 20.0,
          divisions: 18,
          label: style.pointRadius.toStringAsFixed(1),
          onChanged: (value) {
            onStyleChanged(style.copyWith(pointRadius: value));
          },
        ),
      ],
    );
  }
}

class _LabelAppearanceEditor extends StatelessWidget {
  final CanvasStyle style;
  final ValueChanged<CanvasStyle> onStyleChanged;

  const _LabelAppearanceEditor({
    required this.style,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorPalette = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Label Color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colorPalette.map((color) {
            final isSelected = color.value == style.labelColor.value;
            return GestureDetector(
              onTap: () => onStyleChanged(style.copyWith(labelColor: color)),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: _getContrastColor(color),
                        size: 16,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Label Font Size: ${style.labelFontSize.toInt()}'),
        Slider(
          value: style.labelFontSize,
          min: 8.0,
          max: 24.0,
          divisions: 16,
          label: style.labelFontSize.toInt().toString(),
          onChanged: (value) {
            onStyleChanged(style.copyWith(labelFontSize: value));
          },
        ),
      ],
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

