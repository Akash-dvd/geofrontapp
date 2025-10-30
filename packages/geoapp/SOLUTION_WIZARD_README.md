# Solution Wizard - Step-by-Step Solution Viewer

## Overview

The Solution Wizard transforms the solver solution display from a cluttered scroll view into an elegant, step-by-step wizard interface inspired by presentation software.

## Features

### 🎯 **Wizard-Style Navigation**
- **Page 0**: Problem setup (original canvas)
- **Pages 1-N**: Each solution step gets its own dedicated view
- Navigate with arrow buttons or keyboard

### 🎨 **Beautiful Layout**
- **Canvas (2/3 width)**: Full-size geometry visualization for each step
- **Description Panel (1/3 width)**: Scrollable step explanation
- **Progress Bar**: Visual indicator of current position
- **Step Counter**: "Step X of N" display

### ⚡ **Smart Behavior**
- **Auto-launch**: Wizard opens automatically when solutions arrive
- **Close Button**: Return to normal canvas view
- **Floating Action Button**: Reopen wizard from normal view
- **Keyboard Support**: Navigate with arrow keys

## UI Components

### Header Bar
```
┌─────────────────────────────────────────────────────────┐
│ [×] Step 2                               [←] [→]        │
│     Step 2 of 4  ████████░░░░                           │
└─────────────────────────────────────────────────────────┘
```

### Main Content
```
┌─────────────────────────────────┬─────────────────────┐
│                                 │ [SOLUTION]          │
│                                 │                     │
│         CANVAS                  │ Step 2              │
│     (Geometry Display)          │                     │
│                                 │ Description...      │
│                                 │ (scrollable)        │
│                                 │                     │
│                                 │ Objects: 5          │
│                                 │ Visible: 5          │
└─────────────────────────────────┴─────────────────────┘
```

### Footer
```
┌─────────────────────────────────────────────────────────┐
│        ← Use arrow keys or buttons to navigate →       │
└─────────────────────────────────────────────────────────┘
```

## Usage

### For Users

1. **Create a problem** in the GeoDraw canvas
2. **Send to solver** via the solver service
3. **Wait for solution** from solver.aksharaintelligence.com
4. **Wizard auto-opens** showing step-by-step solution
5. **Navigate** through steps using:
   - Arrow buttons in header
   - Arrow keys on keyboard
   - Swipe gestures (touch devices)

### Integration

The wizard integrates seamlessly into `ProblemFormScreen`:

```dart
// In _CanvasAndSolutions widget
if (hasSolutions && _showWizard) {
  return SolutionWizard(
    problemDagManager: dagManager,
    problemToolManager: toolManager,
    selectedIds: selectedIds,
    onSelectionChanged: onSelectionChanged,
    solutionSteps: solutionSteps,
    onClose: () => setState(() => _showWizard = false),
  );
}
```

## Technical Details

### Step Decoding
Each solution step contains:
- `description`: Text explanation
- `geometry`: Serialized DAG data
- `references`: Related objects

The wizard:
1. Decodes each step's geometry using `GeoDrawDecoder`
2. Creates a separate `DAGManager` for each step
3. Renders independent canvases for isolated visualization

### State Management
- **Page Controller**: Manages PageView navigation
- **Current Page**: Tracks active step
- **Auto-show**: Automatically displays wizard when solutions arrive
- **Persistent Mode**: Can close/reopen wizard without losing data

### Error Handling
- **Missing Geometry**: Shows warning badge
- **Decode Errors**: Falls back to empty canvas with error message
- **Empty Solutions**: Hides wizard, shows normal canvas

## Future Enhancements

- [ ] Animation transitions between steps
- [ ] Diff highlighting (show what changed)
- [ ] Step bookmarking
- [ ] Export solution as PDF/images
- [ ] Side-by-side comparison mode
- [ ] Annotations on each step

## Files Modified

- `packages/geoapp/lib/widgets/solution_wizard.dart` - New wizard implementation
- `packages/geoapp/lib/screens/problem_form_screen.dart` - Integration point
- Auto-imports handled through `geodraw` package

## Dependencies

- **geodraw package**: Canvas, DAG, decoder
- **Flutter Material**: UI components, navigation
- **solver_service**: Solution step data structures

---

**Happy Solving! 🎉**

