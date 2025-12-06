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
  polyArc,
  polygon,
  polyLine,
  polyArcGon,
  midpoint,
  center,
  perpendicular,
  parallel,
  perpBisector,
  angleBisector,
  tangent,
  intersection,
  text,
  reflectLine,
  reflectPoint,
  reflectCircle,
  rotate,
  translate,
  dilate,
  // L3 Flexible commands
  circleFlex,
  circle3Flex,
  lineFlex,
  perpbisectorFlex,
  perpendicularFlex,
  parallelFlex,
  // Triangle construction tools
  incircle,
  excircle,
  orthocenter,
  tangents,
  polar,
  alcbc,
  // Imaginary circle
  icircle,
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

/// Callback types used by tools for event notifications.
///
/// These callbacks are part of the Tool class hierarchy and are used
/// throughout the tool system to notify listeners about tool-related events.
/// They are defined here (adjacent to Tool class) to maintain clear ownership
/// and cohesive structure.
///
/// Callback invoked when a geometry object is created by a tool.
typedef OnObjectCreated = void Function(
  GeometryObject object,
  List<String> dependencies,
);

/// Callback invoked when an object is selected by a tool.
typedef OnObjectSelected = void Function(String objectId);

/// Callback invoked when the tool's state changes.
typedef OnToolStateChanged = void Function(String state);

/// Mixin that provides callback properties and helper methods.
///
/// Use this mixin in classes that need to handle tool callbacks:
/// - [UnifiedTool] and its subclasses
/// - [StagedSelectionTool] and its subclasses
/// - [IncrementalUnionTool] and its subclasses
/// - [ToolManager]
///
/// This eliminates code duplication and ensures consistent callback handling.
mixin ToolCallbacksMixin {
  /// Callback for object creation events
  OnObjectCreated? onObjectCreated;

  /// Callback for object selection events
  OnObjectSelected? onObjectSelected;

  /// Callback for tool state change events
  OnToolStateChanged? onToolStateChanged;

  /// Helper method to notify about object creation.
  void notifyObjectCreated(GeometryObject object, List<String> dependencies) {
    onObjectCreated?.call(object, dependencies);
  }

  /// Helper method to notify about object selection.
  void notifyObjectSelected(String objectId) {
    onObjectSelected?.call(objectId);
  }

  /// Helper method to notify about state changes.
  void notifyStateChanged(String state) {
    onToolStateChanged?.call(state);
  }
}

// /// Base implementation with common functionality
// abstract class BaseTool implements Tool {
//   final OnObjectCreated? onObjectCreated;
//   final OnObjectSelected? onObjectSelected;
//   final OnToolStateChanged? onToolStateChanged;

//   BaseTool({
//     this.onObjectCreated,
//     this.onObjectSelected,
//     this.onToolStateChanged,
//   });

//   /// Notify that tool state changed
//   void notifyStateChanged(String state) {
//     onToolStateChanged?.call(state);
//   }

//   /// Notify that an object was created
//   void notifyObjectCreated(GeometryObject object, List<String> dependencies) {
//     onObjectCreated?.call(object, dependencies);
//   }

//   /// Notify that an object was selected
//   void notifyObjectSelected(String objectId) {
//     onObjectSelected?.call(objectId);
//   }
// }
