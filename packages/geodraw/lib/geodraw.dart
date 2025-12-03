/// GeoDraw - Interactive geometry construction engine for GeoFrontApp
///
/// Provides a GeoGebra-like interface for creating, manipulating, and
/// visualizing geometric constructions.
library;

// Core abstractions
export 'models/canvas_object.dart';
export 'models/geometry_object.dart';
export 'models/text/canvas_text.dart';

// Simple geometry objects
export 'models/simple/geo_point.dart';
export 'models/simple/geo_line.dart';
export 'models/simple/geo_circle.dart';
export 'models/transforms/geo_trans.dart';
export 'models/simple/geo_transformed_simple.dart';

// Simple geometry object lists
export 'models/simple_lists/geo_intersection.dart';
export 'models/simple_lists/geo_tangent.dart';

// Complex geometry objects
export 'models/complex/complex_geometry_object.dart';
export 'models/complex/geo_shapes.dart';
export 'models/complex/geo_shapes_list.dart';
export 'models/complex/geo_transformed_complex.dart';

// DAG system
export 'core/dag/dag_node.dart';
export 'core/dag/dag_manager.dart';

// UI components
export 'ui/geodraw_canvas.dart';
export 'ui/geodraw_side_panel.dart';
export 'ui/tool_palette.dart';
export 'ui/object_browser.dart';
export 'ui/unified_prompt_panel.dart';

// Codec system
export 'codec/json_codec.dart';
export 'codec/encoder.dart';
export 'codec/decoder.dart';

// Tool system
export 'tools/tool.dart';
export 'tools/tool_manager.dart';
export 'tools/unified_tool.dart';

// CLI system (selective exports to avoid conflicts)
export 'cli/cli.dart' hide ExecutionResult;
export 'cli/cli_adapter.dart';

// AI system
export 'ai/ai_service.dart';
export 'ai/ai_adapter.dart';

// Command system (new simplified system)
// Exports: SimpleExecutor, CommandParser, CommandSchema, Verifiers, ObjectResolver
export 'core/command/command.dart';
