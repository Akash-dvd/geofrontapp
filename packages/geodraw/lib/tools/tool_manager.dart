import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'tool.dart';
import 'tool_registry.dart';
import 'tool_catalog.dart';
import 'unified_tool.dart';
import 'incremental_union_tool.dart';
import 'staged_selection_tool.dart';
import '../core/command/command_history.dart';
import '../core/dag/dag_manager.dart';
import '../core/label_manager.dart';
import '../models/complex/geo_shapes.dart';
import '../models/complex/geo_shapes_list.dart';
import '../models/geometry_object.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_circle.dart';
import 'package:geocalc/Multivector.dart' show 
    Multivector,
    getCircleCenter,
    constructFreePoint,
    projectPointToLine,
    projectPointToCircle,
    projectPointToSegment,
    projectPointToArc,
    distancePointToPoint;

/// Data class for temporary polygon construction preview
class TemporaryPolygonData {
  final List<GeoPoint> points;
  final int lightSegmentIndex; // Index of the segment that should be drawn light/thin (-1 if none)
  
  TemporaryPolygonData({
    required this.points,
    this.lightSegmentIndex = -1,
  });
}

/// Data class for temporary polyarcgon construction preview
class TemporaryPolyArcGonData {
  final List<GeoPoint> points;
  final int lightArcIndex; // Index of the arc that should be drawn light/thin (-1 if none)
  
  TemporaryPolyArcGonData({
    required this.points,
    this.lightArcIndex = -1,
  });
  
  /// Get the arcs that can be formed from the current points
  /// Pattern: 
  /// - First arc: p1, p2, p3
  /// - Subsequent arcs: last point of previous arc + 2 new points (p3,p4,p5), (p5,p6,p7), etc.)
  /// - Closing arc: (second_to_last, last, p1) - created when p1 is added to even number of points
  List<List<GeoPoint>> get arcTriples {
    final triples = <List<GeoPoint>>[];
    
    // First arc: points 0, 1, 2 (p1, p2, p3)
    if (points.length >= 3) {
      triples.add([points[0], points[1], points[2]]);
    }
    
    // Subsequent arcs: each uses last point of previous arc + 2 new points
    // Arc 2: points[2], points[3], points[4] (p3, p4, p5)
    // Arc 3: points[4], points[5], points[6] (p5, p6, p7)
    // etc.
    // We need at least 5 points for second arc, 7 for third, etc.
    for (var i = 2; i <= points.length - 3; i += 2) {
      if (i + 2 < points.length) {
        triples.add([points[i], points[i + 1], points[i + 2]]);
      }
    }
    
    // No closing arc preview - closing requires adding p1 when we have even number of points
    // The closing arc will be: (second_to_last, last, p1)
    
    return triples;
  }
}

/// Manages the active tool and tool state
class ToolManager with ToolCallbacksMixin {
  final DAGManager dagManager;
  final CommandHistory? commandHistory;

  ToolType _activeToolType = ToolType.select;
  Tool? _activeTool;

  final OnParameterRequest? onParameterRequest;

  ToolManager({
    required this.dagManager,
    this.commandHistory,
    OnObjectCreated? onObjectCreated,
    OnObjectSelected? onObjectSelected,
    OnToolStateChanged? onToolStateChanged,
    this.onParameterRequest,
  }) {
    this.onObjectCreated = onObjectCreated;
    this.onObjectSelected = onObjectSelected;
    this.onToolStateChanged = onToolStateChanged;
    _registerAllTools();
  }

  /// Get the currently active tool type
  ToolType get activeToolType => _activeToolType;

  /// Get the currently active tool instance
  Tool? get activeTool => _activeTool;
  
  /// Get temporary preview polygon if polygon tool is active
  GeoPolygon? getTemporaryPolygon() {
    if (_activeTool is _PolygonTool) {
      return (_activeTool as _PolygonTool).getTemporaryPolygon();
    }
    return null;
  }

  /// Get temporary polygon construction data (points and light segment index) if polygon tool is active
  TemporaryPolygonData? getTemporaryPolygonData() {
    if (_activeTool is _PolygonTool) {
      return (_activeTool as _PolygonTool).getTemporaryPolygonData();
    }
    return null;
  }

  /// Get temporary polyarcgon construction data (points and light arc index) if polyarcgon tool is active
  TemporaryPolyArcGonData? getTemporaryPolyArcGonData() {
    if (_activeTool is _PolyArcGonTool) {
      return (_activeTool as _PolyArcGonTool).getTemporaryPolyArcGonData();
    }
    return null;
  }

  /// Select a tool by type
  void selectTool(ToolType type) {
    // Reset current tool before switching
    _activeTool?.reset();

    _activeToolType = type;
    _activeTool = _createTool(type);

    notifyStateChanged(
      _activeTool?.stateDescription ?? 'No tool selected',
    );
  }

  /// Handle pointer input
  void handleInput(PointerEvent event) {
    _activeTool?.handleInput(event);
  }

  /// Select an object directly (used when object is selected from menu/dropdown)
  /// This bypasses proximity search and directly adds the object as an argument
  /// [clickPosition] is optional and used for tools that need the click position (e.g., glider points)
  void selectObject(GeometryObject object, {Offset? clickPosition}) {
    if (_activeTool is UnifiedTool) {
      (_activeTool as UnifiedTool).selectObject(object, clickPosition: clickPosition);
    } else if (_activeTool is StagedSelectionTool) {
      (_activeTool as StagedSelectionTool).selectObject(object);
    } else if (_activeTool is _PolygonTool) {
      (_activeTool as _PolygonTool).selectObject(object);
    } else if (_activeTool is _PolyArcGonTool) {
      (_activeTool as _PolyArcGonTool).selectObject(object);
    } else if (_activeTool is IncrementalUnionTool) {
      (_activeTool as IncrementalUnionTool).selectObject(object);
    } else if (_activeTool is _UnionTool) {
      (_activeTool as _UnionTool).selectObject(object);
    }
  }

  /// Reset the active tool
  void resetTool() {
    _activeTool?.reset();
  }

  /// Create a tool instance using the registry
  Tool? _createTool(ToolType type) {
    final context = ToolFactoryContext(
          dagManager: dagManager,
      commandHistory: commandHistory, // Optional: only for CLI/AI logging, not core functionality
          onObjectCreated: onObjectCreated,
          onObjectSelected: onObjectSelected,
          onToolStateChanged: onToolStateChanged,
      createFreePoint: _createFreePoint,
      onParameterRequest: onParameterRequest,
    );

    return ToolRegistry().createTool(type, context);
  }

  /// Register all tools with the registry
  void _registerAllTools() {
    final registry = ToolRegistry();

    // Point tool
    registry.registerFromManager(
      ToolType.point,
      (context) => _PointTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
      ),
      const ToolCatalogEntry(
        id: 'point',
        label: 'Point',
        icon: Icons.gps_fixed,
        assetIcon: 'assets/tool_icons/point.svg',
        command: 'Point[]',
        toolType: ToolType.point,
        implemented: true,
      ),
    );

    // Segment tool
    registry.registerFromManager(
      ToolType.lineSegment,
      (context) => _SegmentTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'segment',
        label: 'Segment',
        icon: Icons.show_chart,
        assetIcon: 'assets/tool_icons/segment.svg',
        command: 'Segment[]',
        toolType: ToolType.lineSegment,
        implemented: true,
      ),
    );

    // Line tool
    registry.registerFromManager(
      ToolType.line,
      (context) => _LineTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'line',
        label: 'Line',
        icon: Icons.horizontal_rule,
        assetIcon: 'assets/tool_icons/line.svg',
        command: 'Line[]',
        toolType: ToolType.line,
        implemented: true,
      ),
    );

    // Circle tool
    registry.registerFromManager(
      ToolType.circle,
      (context) => _CircleTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'circle_center',
        label: 'Circle (Center)',
        icon: Icons.circle_outlined,
        assetIcon: 'assets/tool_icons/circle2.svg',
        command: 'Circle[]',
        toolType: ToolType.circle,
        implemented: true,
      ),
    );

    // Circle Three Points tool
    registry.registerFromManager(
      ToolType.circleThreePoints,
      (context) => _CircleThreePointsTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'circle_three_points',
        label: 'Circle (3 Points)',
        icon: Icons.circle,
        assetIcon: 'assets/tool_icons/circle3.svg',
        command: 'Circle3[]',
        toolType: ToolType.circleThreePoints,
        implemented: true,
      ),
    );

    // Arc Three Points tool
    registry.registerFromManager(
      ToolType.arcThreePoints,
      (context) => _ArcThreePointsTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'circular_arc',
        label: 'Arc (3 Points)',
        icon: Icons.panorama_fish_eye,
        assetIcon: 'assets/tool_icons/arc.svg',
        command: 'Arc3[]',
        toolType: ToolType.arcThreePoints,
        implemented: true,
      ),
    );

    // PolyArc tool
    registry.registerFromManager(
      ToolType.polyArc,
      (context) => _PolyArcTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'poly_arc',
        label: 'Poly-Arc',
        icon: Icons.architecture,
        command: 'PolyArc[]',
        toolType: ToolType.polyArc,
        implemented: true,
      ),
    );

    // Polygon tool
    registry.registerFromManager(
      ToolType.polygon,
      (context) => _PolygonTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'polygon',
        label: 'Polygon',
        icon: Icons.change_history,
        assetIcon: 'assets/tool_icons/polygon.svg',
        command: 'Polygon[]',
        toolType: ToolType.polygon,
        implemented: true,
      ),
    );

    // PolyLine tool
    registry.registerFromManager(
      ToolType.polyLine,
      (context) => _PolyLineTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'poly_line',
        label: 'PolyLine',
        icon: Icons.show_chart,
        command: 'PolyLine[]',
        toolType: ToolType.polyLine,
        implemented: true,
      ),
    );

    // PolyArcGon tool
    registry.registerFromManager(
      ToolType.polyArcGon,
      (context) => _PolyArcGonTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'poly_arc_gon',
        label: 'Poly-Arc-Gon',
        icon: Icons.all_inclusive,
        command: 'PolyArcGon[]',
        toolType: ToolType.polyArcGon,
        implemented: true,
      ),
    );

    // Midpoint tool
    registry.registerFromManager(
      ToolType.midpoint,
      (context) => _MidpointTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'midpoint',
        label: 'Midpoint',
        icon: Icons.adjust,
        assetIcon: 'assets/tool_icons/midpoint.svg',
        command: 'Midpoint[]',
        toolType: ToolType.midpoint,
        implemented: true,
      ),
    );

    // Center tool
    registry.registerFromManager(
      ToolType.center,
      (context) => _CenterTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
      ),
      const ToolCatalogEntry(
        id: 'center',
        label: 'Center',
        icon: Icons.center_focus_strong,
        assetIcon: 'assets/tool_icons/center.svg',
        command: 'Center[]',
        toolType: ToolType.center,
        implemented: true,
      ),
    );

    // Perpendicular tool
    registry.registerFromManager(
      ToolType.perpendicular,
      (context) => _PerpendicularTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'perpendicular',
        label: 'Perpendicular',
        icon: Icons.rotate_90_degrees_ccw,
        assetIcon: 'assets/tool_icons/perpendicularline.svg',
        command: 'Perpendicular[]',
        toolType: ToolType.perpendicular,
        implemented: true,
      ),
    );

    // Parallel tool
    registry.registerFromManager(
      ToolType.parallel,
      (context) => _ParallelTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'parallel',
        label: 'Parallel',
        icon: Icons.swap_calls,
        assetIcon: 'assets/tool_icons/parallel_line.svg',
        command: 'Parallel[]',
        toolType: ToolType.parallel,
        implemented: true,
      ),
    );

    // Perpendicular Bisector tool
    registry.registerFromManager(
      ToolType.perpBisector,
      (context) => _PerpBisectorTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'perp_bisector',
        label: 'Perp. Bisector',
        icon: Icons.straighten,
        assetIcon: 'assets/tool_icons/perpendicularbisector.svg',
        command: 'PerpBisector[]',
        toolType: ToolType.perpBisector,
        implemented: true,
      ),
    );

    // Angle Bisector tool
    registry.registerFromManager(
      ToolType.angleBisector,
      (context) => _AngleBisectorTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'angle_bisector',
        label: 'Angle Bisector',
        icon: Icons.call_split,
        assetIcon: 'assets/tool_icons/angle_Bisector.svg',
        command: 'AngleBisector[]',
        toolType: ToolType.angleBisector,
        implemented: true,
      ),
    );

    // Tangent tool
    registry.registerFromManager(
      ToolType.tangent,
      (context) => _TangentTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'tangent',
        label: 'Tangent',
        icon: Icons.rotate_90_degrees_cw,
        assetIcon: 'assets/tool_icons/tangent_lines.svg',
        command: 'Tangent[]',
        toolType: ToolType.tangent,
        implemented: true,
      ),
    );

    // Intersection tool
    registry.registerFromManager(
      ToolType.intersection,
      (context) => _IntersectionTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'intersection',
        label: 'Intersection',
        icon: Icons.control_point,
        assetIcon: 'assets/tool_icons/intersection.svg',
        command: 'Intersect[]',
        toolType: ToolType.intersection,
        implemented: true,
      ),
    );

    // Reflect Line tool
    registry.registerFromManager(
      ToolType.reflectLine,
      (context) => _ReflectLineTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'reflect_line',
        label: 'Reflect Line',
        icon: Icons.flip,
        assetIcon: 'assets/tool_icons/invert_about_line.svg',
        command: 'Reflect[]',
        toolType: ToolType.reflectLine,
        implemented: true,
      ),
    );

    // Reflect Point tool
    registry.registerFromManager(
      ToolType.reflectPoint,
      (context) => _ReflectPointTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'reflect_point',
        label: 'Reflect Point',
        icon: Icons.flip_camera_android,
        assetIcon: 'assets/tool_icons/reflection_about_point.svg',
        command: 'Reflect[]',
        toolType: ToolType.reflectPoint,
        implemented: true,
      ),
    );

    // Reflect Circle tool
    registry.registerFromManager(
      ToolType.reflectCircle,
      (context) => _ReflectCircleTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'reflect_circle',
        label: 'Reflect Circle',
        icon: Icons.flip_camera_ios,
        assetIcon: 'assets/tool_icons/inversion.svg',
        command: 'Reflect[]',
        toolType: ToolType.reflectCircle,
        implemented: true,
      ),
    );

    // Rotate tool
    registry.registerFromManager(
      ToolType.rotate,
      (context) => _RotateTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'rotate',
        label: 'Rotate',
        icon: Icons.rotate_left,
        assetIcon: 'assets/tool_icons/rotate.svg',
        command: 'Rotate[]',
        toolType: ToolType.rotate,
        implemented: true,
      ),
    );

    // Translate tool
    registry.registerFromManager(
      ToolType.translate,
      (context) => _TranslateTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'translate',
        label: 'Translate',
        icon: Icons.open_in_full,
        command: 'Translate[]',
        toolType: ToolType.translate,
        implemented: true,
      ),
    );

    // Dilate tool
    registry.registerFromManager(
      ToolType.dilate,
      (context) => _DilateTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        onParameterRequest: context.onParameterRequest,
      ),
      const ToolCatalogEntry(
        id: 'dilate',
        label: 'Dilate',
        icon: Icons.center_focus_strong,
        assetIcon: 'assets/tool_icons/dilation.svg',
        command: 'Dilate[]',
        toolType: ToolType.dilate,
        implemented: true,
      ),
    );

    // Select and Pan tools (no geometry creation, but register metadata)
    registry.registerFromManager(
      ToolType.select,
      (context) => null,
      const ToolCatalogEntry(
        id: 'move',
        label: 'Move',
        icon: Icons.open_with,
        assetIcon: 'assets/tool_icons/move.svg',
        command: 'Move[]',
        toolType: ToolType.select,
        implemented: true,
      ),
    );

    registry.registerFromManager(
      ToolType.pan,
      (context) => null,
      const ToolCatalogEntry(
        id: 'pan',
        label: 'Pan',
        icon: Icons.pan_tool,
        assetIcon: 'assets/tool_icons/Standard View.svg',
        command: 'Pan[]',
        toolType: ToolType.pan,
        implemented: true,
      ),
    );

    // Delete tool
    registry.registerFromManager(
      ToolType.delete,
      (context) => _DeleteTool(
        dagManager: context.dagManager,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
      ),
      const ToolCatalogEntry(
        id: 'delete',
        label: 'Delete',
        icon: Icons.delete,
        assetIcon: 'assets/tool_icons/delete.svg',
        command: 'Delete[]',
        toolType: ToolType.delete,
        implemented: true,
      ),
    );

    // Union tool
    registry.registerFromManager(
      ToolType.union,
      (context) => _UnionTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
      ),
      const ToolCatalogEntry(
        id: 'union',
        label: 'Union',
        icon: Icons.merge_type,
        assetIcon: 'assets/tool_icons/point_on_object.svg',
        command: 'Union[]',
        toolType: ToolType.union,
        implemented: true,
      ),
    );

    // ========================================================================
    // L3 FLEXIBLE COMMANDS - Relaxed type constraints
    // ========================================================================

    // Circle Flex tool
    registry.registerFromManager(
      ToolType.circleFlex,
      (context) => _CircleFlexTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'circle_flex',
        label: 'Circle (Flex)',
        icon: Icons.circle_outlined,
        assetIcon: 'assets/tool_icons/circle2.svg',
        command: 'CircleFlex[]',
        toolType: ToolType.circleFlex,
        implemented: true,
      ),
    );

    // Geo 3 Flex tool
    registry.registerFromManager(
      ToolType.circle3Flex,
      (context) => _Geo3FlexTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'geo3_flex',
        label: 'Geo 3 (Flex)',
        icon: Icons.circle,
        assetIcon: 'assets/tool_icons/circle3.svg',
        command: 'Geo3Flex[]',
        toolType: ToolType.circle3Flex,
        implemented: true,
      ),
    );

    // Line Flex tool
    registry.registerFromManager(
      ToolType.lineFlex,
      (context) => _LineFlexTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'line_flex',
        label: 'Line (Flex)',
        icon: Icons.horizontal_rule,
        assetIcon: 'assets/tool_icons/line.svg',
        command: 'LineFlex[]',
        toolType: ToolType.lineFlex,
        implemented: true,
      ),
    );

    // Perpendicular Bisector Flex tool
    registry.registerFromManager(
      ToolType.perpbisectorFlex,
      (context) => _PerpBisectorFlexTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'perpbisector_flex',
        label: 'Perp. Bisector (Flex)',
        icon: Icons.straighten,
        assetIcon: 'assets/tool_icons/perpendicularbisector.svg',
        command: 'PerpBisectorFlex[]',
        toolType: ToolType.perpbisectorFlex,
        implemented: true,
      ),
    );

    // Perpendicular Flex tool
    registry.registerFromManager(
      ToolType.perpendicularFlex,
      (context) => _PerpendicularFlexTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'perpendicular_flex',
        label: 'Perpendicular (Flex)',
        icon: Icons.rotate_90_degrees_ccw,
        assetIcon: 'assets/tool_icons/perpendicularline.svg',
        command: 'PerpendicularFlex[]',
        toolType: ToolType.perpendicularFlex,
        implemented: true,
      ),
    );

    // ========================================================================
    // TRIANGLE CONSTRUCTION TOOLS
    // ========================================================================

    // Incircle tool
    registry.registerFromManager(
      ToolType.incircle,
      (context) => _IncircleTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'incircle',
        label: 'Incircle',
        icon: Icons.circle,
        assetIcon: 'assets/tool_icons/circle3.svg',
        command: 'incircle[]',
        toolType: ToolType.incircle,
        implemented: true,
      ),
    );

    // Excircle tool
    registry.registerFromManager(
      ToolType.excircle,
      (context) => _ExcircleTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'excircle',
        label: 'Excircle',
        icon: Icons.circle_outlined,
        assetIcon: 'assets/tool_icons/circle3.svg',
        command: 'excircle[]',
        toolType: ToolType.excircle,
        implemented: true,
      ),
    );

    // Orthocenter tool
    registry.registerFromManager(
      ToolType.orthocenter,
      (context) => _OrthocenterTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'orthocenter',
        label: 'Orthocenter',
        icon: Icons.center_focus_strong,
        assetIcon: 'assets/tool_icons/center.svg',
        command: 'orthocenter[]',
        toolType: ToolType.orthocenter,
        implemented: true,
      ),
    );

    // Tangents tool (different from tangent - this is the new constructTangents)
    registry.registerFromManager(
      ToolType.tangents,
      (context) => _TangentsTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'tangents',
        label: 'Tangents',
        icon: Icons.rotate_90_degrees_cw,
        assetIcon: 'assets/tool_icons/tangent_lines.svg',
        command: 'tangents[]',
        toolType: ToolType.tangents,
        implemented: true,
      ),
    );

    // Polar tool
    registry.registerFromManager(
      ToolType.polar,
      (context) => _PolarTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'polar',
        label: 'Polar',
        icon: Icons.straighten,
        assetIcon: 'assets/tool_icons/perpendicularbisector.svg',
        command: 'polar[]',
        toolType: ToolType.polar,
        implemented: true,
      ),
    );

    // aLCbc tool
    registry.registerFromManager(
      ToolType.alcbc,
      (context) => _AlcbcTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'alcbc',
        label: 'aLCbc',
        icon: Icons.code,
        command: 'alcbc[]',
        toolType: ToolType.alcbc,
        implemented: true,
      ),
    );

    // Imaginary Circle tool
    registry.registerFromManager(
      ToolType.icircle,
      (context) => _IcircleTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'icircle',
        label: 'Imaginary Circle',
        icon: Icons.circle_outlined,
        assetIcon: 'assets/tool_icons/circle2.svg',
        command: 'icircle[]',
        toolType: ToolType.icircle,
        implemented: true,
      ),
    );

    // Parallel Flex tool
    registry.registerFromManager(
      ToolType.parallelFlex,
      (context) => _ParallelFlexTool(
        dagManager: context.dagManager,
        commandHistory: context.commandHistory,
        onObjectCreated: context.onObjectCreated,
        onObjectSelected: context.onObjectSelected,
        onToolStateChanged: context.onToolStateChanged,
        createFreePoint: context.createFreePoint!,
      ),
      const ToolCatalogEntry(
        id: 'parallel_flex',
        label: 'Parallel (Flex)',
        icon: Icons.swap_calls,
        assetIcon: 'assets/tool_icons/parallel_line.svg',
        command: 'ParallelFlex[]',
        toolType: ToolType.parallelFlex,
        implemented: true,
      ),
    );
  }

  GeoPointer _createFreePoint(Offset position) {
    // Use LabelManager to get unique label that checks global namespace
    // This ensures free points created during polygon/polyline creation
    // are aware of intersection points and other existing labels
    final label = LabelManager.getNextAvailableLabel(
      dagManager,
      GeometryObjectType.point,
    );
    
    final point = GeoPointer(
      id: label, // In new system: ID = label
      label: label,
      x: position.dx,
      y: position.dy,
    );

    dagManager.addObject(point, const <String>[]);
    notifyObjectCreated(point, const <String>[]);
    return point;
  }

  /// Get list of all available tools from registry
  List<ToolType> get availableTools => ToolRegistry().availableTools;

  /// Check if a tool type is available
  bool isToolAvailable(ToolType type) {
    return ToolRegistry().isToolAvailable(type);
  }
}

// ============================================================================
// Inline Tool Implementations (merged from unified_*_tool.dart files)
// ============================================================================

/// Point tool - creates points immediately on click or glider points on objects
class _PointTool extends UnifiedTool {
  _PointTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
  });

  // Store the last click position for glider point creation
  Offset? _lastClickPosition;

  @override
  ToolType get type => ToolType.point;

  @override
  String get commandName => 'point';

  @override
  String get name => 'Point';

  @override
  IconData get icon => Icons.circle;

  @override
  String get tooltip => 'Create a free point or glider point on an object';

  @override
  void handleInput(PointerEvent event) {
    if (event is PointerDownEvent) {
      // Store click position for potential glider point creation
      _lastClickPosition = event.position;
      
      // Check for nearby objects that could be used for glider points
      final nearby = dagManager.proximitySearch(event.position, threshold: 15.0);
      
      // Check if any nearby object matches the glider point pattern (Pattern 1)
      // Pattern 1 accepts: GeoLine, GeoCircle, GeoSegment, GeoArc (but NOT UnionGeometryObjectList)
      final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
      if (nextConstraint != null) {
        for (final obj in nearby) {
          // Skip union objects - they need special handling via dropdown
          if (obj is UnionGeometryObjectList) {
            continue;
          }
          if (nextConstraint.accepts(obj)) {
            // Found a valid object for glider point - use selectObject instead
            selectObject(obj, clickPosition: event.position);
            return;
          }
        }
      }
      
      // No valid object found - create a free point
      _createPointAt(event.position);
    }
  }

  @override
  void selectObject(GeometryObject object, {Offset? clickPosition}) {
    // Glider points are not supported on union objects
    if (object is UnionGeometryObjectList) {
      notifyStateChanged('Error: Glider points are not supported on union objects. Please select a child element (line, segment, arc, etc.)');
      return;
    }
    
    // Check if this is for a glider point (Pattern 1)
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint != null && nextConstraint.accepts(object)) {
      // This is a glider point creation - use the provided click position or stored one
      final positionToUse = clickPosition ?? _lastClickPosition;
      if (positionToUse != null) {
        _createGliderPointAtPosition(object, positionToUse);
        _lastClickPosition = null; // Clear after use
        return;
      }
    }
    
    // Use base class implementation which will validate against schema
    // The point command has Pattern 1 that accepts GeoLine, GeoCircle, GeoSegment, GeoArc, etc.
    // This will automatically route to the glider point pattern
    super.selectObject(object, clickPosition: clickPosition);
  }
  
  Future<void> _createGliderPointAtPosition(GeometryObject object, Offset clickPosition) async {
    try {
      // Glider points are not supported on union objects
      if (object is UnionGeometryObjectList) {
        notifyStateChanged('Error: Glider points are not supported on union objects. Please select a child element.');
        return;
      }
      
      // Project the click position onto the object to get the initial position
      final clickPoint = constructFreePoint(clickPosition.dx, clickPosition.dy);
      Multivector? projectedMultivector;
      Offset initialPosition;
      
      if (object is GeoLine) {
        projectedMultivector = projectPointToLine(clickPoint, object.multivector);
        initialPosition = Offset(projectedMultivector.e1, projectedMultivector.e2);
      } else if (object is GeoCircle) {
        projectedMultivector = projectPointToCircle(clickPoint, object.multivector);
        initialPosition = Offset(projectedMultivector.e1, projectedMultivector.e2);
      } else if (object is GeoSegment) {
        projectedMultivector = projectPointToSegment(clickPoint, object.boundary.boundary);
        initialPosition = Offset(projectedMultivector.e1, projectedMultivector.e2);
      } else if (object is GeoArc) {
        final counterClockwise = object.boundary.multivector.o >= 0;
        projectedMultivector = projectPointToArc(
          clickPoint,
          object.boundary.multivector,
          object.startPoint.multivector,
          object.endPoint.multivector,
          counterClockwise,
        );
        if (projectedMultivector == null) {
          notifyStateChanged('Error: Could not project point onto arc');
          return;
        }
        initialPosition = Offset(projectedMultivector.e1, projectedMultivector.e2);
      } else {
        // Fallback to click position
        projectedMultivector = clickPoint;
        initialPosition = clickPosition;
      }
      
      final label = LabelManager.getNextAvailableLabel(
        dagManager,
        GeometryObjectType.point,
      );
      
      // Use withMultivector constructor to set the correct projected multivector
      final gliderPoint = GeoGliderPoint.withMultivector(
        id: label,
        label: label,
        objectId: object.id,
        initialX: initialPosition.dx,
        initialY: initialPosition.dy,
        multivector: projectedMultivector,
      );
      
      dagManager.addObject(gliderPoint, [object.id]);
      onObjectCreated?.call(gliderPoint, gliderPoint.dependencies);
      notifyStateChanged('Created glider point ${gliderPoint.label} on ${object.runtimeType}');
    } catch (e) {
      notifyStateChanged('Error: $e');
    }
  }
  
  // Helper function to project a point onto a union object
  Multivector? _projectPointToUnion(Multivector point, UnionGeometryObjectList union) {
    Multivector? bestProjection;
    double bestDistance = double.infinity;

    for (final element in union.elements) {
      Multivector? projection;
      
      if (element is GeoLine) {
        projection = projectPointToLine(point, element.multivector);
      } else if (element is GeoCircle) {
        projection = projectPointToCircle(point, element.multivector);
      } else if (element is GeoSegment) {
        projection = projectPointToSegment(point, element.boundary.boundary);
      } else if (element is GeoArc) {
        final counterClockwise = element.boundary.multivector.o >= 0;
        projection = projectPointToArc(
          point,
          element.boundary.multivector,
          element.startPoint.multivector,
          element.endPoint.multivector,
          counterClockwise,
        );
      }

      if (projection != null) {
        final dist = distancePointToPoint(point, projection);
        if (dist < bestDistance) {
          bestDistance = dist;
          bestProjection = projection;
        }
      }
    }

    return bestProjection;
  }

  Future<void> _createPointAt(Offset position) async {
    try {
      // Use LabelManager to get unique label that checks global namespace
      // This ensures points are aware of intersection points and other existing labels
      final label = LabelManager.getNextAvailableLabel(
        dagManager,
        GeometryObjectType.point,
      );
      final result = await executor.execute(
        commandName: commandName,
        arguments: [position.dx, position.dy],
        customLabel: label,
      );

      if (result.success && result.object is GeometryObject) {
        final geometry = result.object as GeometryObject;
        onObjectCreated?.call(geometry, geometry.dependencies);
        notifyStateChanged(result.message);
      } else {
        notifyStateChanged('Error: ${result.message}');
      }
    } catch (e) {
      notifyStateChanged('Error: $e');
    }
  }

  @override
  GeometryObject? createObjectAtPosition(Offset position) => null;

  @override
  void reset() {
    notifyStateChanged('Click to create a point, or click on a line/circle/arc/segment to create a glider point');
  }

  @override
  bool get isComplete => true;

  @override
  String get stateDescription => 'Click to create a point, or click on a line/circle/arc/segment to create a glider point';
}

/// Segment tool - creates segments between two points
class _SegmentTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _SegmentTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.lineSegment;

  @override
  String get commandName => 'segment';

  @override
  String get name => 'Segment';

  @override
  IconData get icon => Icons.show_chart;

  @override
  String get tooltip => 'Create a segment between two points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Click first point for segment');
  }
}

/// Line tool - creates lines through two points
class _LineTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _LineTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.line;

  @override
  String get commandName => 'line';

  @override
  String get name => 'Line';

  @override
  IconData get icon => Icons.horizontal_rule;

  @override
  String get tooltip => 'Create a line through two points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Click first point for line');
  }
}

/// Circle tool - creates circles with center and point
class _CircleTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _CircleTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.circle;

  @override
  String get commandName => 'circle';

  @override
  String get name => 'Circle';

  @override
  IconData get icon => Icons.circle_outlined;

  @override
  String get tooltip => 'Create a circle with center and point';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Click center point for circle');
  }
}

/// Circle through three points tool
class _CircleThreePointsTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _CircleThreePointsTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.circleThreePoints;

  @override
  String get commandName => 'circle3';

  @override
  String get name => 'Circle (3 Points)';

  @override
  IconData get icon => Icons.circle;

  @override
  String get tooltip => 'Create a circle through three points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select three points for circle');
  }
}

/// Arc through three points tool
class _ArcThreePointsTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _ArcThreePointsTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.arcThreePoints;

  @override
  String get commandName => 'arc3';

  @override
  String get name => 'Arc (3 Points)';

  @override
  IconData get icon => Icons.panorama_fish_eye;

  @override
  String get tooltip => 'Create a circular arc through three points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select three points for arc');
  }
}

/// Poly-arc tool - incrementally builds chained arcs via point selection
class _PolyArcTool extends IncrementalUnionTool<GeoPolyArc> {
  _PolyArcTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  final GeoPointer Function(Offset position) createFreePoint;

  @override
  ToolType get type => ToolType.polyArc;

  @override
  String get name => 'Poly-Arc';

  @override
  IconData get icon => Icons.architecture;

  @override
  String get tooltip => 'Build a chain of arcs incrementally';

  @override
  String get createCommandName => 'polyArc';

  @override
  String? get extendCommandName => 'extendPolyArc';

  @override
  String get creatingMessage => 'Creating poly-arc...';

  @override
  String get extendingMessage => 'Extending poly-arc...';

  @override
  String creationSuccessMessage(GeoPolyArc object) =>
      'Poly-arc created. Select two more points to extend';

  @override
  String extensionSuccessMessage(GeoPolyArc object) =>
      'Poly-arc extended. Select two more points to continue';

  @override
  String formatCreationFailure(String reason) =>
      'Unable to create poly-arc: $reason';

  @override
  String formatExtensionFailure(String reason) =>
      'Unable to extend poly-arc: $reason';

  @override
  String get unresolvedInputMessage =>
      'Unable to resolve a point at that location';

  @override
  bool isInitialInputComplete(List<dynamic> inputs) =>
      inputs.length >= 3 && inputs.length.isOdd;

  @override
  int extensionBatchSize(GeoPolyArc object) => 2;

  @override
  List<dynamic> buildCreateArguments(List<dynamic> inputs) =>
      List<dynamic>.from(inputs);

  @override
  List<dynamic> buildExtendArguments(
    GeoPolyArc object,
    List<dynamic> newInputs,
  ) {
    if (newInputs.length < 2) {
      return <dynamic>[object];
    }
    return <dynamic>[object, newInputs[newInputs.length - 2], newInputs.last];
  }

  @override
  List<dynamic>? resolveDependencies(List<String> dependencyIds) {
    final resolved = <GeoPoint>[];
    for (final id in dependencyIds) {
      final candidate = dagManager.getObject(id);
      if (candidate is GeoPoint) {
        resolved.add(candidate);
        continue;
      }
      return null;
    }
    return resolved;
  }

  @override
  dynamic resolveInput(Offset position) {
    final nearby = dagManager.proximitySearch(
      position,
      threshold: selectionThreshold,
    );
    for (final candidate in nearby) {
      if (candidate is GeoPoint) {
        return candidate;
      }
    }
    return createFreePoint(position);
  }

  @override
  String initialPrompt(int inputCount) {
    switch (inputCount) {
      case 0:
        return 'Select first point for poly-arc';
      case 1:
        return 'Select second point for poly-arc';
      case 2:
        return 'Select third point to complete first arc';
      default:
        return 'Select points for poly-arc';
    }
  }

  @override
  String extensionPrompt(int newInputCount) {
    if (newInputCount <= 0) {
      return 'Select control point to extend poly-arc';
    }
    if (newInputCount == 1) {
      return 'Select end point to complete the new arc';
    }
    return 'Select control point to extend poly-arc';
  }

  @override
  String? validateNextInput(List<dynamic> currentInputs, dynamic candidate) {
    if (candidate is! GeoPoint) {
      return 'Select a point to continue';
    }
    if (currentInputs.isNotEmpty) {
      final last = currentInputs.last;
      if (last is GeoPoint && last.id == candidate.id) {
        return 'Select a distinct point to continue';
      }
    }
    return null;
  }
}

/// Polygon tool - incrementally builds polygon via point selection
/// During construction, creates a polyline. When first point is selected again, completes the polygon.
class _PolygonTool extends Tool {
  _PolygonTool({
    required this.dagManager,
    this.commandHistory,
    this.onObjectCreated,
    this.onObjectSelected,
    this.onToolStateChanged,
    required this.createFreePoint,
  });

  final DAGManager dagManager;
  final CommandHistory? commandHistory;
  final OnObjectCreated? onObjectCreated;
  final OnObjectSelected? onObjectSelected;
  final OnToolStateChanged? onToolStateChanged;
  final GeoPointer Function(Offset position) createFreePoint;
  
  GeoPoint? _firstPoint;
  final List<GeoPoint> _trackedInputs = [];

  @override
  ToolType get type => ToolType.polygon;

  @override
  String get name => 'Polygon';

  @override
  IconData get icon => Icons.change_history;

  @override
  String get tooltip => 'Build a polygon incrementally';

  @override
  bool get isComplete => false; // Polygon tool is never "complete" until reset

  @override
  String get stateDescription {
    if (_trackedInputs.isEmpty) {
      return 'Select first vertex for polygon';
    } else if (_trackedInputs.length == 1) {
      return 'Select second vertex for polygon';
    } else {
      return 'Select vertices for polygon (${_trackedInputs.length} so far). Click first point to complete';
    }
  }

  static const double selectionThreshold = 10.0;

  dynamic resolveInput(Offset position) {
    final nearby = dagManager.proximitySearch(
      position,
      threshold: selectionThreshold,
    );
    for (final candidate in nearby) {
      if (candidate is GeoPoint) {
        return candidate;
      }
    }
    return createFreePoint(position);
  }

  String? _validateNextInput(GeoPoint candidate) {
    // Prevent selecting the same point twice in a row
    if (_trackedInputs.isNotEmpty) {
      if (_trackedInputs.last.id == candidate.id) {
        return 'Select a distinct point to continue';
      }
    }
    
    // Track first point on first input
    if (_trackedInputs.isEmpty) {
      _firstPoint = candidate;
      return null;
    }
    
    // Check if candidate is the first point (completion)
    if (_firstPoint != null && candidate.id == _firstPoint!.id) {
      // This is completion - will be handled in handleInput
      return null;
    }
    
    // Prevent reselecting interior points (p2, p3... pn-1)
    // Allow: p1 (to complete), pn (current end), or new point
    if (_trackedInputs.length >= 3) {
      // Check if this is an interior point (not first, not last)
      for (var i = 1; i < _trackedInputs.length - 1; i++) {
        if (_trackedInputs[i].id == candidate.id) {
          return 'Cannot reselect interior points. Select first point to complete, or add a new point';
        }
      }
    }
    
    return null;
  }

  /// Get temporary polygon for preview rendering (with colored interior)
  /// This should be called by the canvas to render the preview
  /// Returns null now - use getTemporaryPolygonData() instead
  GeoPolygon? getTemporaryPolygon() {
    return null; // No longer using polyline-based preview
  }

  /// Get temporary polygon construction data for preview rendering
  TemporaryPolygonData? getTemporaryPolygonData() {
    if (_trackedInputs.length < 2) return null;
    
    // Determine which segment should be light/thin
    // - If 2 points: no light segment (just one segment)
    // - If 3+ points: the closing segment (from last point back to first) should be light
    // Use points.length as the indicator for the closing segment
    int lightSegmentIndex = -1;
    if (_trackedInputs.length >= 3) {
      // The closing segment (from last point back to first) should be light
      lightSegmentIndex = _trackedInputs.length; // Use length to indicate closing segment
    }
    
    return TemporaryPolygonData(
      points: List<GeoPoint>.from(_trackedInputs),
      lightSegmentIndex: lightSegmentIndex,
    );
  }

  @override
  void handleInput(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }

    // Resolve input first
    dynamic candidate;
    try {
      candidate = resolveInput(event.position);
    } catch (error) {
      onToolStateChanged?.call('Unable to create polygon: $error');
      return;
    }

    if (candidate == null || candidate is! GeoPoint) {
      onToolStateChanged?.call('Unable to resolve a point at that location');
      return;
    }

    // Validate input
    final message = _validateNextInput(candidate);
    if (message != null) {
      onToolStateChanged?.call(message);
      return;
    }

    // Check if this is completion (selecting first point again)
    if (_trackedInputs.length >= 2 && 
        _firstPoint != null && 
        candidate.id == _firstPoint!.id) {
      // Complete the polygon
      _completePolygon();
      return;
    }

    // Add the point
    if (_trackedInputs.isEmpty) {
      _trackedInputs.add(candidate);
    } else {
      // Only add if it's not already the last point
      if (_trackedInputs.last.id != candidate.id) {
        _trackedInputs.add(candidate);
      }
    }

    // Notify state change
    onToolStateChanged?.call(stateDescription);
  }

  Future<void> _completePolygon() async {
    if (_trackedInputs.length < 3) {
      onToolStateChanged?.call('Polygon requires at least 3 vertices');
      return;
    }
    
    try {
      final label = LabelManager.getNextAvailableLabel(
        dagManager,
        GeometryObjectType.polygon,
      );
      
      // Create polygon from tracked points
      final polygonPoints = List<GeoPoint>.from(_trackedInputs);
      // Ensure it's closed (add first point at end)
      if (polygonPoints.first.id != polygonPoints.last.id) {
        polygonPoints.add(polygonPoints.first);
      }
      
      // Create polygon without existing element labels (since we're not using polyline)
      final polygon = GeoPolygon.fromDependencies(
        id: label,
        label: label,
        points: polygonPoints,
        dagManager: dagManager,
      );
      
      // Add the final polygon
      dagManager.addObject(polygon, polygon.dependencies);
      
      onObjectCreated?.call(polygon, polygon.dependencies);
      onToolStateChanged?.call('Polygon completed with ${polygon.vertexCount} vertices');
      
      // Reset state
      _firstPoint = null;
      _trackedInputs.clear();
      reset();
    } catch (e) {
      onToolStateChanged?.call('Failed to complete polygon: $e');
    }
  }

  /// Select an object directly (used when object is selected from menu/dropdown)
  /// This allows selecting pre-existing points for polygon construction
  void selectObject(GeometryObject object) {
    if (object is! GeoPoint) {
      onToolStateChanged?.call('Polygon tool requires point selection');
      return;
    }

    // Validate input
    final message = _validateNextInput(object);
    if (message != null) {
      onToolStateChanged?.call(message);
      return;
    }

    // Check if this is completion (selecting first point again)
    if (_trackedInputs.length >= 2 && 
        _firstPoint != null && 
        object.id == _firstPoint!.id) {
      // Complete the polygon
      _completePolygon();
      return;
    }

    // Add the point
    if (_trackedInputs.isEmpty) {
      _firstPoint = object;
      _trackedInputs.add(object);
    } else {
      // Only add if it's not already the last point
      if (_trackedInputs.last.id != object.id) {
        _trackedInputs.add(object);
      }
    }

    // Notify state change
    onToolStateChanged?.call(stateDescription);
  }

  @override
  void reset() {
    _firstPoint = null;
    _trackedInputs.clear();
  }
}

/// PolyLine tool - incrementally builds polyline via point selection
class _PolyLineTool extends IncrementalUnionTool<GeoPolyLine> {
  _PolyLineTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  final GeoPointer Function(Offset position) createFreePoint;

  @override
  ToolType get type => ToolType.polyLine;

  @override
  String get name => 'PolyLine';

  @override
  IconData get icon => Icons.show_chart;

  @override
  String get tooltip => 'Build a polyline incrementally';

  @override
  String get createCommandName => 'polyLine';

  @override
  String? get extendCommandName => 'extendPolyLine';

  @override
  String get creatingMessage => 'Creating polyline...';

  @override
  String get extendingMessage => 'Extending polyline...';

  @override
  String creationSuccessMessage(GeoPolyLine object) =>
      'Polyline created with ${object.vertexCount} points. Select another point to extend';

  @override
  String extensionSuccessMessage(GeoPolyLine object) =>
      'Polyline extended to ${object.vertexCount} points. Select another point to continue';

  @override
  String formatCreationFailure(String reason) =>
      'Unable to create polyline: $reason';

  @override
  String formatExtensionFailure(String reason) =>
      'Unable to extend polyline: $reason';

  @override
  String get unresolvedInputMessage =>
      'Unable to resolve a point at that location';

  @override
  bool isInitialInputComplete(List<dynamic> inputs) => inputs.length >= 2;

  @override
  int extensionBatchSize(GeoPolyLine object) => 1;

  @override
  List<dynamic> buildCreateArguments(List<dynamic> inputs) =>
      List<dynamic>.from(inputs);

  @override
  List<dynamic> buildExtendArguments(
    GeoPolyLine object,
    List<dynamic> newInputs,
  ) {
    if (newInputs.isEmpty) {
      return <dynamic>[object];
    }
    return <dynamic>[object, newInputs.last];
  }

  @override
  List<dynamic>? resolveDependencies(List<String> dependencyIds) {
    final resolved = <GeoPoint>[];
    for (final id in dependencyIds) {
      final candidate = dagManager.getObject(id);
      if (candidate is GeoPoint) {
        resolved.add(candidate);
        continue;
      }
      return null;
    }
    return resolved;
  }

  @override
  dynamic resolveInput(Offset position) {
    final nearby = dagManager.proximitySearch(
      position,
      threshold: selectionThreshold,
    );
    for (final candidate in nearby) {
      if (candidate is GeoPoint) {
        return candidate;
      }
    }
    return createFreePoint(position);
  }

  @override
  String initialPrompt(int inputCount) {
    switch (inputCount) {
      case 0:
        return 'Select start point for polyline';
      case 1:
        return 'Select second point to create polyline';
      default:
        return 'Select points for polyline ($inputCount so far)';
    }
  }

  @override
  String extensionPrompt(int newInputCount) {
    return 'Select another point to extend polyline';
  }

  @override
  String? validateNextInput(List<dynamic> currentInputs, dynamic candidate) {
    if (candidate is! GeoPoint) {
      return 'Select a point to continue';
    }
    if (currentInputs.isNotEmpty) {
      final last = currentInputs.last;
      if (last is GeoPoint && last.id == candidate.id) {
        return 'Select a distinct point to continue';
      }
    }
    return null;
  }
}

/// PolyArcGon tool - incrementally builds closed poly-arc via point selection
class _PolyArcGonTool extends Tool {
  _PolyArcGonTool({
    required this.dagManager,
    this.commandHistory,
    this.onObjectCreated,
    this.onObjectSelected,
    this.onToolStateChanged,
    required this.createFreePoint,
  });

  final DAGManager dagManager;
  final CommandHistory? commandHistory;
  final OnObjectCreated? onObjectCreated;
  final OnObjectSelected? onObjectSelected;
  final OnToolStateChanged? onToolStateChanged;
  final GeoPointer Function(Offset position) createFreePoint;
  
  GeoPoint? _firstPoint;
  final List<GeoPoint> _trackedInputs = [];

  @override
  ToolType get type => ToolType.polyArcGon;

  @override
  String get name => 'Poly-Arc-Gon';

  @override
  IconData get icon => Icons.all_inclusive;

  @override
  String get tooltip => 'Build a closed poly-arc incrementally';

  @override
  bool get isComplete => false; // Polyarcgon tool is never "complete" until reset

  @override
  String get stateDescription {
    if (_trackedInputs.isEmpty) {
      return 'Select first point for poly-arc-gon';
    } else if (_trackedInputs.length == 1) {
      return 'Select second point for poly-arc-gon';
    } else if (_trackedInputs.length == 2) {
      return 'Select third point for poly-arc-gon (first arc)';
    } else if (_trackedInputs.length == 3) {
      return 'Select fourth point, or select first point to close';
    } else if (_trackedInputs.length.isEven) {
      // Even number: 4, 6, 8... - can close with p1 (will be odd-numbered: 5th, 7th, 9th)
      return 'Select next point to complete arc, or select first point to close';
    } else {
      // Odd number: 5, 7, 9... - have complete arcs, need even number to close
      return 'Select two more points to extend (need even number to close)';
    }
  }

  static const double selectionThreshold = 10.0;

  dynamic resolveInput(Offset position) {
    final nearby = dagManager.proximitySearch(
      position,
      threshold: selectionThreshold,
    );
    for (final candidate in nearby) {
      if (candidate is GeoPoint) {
        return candidate;
      }
    }
    return createFreePoint(position);
  }

  String? _validateNextInput(GeoPoint candidate) {
    // Prevent selecting the same point twice in a row
    if (_trackedInputs.isNotEmpty) {
      if (_trackedInputs.last.id == candidate.id) {
        return 'Select a distinct point to continue';
      }
    }
    
    // Track first point on first input
    if (_trackedInputs.isEmpty) {
      _firstPoint = candidate;
      return null;
    }
    
    // Check if candidate is the first point (completion)
    // Also check if candidate matches the first point in tracked inputs (in case _firstPoint is null)
    final isFirstPoint = (_firstPoint != null && candidate.id == _firstPoint!.id) ||
        (_trackedInputs.isNotEmpty && candidate.id == _trackedInputs.first.id);
    
    if (isFirstPoint) {
      // p1 can only be added when we have even number of points (2*n where n >= 2)
      // p1 will be the (2*n+1)th point (odd-numbered position)
      // Examples: 4 points → p1 as 5th (close), 6 points → p1 as 7th (close)
      if (_trackedInputs.length >= 4 && _trackedInputs.length.isEven) {
        // Ensure _firstPoint is set
        if (_firstPoint == null && _trackedInputs.isNotEmpty) {
          _firstPoint = _trackedInputs.first;
        }
        return null; // Allow completion - p1 will be odd-numbered (2*n+1)
      }
      // If we have odd number of points, p1 cannot be added (would be even-numbered)
      if (_trackedInputs.length >= 3 && _trackedInputs.length.isOdd) {
        return 'Cannot add p1 now - need even number of points (4, 6, 8...) to close';
      }
      return 'Need at least 4 points (even number) to close poly-arc-gon';
    }
    
    // Prevent reselecting any interior points (p2, p3, p4... pn-1)
    // p1 is already handled above for closing, so if we reach here, p1 cannot be used
    // Only allow: new points
    if (_trackedInputs.length >= 2) {
      // Check if this is any previously selected point (excluding p1 which is handled above)
      for (var i = 0; i < _trackedInputs.length; i++) {
        if (_trackedInputs[i].id == candidate.id) {
          // p1 should have been handled above, so if we're here, it's not p1 or can't close
          return 'Cannot reselect points. Only p1 can be reselected to close (when you have even number of points)';
        }
      }
    }
    
    // Allow adding new points
    return null;
  }

  /// Get temporary polyarcgon construction data for preview rendering
  TemporaryPolyArcGonData? getTemporaryPolyArcGonData() {
    if (_trackedInputs.length < 3) return null;
    
    // No preview arc - closing requires adding p1 when we have even number of points
    // The closing arc will be: (second_to_last, last, p1)
    
    return TemporaryPolyArcGonData(
      points: List<GeoPoint>.from(_trackedInputs),
      lightArcIndex: -1, // No preview arc
    );
  }

  @override
  void handleInput(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }

    // Resolve input first
    dynamic candidate;
    try {
      candidate = resolveInput(event.position);
    } catch (error) {
      onToolStateChanged?.call('Unable to create poly-arc-gon: $error');
      return;
    }

    if (candidate == null || candidate is! GeoPoint) {
      onToolStateChanged?.call('Unable to resolve a point at that location');
      return;
    }

    // Validate input
    final message = _validateNextInput(candidate);
    if (message != null) {
      onToolStateChanged?.call(message);
      return;
    }

    // Check if this is completion (selecting first point again)
    // We can complete if:
    // - We have at least 4 points (even number: 2*n where n >= 2)
    // - The candidate is the first point (p1)
    // - p1 will be the (2*n+1)th point (odd-numbered position)
    final isFirstPointForCompletion = (_firstPoint != null && candidate.id == _firstPoint!.id) ||
        (_trackedInputs.isNotEmpty && candidate.id == _trackedInputs.first.id);
    
    if (_trackedInputs.length >= 4 && 
        isFirstPointForCompletion &&
        _trackedInputs.length.isEven) {
      // Add p1 to complete the sequence
      // When p1 is added, the closing arc will be: (second_to_last, last, p1)
      // Example: [p1,p2,p3,p4] + p1 → [p1,p2,p3,p4,p1] → closing arc (p3,p4,p1)
      _trackedInputs.add(candidate);
      _completePolyArcGon();
      return;
    }

    // Add the point
    if (_trackedInputs.isEmpty) {
      _trackedInputs.add(candidate);
    } else {
      // Only add if it's not already the last point
      if (_trackedInputs.last.id != candidate.id) {
        _trackedInputs.add(candidate);
      }
    }

    // Notify state change
    onToolStateChanged?.call(stateDescription);
  }

  Future<void> _completePolyArcGon() async {
    // When p1 is added to even number of points, we have odd total (2*n+1)
    // The closing arc is: (second_to_last, last, p1)
    // Example: [p1,p2,p3,p4] + p1 → [p1,p2,p3,p4,p1] → closing arc (p3,p4,p1)
    if (_trackedInputs.length < 5 || !_trackedInputs.length.isOdd) {
      onToolStateChanged?.call('Poly-arc-gon requires at least 4 points (even number) before closing with p1');
      return;
    }
    
    try {
      final label = LabelManager.getNextAvailableLabel(
        dagManager,
        GeometryObjectType.polyArcGon,
      );
      
      // Create polyarcgon from tracked points
      // The points form arcs:
      // - First arc: p1, p2, p3
      // - Subsequent arcs: p3,p4,p5, p5,p6,p7, etc.
      // - Closing arc: (second_to_last, last, p1) - created by fromDependencies when p1 is last
      final points = List<GeoPoint>.from(_trackedInputs);
      
      // p1 should already be the last point (added in handleInput before calling this)
      // Verify it's closed for GeoPolyArcGon.fromDependencies
      if (points.first.id != points.last.id) {
        // This shouldn't happen, but add p1 if somehow missing
        points.add(points.first);
      }
      
      // Create polyarcgon - fromDependencies will create the closing arc correctly
      // The closing arc uses: (points[length-3], points[length-2], points[length-1])
      // which is (second_to_last, last, p1) - doesn't involve p2
      final polyarcgon = GeoPolyArcGon.fromDependencies(
        id: label,
        label: label,
        points: points,
        dagManager: dagManager,
      );
      
      // Add the final polyarcgon
      dagManager.addObject(polyarcgon, polyarcgon.dependencies);
      
      onObjectCreated?.call(polyarcgon, polyarcgon.dependencies);
      onToolStateChanged?.call('Poly-arc-gon completed with ${polyarcgon.elements.length} arcs');
      
      // Reset state
      _firstPoint = null;
      _trackedInputs.clear();
      reset();
    } catch (e) {
      onToolStateChanged?.call('Failed to complete poly-arc-gon: $e');
    }
  }

  /// Select an object directly (used when object is selected from menu/dropdown)
  /// This allows selecting pre-existing points for poly-arc-gon construction
  void selectObject(GeometryObject object) {
    if (object is! GeoPoint) {
      onToolStateChanged?.call('Poly-arc-gon tool requires point selection');
      return;
    }

    // Validate input
    final message = _validateNextInput(object);
    if (message != null) {
      onToolStateChanged?.call(message);
      return;
    }

    // Check if this is completion (selecting first point again)
    // We can complete if:
    // - We have at least 4 points (even number: 2*n where n >= 2)
    // - The candidate is the first point (p1)
    // - p1 will be the (2*n+1)th point (odd-numbered position)
    final isFirstPointForCompletion = (_firstPoint != null && object.id == _firstPoint!.id) ||
        (_trackedInputs.isNotEmpty && object.id == _trackedInputs.first.id);
    
    if (_trackedInputs.length >= 4 && 
        isFirstPointForCompletion &&
        _trackedInputs.length.isEven) {
      // Add p1 to complete the sequence
      _trackedInputs.add(object);
      _completePolyArcGon();
      return;
    }

    // Add the point
    if (_trackedInputs.isEmpty) {
      _firstPoint = object;
      _trackedInputs.add(object);
    } else {
      // Only add if it's not already the last point
      if (_trackedInputs.last.id != object.id) {
        _trackedInputs.add(object);
      }
    }

    // Notify state change
    onToolStateChanged?.call(stateDescription);
  }

  @override
  void reset() {
    _firstPoint = null;
    _trackedInputs.clear();
  }
}

/// Reflect Line tool - reflects object across a line
class _ReflectLineTool extends StagedSelectionTool {
  _ReflectLineTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.reflectLine;

  @override
  String get name => 'Reflect Line';

  @override
  IconData get icon => Icons.flip;

  @override
  String get tooltip => 'Reflect object across a line';

  @override
  String get commandName => 'reflect';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoLine, GeoLine2P}, // Stage 1: Line
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to reflect';
      case 1:
        return 'Select line to reflect across';
      default:
        return 'Reflecting...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    return [selectedObjects[0], selectedObjects[1]];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (reflection)';

  @override
  String failureMessage(String reason) =>
      'Unable to reflect object: $reason';
}

/// Reflect Point tool - reflects object across a point
class _ReflectPointTool extends StagedSelectionTool {
  _ReflectPointTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.reflectPoint;

  @override
  String get name => 'Reflect Point';

  @override
  IconData get icon => Icons.flip_camera_android;

  @override
  String get tooltip => 'Reflect object across a point';

  @override
  String get commandName => 'reflect';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoPoint, GeoPointer, GeoMidpoint}, // Stage 1: Point
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to reflect';
      case 1:
        return 'Select point to reflect across';
      default:
        return 'Reflecting...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    return [selectedObjects[0], selectedObjects[1]];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (reflection)';

  @override
  String failureMessage(String reason) =>
      'Unable to reflect object: $reason';
}

/// Reflect Circle tool - reflects object across a circle (inversion)
class _ReflectCircleTool extends StagedSelectionTool {
  _ReflectCircleTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.reflectCircle;

  @override
  String get name => 'Reflect Circle';

  @override
  IconData get icon => Icons.flip_camera_ios;

  @override
  String get tooltip => 'Reflect object across a circle (inversion)';

  @override
  String get commandName => 'reflect';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoCircle, GeoCircle2P, GeoCircle3P}, // Stage 1: Circle
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to invert';
      case 1:
        return 'Select circle for inversion';
      default:
        return 'Inverting...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    return [selectedObjects[0], selectedObjects[1]];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (inversion)';

  @override
  String failureMessage(String reason) =>
      'Unable to invert object: $reason';
}

/// Rotate tool - rotates object around a center point by an angle
class _RotateTool extends StagedSelectionTool {
  _RotateTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.rotate;

  @override
  String get name => 'Rotate';

  @override
  IconData get icon => Icons.rotate_left;

  @override
  String get tooltip => 'Rotate object around a center point';

  @override
  String get commandName => 'rotate';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoPoint, GeoPointer, GeoMidpoint, GeoCircle}, // Stage 1: Center point or circle
  ];

  @override
  List<ParameterSpec> get parameterSpecs => const [
    ParameterSpec(
      key: 'angle',
      label: 'Angle',
      type: ParameterType.angle,
      defaultValue: 90.0,
      hint: 'Enter rotation angle',
    ),
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to rotate';
      case 1:
        return 'Select center point or circle for rotation';
      default:
        return 'Rotating...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    // UI sends angle in radians (already converted from degrees if user selected degrees)
    // Default to 90 degrees = π/2 radians if not provided
    final angleRadians = (parameters?['angle'] ?? (90.0 * math.pi / 180.0)) as double;
    final angleDegrees = angleRadians * 180.0 / math.pi;
    debugPrint('[RotateTool] buildArguments: Angle = ${angleRadians.toStringAsFixed(6)} radians (${angleDegrees.toStringAsFixed(2)}°)');
    
    // If center is a circle, extract its center point
    final center = selectedObjects[1];
    GeometryObject centerPoint = center;
    if (center is GeoCircle) {
      // Create a temporary point at the circle's center
      final centerMv = getCircleCenter(center.multivector);
      centerPoint = GeoPointer(
        id: '${center.id}_center',
        label: '${center.label}_center',
        x: centerMv.e1,
        y: centerMv.e2,
      );
    }
    // Convert radians back to degrees for the command (command expects degrees)
    return [selectedObjects[0], centerPoint, angleDegrees];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (rotated)';

  @override
  String failureMessage(String reason) =>
      'Unable to rotate object: $reason';
}

/// Translate tool - translates object by a vector
class _TranslateTool extends StagedSelectionTool {
  _TranslateTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.translate;

  @override
  String get name => 'Translate';

  @override
  IconData get icon => Icons.open_in_full;

  @override
  String get tooltip => 'Translate object by a vector';

  @override
  String get commandName => 'translate';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoSegment, GeoSegment2P}, // Stage 1: Segment (defines vector)
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to translate';
      case 1:
        return 'Select segment (defines translation vector)';
      default:
        return 'Translating...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    return [selectedObjects[0], selectedObjects[1]];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (translated)';

  @override
  String failureMessage(String reason) =>
      'Unable to translate object: $reason';
}

/// Dilate tool - scales object from a center by a factor
class _DilateTool extends StagedSelectionTool {
  _DilateTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    super.onParameterRequest,
  });

  @override
  ToolType get type => ToolType.dilate;

  @override
  String get name => 'Dilate';

  @override
  IconData get icon => Icons.center_focus_strong;

  @override
  String get tooltip => 'Scale object from a center point';

  @override
  String get commandName => 'dilate';

  @override
  int get totalStages => 2;

  @override
  List<Set<Type>> get stageTypeConstraints => [
    {}, // Stage 0: Any geometry object
    {GeoPoint, GeoPointer, GeoMidpoint, GeoCircle}, // Stage 1: Center point or circle
  ];

  @override
  List<ParameterSpec> get parameterSpecs => const [
    ParameterSpec(
      key: 'scale',
      label: 'Scale Factor',
      type: ParameterType.number,
      defaultValue: 2.0,
      hint: 'Enter scale factor (positive for dilation, negative for compression)',
    ),
  ];

  @override
  String stagePrompt(int stage) {
    switch (stage) {
      case 0:
        return 'Select object to dilate';
      case 1:
        return 'Select center point or circle for dilation';
      default:
        return 'Dilating...';
    }
  }

  @override
  List<dynamic> buildArguments(
    List<GeometryObject> selectedObjects,
    Map<String, dynamic>? parameters,
  ) {
    final scale = (parameters?['scale'] ?? 2.0) as double;
    // If center is a circle, extract its center point
    final center = selectedObjects[1];
    GeometryObject centerPoint = center;
    if (center is GeoCircle) {
      // Create a temporary point at the circle's center
      final centerMv = getCircleCenter(center.multivector);
      centerPoint = GeoPointer(
        id: '${center.id}_center',
        label: '${center.label}_center',
        x: centerMv.e1,
        y: centerMv.e2,
      );
    }
    return [selectedObjects[0], centerPoint, scale];
  }

  @override
  String successMessage(GeometryObject result) =>
      'Created ${result.label} (dilated)';

  @override
  String failureMessage(String reason) =>
      'Unable to dilate object: $reason';
}

/// Midpoint tool - constructs midpoint between two points
class _MidpointTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _MidpointTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.midpoint;

  @override
  String get commandName => 'midpoint';

  @override
  String get name => 'Midpoint';

  @override
  IconData get icon => Icons.adjust;

  @override
  String get tooltip => 'Create midpoint of two points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select two points for midpoint');
  }
}

/// Center tool - finds and draws the center of a circle
class _CenterTool extends UnifiedTool {
  _CenterTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
  });

  @override
  ToolType get type => ToolType.center;

  @override
  String get commandName => 'center';

  @override
  String get name => 'Center';

  @override
  IconData get icon => Icons.center_focus_strong;

  @override
  String get tooltip => 'Find and draw the center of a circle';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    // Center tool doesn't create objects at arbitrary positions
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select a circle to find its center');
  }
}

/// Perpendicular line tool - builds a line perpendicular to a reference line through a point
class _PerpendicularTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _PerpendicularTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.perpendicular;

  @override
  String get commandName => 'perpendicular';

  @override
  String get name => 'Perpendicular Line';

  @override
  IconData get icon => Icons.rotate_90_degrees_ccw;

  @override
  String get tooltip => 'Create a line perpendicular to another line';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select a point and a line for perpendicular');
  }
}

/// Parallel line tool - builds a line parallel to a reference line
class _ParallelTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _ParallelTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.parallel;

  @override
  String get commandName => 'parallel';

  @override
  String get name => 'Parallel Line';

  @override
  IconData get icon => Icons.swap_calls;

  @override
  String get tooltip => 'Create a line parallel to another line';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select a line and a point for parallel line');
  }
}

/// Perpendicular bisector tool - constructs bisector of segment formed by two points
class _PerpBisectorTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _PerpBisectorTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.perpBisector;

  @override
  String get commandName => 'perpbisector';

  @override
  String get name => 'Perpendicular Bisector';

  @override
  IconData get icon => Icons.straighten;

  @override
  String get tooltip => 'Create the perpendicular bisector of two points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select two points for perpendicular bisector');
  }
}

/// Angle bisector tool - constructs angle bisector from 3 points or 2 lines
class _AngleBisectorTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _AngleBisectorTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.angleBisector;

  @override
  String get commandName => 'anglebisector';

  @override
  String get name => 'Angle Bisector';

  @override
  IconData get icon => Icons.call_split;

  @override
  String get tooltip =>
      'Create angle bisector from three points (vertex at middle) or two lines';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    // Can accept GeoPoint or GeoLine depending on the pattern
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    // Cannot create GeoLine at position, user must select existing lines
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select three points (or two lines) for angle bisector');
  }
}

/// Intersection tool - finds intersection points between two objects
class _IntersectionTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _IntersectionTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.intersection;

  @override
  String get commandName => 'intersection';

  @override
  String get name => 'Intersection';

  @override
  IconData get icon => Icons.control_point;

  @override
  String get tooltip => 'Find intersection points between two objects';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    // Intersection requires selecting existing objects (lines, circles, points)
    // Cannot create new objects at position
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select two objects to find intersection');
  }
}

/// Tangent tool - constructs tangents from point/circle inputs
class _TangentTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _TangentTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.tangent;

  @override
  String get commandName => 'tangent';

  @override
  String get name => 'Tangent';

  @override
  IconData get icon => Icons.rotate_90_degrees_cw;

  @override
  String get tooltip => 'Create tangents between point/circle inputs';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select point or circle for tangent');
  }
}

/// Circle Flex tool - creates circles with flexible center and point
class _CircleFlexTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _CircleFlexTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.circleFlex;

  @override
  String get commandName => 'circleFlex';

  @override
  String get name => 'Circle (Flex)';

  @override
  IconData get icon => Icons.circle_outlined;

  @override
  String get tooltip => 'Create a circle with flexible center and point';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(SimpleGeometryObject) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select center (point or circle) for circle');
  }
}

/// Circle 3 Flex tool - creates circles through three flexible objects
class _Geo3FlexTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _Geo3FlexTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.circle3Flex;

  @override
  String get commandName => 'geo3Flex';

  @override
  String get name => 'Geo 3 (Flex)';

  @override
  IconData get icon => Icons.circle;

  @override
  String get tooltip => 'Create geometry through three flexible objects (point, line, or circle)';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(SimpleGeometryObject) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select three objects for geometry');
  }
}

/// Line Flex tool - creates lines through two flexible objects
class _LineFlexTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _LineFlexTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.lineFlex;

  @override
  String get commandName => 'lineFlex';

  @override
  String get name => 'Line (Flex)';

  @override
  IconData get icon => Icons.horizontal_rule;

  @override
  String get tooltip => 'Create a line through two flexible objects';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(SimpleGeometryObject) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select two objects for line');
  }
}

/// Perpendicular Bisector Flex tool - creates bisector with flexible arguments
class _PerpBisectorFlexTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _PerpBisectorFlexTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.perpbisectorFlex;

  @override
  String get commandName => 'perpbisectorFlex';

  @override
  String get name => 'Perp. Bisector (Flex)';

  @override
  IconData get icon => Icons.straighten;

  @override
  String get tooltip => 'Create perpendicular bisector with flexible arguments';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType?.accepts(SimpleGeometryObject) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select two objects (point or circle) for bisector');
  }
}

/// Perpendicular Flex tool - creates perpendicular line with flexible point
class _PerpendicularFlexTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _PerpendicularFlexTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.perpendicularFlex;

  @override
  String get commandName => 'perpendicularFlex';

  @override
  String get name => 'Perpendicular (Flex)';

  @override
  IconData get icon => Icons.rotate_90_degrees_ccw;

  @override
  String get tooltip => 'Create perpendicular line with flexible point';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType != null && 
        (nextType.accepts(GeoPoint) || nextType.accepts(GeoCircle))) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select point (point or circle) and line for perpendicular');
  }
}

/// Parallel Flex tool - creates parallel line with flexible point
class _ParallelFlexTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _ParallelFlexTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.parallelFlex;

  @override
  String get commandName => 'parallelFlex';

  @override
  String get name => 'Parallel (Flex)';

  @override
  IconData get icon => Icons.swap_calls;

  @override
  String get tooltip => 'Create parallel line with flexible point';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextType = verifier.schema.nextConstraint(verifier.arguments);
    if (nextType != null && 
        (nextType.accepts(GeoPoint) || nextType.accepts(GeoCircle))) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select line and point (point or circle) for parallel');
  }
}

/// Incircle tool - constructs incircle from three vertices
class _IncircleTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _IncircleTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.incircle;

  @override
  String get commandName => 'incircle';

  @override
  String get name => 'Incircle';

  @override
  IconData get icon => Icons.circle;

  @override
  String get tooltip => 'Construct incircle from three vertices';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select three vertices for incircle');
  }
}

/// Excircle tool - constructs excircle from three vertices and a side
class _ExcircleTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _ExcircleTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.excircle;

  @override
  String get commandName => 'excircle';

  @override
  String get name => 'Excircle';

  @override
  IconData get icon => Icons.circle_outlined;

  @override
  String get tooltip => 'Construct excircle from three vertices and a side';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select three vertices and a side for excircle');
  }
}

/// Orthocenter tool - constructs orthocenter from three vertices
class _OrthocenterTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _OrthocenterTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.orthocenter;

  @override
  String get commandName => 'orthocenter';

  @override
  String get name => 'Orthocenter';

  @override
  IconData get icon => Icons.center_focus_strong;

  @override
  String get tooltip => 'Construct orthocenter from three vertices';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select three vertices for orthocenter');
  }
}

/// Tangents tool - constructs tangents between two objects
class _TangentsTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _TangentsTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.tangents;

  @override
  String get commandName => 'tangents';

  @override
  String get name => 'Tangents';

  @override
  IconData get icon => Icons.rotate_90_degrees_cw;

  @override
  String get tooltip => 'Construct tangents between two objects';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    if (nextConstraint?.accepts(GeoCircle) ?? false) {
      // Could create a circle, but for tangents we typically select existing objects
      return null;
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select two objects (point-point, point-circle, or circle-circle) for tangents');
  }
}

/// Polar tool - constructs polar line of a point with respect to a circle
class _PolarTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _PolarTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.polar;

  @override
  String get commandName => 'polar';

  @override
  String get name => 'Polar';

  @override
  IconData get icon => Icons.straighten;

  @override
  String get tooltip => 'Construct polar line of a point with respect to a circle';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select point and circle for polar line');
  }
}

/// aLCbc tool - applies aLCbc operation on three multivectors
class _AlcbcTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _AlcbcTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.alcbc;

  @override
  String get commandName => 'alcbc';

  @override
  String get name => 'aLCbc';

  @override
  IconData get icon => Icons.code;

  @override
  String get tooltip => 'Apply aLCbc operation on three objects';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select three objects for aLCbc operation');
  }
}

/// Imaginary Circle tool - constructs imaginary circle from two points
class _IcircleTool extends UnifiedTool {
  final GeoPointer Function(Offset position) createFreePoint;

  _IcircleTool({
    required super.dagManager,
    super.commandHistory,
    super.onObjectCreated,
    super.onObjectSelected,
    super.onToolStateChanged,
    required this.createFreePoint,
  });

  @override
  ToolType get type => ToolType.icircle;

  @override
  String get commandName => 'icircle';

  @override
  String get name => 'Imaginary Circle';

  @override
  IconData get icon => Icons.circle_outlined;

  @override
  String get tooltip => 'Construct imaginary circle from two points';

  @override
  GeometryObject? createObjectAtPosition(Offset position) {
    final nextConstraint = verifier.schema.nextConstraint(verifier.arguments);
    if (nextConstraint?.accepts(GeoPointer) ?? false) {
      return createFreePoint(position);
    }
    return null;
  }

  @override
  void reset() {
    super.reset();
    notifyStateChanged('Select two points for imaginary circle');
  }

  @override
  bool get isComplete => verifier.isComplete;

  @override
  String get stateDescription => 'Select two points for imaginary circle';
}

/// Delete tool - deletes selected objects when clicked
class _DeleteTool with ToolCallbacksMixin implements Tool {
  final DAGManager dagManager;

  _DeleteTool({
    required this.dagManager,
    OnObjectCreated? onObjectCreated,
    OnObjectSelected? onObjectSelected,
    OnToolStateChanged? onToolStateChanged,
  }) {
    this.onObjectCreated = onObjectCreated;
    this.onObjectSelected = onObjectSelected;
    this.onToolStateChanged = onToolStateChanged;
  }

  @override
  ToolType get type => ToolType.delete;

  @override
  String get name => 'Delete';

  @override
  IconData get icon => Icons.delete;

  @override
  String get tooltip => 'Delete selected objects';

  @override
  bool get isComplete => true;

  @override
  String get stateDescription => 'Click on an object to delete it';

  @override
  void handleInput(PointerEvent event) {
    if (event is PointerDownEvent) {
      // The canvas will handle object selection and deletion
      // This tool just needs to be active
      notifyStateChanged('Click on an object to delete it');
    }
  }

  @override
  void reset() {
    notifyStateChanged('Click on an object to delete it');
  }
}

/// Union tool - creates a union of simple or complex geometry objects
class _UnionTool with ToolCallbacksMixin implements Tool {
  final DAGManager dagManager;
  final CommandHistory? commandHistory;
  
  final List<GeometryObject> _collectedObjects = [];
  GeoUnion? _currentUnion;
  String? _currentUnionId;
  HistoryMarker? _historyMarker;

  _UnionTool({
    required this.dagManager,
    this.commandHistory,
    OnObjectCreated? onObjectCreated,
    OnObjectSelected? onObjectSelected,
    OnToolStateChanged? onToolStateChanged,
  }) {
    this.onObjectCreated = onObjectCreated;
    this.onObjectSelected = onObjectSelected;
    this.onToolStateChanged = onToolStateChanged;
  }

  @override
  ToolType get type => ToolType.union;

  @override
  String get name => 'Union';

  @override
  IconData get icon => Icons.merge_type;

  @override
  String get tooltip => 'Create a union of objects';

  @override
  bool get isComplete => false; // Always allows adding more objects

  @override
  String get stateDescription {
    if (_collectedObjects.isEmpty) {
      return 'Click objects to add to union';
    }
    return 'Union: ${_collectedObjects.length} object(s). Click more objects to add';
  }

  /// Select an object directly (used when object is selected from menu/dropdown)
  void selectObject(GeometryObject object) {
    _startTransactionIfNeeded();
    _addObjectToUnion(object);
  }

  void _addObjectToUnion(GeometryObject object) {
    // If object is a UnionGeometryObjectList and the list itself was selected,
    // add all its children. Otherwise, add the object itself.
    final collectedIds = _collectedObjects.map((obj) => obj.id).toSet();
    
    if (object is UnionGeometryObjectList) {
      // When a list is selected, add all its children (not the list itself)
      for (final child in object.elements) {
        if (!collectedIds.contains(child.id)) {
          _collectedObjects.add(child);
          collectedIds.add(child.id);
        }
      }
    } else {
      // Add the object itself if not already in the collection
      if (!collectedIds.contains(object.id)) {
        _collectedObjects.add(object);
      }
    }

    _updateUnion();
    notifyStateChanged(stateDescription);
  }

  void _updateUnion() {
    if (_collectedObjects.isEmpty) {
      // Remove existing union if no objects
      if (_currentUnionId != null) {
        try {
          dagManager.deleteObject(_currentUnionId!, cascade: false);
        } catch (e) {
          // Ignore errors
        }
        _currentUnion = null;
        _currentUnionId = null;
      }
      return;
    }

    // Get dependencies (all IDs of collected objects)
    final dependencies = _collectedObjects.map((obj) => obj.id).toList();
    
    // Generate label
    final label = LabelManager.getNextAvailableLabel(
      dagManager,
      GeometryObjectType.union,
    );

    // Create or update union
    if (_currentUnion == null) {
      // Create new union
      _currentUnion = GeoUnion(
        id: label,
        label: label,
        dependencies: dependencies,
        elements: List<GeometryObject>.from(_collectedObjects),
      );
      
      dagManager.addObject(_currentUnion!, dependencies);
      _currentUnionId = _currentUnion!.id;
      
      notifyObjectCreated(_currentUnion!, dependencies);
    } else {
      // Update existing union
      final updatedUnion = GeoUnion(
        id: _currentUnion!.id,
        label: _currentUnion!.label,
        dependencies: dependencies,
        elements: List<GeometryObject>.from(_collectedObjects),
        visible: _currentUnion!.visible,
        styleOverrides: _currentUnion!.styleOverrides,
      );
      
      dagManager.updateObject(_currentUnionId!, updatedUnion);
      _currentUnion = updatedUnion;
      
      notifyObjectSelected(_currentUnion!.id);
    }
  }

  void _startTransactionIfNeeded() {
    if (_historyMarker == null) {
      _historyMarker = dagManager.markHistory();
    }
  }

  @override
  void handleInput(PointerEvent event) {
    // The canvas will handle object selection and call selectObject
    // This tool just needs to be active
    if (event is PointerDownEvent) {
      notifyStateChanged(stateDescription);
    }
  }

  @override
  void reset() {
    if (_historyMarker != null) {
      dagManager.rollbackToMarker(_historyMarker!);
      _historyMarker = null;
    }
    
    if (_currentUnionId != null) {
      try {
        dagManager.deleteObject(_currentUnionId!, cascade: false);
      } catch (e) {
        // Ignore errors
      }
    }
    
    _collectedObjects.clear();
    _currentUnion = null;
    _currentUnionId = null;
    _historyMarker = null;
    
    notifyStateChanged('Click objects to add to union');
  }
}

