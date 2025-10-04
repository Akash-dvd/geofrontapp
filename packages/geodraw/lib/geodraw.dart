/// GeoDraw - Interactive geometry construction engine for GeoFrontApp
/// 
/// Provides a GeoGebra-like interface for creating, manipulating, and
/// visualizing geometric constructions.
library geodraw;

// Core abstractions
export 'models/canvas_object.dart';
export 'models/geometry_object.dart';

// Simple geometry objects
export 'models/simple/geo_point.dart';
export 'models/simple/geo_line.dart';
export 'models/simple/geo_circle.dart';
export 'models/simple/geo_trans.dart';

// Simple geometry object lists
export 'models/simple_lists/geo_intersection.dart';

// Complex geometry objects
export 'models/complex/geo_shapes.dart';

// DAG system
export 'dag/dag_node.dart';
export 'dag/dag_manager.dart';

// Codec system
export 'codec/json_codec.dart';

// Tools
export 'tools/tool_manager.dart';

// CLI
export 'cli/command_parser.dart';
export 'cli/command_executor.dart';
export 'cli/command_history.dart';

// UI components
export 'ui/geodraw_canvas.dart';
export 'ui/tool_palette.dart';
export 'ui/cli_panel.dart';
export 'ui/object_browser.dart';
export 'ui/ai_panel.dart';

// Codec system
export 'codec/json_codec.dart';
export 'codec/encoder.dart';
export 'codec/decoder.dart';

// Tool system
export 'tools/tool.dart';

// AI system
export 'ai/ai_service.dart';
export 'ai/command_validator.dart';
export 'tools/tool_manager.dart';
export 'tools/point_tool.dart';
export 'tools/line_tool.dart';
export 'tools/circle_tool.dart';

// CLI system
export 'cli/cli.dart';
export 'cli/command_parser.dart';
export 'cli/command_executor.dart';
export 'cli/command_history.dart';
