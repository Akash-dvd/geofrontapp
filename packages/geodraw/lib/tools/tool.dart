import 'package:flutter/material.dart';
import '../models/geometry_object.dart';

/// Types of available construction tools
enum ToolType {
  select,
  pan,
  point,
  lineSegment,
  line,
  circle,
  circleThreePoints,
  arcThreePoints,
  midpoint,
  perpendicular,
  parallel,
  perpBisector,
  tangent,
  intersection,
  text,
}

/// Abstract base class for all construction tools
abstract class Tool {
  /// Type of this tool
  ToolType get type;

  /// Display name of the tool
  String get name;

  /// Icon for the tool
  IconData get icon;

  /// Tooltip description
  String get tooltip;

  /// Handle pointer/touch input
  void handleInput(PointerEvent event);

  /// Reset tool state
  void reset();

  /// Check if tool operation is complete
  bool get isComplete;

  /// Get the current state description
  String get stateDescription;
}

/// Callback types for tool events
typedef OnObjectCreated =
    void Function(GeometryObject object, List<String> dependencies);
typedef OnObjectSelected = void Function(String objectId);
typedef OnToolStateChanged = void Function(String state);

/// Base implementation with common functionality
abstract class BaseTool implements Tool {
  final OnObjectCreated? onObjectCreated;
  final OnObjectSelected? onObjectSelected;
  final OnToolStateChanged? onToolStateChanged;

  BaseTool({
    this.onObjectCreated,
    this.onObjectSelected,
    this.onToolStateChanged,
  });

  /// Notify that tool state changed
  void notifyStateChanged(String state) {
    onToolStateChanged?.call(state);
  }

  /// Notify that an object was created
  void notifyObjectCreated(GeometryObject object, List<String> dependencies) {
    onObjectCreated?.call(object, dependencies);
  }

  /// Notify that an object was selected
  void notifyObjectSelected(String objectId) {
    onObjectSelected?.call(objectId);
  }
}
