import 'package:flutter/material.dart';
import 'tool.dart';
import 'point_tool.dart';
import 'line_tool.dart';
import 'circle_tool.dart';
import '../dag/dag_manager.dart';

/// Manages the active tool and tool state
class ToolManager {
  final DAGManager dagManager;
  
  ToolType _activeToolType = ToolType.select;
  Tool? _activeTool;
  
  final OnObjectCreated? onObjectCreated;
  final OnObjectSelected? onObjectSelected;
  final OnToolStateChanged? onToolStateChanged;

  ToolManager({
    required this.dagManager,
    this.onObjectCreated,
    this.onObjectSelected,
    this.onToolStateChanged,
  });

  /// Get the currently active tool type
  ToolType get activeToolType => _activeToolType;

  /// Get the currently active tool instance
  Tool? get activeTool => _activeTool;

  /// Select a tool by type
  void selectTool(ToolType type) {
    // Reset current tool before switching
    _activeTool?.reset();
    
    _activeToolType = type;
    _activeTool = _createTool(type);
    
    onToolStateChanged?.call(_activeTool?.stateDescription ?? 'No tool selected');
  }

  /// Handle pointer input
  void handleInput(PointerEvent event) {
    _activeTool?.handleInput(event);
  }

  /// Reset the active tool
  void resetTool() {
    _activeTool?.reset();
  }

  /// Create a tool instance by type
  Tool? _createTool(ToolType type) {
    switch (type) {
      case ToolType.point:
        return PointTool(
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
        );
        
      case ToolType.line:
        return LineTool(
          dagManager: dagManager,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
        );
        
      case ToolType.circle:
        return CircleTool(
          dagManager: dagManager,
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
        );
        
      case ToolType.select:
      case ToolType.pan:
        // These tools don't create geometry
        return null;
        
      default:
        // Other tools not yet implemented
        return null;
    }
  }

  /// Get list of all available tools
  List<ToolType> get availableTools => [
    ToolType.select,
    ToolType.pan,
    ToolType.point,
    ToolType.line,
    ToolType.circle,
  ];

  /// Check if a tool type is available
  bool isToolAvailable(ToolType type) {
    return availableTools.contains(type);
  }

  /// Get tool metadata
  ToolMetadata getToolMetadata(ToolType type) {
    switch (type) {
      case ToolType.select:
        return const ToolMetadata(
          name: 'Select',
          icon: Icons.touch_app,
          tooltip: 'Select and move objects',
        );
      case ToolType.pan:
        return const ToolMetadata(
          name: 'Pan',
          icon: Icons.pan_tool,
          tooltip: 'Pan the canvas',
        );
      case ToolType.point:
        return const ToolMetadata(
          name: 'Point',
          icon: Icons.circle,
          tooltip: 'Create a free point',
        );
      case ToolType.line:
        return const ToolMetadata(
          name: 'Line',
          icon: Icons.horizontal_rule,
          tooltip: 'Create a line through two points',
        );
      case ToolType.circle:
        return const ToolMetadata(
          name: 'Circle',
          icon: Icons.circle_outlined,
          tooltip: 'Create a circle',
        );
      default:
        return const ToolMetadata(
          name: 'Unknown',
          icon: Icons.help_outline,
          tooltip: 'Not implemented',
        );
    }
  }
}

/// Tool metadata for UI display
class ToolMetadata {
  final String name;
  final IconData icon;
  final String tooltip;

  const ToolMetadata({
    required this.name,
    required this.icon,
    required this.tooltip,
  });
}
