import 'package:flutter/material.dart';

import 'tool.dart';
import 'tool_catalog.dart';
import '../core/command/command_history.dart';
import '../core/dag/dag_manager.dart';
import '../models/simple/geo_point.dart';

/// Context passed to tool factories containing all dependencies
class ToolFactoryContext {
  final DAGManager dagManager;
  
  /// Optional command history for CLI/AI logging and replay.
  /// 
  /// This is separate from DAGManager.history:
  /// - DAGManager.history: Tracks geometric state (objects, dependencies) for undo/redo
  /// - CommandHistory: Records command strings (e.g., "point(10, 20)") for CLI replay/AI context
  /// 
  /// Tools can work without this - it's only used for optional logging/recall functionality.
  final CommandHistory? commandHistory;
  
  final OnObjectCreated? onObjectCreated;
  final OnObjectSelected? onObjectSelected;
  final OnToolStateChanged? onToolStateChanged;
  final GeoPointer Function(Offset position)? createFreePoint;
  final dynamic labelGenerator;
  final dynamic onParameterRequest;

  ToolFactoryContext({
    required this.dagManager,
    this.commandHistory,
    this.onObjectCreated,
    this.onObjectSelected,
    this.onToolStateChanged,
    this.createFreePoint,
    this.labelGenerator,
    this.onParameterRequest,
  });
}

/// Factory function type for creating tool instances
typedef ToolFactory = Tool? Function(ToolFactoryContext context);

/// Registry for all tools - provides both creation and metadata
/// This is a singleton that centralizes tool definitions
class ToolRegistry {
  static final ToolRegistry _instance = ToolRegistry._internal();
  factory ToolRegistry() => _instance;
  ToolRegistry._internal();

  final Map<ToolType, ToolFactory> _factories = {};
  final Map<ToolType, ToolCatalogEntry> _metadata = {};

  /// Register a tool with its factory and metadata
  void _register(
    ToolType type,
    ToolFactory factory,
    ToolCatalogEntry metadata,
  ) {
    _factories[type] = factory;
    _metadata[type] = metadata;
  }

  /// Create a tool instance using the provided context
  Tool? createTool(ToolType type, ToolFactoryContext context) {
    final factory = _factories[type];
    if (factory == null) return null;
    return factory(context);
  }

  /// Get catalog entry for a tool type
  ToolCatalogEntry? getCatalogEntry(ToolType type) {
    return _metadata[type];
  }

  /// Get all registered tool types
  List<ToolType> get registeredTypes => _factories.keys.toList();

  /// Check if a tool type is registered
  bool isRegistered(ToolType type) => _factories.containsKey(type);

  /// Get all catalog entries
  List<ToolCatalogEntry> get allCatalogEntries =>
      _metadata.values.toList();

  /// Get available tools (tools that are registered and implemented)
  List<ToolType> get availableTools => _factories.keys
      .where((type) => _metadata[type]?.implemented ?? false)
      .toList();

  /// Check if a tool type is available
  bool isToolAvailable(ToolType type) {
    return _factories.containsKey(type) &&
        (_metadata[type]?.implemented ?? false);
  }

  /// Allow external registration (called by ToolManager during initialization)
  void registerFromManager(
    ToolType type,
    ToolFactory factory,
    ToolCatalogEntry metadata,
  ) {
    _register(type, factory, metadata);
  }
}

