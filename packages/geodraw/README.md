# GeoDraw

Interactive geometry construction engine for GeoFrontApp.

## Overview

GeoDraw provides a GeoGebra-like interface for creating, manipulating, and visualizing geometric constructions through multiple input methods:

- **Interactive Tools**: Point-and-click interface for geometric construction
- **Command-Line Interface**: Programmatic construction via text commands
- **AI-Powered NLP**: Natural language processing for intuitive construction

## Features

- Complete object hierarchy (points, lines, circles, polygons)
- Dependency tracking via DAG (Directed Acyclic Graph)
- JSON codec for serialization/deserialization
- Undo/redo functionality
- Multi-modal input (tools, CLI, AI)
- Canvas rendering with viewport controls

## Architecture

See [GeoDraw Specification](../../.spec-kit/memory/specifications/geodraw.md) for detailed architecture and design decisions.

## Usage

### Basic Geometry Construction

```dart
import 'package:geodraw/geodraw.dart';

// Create a DAG manager
final dagManager = DAGManager();

// Create points
final p1 = GeoPointer(x: 0, y: 0, label: 'A');
final p2 = GeoPointer(x: 5, y: 0, label: 'B');

// Add to DAG
final id1 = dagManager.addObject(p1, []);
final id2 = dagManager.addObject(p2, []);

// Create line through points
final line = GeoLine2P(label: 'AB');
dagManager.addObject(line, [id1, id2]);

// Propagate updates
dagManager.propagateUpdates();
```

### AI-Powered Construction

```dart
import 'package:geodraw/geodraw.dart';

// Setup AI service
final aiService = AIService(
  config: AIServiceConfig.development(),
);

// Generate commands from natural language
final response = await aiService.generateCommands(
  'Draw an equilateral triangle with side length 5',
);

if (response.isSuccess) {
  // Validate commands
  final validator = CommandValidator();
  final validation = validator.validate(response.commands!);
  
  if (validation.isValid) {
    // Execute commands
    final executor = CommandExecutor();
    for (final command in validation.validCommands) {
      await executor.execute(command);
    }
  }
}
```

### UI Integration

```dart
import 'package:flutter/material.dart';
import 'package:geodraw/geodraw.dart';

class MyGeometryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dagManager = DAGManager();
    final toolManager = ToolManager(dagManager: dagManager);
    final aiService = AIService(config: AIServiceConfig.development());
    final commandExecutor = CommandExecutor();
    
    return Scaffold(
      body: Column(
        children: [
          // Tool palette
          ToolPalette(
            toolManager: toolManager,
            onToolSelected: (tool) => toolManager.selectTool(tool),
          ),
          
          // Canvas
          Expanded(
            child: GeoDrawCanvas(
              dagManager: dagManager,
              toolManager: toolManager,
            ),
          ),
          
          // AI Panel
          AIPanel(
            aiService: aiService,
            commandExecutor: commandExecutor,
            dagManager: dagManager,
          ),
        ],
      ),
    );
  }
}
```

## Testing

Run all tests:

```bash
flutter test
```

Current test coverage: **69 tests passing**

## License

Private package for GeoFrontApp
