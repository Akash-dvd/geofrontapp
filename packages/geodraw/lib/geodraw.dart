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
export 'models/simple/geo_trans.dart';

// Simple geometry object lists
export 'models/simple_lists/geo_intersection.dart';

// Complex geometry objects
export 'models/complex/geo_shapes.dart';

// DAG system
export 'dag/dag_node.dart';
export 'dag/dag_manager.dart';

// UI components
export 'ui/geodraw_canvas.dart';
export 'ui/tool_palette.dart';
export 'ui/object_browser.dart';
export 'ui/unified_prompt_panel.dart'
    hide CommandParser; // Has internal CommandParser helper

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
export 'cli/command_history.dart';

// AI system
export 'ai/ai_service.dart';
export 'ai/ai_adapter.dart';

// Command system (new simplified system)
// Exports: SimpleExecutor, CommandParser, CommandSchema, Verifiers, ObjectResolver
export 'core/command/command.dart';
