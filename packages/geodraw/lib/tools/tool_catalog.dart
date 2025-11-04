import 'package:flutter/material.dart';

import 'tool.dart';

/// Represents a single tool descriptor for palette rendering.
class ToolCatalogEntry {
  final String id;
  final String label;
  final IconData? icon;
  final String? assetIcon;
  final String? command;
  final ToolType? toolType;
  final bool implemented;

  const ToolCatalogEntry({
    required this.id,
    required this.label,
    this.icon,
    this.assetIcon,
    this.command,
    this.toolType,
    this.implemented = false,
  }) : assert(
         icon != null || assetIcon != null,
         'ToolCatalogEntry requires either an IconData or assetIcon',
       );
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
  assetIcon: 'assets/tool_icons/move.svg',
  command: 'Move[]',
  toolType: ToolType.select,
  implemented: true,
);

const ToolCatalogEntry _panTool = ToolCatalogEntry(
  id: 'pan',
  label: 'Pan',
  icon: Icons.pan_tool,
  assetIcon: 'assets/tool_icons/Standard View.svg',
  command: 'Pan[]',
  toolType: ToolType.pan,
  implemented: true,
);

const ToolCatalogEntry _pointTool = ToolCatalogEntry(
  id: 'point',
  label: 'Point',
  icon: Icons.gps_fixed,
  assetIcon: 'assets/tool_icons/point.svg',
  command: 'Point[]',
  toolType: ToolType.point,
  implemented: true,
);

const ToolCatalogEntry _segmentTool = ToolCatalogEntry(
  id: 'segment',
  label: 'Segment',
  icon: Icons.show_chart,
  assetIcon: 'assets/tool_icons/segment.svg',
  command: 'Segment[]',
  toolType: ToolType.lineSegment,
  implemented: true,
);

const ToolCatalogEntry _lineTool = ToolCatalogEntry(
  id: 'line',
  label: 'Line',
  icon: Icons.horizontal_rule,
  assetIcon: 'assets/tool_icons/line.svg',
  command: 'Line[]',
  toolType: ToolType.line,
  implemented: true,
);

const ToolCatalogEntry _polygonTool = ToolCatalogEntry(
  id: 'polygon',
  label: 'Polygon',
  icon: Icons.change_history,
  assetIcon: 'assets/tool_icons/polygon.svg',
  command: 'Polygon[]',
  toolType: ToolType.polygon,
  implemented: true,
);

const ToolCatalogEntry _polyLineTool = ToolCatalogEntry(
  id: 'poly_line',
  label: 'PolyLine',
  icon: Icons.show_chart,
  command: 'PolyLine[]',
  toolType: ToolType.polyLine,
  implemented: true,
);

const ToolCatalogEntry _polyArcToolEntry = ToolCatalogEntry(
  id: 'poly_arc',
  label: 'Poly-Arc',
  icon: Icons.architecture,
  command: 'PolyArc[]',
  toolType: ToolType.polyArc,
  implemented: true,
);

const ToolCatalogEntry _polyArcGonTool = ToolCatalogEntry(
  id: 'poly_arc_gon',
  label: 'Poly-Arc-Gon',
  icon: Icons.all_inclusive,
  command: 'PolyArcGon[]',
  toolType: ToolType.polyArcGon,
  implemented: true,
);

const ToolCatalogEntry _circleCenterTool = ToolCatalogEntry(
  id: 'circle_center',
  label: 'Circle (Center)',
  icon: Icons.circle_outlined,
  assetIcon: 'assets/tool_icons/circle2.svg',
  command: 'Circle[]',
  toolType: ToolType.circle,
  implemented: true,
);

const ToolCatalogEntry _textTool = ToolCatalogEntry(
  id: 'text',
  label: 'Text',
  icon: Icons.text_fields,
  command: 'Text(x, y, "Label")',
  toolType: ToolType.text,
  implemented: true,
);

const ToolCatalogEntry _eraserTool = ToolCatalogEntry(
  id: 'eraser',
  label: 'Eraser',
  icon: Icons.auto_fix_off,
  assetIcon: 'assets/tool_icons/delete.svg',
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
  assetIcon: 'assets/tool_icons/delete.svg',
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
  assetIcon: 'assets/tool_icons/perpendicularline.svg',
  command: 'Perpendicular[]',
  toolType: ToolType.perpendicular,
  implemented: true,
);

const ToolCatalogEntry _parallelTool = ToolCatalogEntry(
  id: 'parallel',
  label: 'Parallel',
  icon: Icons.swap_calls,
  assetIcon: 'assets/tool_icons/parallel_line.svg',
  command: 'Parallel[]',
  toolType: ToolType.parallel,
  implemented: true,
);

const ToolCatalogEntry _angleBisectorTool = ToolCatalogEntry(
  id: 'angle_bisector',
  label: 'Angle Bisector',
  icon: Icons.call_split,
  assetIcon: 'assets/tool_icons/angle_Bisector.svg',
  command: 'AngleBisector[]',
  toolType: ToolType.angleBisector,
  implemented: true,
);

const ToolCatalogEntry _midpointTool = ToolCatalogEntry(
  id: 'midpoint',
  label: 'Midpoint',
  icon: Icons.adjust,
  assetIcon: 'assets/tool_icons/midpoint.svg',
  command: 'Midpoint[]',
  toolType: ToolType.midpoint,
  implemented: true,
);

const ToolCatalogEntry _tangentTool = ToolCatalogEntry(
  id: 'tangent',
  label: 'Tangent',
  icon: Icons.rotate_90_degrees_cw,
  assetIcon: 'assets/tool_icons/tangent_lines.svg',
  command: 'Tangent[]',
  toolType: ToolType.tangent,
  implemented: true,
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
  assetIcon: 'assets/tool_icons/angle.svg',
  command: 'Angle[]',
);

const ToolCatalogEntry _areaTool = ToolCatalogEntry(
  id: 'area',
  label: 'Area',
  icon: Icons.crop_square,
  assetIcon: 'assets/tool_icons/area.svg',
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
  assetIcon: 'assets/tool_icons/ray.svg',
  command: 'Ray[]',
  toolType: ToolType.line,
);

const ToolCatalogEntry _vectorTool = ToolCatalogEntry(
  id: 'vector',
  label: 'Vector',
  icon: Icons.arrow_forward,
  assetIcon: 'assets/tool_icons/polar.svg',
  command: 'Vector[]',
);

const ToolCatalogEntry _circleThreePointsTool = ToolCatalogEntry(
  id: 'circle_three_points',
  label: 'Circle (3 Points)',
  icon: Icons.circle,
  assetIcon: 'assets/tool_icons/circle3.svg',
  command: 'Circle3[]',
  toolType: ToolType.circleThreePoints,
  implemented: true,
);

const ToolCatalogEntry _perpBisectorTool = ToolCatalogEntry(
  id: 'perp_bisector',
  label: 'Perp. Bisector',
  icon: Icons.straighten,
  assetIcon: 'assets/tool_icons/perpendicularbisector.svg',
  command: 'PerpBisector[]',
  toolType: ToolType.perpBisector,
  implemented: true,
);

const ToolCatalogEntry _circularArcTool = ToolCatalogEntry(
  id: 'circular_arc',
  label: 'Arc (3 Points)',
  icon: Icons.panorama_fish_eye,
  assetIcon: 'assets/tool_icons/arc.svg',
  command: 'Arc3[]',
  toolType: ToolType.arcThreePoints,
  implemented: true,
);

const ToolCatalogEntry _regularPolygonTool = ToolCatalogEntry(
  id: 'regular_polygon',
  label: 'Regular Polygon',
  icon: Icons.all_inclusive,
  assetIcon: 'assets/tool_icons/regular_Polygon.svg',
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
  assetIcon: 'assets/tool_icons/invert_about_line.svg',
  command: 'Reflect[]',
  toolType: ToolType.reflectLine,
  implemented: true,
);

const ToolCatalogEntry _rotateTool = ToolCatalogEntry(
  id: 'rotate',
  label: 'Rotate',
  icon: Icons.rotate_left,
  assetIcon: 'assets/tool_icons/rotate.svg',
  command: 'Rotate[]',
  toolType: ToolType.rotate,
  implemented: true,
);

const ToolCatalogEntry _translateTool = ToolCatalogEntry(
  id: 'translate',
  label: 'Translate',
  icon: Icons.open_in_full,
  command: 'Translate[]',
  toolType: ToolType.translate,
  implemented: true,
);

const ToolCatalogEntry _dilateTool = ToolCatalogEntry(
  id: 'dilate',
  label: 'Dilate',
  icon: Icons.center_focus_strong,
  assetIcon: 'assets/tool_icons/dilation.svg',
  command: 'Dilate[]',
  toolType: ToolType.dilate,
  implemented: true,
);

const ToolCatalogEntry _reflectPointTool = ToolCatalogEntry(
  id: 'reflect_point',
  label: 'Reflect Point',
  icon: Icons.flip_camera_android,
  assetIcon: 'assets/tool_icons/reflection_about_point.svg',
  command: 'Reflect[]',
  toolType: ToolType.reflectPoint,
  implemented: true,
);

const ToolCatalogEntry _reflectCircleTool = ToolCatalogEntry(
  id: 'reflect_circle',
  label: 'Reflect Circle',
  icon: Icons.flip_camera_ios,
  assetIcon: 'assets/tool_icons/inversion.svg',
  command: 'Reflect[]',
  toolType: ToolType.reflectCircle,
  implemented: true,
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
  assetIcon: 'assets/tool_icons/intersection.svg',
  command: 'Intersect[]',
  toolType: ToolType.intersection,
  implemented: true,
);

const ToolCatalogEntry _pointOnObjectTool = ToolCatalogEntry(
  id: 'point_on_object',
  label: 'Point on Object',
  icon: Icons.my_location,
  assetIcon: 'assets/tool_icons/point_on_object.svg',
  command: 'PointOn[]',
);

const ToolCatalogEntry _attachPointTool = ToolCatalogEntry(
  id: 'attach_point',
  label: 'Attach/Detach',
  icon: Icons.link,
  assetIcon: 'assets/tool_icons/attach_detach.svg',
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
  assetIcon: 'assets/tool_icons/inversion.svg',
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
      _polyArcToolEntry,
      _circleCenterTool,
      _textTool,
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
      _polyArcToolEntry,
      _circleCenterTool,
      _textTool,
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
      _perpBisectorTool,
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
    tools: [
      _polygonTool,
      _polyLineTool,
      _polyArcToolEntry,
      _polyArcGonTool,
      _regularPolygonTool,
      _rigidPolygonTool,
    ],
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
      _textTool,
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
      _perpBisectorTool,
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
      _perpBisectorTool,
      _angleBisectorTool,
    ],
  ),
  ToolCategoryGroup(
    name: 'Circles',
    tools: [_circleCenterTool, _circleThreePointsTool, _circularArcTool],
  ),
  ToolCategoryGroup(
    name: 'Polygons',
    tools: [
      _polygonTool,
      _polyLineTool,
      _polyArcToolEntry,
      _polyArcGonTool,
      _regularPolygonTool,
      _rigidPolygonTool,
      _locusTool,
    ],
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
