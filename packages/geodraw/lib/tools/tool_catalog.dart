import 'package:flutter/material.dart';

import 'tool.dart';
import 'tool_registry.dart';

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

/// Internal structure for defining tool groups by ToolType (before registry lookup)
class _ToolGroupDefinition {
  final String name;
  final List<ToolType> toolTypes;
  final List<ToolCatalogEntry> placeholders;

  const _ToolGroupDefinition({
    required this.name,
    this.toolTypes = const [],
    this.placeholders = const [],
  });
}

/// Palette tiers inspired by GeoGebra layouts.
enum ToolPaletteLevel { level1, level2, level3 }

// Placeholder entries for non-implemented tools (those without ToolType)
// Implemented tools are defined in ToolRegistry and queried dynamically
const ToolCatalogEntry _eraserTool = ToolCatalogEntry(
  id: 'eraser',
  label: 'Eraser',
  icon: Icons.auto_fix_off,
  assetIcon: 'assets/tool_icons/delete.svg',
  command: 'Delete[]',
  implemented: false,
);

const ToolCatalogEntry _deleteTool = ToolCatalogEntry(
  id: 'delete',
  label: 'Delete',
  icon: Icons.delete_outline,
  assetIcon: 'assets/tool_icons/delete.svg',
  command: 'Delete[]',
  implemented: false,
);

const ToolCatalogEntry _copyTool = ToolCatalogEntry(
  id: 'copy',
  label: 'Copy',
  icon: Icons.copy,
  command: 'Copy[]',
  implemented: false,
);

const ToolCatalogEntry _redefineTool = ToolCatalogEntry(
  id: 'redefine',
  label: 'Redefine',
  icon: Icons.edit_note,
  command: 'Redefine[]',
  implemented: false,
);

// All construction tools are registered in ToolRegistry

const ToolCatalogEntry _distanceTool = ToolCatalogEntry(
  id: 'distance',
  label: 'Distance',
  icon: Icons.straighten,
  command: 'Distance[]',
  implemented: false,
);

const ToolCatalogEntry _angleMeasureTool = ToolCatalogEntry(
  id: 'angle_measure',
  label: 'Angle',
  icon: Icons.rotate_right,
  assetIcon: 'assets/tool_icons/angle.svg',
  command: 'Angle[]',
  implemented: false,
);

const ToolCatalogEntry _areaTool = ToolCatalogEntry(
  id: 'area',
  label: 'Area',
  icon: Icons.crop_square,
  assetIcon: 'assets/tool_icons/area.svg',
  command: 'Area[]',
  implemented: false,
);

const ToolCatalogEntry _slopeTool = ToolCatalogEntry(
  id: 'slope',
  label: 'Slope',
  icon: Icons.trending_up,
  command: 'Slope[]',
  implemented: false,
);

const ToolCatalogEntry _rayTool = ToolCatalogEntry(
  id: 'ray',
  label: 'Ray',
  icon: Icons.linear_scale,
  assetIcon: 'assets/tool_icons/ray.svg',
  command: 'Ray[]',
  implemented: false,
);

const ToolCatalogEntry _vectorTool = ToolCatalogEntry(
  id: 'vector',
  label: 'Vector',
  icon: Icons.arrow_forward,
  assetIcon: 'assets/tool_icons/polar.svg',
  command: 'Vector[]',
  implemented: false,
);

// All circle/arc tools are registered in ToolRegistry

const ToolCatalogEntry _regularPolygonTool = ToolCatalogEntry(
  id: 'regular_polygon',
  label: 'Regular Polygon',
  icon: Icons.all_inclusive,
  assetIcon: 'assets/tool_icons/regular_Polygon.svg',
  command: 'RegularPolygon[]',
  implemented: false,
);

const ToolCatalogEntry _rigidPolygonTool = ToolCatalogEntry(
  id: 'rigid_polygon',
  label: 'Rigid Polygon',
  icon: Icons.category,
  command: 'RigidPolygon[]',
  implemented: false,
);

// All transformation tools are registered in ToolRegistry

const ToolCatalogEntry _locusTool = ToolCatalogEntry(
  id: 'locus',
  label: 'Locus',
  icon: Icons.timeline,
  command: 'Locus[]',
  implemented: false,
);

// Intersection tool is registered in ToolRegistry

const ToolCatalogEntry _pointOnObjectTool = ToolCatalogEntry(
  id: 'point_on_object',
  label: 'Point on Object',
  icon: Icons.my_location,
  assetIcon: 'assets/tool_icons/point_on_object.svg',
  command: 'PointOn[]',
  implemented: false,
);

const ToolCatalogEntry _attachPointTool = ToolCatalogEntry(
  id: 'attach_point',
  label: 'Attach/Detach',
  icon: Icons.link,
  assetIcon: 'assets/tool_icons/attach_detach.svg',
  command: 'AttachCopyToView[]',
  implemented: false,
);

const ToolCatalogEntry _ellipseTool = ToolCatalogEntry(
  id: 'ellipse',
  label: 'Ellipse',
  icon: Icons.tonality,
  command: 'Ellipse[]',
  implemented: false,
);

const ToolCatalogEntry _hyperbolaTool = ToolCatalogEntry(
  id: 'hyperbola',
  label: 'Hyperbola',
  icon: Icons.leak_add,
  command: 'Hyperbola[]',
  implemented: false,
);

const ToolCatalogEntry _parabolaTool = ToolCatalogEntry(
  id: 'parabola',
  label: 'Parabola',
  icon: Icons.stacked_line_chart,
  command: 'Parabola[]',
  implemented: false,
);

const ToolCatalogEntry _conicTool = ToolCatalogEntry(
  id: 'conic',
  label: 'Conic (5 Points)',
  icon: Icons.blur_circular,
  command: 'Conic[]',
  implemented: false,
);

const ToolCatalogEntry _shearTool = ToolCatalogEntry(
  id: 'shear',
  label: 'Shear',
  icon: Icons.swap_horiz,
  command: 'Shear[]',
  implemented: false,
);

const ToolCatalogEntry _stretchTool = ToolCatalogEntry(
  id: 'stretch',
  label: 'Stretch',
  icon: Icons.unfold_more,
  command: 'Stretch[]',
  implemented: false,
);

const ToolCatalogEntry _invertTool = ToolCatalogEntry(
  id: 'invert',
  label: 'Invert',
  icon: Icons.blur_on,
  assetIcon: 'assets/tool_icons/inversion.svg',
  command: 'Invert[]',
  implemented: false,
);

const ToolCatalogEntry _bestFitLineTool = ToolCatalogEntry(
  id: 'best_fit',
  label: 'Best Fit Line',
  icon: Icons.trending_flat,
  command: 'FitLine[]',
  implemented: false,
);

const ToolCatalogEntry _traceTool = ToolCatalogEntry(
  id: 'trace',
  label: 'Trace',
  icon: Icons.brush,
  command: 'Trace[]',
  implemented: false,
);

const ToolCatalogEntry _relationTool = ToolCatalogEntry(
  id: 'relation',
  label: 'Relation',
  icon: Icons.device_hub,
  command: 'Relation[]',
  implemented: false,
);

const ToolCatalogEntry _mirrorCurveTool = ToolCatalogEntry(
  id: 'mirror_curve',
  label: 'Mirror Curve',
  icon: Icons.multiline_chart,
  command: 'MirrorCurve[]',
  implemented: false,
);

// Group definitions using ToolType references - entries built from registry
const List<_ToolGroupDefinition> _level1GroupDefinitions = [
  _ToolGroupDefinition(
    name: 'Basic Tools',
    toolTypes: [
      ToolType.select,
      ToolType.point,
      ToolType.lineSegment,
      ToolType.line,
      ToolType.polygon,
      ToolType.polyArc,
      ToolType.circle,
    ],
    placeholders: [_eraserTool],
  ),
];

const List<_ToolGroupDefinition> _level2GroupDefinitions = [
  _ToolGroupDefinition(
    name: 'Basic Tools',
    toolTypes: [
      ToolType.select,
      ToolType.pan,
      ToolType.point,
      ToolType.lineSegment,
      ToolType.line,
      ToolType.polygon,
      ToolType.polyArc,
      ToolType.circle,
    ],
    placeholders: [_eraserTool],
  ),
  _ToolGroupDefinition(
    name: 'Edit Tools',
    toolTypes: [ToolType.select],
    placeholders: [_deleteTool, _copyTool, _redefineTool],
  ),
  _ToolGroupDefinition(
    name: 'Construct Tools',
    toolTypes: [
      ToolType.perpendicular,
      ToolType.parallel,
      ToolType.perpBisector,
      ToolType.angleBisector,
      ToolType.midpoint,
      ToolType.tangent,
      ToolType.incircle,
      ToolType.excircle,
      ToolType.orthocenter,
      ToolType.tangents,
      ToolType.polar,
      ToolType.icircle,
    ],
  ),
  _ToolGroupDefinition(
    name: 'Measure Tools',
    placeholders: [_distanceTool, _angleMeasureTool, _areaTool, _slopeTool],
  ),
  _ToolGroupDefinition(
    name: 'Lines & Segments',
    toolTypes: [ToolType.line, ToolType.lineSegment],
    placeholders: [_rayTool, _vectorTool],
  ),
  _ToolGroupDefinition(
    name: 'Circles & Arcs',
    toolTypes: [
      ToolType.circle,
      ToolType.circleThreePoints,
      ToolType.arcThreePoints,
      ToolType.incircle,
      ToolType.excircle,
      ToolType.icircle,
    ],
  ),
  _ToolGroupDefinition(
    name: 'Polygons',
    toolTypes: [
      ToolType.polygon,
      ToolType.polyLine,
      ToolType.polyArc,
      ToolType.polyArcGon,
    ],
    placeholders: [_regularPolygonTool, _rigidPolygonTool],
  ),
  _ToolGroupDefinition(
    name: 'Transformations',
    toolTypes: [
      ToolType.reflectLine,
      ToolType.rotate,
      ToolType.translate,
      ToolType.dilate,
    ],
  ),
];

const List<_ToolGroupDefinition> _level3GroupDefinitions = [
  _ToolGroupDefinition(
    name: 'Basic Tools',
    toolTypes: [
      ToolType.select,
      ToolType.point,
      ToolType.lineSegment,
      ToolType.line,
      ToolType.polygon,
      ToolType.circle,
    ],
  ),
  _ToolGroupDefinition(
    name: 'Edit Tools',
    toolTypes: [ToolType.select],
    placeholders: [_deleteTool, _redefineTool, _copyTool],
  ),
  _ToolGroupDefinition(
    name: 'Construct Tools',
    toolTypes: [
      ToolType.midpoint,
      ToolType.center,
      ToolType.intersection,
      ToolType.perpendicular,
      ToolType.parallel,
      ToolType.perpBisector,
      ToolType.tangent,
      ToolType.incircle,
      ToolType.excircle,
      ToolType.orthocenter,
      ToolType.tangents,
      ToolType.polar,
      ToolType.alcbc,
    ],
    placeholders: [_locusTool],
  ),
  _ToolGroupDefinition(
    name: 'Measure Tools',
    placeholders: [_distanceTool, _angleMeasureTool, _areaTool, _slopeTool],
  ),
  _ToolGroupDefinition(
    name: 'Points',
    toolTypes: [
      ToolType.point,
      ToolType.intersection,
      ToolType.midpoint,
      ToolType.center,
      ToolType.orthocenter,
    ],
    placeholders: [_pointOnObjectTool, _attachPointTool],
  ),
  _ToolGroupDefinition(
    name: 'Lines',
    toolTypes: [
      ToolType.line,
      ToolType.lineSegment,
      ToolType.perpendicular,
      ToolType.parallel,
      ToolType.perpBisector,
      ToolType.angleBisector,
      // L3 Flexible commands
      ToolType.lineFlex,
      ToolType.perpendicularFlex,
      ToolType.parallelFlex,
      ToolType.perpbisectorFlex,
      // Advanced line tools
      ToolType.tangents,
      ToolType.polar,
    ],
    placeholders: [_rayTool, _vectorTool],
  ),
  _ToolGroupDefinition(
    name: 'Circles',
    toolTypes: [
      ToolType.circle,
      ToolType.circleThreePoints,
      ToolType.arcThreePoints,
      ToolType.center,
      // L3 Flexible commands
      ToolType.circleFlex,
      ToolType.circle3Flex,
      // Triangle construction
      ToolType.incircle,
      ToolType.excircle,
      // Imaginary circle
      ToolType.icircle,
    ],
  ),
  _ToolGroupDefinition(
    name: 'Polygons',
    toolTypes: [
      ToolType.polygon,
      ToolType.polyLine,
      ToolType.polyArc,
      ToolType.polyArcGon,
    ],
    placeholders: [_regularPolygonTool, _rigidPolygonTool, _locusTool],
  ),
  _ToolGroupDefinition(
    name: 'Conics',
    placeholders: [_conicTool, _ellipseTool, _parabolaTool, _hyperbolaTool],
  ),
  _ToolGroupDefinition(
    name: 'Transformations',
    toolTypes: [
      ToolType.reflectLine,
      ToolType.reflectPoint,
      ToolType.reflectCircle,
      ToolType.rotate,
      ToolType.translate,
      ToolType.dilate,
    ],
    placeholders: [_shearTool, _stretchTool, _invertTool],
  ),
  _ToolGroupDefinition(
    name: 'Other / Advanced',
    toolTypes: [
      ToolType.alcbc,
    ],
    placeholders: [
      _locusTool,
      _mirrorCurveTool,
      _traceTool,
      _relationTool,
      _bestFitLineTool,
    ],
  ),
];

const Map<ToolPaletteLevel, List<_ToolGroupDefinition>> _toolPaletteDefinitions =
    {
  ToolPaletteLevel.level1: _level1GroupDefinitions,
  ToolPaletteLevel.level2: _level2GroupDefinitions,
  ToolPaletteLevel.level3: _level3GroupDefinitions,
};

/// Get tool groups for a level, building entries from registry
List<ToolCategoryGroup> toolGroupsForLevel(ToolPaletteLevel level) {
  final registry = ToolRegistry();
  final definitions = _toolPaletteDefinitions[level] ?? const [];

  return definitions.map((def) {
    final tools = <ToolCatalogEntry>[];

    // Add entries from registry for implemented tools
    for (final toolType in def.toolTypes) {
      final entry = registry.getCatalogEntry(toolType);
      if (entry != null) {
        tools.add(entry);
      }
    }

    // Add placeholder entries for non-implemented tools
    tools.addAll(def.placeholders);

    return ToolCategoryGroup(name: def.name, tools: tools);
  }).toList();
}
