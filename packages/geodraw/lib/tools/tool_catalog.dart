import 'package:flutter/material.dart';

import 'tool.dart';

/// Represents a single tool descriptor for palette rendering.
class ToolCatalogEntry {
  final String id;
  final String label;
  final IconData icon;
  final String? command;
  final ToolType? toolType;
  final bool implemented;

  const ToolCatalogEntry({
    required this.id,
    required this.label,
    required this.icon,
    this.command,
    this.toolType,
    this.implemented = false,
  });
}

/// Group of tools displayed under the same category heading.
class ToolCategoryGroup {
  final String name;
  final List<ToolCatalogEntry> tools;

  const ToolCategoryGroup({required this.name, required this.tools});
}

/// Palette tiers inspired by GeoGebra layouts.
enum ToolPaletteLevel { level1, level2, level3 }

const ToolCatalogEntry _moveTool = ToolCatalogEntry(
  id: 'move',
  label: 'Move',
  icon: Icons.open_with,
  command: 'Move[]',
  toolType: ToolType.select,
  implemented: true,
);

const ToolCatalogEntry _panTool = ToolCatalogEntry(
  id: 'pan',
  label: 'Pan',
  icon: Icons.pan_tool,
  command: 'Pan[]',
  toolType: ToolType.pan,
  implemented: true,
);

const ToolCatalogEntry _pointTool = ToolCatalogEntry(
  id: 'point',
  label: 'Point',
  icon: Icons.gps_fixed,
  command: 'Point[]',
  toolType: ToolType.point,
  implemented: true,
);

const ToolCatalogEntry _segmentTool = ToolCatalogEntry(
  id: 'segment',
  label: 'Segment',
  icon: Icons.show_chart,
  command: 'Segment[]',
  toolType: ToolType.lineSegment,
);

const ToolCatalogEntry _lineTool = ToolCatalogEntry(
  id: 'line',
  label: 'Line',
  icon: Icons.horizontal_rule,
  command: 'Line[]',
  toolType: ToolType.line,
  implemented: true,
);

const ToolCatalogEntry _polygonTool = ToolCatalogEntry(
  id: 'polygon',
  label: 'Polygon',
  icon: Icons.change_history,
  command: 'Polygon[]',
);

const ToolCatalogEntry _circleCenterTool = ToolCatalogEntry(
  id: 'circle_center',
  label: 'Circle (Center)',
  icon: Icons.circle_outlined,
  command: 'Circle[]',
  toolType: ToolType.circle,
  implemented: true,
);

const ToolCatalogEntry _eraserTool = ToolCatalogEntry(
  id: 'eraser',
  label: 'Eraser',
  icon: Icons.auto_fix_off,
  command: 'Delete[]',
);

const ToolCatalogEntry _selectTool = ToolCatalogEntry(
  id: 'select',
  label: 'Select',
  icon: Icons.touch_app,
  command: 'Select[]',
  toolType: ToolType.select,
  implemented: true,
);

const ToolCatalogEntry _deleteTool = ToolCatalogEntry(
  id: 'delete',
  label: 'Delete',
  icon: Icons.delete_outline,
  command: 'Delete[]',
);

const ToolCatalogEntry _copyTool = ToolCatalogEntry(
  id: 'copy',
  label: 'Copy',
  icon: Icons.copy,
  command: 'Copy[]',
);

const ToolCatalogEntry _redefineTool = ToolCatalogEntry(
  id: 'redefine',
  label: 'Redefine',
  icon: Icons.edit_note,
  command: 'Redefine[]',
);

const ToolCatalogEntry _perpendicularTool = ToolCatalogEntry(
  id: 'perpendicular',
  label: 'Perpendicular',
  icon: Icons.rotate_90_degrees_ccw,
  command: 'Perpendicular[]',
  toolType: ToolType.perpendicular,
);

const ToolCatalogEntry _parallelTool = ToolCatalogEntry(
  id: 'parallel',
  label: 'Parallel',
  icon: Icons.swap_calls,
  command: 'Parallel[]',
  toolType: ToolType.parallel,
);

const ToolCatalogEntry _angleBisectorTool = ToolCatalogEntry(
  id: 'angle_bisector',
  label: 'Angle Bisector',
  icon: Icons.call_split,
  command: 'AngleBisector[]',
);

const ToolCatalogEntry _midpointTool = ToolCatalogEntry(
  id: 'midpoint',
  label: 'Midpoint',
  icon: Icons.adjust,
  command: 'Midpoint[]',
  toolType: ToolType.midpoint,
);

const ToolCatalogEntry _tangentTool = ToolCatalogEntry(
  id: 'tangent',
  label: 'Tangent',
  icon: Icons.rotate_90_degrees_cw,
  command: 'Tangent[]',
);

const ToolCatalogEntry _distanceTool = ToolCatalogEntry(
  id: 'distance',
  label: 'Distance',
  icon: Icons.straighten,
  command: 'Distance[]',
);

const ToolCatalogEntry _angleMeasureTool = ToolCatalogEntry(
  id: 'angle_measure',
  label: 'Angle',
  icon: Icons.rotate_right,
  command: 'Angle[]',
);

const ToolCatalogEntry _areaTool = ToolCatalogEntry(
  id: 'area',
  label: 'Area',
  icon: Icons.crop_square,
  command: 'Area[]',
);

const ToolCatalogEntry _slopeTool = ToolCatalogEntry(
  id: 'slope',
  label: 'Slope',
  icon: Icons.trending_up,
  command: 'Slope[]',
);

const ToolCatalogEntry _rayTool = ToolCatalogEntry(
  id: 'ray',
  label: 'Ray',
  icon: Icons.linear_scale,
  command: 'Ray[]',
  toolType: ToolType.line,
);

const ToolCatalogEntry _vectorTool = ToolCatalogEntry(
  id: 'vector',
  label: 'Vector',
  icon: Icons.arrow_forward,
  command: 'Vector[]',
);

const ToolCatalogEntry _circleThreePointsTool = ToolCatalogEntry(
  id: 'circle_three_points',
  label: 'Circle (3 Points)',
  icon: Icons.circle,
  command: 'Circle[]',
  toolType: ToolType.circleThreePoints,
);

const ToolCatalogEntry _circularArcTool = ToolCatalogEntry(
  id: 'circular_arc',
  label: 'Circular Arc',
  icon: Icons.panorama_fish_eye,
  command: 'CircularArc[]',
);

const ToolCatalogEntry _regularPolygonTool = ToolCatalogEntry(
  id: 'regular_polygon',
  label: 'Regular Polygon',
  icon: Icons.all_inclusive,
  command: 'RegularPolygon[]',
);

const ToolCatalogEntry _rigidPolygonTool = ToolCatalogEntry(
  id: 'rigid_polygon',
  label: 'Rigid Polygon',
  icon: Icons.category,
  command: 'RigidPolygon[]',
);

const ToolCatalogEntry _reflectLineTool = ToolCatalogEntry(
  id: 'reflect_line',
  label: 'Reflect Line',
  icon: Icons.flip,
  command: 'Reflect[]',
  toolType: ToolType.perpBisector,
);

const ToolCatalogEntry _rotateTool = ToolCatalogEntry(
  id: 'rotate',
  label: 'Rotate',
  icon: Icons.rotate_left,
  command: 'Rotate[]',
  toolType: ToolType.perpendicular,
);

const ToolCatalogEntry _translateTool = ToolCatalogEntry(
  id: 'translate',
  label: 'Translate',
  icon: Icons.open_in_full,
  command: 'Translate[]',
  toolType: ToolType.parallel,
);

const ToolCatalogEntry _dilateTool = ToolCatalogEntry(
  id: 'dilate',
  label: 'Dilate',
  icon: Icons.center_focus_strong,
  command: 'Dilate[]',
  toolType: ToolType.parallel,
);

const ToolCatalogEntry _reflectPointTool = ToolCatalogEntry(
  id: 'reflect_point',
  label: 'Reflect Point',
  icon: Icons.flip_camera_android,
  command: 'Reflect[]',
);

const ToolCatalogEntry _reflectCircleTool = ToolCatalogEntry(
  id: 'reflect_circle',
  label: 'Reflect Circle',
  icon: Icons.flip_camera_ios,
  command: 'Reflect[]',
);

const ToolCatalogEntry _locusTool = ToolCatalogEntry(
  id: 'locus',
  label: 'Locus',
  icon: Icons.timeline,
  command: 'Locus[]',
);

const ToolCatalogEntry _intersectTool = ToolCatalogEntry(
  id: 'intersection',
  label: 'Intersection',
  icon: Icons.control_point,
  command: 'Intersect[]',
  toolType: ToolType.intersection,
);

const ToolCatalogEntry _pointOnObjectTool = ToolCatalogEntry(
  id: 'point_on_object',
  label: 'Point on Object',
  icon: Icons.my_location,
  command: 'PointOn[]',
);

const ToolCatalogEntry _attachPointTool = ToolCatalogEntry(
  id: 'attach_point',
  label: 'Attach/Detach',
  icon: Icons.link,
  command: 'AttachCopyToView[]',
);

const ToolCatalogEntry _ellipseTool = ToolCatalogEntry(
  id: 'ellipse',
  label: 'Ellipse',
  icon: Icons.tonality,
  command: 'Ellipse[]',
);

const ToolCatalogEntry _hyperbolaTool = ToolCatalogEntry(
  id: 'hyperbola',
  label: 'Hyperbola',
  icon: Icons.leak_add,
  command: 'Hyperbola[]',
);

const ToolCatalogEntry _parabolaTool = ToolCatalogEntry(
  id: 'parabola',
  label: 'Parabola',
  icon: Icons.stacked_line_chart,
  command: 'Parabola[]',
);

const ToolCatalogEntry _conicTool = ToolCatalogEntry(
  id: 'conic',
  label: 'Conic (5 Points)',
  icon: Icons.blur_circular,
  command: 'Conic[]',
);

const ToolCatalogEntry _shearTool = ToolCatalogEntry(
  id: 'shear',
  label: 'Shear',
  icon: Icons.swap_horiz,
  command: 'Shear[]',
);

const ToolCatalogEntry _stretchTool = ToolCatalogEntry(
  id: 'stretch',
  label: 'Stretch',
  icon: Icons.unfold_more,
  command: 'Stretch[]',
);

const ToolCatalogEntry _invertTool = ToolCatalogEntry(
  id: 'invert',
  label: 'Invert',
  icon: Icons.blur_on,
  command: 'Invert[]',
);

const ToolCatalogEntry _bestFitLineTool = ToolCatalogEntry(
  id: 'best_fit',
  label: 'Best Fit Line',
  icon: Icons.trending_flat,
  command: 'FitLine[]',
);

const ToolCatalogEntry _traceTool = ToolCatalogEntry(
  id: 'trace',
  label: 'Trace',
  icon: Icons.brush,
  command: 'Trace[]',
);

const ToolCatalogEntry _relationTool = ToolCatalogEntry(
  id: 'relation',
  label: 'Relation',
  icon: Icons.device_hub,
  command: 'Relation[]',
);

const ToolCatalogEntry _mirrorCurveTool = ToolCatalogEntry(
  id: 'mirror_curve',
  label: 'Mirror Curve',
  icon: Icons.multiline_chart,
  command: 'MirrorCurve[]',
);

const List<ToolCategoryGroup> level1ToolGroups = [
  ToolCategoryGroup(
    name: 'Basic Tools',
    tools: [
      _moveTool,
      _pointTool,
      _segmentTool,
      _lineTool,
      _polygonTool,
      _circleCenterTool,
      _eraserTool,
    ],
  ),
];

const List<ToolCategoryGroup> level2ToolGroups = [
  ToolCategoryGroup(
    name: 'Basic Tools',
    tools: [
      _moveTool,
      _panTool,
      _pointTool,
      _segmentTool,
      _lineTool,
      _polygonTool,
      _circleCenterTool,
      _eraserTool,
    ],
  ),
  ToolCategoryGroup(
    name: 'Edit Tools',
    tools: [_moveTool, _deleteTool, _selectTool, _copyTool, _redefineTool],
  ),
  ToolCategoryGroup(
    name: 'Construct Tools',
    tools: [
      _perpendicularTool,
      _parallelTool,
      _angleBisectorTool,
      _midpointTool,
      _tangentTool,
    ],
  ),
  ToolCategoryGroup(
    name: 'Measure Tools',
    tools: [_distanceTool, _angleMeasureTool, _areaTool, _slopeTool],
  ),
  ToolCategoryGroup(
    name: 'Lines & Segments',
    tools: [_lineTool, _rayTool, _segmentTool, _vectorTool],
  ),
  ToolCategoryGroup(
    name: 'Circles & Arcs',
    tools: [_circleCenterTool, _circleThreePointsTool, _circularArcTool],
  ),
  ToolCategoryGroup(
    name: 'Polygons',
    tools: [_polygonTool, _regularPolygonTool, _rigidPolygonTool],
  ),
  ToolCategoryGroup(
    name: 'Transformations',
    tools: [_reflectLineTool, _rotateTool, _translateTool, _dilateTool],
  ),
];

const List<ToolCategoryGroup> level3ToolGroups = [
  ToolCategoryGroup(
    name: 'Basic Tools',
    tools: [
      _moveTool,
      _pointTool,
      _segmentTool,
      _lineTool,
      _polygonTool,
      _circleCenterTool,
    ],
  ),
  ToolCategoryGroup(
    name: 'Edit Tools',
    tools: [_moveTool, _deleteTool, _redefineTool, _copyTool, _selectTool],
  ),
  ToolCategoryGroup(
    name: 'Construct Tools',
    tools: [
      _midpointTool,
      _intersectTool,
      _perpendicularTool,
      _parallelTool,
      _tangentTool,
      _locusTool,
    ],
  ),
  ToolCategoryGroup(
    name: 'Measure Tools',
    tools: [_distanceTool, _angleMeasureTool, _areaTool, _slopeTool],
  ),
  ToolCategoryGroup(
    name: 'Points',
    tools: [
      _pointTool,
      _pointOnObjectTool,
      _intersectTool,
      _midpointTool,
      _attachPointTool,
    ],
  ),
  ToolCategoryGroup(
    name: 'Lines',
    tools: [
      _lineTool,
      _rayTool,
      _segmentTool,
      _vectorTool,
      _perpendicularTool,
      _parallelTool,
      _angleBisectorTool,
    ],
  ),
  ToolCategoryGroup(
    name: 'Circles',
    tools: [_circleCenterTool, _circleThreePointsTool, _circularArcTool],
  ),
  ToolCategoryGroup(
    name: 'Polygons',
    tools: [_polygonTool, _regularPolygonTool, _rigidPolygonTool, _locusTool],
  ),
  ToolCategoryGroup(
    name: 'Conics',
    tools: [_conicTool, _ellipseTool, _parabolaTool, _hyperbolaTool],
  ),
  ToolCategoryGroup(
    name: 'Transformations',
    tools: [
      _reflectLineTool,
      _reflectPointTool,
      _reflectCircleTool,
      _rotateTool,
      _translateTool,
      _dilateTool,
      _shearTool,
      _stretchTool,
      _invertTool,
    ],
  ),
  ToolCategoryGroup(
    name: 'Other / Advanced',
    tools: [
      _locusTool,
      _mirrorCurveTool,
      _traceTool,
      _relationTool,
      _bestFitLineTool,
    ],
  ),
];

const Map<ToolPaletteLevel, List<ToolCategoryGroup>> toolPaletteCatalog = {
  ToolPaletteLevel.level1: level1ToolGroups,
  ToolPaletteLevel.level2: level2ToolGroups,
  ToolPaletteLevel.level3: level3ToolGroups,
};

List<ToolCategoryGroup> toolGroupsForLevel(ToolPaletteLevel level) {
  return toolPaletteCatalog[level] ?? const [];
}
