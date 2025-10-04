import 'package:flutter/material.dart';
import '../tools/tool_manager.dart';
import '../tools/tool.dart';

/// Widget for selecting and managing construction tools
class ToolPalette extends StatelessWidget {
  final ToolManager toolManager;
  final ValueChanged<ToolType> onToolSelected;
  final Axis direction;

  const ToolPalette({
    super.key,
    required this.toolManager,
    required this.onToolSelected,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final tools = [
      _ToolButton(
        type: ToolType.select,
        icon: Icons.mouse,
        tooltip: 'Select',
        isActive: toolManager.activeToolType == ToolType.select,
        onPressed: () => onToolSelected(ToolType.select),
      ),
      _ToolButton(
        type: ToolType.pan,
        icon: Icons.pan_tool,
        tooltip: 'Pan',
        isActive: toolManager.activeToolType == ToolType.pan,
        onPressed: () => onToolSelected(ToolType.pan),
      ),
      const Divider(),
      _ToolButton(
        type: ToolType.point,
        icon: Icons.circle,
        tooltip: 'Point',
        isActive: toolManager.activeToolType == ToolType.point,
        onPressed: () => onToolSelected(ToolType.point),
      ),
      _ToolButton(
        type: ToolType.line,
        icon: Icons.remove,
        tooltip: 'Line',
        isActive: toolManager.activeToolType == ToolType.line,
        onPressed: () => onToolSelected(ToolType.line),
      ),
      _ToolButton(
        type: ToolType.circle,
        icon: Icons.circle_outlined,
        tooltip: 'Circle',
        isActive: toolManager.activeToolType == ToolType.circle,
        onPressed: () => onToolSelected(ToolType.circle),
      ),
      const Divider(),
      _ToolButton(
        type: ToolType.midpoint,
        icon: Icons.adjust,
        tooltip: 'Midpoint',
        isActive: toolManager.activeToolType == ToolType.midpoint,
        onPressed: () => onToolSelected(ToolType.midpoint),
      ),
      _ToolButton(
        type: ToolType.perpendicular,
        icon: Icons.add,
        tooltip: 'Perpendicular',
        isActive: toolManager.activeToolType == ToolType.perpendicular,
        onPressed: () => onToolSelected(ToolType.perpendicular),
      ),
      _ToolButton(
        type: ToolType.intersection,
        icon: Icons.close,
        tooltip: 'Intersection',
        isActive: toolManager.activeToolType == ToolType.intersection,
        onPressed: () => onToolSelected(ToolType.intersection),
      ),
    ];

    return direction == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: tools,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: tools,
          );
  }
}

class _ToolButton extends StatelessWidget {
  final ToolType type;
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.type,
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: IconButton(
          icon: Icon(icon),
          color: isActive ? Colors.blue : Colors.grey[700],
          onPressed: onPressed,
        ),
      ),
    );
  }
}
