import 'package:flutter/material.dart';

import '../dag/dag_manager.dart';
import '../models/canvas_style.dart';
import '../models/geometry_object.dart';

/// Browser widget for viewing and managing geometric objects
class ObjectBrowser extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final sortedNodes = dagManager.topologicalSort();

    Future<void> handleEdit(GeometryObject object) async {
      final updated = await _showEditDialog(context, object);
      if (updated != null) {
        dagManager.updateObject(object.id, updated);
      }
    }

    return Container(
      // width controlled by parent, not internally
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(left: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Objects (${dagManager.nodeCount})',
                  style: const TextStyle(
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
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedNodes.length,
                    itemBuilder: (context, index) {
                      final node = sortedNodes[index];
                      final geometry = node.object;
                      return _ObjectListTile(
                        node: node,
                        object: geometry,
                        isSelected: selectedIds.contains(node.id),
                        onTap: () {
                          onSelectionChanged?.call({node.id});
                        },
                        onDelete: () {
                          onDeleteRequested?.call(node.id);
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

    Color _parseColor(String input, Color fallback) {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return fallback;
      try {
        return CanvasStyle.colorFromHex(trimmed);
      } catch (_) {
        return fallback;
      }
    }

    double _parseDouble(String input, double fallback) {
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
                    final newStrokeColor = _parseColor(
                      strokeColorController.text,
                      style.strokeColor,
                    );
                    final newFillColor = _parseColor(
                      fillColorController.text,
                      style.fillColor,
                    );
                    final newLabelColor = _parseColor(
                      labelColorController.text,
                      style.labelColor,
                    );
                    final newStrokeWidth = _parseDouble(
                      strokeWidthController.text,
                      style.strokeWidth,
                    );
                    final newPointRadius = _parseDouble(
                      pointRadiusController.text,
                      style.pointRadius,
                    );
                    final newLabelFontSize = _parseDouble(
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
                      color: newStrokeColor,
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
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ObjectListTile({
    required this.node,
    required this.object,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : null,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: object.color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: object.color, width: 2),
          ),
        ),
        title: Text(
          object.label.isEmpty ? object.id : object.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${object.runtimeType.toString().replaceAll('Geo', '')} • Depth: ${node.depth}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.isFree)
              Tooltip(
                message: 'Free object',
                child: Icon(
                  Icons.lock_open,
                  size: 14,
                  color: Colors.green[700],
                ),
              )
            else
              Tooltip(
                message: '${node.parentIds.length} dependencies',
                child: Icon(Icons.link, size: 14, color: Colors.grey[600]),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              color: Colors.blueGrey[600],
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              color: Colors.red[400],
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
