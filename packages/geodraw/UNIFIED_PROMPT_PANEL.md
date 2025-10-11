# Unified Prompt Panel - Design Document

## Overview

Created a new unified prompt panel (`unified_prompt_panel.dart`) that combines CLI and AI functionality in a single, space-efficient component at the bottom of the canvas.

## Key Features

### 1. Mode Toggle
- **CLI Mode**: Traditional command-line interface for direct commands
- **AI Mode**: Natural language input for AI-powered construction
- Single button toggle to switch between modes instantly

### 2. Unified Interface
- Single input field that adapts to the selected mode
- Consistent header with mode indicator
- Shared output/result display area
- Clear button to reset the panel

### 3. Space Efficiency
- Fixed height panel at bottom of canvas (default: 200px, configurable)
- Maximizes canvas area for construction work
- Object browser remains on the side for construction hierarchy

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ Canvas (maximized)                                   │
│                                                      │
├─────────────────────────────────────────────────────┤
│ [CLI] [AI]   Clear                    ← Header      │
├─────────────────────────────────────────────────────┤
│                                                      │
│ Output/Results Area                   ← Scrollable  │
│                                                      │
├─────────────────────────────────────────────────────┤
│ > prompt input...            [Send]   ← Input Area  │
└─────────────────────────────────────────────────────┘
```

## Component Breakdown

### Header
```dart
- Mode indicator icon (Terminal/Psychology)
- Toggle buttons: [CLI] [AI]
- Clear button
```

### Output Area (Scrollable)
**CLI Mode:**
- Command history with `> command` format
- Success/error messages with color coding
- Created object IDs

**AI Mode:**
- Generated commands list (numbered)
- Execution log with ✓/✗ markers
- Error messages if generation fails

### Input Area
**CLI Mode:**
- `> ` prompt prefix
- Single-line input
- Enter to execute
- Send button (green terminal icon)

**AI Mode:**
- `✨ ` prompt prefix
- Multi-line input (2 lines)
- Generate button (purple wand icon)
- Execute button (green play icon) - appears after generation

## Usage

### Basic Setup
```dart
UnifiedPromptPanel(
  dagManager: dagManager,
  cliExecutor: cliExecutor,        // Optional
  aiService: aiService,             // Optional
  aiAdapter: aiAdapter,             // Optional
  onConstructionComplete: () {
    // Callback when construction finishes
  },
  height: 200,                      // Optional, default 200
)
```

### Integration Example
```dart
Column(
  children: [
    Expanded(
      child: Row(
        children: [
          Expanded(child: GeoDrawCanvas(...)),
          ObjectBrowser(...),  // Side panel
        ],
      ),
    ),
    UnifiedPromptPanel(...),  // Bottom panel
  ],
)
```

## Benefits

### 1. **Maximized Canvas Space**
- Canvas gets full height minus the compact prompt panel
- No large side panels eating canvas width
- Object browser remains visible for construction hierarchy

### 2. **Seamless Mode Switching**
- One-click toggle between CLI and AI
- No UI reorganization needed
- Input focus maintained across switches

### 3. **Consistent UX**
- Same interface style (dark theme)
- Same interaction patterns
- Unified keyboard shortcuts (Enter to execute in CLI)

### 4. **Simpler Layout**
- Single unified component instead of separate CLI/AI panels
- Easier to position and resize
- Less prop drilling

### 5. **Flexible Configuration**
- Can use CLI only (set aiService=null)
- Can use AI only (set cliExecutor=null)
- Can use both
- Adjustable height

## Implementation Details

### State Management
```dart
- _mode: PromptMode.cli | PromptMode.ai
- _cliOutput: List<String> for CLI history
- _generatedCommands: List<String>? for AI commands
- _executionLog: List<String> for execution results
- _isLoadingAI: bool for AI generation state
- _isExecuting: bool for command execution state
```

### Internal CommandParser
The panel includes a lightweight internal `CommandParser` for CLI mode parsing. This is hidden from the public export to avoid conflicts with the main `CommandParser` from the command system.

```dart
// Internal helper - not exported
class CommandParser {
  Command? parse(String input) { ... }
}
```

### Color Scheme
- **Background**: Dark grey (#212121 / grey[900])
- **Header**: Darker grey (#303030 / grey[850])
- **CLI Mode**: Green accents (#66BB6A / green[400])
- **AI Mode**: Purple accents (#BA68C8 / purple[300])
- **Success**: Green text (#81C784 / green[300])
- **Error**: Red text (#E57373 / red[300])
- **Normal Text**: Light grey (#E0E0E0 / grey[300])

## Migration Guide

### From Separate CLI/AI Panels

**Before:**
```dart
Column(
  children: [
    if (showCLI) CLIPanel(...),
    if (showAI) AIPanel(...),
  ],
)
```

**After:**
```dart
UnifiedPromptPanel(
  cliExecutor: cliExecutor,
  aiService: aiService,
  aiAdapter: aiAdapter,
  // Toggle handled internally!
)
```

### Benefits of Migration
1. Remove toggle state management from parent
2. No conditional rendering logic needed
3. Single component to position
4. Consistent height (no layout jumps)

## Future Enhancements

Potential additions:
1. **Command History Navigation**: Up/down arrows in CLI mode
2. **Autocomplete**: Suggest commands as you type
3. **Syntax Highlighting**: Color code commands in AI results
4. **Save/Load**: Save command sequences
5. **Keyboard Shortcuts**: Ctrl+Enter for AI, Enter for CLI, Tab to toggle modes
6. **Resizable Height**: Drag handle to adjust panel height
7. **Collapsible**: Minimize to single line for maximum canvas space

## File Location
```
packages/geodraw/lib/ui/unified_prompt_panel.dart
```

## Export
```dart
// In geodraw.dart
export 'ui/unified_prompt_panel.dart' hide CommandParser;
```

The `CommandParser` class inside the panel is hidden to avoid conflict with the main command system's `CommandParser`.
