import 'package:flutter/material.dart';
import 'package:geodraw/geodraw.dart';

import '../config/env_config.dart';
import '../models/problem.dart';

/// Service for navigating to GeoDraw functionality
/// Follows constitutional requirement for clear API boundaries
class GeoDrawNavigationService {
  /// Navigate to GeoDraw for creating a new problem
  static Future<String?> navigateToCreate(
    BuildContext context,
  ) async {
    return await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (context) => const GeoDrawCreateScreen()),
    );
  }

  /// Navigate to GeoDraw for editing an existing problem
  static Future<String?> navigateToEdit(
    BuildContext context,
    Problem problem,
  ) async {
    return await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (context) => GeoDrawEditScreen(problem: problem),
      ),
    );
  }

  /// Navigate to GeoDraw for viewing a problem (read-only)
  static Future<void> navigateToView(
    BuildContext context,
    Problem problem,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GeoDrawViewScreen(problem: problem),
      ),
    );
  }
}

/// Screen for GeoDraw creation functionality
class GeoDrawCreateScreen extends StatefulWidget {
  const GeoDrawCreateScreen({super.key});

  @override
  State<GeoDrawCreateScreen> createState() => _GeoDrawCreateScreenState();
}

class _GeoDrawCreateScreenState extends State<GeoDrawCreateScreen> {
  late DAGManager _dagManager;
  late ToolManager _toolManager;
  late UnifiedCLIExecutor _commandExecutor;
  late AIService _aiService;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _dagManager = DAGManager();
    _toolManager = ToolManager(
      dagManager: _dagManager,
      onObjectCreated: (object, deps) {
        // Trigger rebuild when tool creates object
        setState(() {});
      },
      onToolStateChanged: (state) {
        // Could update UI with tool state
        setState(() {});
      },
    );
    _commandExecutor = UnifiedCLIExecutor(dagManager: _dagManager);
    _aiService = AIService(
      config: AIServiceConfig.production(EnvConfig.edgeLlmEndpoint),
    );
  }

  void _handleSave() {
    // Export construction to JSON using GeoDrawEncoder
    final encoder = GeoDrawEncoder();
    final geometryData = encoder.encodeForStorage(
      _dagManager,
      base64: false,
      pretty: false,
    );
    Navigator.of(context).pop(geometryData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoDraw - Create'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save construction',
            onPressed: _handleSave,
          ),
        ],
      ),
      body: Row(
        children: [
          // Tool Palette
          ToolPalette(
            toolManager: _toolManager,
            onToolSelected: (toolType) {
              setState(() {
                _toolManager.selectTool(toolType);
              });
            },
          ),
          // Main content area (Canvas only)
          Expanded(
            child: GeoDrawCanvas(
              dagManager: _dagManager,
              toolManager: _toolManager,
              selectedIds: _selectedIds,
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedIds.clear();
                  _selectedIds.addAll(newSelection);
                });
              },
              showGrid: true,
            ),
          ),
          // Right sidebar: Object Browser + Unified Prompt (like chat)
          SizedBox(
            width: 300,
            child: Column(
              children: [
                // Object Browser - DAG elements list (history at top)
                Expanded(
                  child: ObjectBrowser(
                    dagManager: _dagManager,
                    selectedIds: _selectedIds,
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedIds.clear();
                        _selectedIds.addAll(newSelection);
                      });
                    },
                  ),
                ),
                // Unified Prompt Panel - CLI/AI input (prompt at bottom)
                UnifiedPromptPanel(
                  dagManager: _dagManager,
                  cliExecutor: _commandExecutor,
                  aiService: _aiService,
                  aiAdapter: AIAdapter(dagManager: _dagManager),
                  onConstructionComplete: () => setState(() {}),
                  height: 180,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen for GeoDraw editing functionality
class GeoDrawEditScreen extends StatefulWidget {
  const GeoDrawEditScreen({super.key, required this.problem});

  final Problem problem;

  @override
  State<GeoDrawEditScreen> createState() => _GeoDrawEditScreenState();
}

class _GeoDrawEditScreenState extends State<GeoDrawEditScreen> {
  late DAGManager _dagManager;
  late ToolManager _toolManager;
  late UnifiedCLIExecutor _commandExecutor;
  late AIService _aiService;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();

    // Load existing geometry data if available
    if (widget.problem.geometryData != null) {
      try {
        final decoder = GeoDrawDecoder();
        _dagManager = decoder.decodeFromStorage(
          widget.problem.geometryData!,
        );
      } catch (e) {
        // If decoding fails, start with empty canvas
        debugPrint('Failed to load geometry data: $e');
        _dagManager = DAGManager();
      }
    } else {
      _dagManager = DAGManager();
    }

    _toolManager = ToolManager(
      dagManager: _dagManager,
      onObjectCreated: (object, deps) {
        setState(() {});
      },
      onToolStateChanged: (state) {
        setState(() {});
      },
    );
    _commandExecutor = UnifiedCLIExecutor(dagManager: _dagManager);
    _aiService = AIService(
      config: AIServiceConfig.production(EnvConfig.edgeLlmEndpoint),
    );
  }

  void _handleSave() {
    // Export construction to JSON
    final encoder = GeoDrawEncoder();
    final geometryData = encoder.encodeForStorage(
      _dagManager,
      base64: false,
      pretty: false,
    );
    Navigator.of(context).pop(geometryData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${widget.problem.title}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save changes',
            onPressed: _handleSave,
          ),
        ],
      ),
      body: Row(
        children: [
          // Tool Palette
          ToolPalette(
            toolManager: _toolManager,
            onToolSelected: (toolType) {
              setState(() {
                _toolManager.selectTool(toolType);
              });
            },
          ),
          // Main content area (Canvas only)
          Expanded(
            child: GeoDrawCanvas(
              dagManager: _dagManager,
              toolManager: _toolManager,
              selectedIds: _selectedIds,
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedIds.clear();
                  _selectedIds.addAll(newSelection);
                });
              },
              showGrid: true,
            ),
          ),
          // Right sidebar: Object Browser + Unified Prompt (like chat)
          SizedBox(
            width: 300,
            child: Column(
              children: [
                // Object Browser - DAG elements list (history at top)
                Expanded(
                  child: ObjectBrowser(
                    dagManager: _dagManager,
                    selectedIds: _selectedIds,
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedIds.clear();
                        _selectedIds.addAll(newSelection);
                      });
                    },
                  ),
                ),
                // Unified Prompt Panel - CLI/AI input (prompt at bottom)
                UnifiedPromptPanel(
                  dagManager: _dagManager,
                  cliExecutor: _commandExecutor,
                  aiService: _aiService,
                  aiAdapter: AIAdapter(dagManager: _dagManager),
                  onConstructionComplete: () => setState(() {}),
                  height: 180,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen for GeoDraw viewing functionality (read-only)
class GeoDrawViewScreen extends StatefulWidget {
  const GeoDrawViewScreen({super.key, required this.problem});

  final Problem problem;

  @override
  State<GeoDrawViewScreen> createState() => _GeoDrawViewScreenState();
}

class _GeoDrawViewScreenState extends State<GeoDrawViewScreen> {
  late DAGManager _dagManager;
  late ToolManager _toolManager;

  @override
  void initState() {
    super.initState();

    // Load existing geometry data if available
    if (widget.problem.geometryData != null) {
      try {
        final decoder = GeoDrawDecoder();
        _dagManager = decoder.decodeFromStorage(
          widget.problem.geometryData!,
        );
      } catch (e) {
        debugPrint('Failed to load geometry data: $e');
        _dagManager = DAGManager();
      }
    } else {
      _dagManager = DAGManager();
    }

    // Create tool manager but don't allow tool selection in view mode
    _toolManager = ToolManager(
      dagManager: _dagManager,
      onObjectCreated: (object, deps) {
        setState(() {});
      },
      onToolStateChanged: (state) {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View: ${widget.problem.title}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Row(
        children: [
          // Main content area (Canvas only, no prompts in view mode)
          Expanded(
            child: GeoDrawCanvas(
              dagManager: _dagManager,
              toolManager: _toolManager,
              selectedIds: const {},
              onSelectionChanged: null, // Read-only mode
              showGrid: true,
            ),
          ),
          // Object Browser (read-only)
          SizedBox(
            width: 250,
            child: ObjectBrowser(
              dagManager: _dagManager,
              selectedIds: const {},
              onSelectionChanged: null, // Read-only mode
            ),
          ),
        ],
      ),
    );
  }
}
