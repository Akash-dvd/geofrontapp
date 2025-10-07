import 'package:flutter/material.dart';
import 'package:geodraw/geodraw.dart';

/// Complete GeoDraw UI demo application showcasing all features
void main() {
  runApp(const GeoDrawUIDemo());
}

class GeoDrawUIDemo extends StatelessWidget {
  const GeoDrawUIDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoDraw UI Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GeoDrawWorkspace(),
    );
  }
}

class GeoDrawWorkspace extends StatefulWidget {
  const GeoDrawWorkspace({super.key});

  @override
  State<GeoDrawWorkspace> createState() => _GeoDrawWorkspaceState();
}

class _GeoDrawWorkspaceState extends State<GeoDrawWorkspace> {
  late DAGManager _dagManager;
  late ToolManager _toolManager;
  late CommandExecutor _commandExecutor;
  late AIService _aiService;
  Set<String> _selectedIds = {};
  bool _showCLI = false;
  bool _showAI = false;
  bool _showBrowser = true;

  @override
  void initState() {
    super.initState();
    _dagManager = DAGManager();
    _toolManager = ToolManager(dagManager: _dagManager);
    _commandExecutor = CommandExecutor();
    _aiService = AIService(config: AIServiceConfig.development());
    
    // Create initial construction
    _createInitialConstruction();
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }

  void _createInitialConstruction() {
    // Create three points forming a triangle
    final p1 = GeoPointer(id: 'A', label: 'A', x: -100, y: -50, color: Colors.red);
    final p2 = GeoPointer(id: 'B', label: 'B', x: 100, y: -50, color: Colors.red);
    final p3 = GeoPointer(id: 'C', label: 'C', x: 0, y: 100, color: Colors.red);

    _dagManager.addObject(p1, []);
    _dagManager.addObject(p2, []);
    _dagManager.addObject(p3, []);

    // Create lines
    final line1 = GeoLine2P.fromPoints(
      id: 'AB',
      label: 'AB',
      p1: p1,
      p2: p2,
      color: Colors.blue,
    );
    final line2 = GeoLine2P.fromPoints(
      id: 'BC',
      label: 'BC',
      p1: p2,
      p2: p3,
      color: Colors.blue,
    );
    final line3 = GeoLine2P.fromPoints(
      id: 'CA',
      label: 'CA',
      p1: p3,
      p2: p1,
      color: Colors.blue,
    );

    _dagManager.addObject(line1, ['A', 'B']);
    _dagManager.addObject(line2, ['B', 'C']);
    _dagManager.addObject(line3, ['C', 'A']);

    _dagManager.propagateUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoDraw UI Demo'),
        actions: [
          IconButton(
            icon: Icon(_showBrowser ? Icons.chevron_right : Icons.chevron_left),
            tooltip: _showBrowser ? 'Hide Browser' : 'Show Browser',
            onPressed: () {
              setState(() {
                _showBrowser = !_showBrowser;
              });
            },
          ),
          IconButton(
            icon: Icon(_showCLI ? Icons.terminal : Icons.code),
            tooltip: _showCLI ? 'Hide CLI' : 'Show CLI',
            onPressed: () {
              setState(() {
                _showCLI = !_showCLI;
                if (_showCLI) _showAI = false; // Only one panel at a time
              });
            },
          ),
          IconButton(
            icon: Icon(_showAI ? Icons.psychology : Icons.auto_fix_high),
            tooltip: _showAI ? 'Hide AI' : 'Show AI',
            onPressed: () {
              setState(() {
                _showAI = !_showAI;
                if (_showAI) _showCLI = false; // Only one panel at a time
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Export JSON',
            onPressed: _exportJSON,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: () {
              setState(() {
                _dagManager.clear();
                _selectedIds.clear();
                _createInitialConstruction();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tool palette
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(
                bottom: BorderSide(color: Colors.grey[400]!),
              ),
            ),
            child: Row(
              children: [
                ToolPalette(
                  toolManager: _toolManager,
                  direction: Axis.horizontal,
                  onToolSelected: (tool) {
                    setState(() {
                      _toolManager.selectTool(tool);
                      _selectedIds.clear();
                    });
                  },
                ),
                const Spacer(),
                Text(
                  'Active Tool: ${_toolManager.activeTool.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Main workspace
          Expanded(
            child: Row(
              children: [
                // Canvas
                Expanded(
                  child: GeoDrawCanvas(
                    dagManager: _dagManager,
                    toolManager: _toolManager,
                    selectedIds: _selectedIds,
                    onSelectionChanged: (ids) {
                      setState(() {
                        _selectedIds = ids;
                      });
                    },
                  ),
                ),

                // Object browser
                if (_showBrowser)
                  ObjectBrowser(
                    dagManager: _dagManager,
                    selectedIds: _selectedIds,
                    onSelectionChanged: (ids) {
                      setState(() {
                        _selectedIds = ids;
                      });
                    },
                    onDeleteRequested: (id) {
                      _showDeleteDialog(id);
                    },
                  ),
              ],
            ),
          ),

          // CLI panel
          if (_showCLI)
            CLIPanel(
              dagManager: _dagManager,
              commandExecutor: _commandExecutor,
            ),

          // AI panel
          if (_showAI)
            Container(
              height: 400,
              padding: const EdgeInsets.all(8),
              child: AIPanel(
                aiService: _aiService,
                commandExecutor: _commandExecutor,
                dagManager: _dagManager,
                onConstructionComplete: () {
                  setState(() {}); // Refresh UI
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Show Help',
        onPressed: _showHelpDialog,
        child: const Icon(Icons.help_outline),
      ),
    );
  }

  void _exportJSON() {
    final codec = GeoDrawCodec();
    final json = codec.encode(_dagManager);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export JSON'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              json.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String id) {
    final node = _dagManager.getNode(id);
    if (node == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Object'),
        content: Text(
          'Delete ${node.object.label} (${node.id})?\n\n'
          '${node.hasChildren ? "Warning: This object has ${node.childIds.length} dependent(s)." : ""}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _dagManager.deleteObject(id, cascade: true);
                _selectedIds.remove(id);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tools:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Select: Click to select objects'),
                Text('• Pan: Drag to move the viewport'),
                Text('• Point: Click to create free points'),
                Text('• Line: Click two points to create a line'),
                Text('• Circle: Click center then radius point'),
                SizedBox(height: 16),
                Text('Commands:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• point(x, y, label)'),
                Text('• line(p1, p2, label)'),
                Text('• circle(center, point, label)'),
                Text('• midpoint(p1, p2, label)'),
                SizedBox(height: 16),
                Text('AI Construction:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Click AI button to open natural language panel'),
                Text('• Describe your construction in plain English'),
                Text('• AI will generate and validate commands'),
                Text('• Review and execute the construction'),
                SizedBox(height: 16),
                Text('Controls:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Mouse wheel: Zoom in/out'),
                Text('• Drag: Pan or move objects'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
