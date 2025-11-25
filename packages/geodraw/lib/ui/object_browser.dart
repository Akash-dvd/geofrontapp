import 'package:flutter/material.dart';

import '../core/dag/dag_manager.dart';
import '../models/canvas_style.dart';
import '../models/geometry_object.dart';

/// Browser widget for viewing and managing geometric objects
class ObjectBrowser extends StatefulWidget {
  final DAGManager dagManager;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final ValueChanged<String>? onDeleteRequested;
  final double width;

  const ObjectBrowser({
    super.key,
    required this.dagManager,
    this.selectedIds = const {},
    this.onSelectionChanged,
    this.onDeleteRequested,
    this.width = 250,
  });

  @override
  State<ObjectBrowser> createState() => _ObjectBrowserState();
}

class _ObjectBrowserState extends State<ObjectBrowser> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outlineColor = colorScheme.outlineVariant.withOpacity(0.35);
    final panelColor = colorScheme.surfaceContainerHighest.withOpacity(0.92);
    final headerColor = colorScheme.surface;
    final headerBorder = BorderSide(color: outlineColor, width: 1);
    final sortedNodes = widget.dagManager
        .topologicalSort()
        .where((node) => node.object is GeometryObject)
        .toList();

    Future<void> handleEdit(GeometryObject object) async {
      final updated = await _showEditDialog(context, object);
      if (updated != null) {
        widget.dagManager.updateObject(object.id, updated);
        setState(() {});
      }
    }

    void handleVisibilityToggle(GeometryObject object) {
      final updated = object.copyWith(visible: !object.visible);
      widget.dagManager.updateObject(object.id, updated);
      setState(() {});
    }

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(left: BorderSide(color: outlineColor, width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: headerColor,
              border: Border(bottom: headerBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Objects (${widget.dagManager.nodeCount})',
                  style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ) ??
                      const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Object list
          Expanded(
            child: sortedNodes.isEmpty
                ? Center(
                    child: Text(
                      'No objects',
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ) ??
                          TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedNodes.length,
                    itemBuilder: (context, index) {
                      final node = sortedNodes[index];
                      final geometry = node.object as GeometryObject;
                      return _ObjectListTile(
                        node: node,
                        object: geometry,
                        isSelected: widget.selectedIds.contains(node.id),
                        onToggleVisibility: () => handleVisibilityToggle(geometry),
                        onTap: () {
                          widget.onSelectionChanged?.call({node.id});
                        },
                        onDelete: () {
                          widget.onDeleteRequested?.call(node.id);
                        },
                        onEdit: () => handleEdit(geometry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<GeometryObject?> _showEditDialog(
    BuildContext context,
    GeometryObject object,
  ) async {
    final labelController = TextEditingController(text: object.label);
    final CanvasStyle style = object.style;
    final strokeColorController = TextEditingController(
      text: CanvasStyle.colorToHex(style.strokeColor),
    );
    final fillColorController = TextEditingController(
      text: CanvasStyle.colorToHex(style.fillColor),
    );
    final labelColorController = TextEditingController(
      text: CanvasStyle.colorToHex(style.labelColor),
    );
    final strokeWidthController = TextEditingController(
      text: style.strokeWidth.toString(),
    );
    final pointRadiusController = TextEditingController(
      text: style.pointRadius.toString(),
    );
    final labelFontSizeController = TextEditingController(
      text: style.labelFontSize.toString(),
    );
    bool filled = style.filled;

    Color parseColor(String input, Color fallback) {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return fallback;
      try {
        return CanvasStyle.colorFromHex(trimmed);
      } catch (_) {
        return fallback;
      }
    }

    double parseDouble(String input, double fallback) {
      final value = double.tryParse(input.trim());
      return value ?? fallback;
    }

    return showDialog<GeometryObject>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('Edit ${object.runtimeType}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(labelText: 'Label'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: strokeColorController,
                      decoration: const InputDecoration(
                        labelText: 'Stroke Color (#RRGGBB or #AARRGGBB)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fillColorController,
                      decoration: const InputDecoration(
                        labelText: 'Fill Color (#RRGGBB or #AARRGGBB)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: strokeWidthController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Stroke Width',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: pointRadiusController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Point Radius',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: labelFontSizeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Label Font Size',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: labelColorController,
                            decoration: const InputDecoration(
                              labelText: 'Label Color (#RRGGBB or #AARRGGBB)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Switch(
                          value: filled,
                          onChanged: (value) => setState(() => filled = value),
                        ),
                        const Text('Filled'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newStrokeColor = parseColor(
                      strokeColorController.text,
                      style.strokeColor,
                    );
                    final newFillColor = parseColor(
                      fillColorController.text,
                      style.fillColor,
                    );
                    final newLabelColor = parseColor(
                      labelColorController.text,
                      style.labelColor,
                    );
                    final newStrokeWidth = parseDouble(
                      strokeWidthController.text,
                      style.strokeWidth,
                    );
                    final newPointRadius = parseDouble(
                      pointRadiusController.text,
                      style.pointRadius,
                    );
                    final newLabelFontSize = parseDouble(
                      labelFontSizeController.text,
                      style.labelFontSize,
                    );

                    final updatedStyle = style.copyWith(
                      strokeColor: newStrokeColor,
                      fillColor: newFillColor,
                      strokeWidth: newStrokeWidth,
                      pointRadius: newPointRadius,
                      filled: filled,
                      labelColor: newLabelColor,
                      labelFontSize: newLabelFontSize,
                    );

                    final updatedLabel = labelController.text.trim();
                    final updatedObject = object.copyWith(
                      label: updatedLabel,
                      style: updatedStyle,
                    );

                    Navigator.of(dialogContext).pop(updatedObject);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ObjectListTile extends StatelessWidget {
  final node;
  final GeometryObject object;
  final bool isSelected;
  final VoidCallback onToggleVisibility;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ObjectListTile({
    required this.node,
    required this.object,
    required this.isSelected,
    required this.onToggleVisibility,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outlineColor = colorScheme.outlineVariant.withOpacity(0.3);
    final selectionColor =
        isSelected ? colorScheme.primary.withOpacity(0.12) : Colors.transparent;
    final iconAccent = colorScheme.primary;
    final secondaryIcon = colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: selectionColor,
        border: Border(bottom: BorderSide(color: outlineColor, width: 1)),
      ),
      child: ListTile(
        dense: true,
        leading: Tooltip(
          message: object.visible ? 'Click to hide' : 'Click to show',
          waitDuration: const Duration(milliseconds: 250),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleVisibility,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
                    color: object.visible
                        ? object.style.strokeColor.withOpacity(0.22)
                        : Colors.transparent,
            shape: BoxShape.circle,
                    border: Border.all(
                      color: object.style.strokeColor.withOpacity(
                        object.visible ? 1 : 0.5,
                      ),
                      width: 2,
                    ),
                  ),
                  child: object.visible
                      ? const SizedBox.shrink()
                      : Icon(
                          Icons.visibility_off,
                          size: 14,
                          color: secondaryIcon,
                        ),
                ),
              ),
            ),
          ),
        ),
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
          object.label.isEmpty ? object.id : object.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ) ??
                    TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
              Text(
          '${object.runtimeType.toString().replaceAll('Geo', '')} • Depth: ${node.depth}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.isFree)
              Tooltip(
                message: 'Free object',
                child: Icon(Icons.lock_open, size: 14, color: iconAccent),
              )
            else
              Tooltip(
                message: '${node.parentIds.length} dependencies',
                child: Icon(Icons.link, size: 14, color: secondaryIcon),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              color: secondaryIcon,
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              color: theme.colorScheme.error,
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: null,
      ),
    );
  }
}
