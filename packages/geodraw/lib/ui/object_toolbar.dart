import 'package:flutter/material.dart';
import '../models/geometry_object.dart';
import '../models/canvas_style.dart';
import '../core/dag/dag_manager.dart';
import '../core/label_manager.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_circle.dart';
import '../models/complex/complex_geometry_object.dart';
import '../models/complex/geo_shapes.dart';

/// Horizontal toolbar that appears when objects are selected
class ObjectToolbar extends StatelessWidget {
  final List<GeometryObject> selectedObjects;
  final DAGManager dagManager;
  final VoidCallback? onSettingsToggle;
  final bool settingsPanelOpen;
  final ValueChanged<GeometryObject> onObjectUpdated;

  const ObjectToolbar({
    super.key,
    required this.selectedObjects,
    required this.dagManager,
    this.onSettingsToggle,
    this.settingsPanelOpen = false,
    required this.onObjectUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedObjects.isEmpty) return const SizedBox.shrink();

    // Use the first selected object's style as the base
    final firstObject = selectedObjects.first;
    final style = firstObject.style;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: const BoxConstraints(maxHeight: 48),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Color & Opacity
          _ColorOpacitySection(
            style: style,
            onStyleChanged: (newStyle) => _updateAllObjects(newStyle),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: const VerticalDivider(width: 1, thickness: 1),
          ),
          const SizedBox(width: 8),
          
          // Style
          _StyleSection(
            style: style,
            object: firstObject,
            onStyleChanged: (newStyle) => _updateAllObjects(newStyle),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: const VerticalDivider(width: 1, thickness: 1),
          ),
          const SizedBox(width: 8),
          
          // Label
          _LabelSection(
            objects: selectedObjects,
            dagManager: dagManager,
            onLabelChanged: (object) => onObjectUpdated(object),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: const VerticalDivider(width: 1, thickness: 1),
          ),
          const SizedBox(width: 8),
          
          // Settings
          IconButton(
            icon: Icon(
              settingsPanelOpen ? Icons.settings : Icons.settings_outlined,
              size: 18,
            ),
            tooltip: 'Settings',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onSettingsToggle,
            color: settingsPanelOpen
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _updateAllObjects(CanvasStyle newStyle) {
    for (final obj in selectedObjects) {
      final updated = obj.copyWith(style: newStyle);
      onObjectUpdated(updated);
    }
  }
}

/// Color and Opacity section
class _ColorOpacitySection extends StatefulWidget {
  final CanvasStyle style;
  final ValueChanged<CanvasStyle> onStyleChanged;

  const _ColorOpacitySection({
    required this.style,
    required this.onStyleChanged,
  });

  @override
  State<_ColorOpacitySection> createState() => _ColorOpacitySectionState();
}

class _ColorOpacitySectionState extends State<_ColorOpacitySection> {
  final List<Color> _colorPalette = [
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color button
        PopupMenuButton<Color>(
          tooltip: 'Color',
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.style.strokeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outline,
                width: 1.5,
              ),
            ),
          ),
          itemBuilder: (context) => _colorPalette.map((color) {
            return PopupMenuItem<Color>(
              value: color,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
            );
          }).toList(),
          onSelected: (color) {
            widget.onStyleChanged(
              widget.style.copyWith(strokeColor: color),
            );
          },
        ),
        const SizedBox(width: 6),
        
        // Opacity slider (only if filled)
        if (widget.style.filled)
          PopupMenuButton<void>(
            tooltip: 'Fill Opacity',
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.style.fillColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outline,
                  width: 1.5,
                ),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                enabled: false,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    final opacity = widget.style.fillColor.opacity;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Fill Opacity: ${(opacity * 100).toInt()}%'),
                        Slider(
                          value: opacity,
                          onChanged: (value) {
                            setState(() {
                              widget.onStyleChanged(
                                widget.style.copyWith(
                                  fillColor: widget.style.fillColor
                                      .withOpacity(value),
                                ),
                              );
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Style section (line pattern, width)
class _StyleSection extends StatelessWidget {
  final CanvasStyle style;
  final GeometryObject object;
  final ValueChanged<CanvasStyle> onStyleChanged;

  const _StyleSection({
    required this.style,
    required this.object,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLine = object.runtimeType.toString().contains('Line');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Line pattern (only for lines)
        if (isLine)
          PopupMenuButton<String>(
            tooltip: 'Line Style',
            child: Icon(
              _getLinePatternIcon(style.linePattern),
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'solid',
                child: Row(
                  children: [
                    Icon(Icons.remove, size: 16),
                    SizedBox(width: 8),
                    Text('Solid'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dashed',
                child: Row(
                  children: [
                    Icon(Icons.drag_handle, size: 16),
                    SizedBox(width: 8),
                    Text('Dashed'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dotted',
                child: Row(
                  children: [
                    Icon(Icons.more_horiz, size: 16),
                    SizedBox(width: 8),
                    Text('Dotted'),
                  ],
                ),
              ),
            ],
            onSelected: (pattern) {
              onStyleChanged(style.copyWith(linePattern: pattern));
            },
          ),
        if (isLine) const SizedBox(width: 6),
        
        // Width/Thickness slider
        PopupMenuButton<void>(
          tooltip: isLine ? 'Line Width' : 'Thickness',
          child: Icon(
            Icons.format_size,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          itemBuilder: (context) => [
            PopupMenuItem<void>(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, setState) {
                  final width = style.strokeWidth;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${isLine ? 'Line' : 'Stroke'} Width: ${width.toStringAsFixed(1)}'),
                      Slider(
                        value: width,
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        onChanged: (value) {
                          setState(() {
                            onStyleChanged(style.copyWith(strokeWidth: value));
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getLinePatternIcon(String pattern) {
    switch (pattern.toLowerCase()) {
      case 'dashed':
        return Icons.drag_handle;
      case 'dotted':
        return Icons.more_horiz;
      default:
        return Icons.remove;
    }
  }
}

/// Label section
class _LabelSection extends StatefulWidget {
  final List<GeometryObject> objects;
  final DAGManager dagManager;
  final ValueChanged<GeometryObject> onLabelChanged;

  const _LabelSection({
    required this.objects,
    required this.dagManager,
    required this.onLabelChanged,
  });

  @override
  State<_LabelSection> createState() => _LabelSectionState();
}

class _LabelSectionState extends State<_LabelSection> {
  final TextEditingController _labelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.objects.length == 1) {
      _labelController.text = widget.objects.first.label;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final firstObject = widget.objects.first;
    final hasLabel = firstObject.label.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show/Hide label toggle
        IconButton(
          icon: Icon(
            hasLabel ? Icons.label : Icons.label_outline,
            size: 18,
            color: hasLabel
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          tooltip: hasLabel ? 'Hide Label' : 'Show Label',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            final newLabel = hasLabel ? '' : firstObject.id;
            _updateLabel(firstObject, newLabel);
          },
        ),
        
        // Edit label button
        if (widget.objects.length == 1)
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Edit Label',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _showLabelEditDialog(context, firstObject),
          ),
      ],
    );
  }

  void _updateLabel(GeometryObject object, String newLabel) {
    // Validate label with LabelManager (checks nodes AND elements globally)
    if (newLabel.isNotEmpty && newLabel != object.label) {
      // Use LabelManager to check global uniqueness
      final isUnique = LabelManager.isLabelUnique(
        widget.dagManager,
        newLabel,
        excludeId: object.id,
      );
      
      if (!isUnique) {
        final suggestion = LabelManager.suggestNextLabel(
          widget.dagManager,
          newLabel,
          _getObjectType(object),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Label already exists. Suggested: $suggestion'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    final updated = object.copyWith(label: newLabel);
    widget.onLabelChanged(updated);
  }

  GeometryObjectType _getObjectType(GeometryObject object) {
    if (object is GeoPoint) return GeometryObjectType.point;
    if (object is GeoLine || object is GeoSegment || object is GeoArc) {
      return GeometryObjectType.line;
    }
    if (object is GeoCircle) return GeometryObjectType.circle;
    if (object is GenSimpleGeometryObjectList) return GeometryObjectType.simpleList;
    if (object is UnionGeometryObjectList) return GeometryObjectType.union;
    return GeometryObjectType.point; // Default fallback
  }

  Future<void> _showLabelEditDialog(
    BuildContext context,
    GeometryObject object,
  ) async {
    _labelController.text = object.label;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Label'),
        content: TextField(
          controller: _labelController,
          decoration: const InputDecoration(
            hintText: 'Enter label (leave empty to hide)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_labelController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      _updateLabel(object, result.trim());
    }
  }
}

