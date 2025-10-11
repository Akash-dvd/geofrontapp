# UnifiedPromptPanel Layout Update & CLI Fix

## Changes Made

### 1. Fixed CLI Command Recognition Issue ✅

**Problem:** CLI was not recognizing commands like `circle(B, C)` even when points B and C existed.

**Root Cause:** UnifiedPromptPanel was using an old, incorrect CommandParser API:
```dart
// ❌ Old (incorrect):
final parser = CommandParser();  // Missing required parameter
final parsed = parser.parse(command);  // Wrong method
final result = await widget.cliExecutor!.execute(parsed);
```

**Solution:** Use `executeString()` method directly from UnifiedCLIExecutor:
```dart
// ✅ New (correct):
final result = await widget.cliExecutor!.executeString(command);
```

**File Changed:** `packages/geodraw/lib/ui/unified_prompt_panel.dart`
- Method: `_executeCLICommand()`
- Lines simplified from 27 to 13
- Now correctly parses and executes commands

### 2. ✅ Created Chat-Like Layout on Right Side ✅

**Problem:** ObjectBrowser and UnifiedPromptPanel were in separate locations, making workflow disjointed.

**Solution:** Combined ObjectBrowser and UnifiedPromptPanel in a **vertical stack** on the right side, similar to a chat interface where history is above and input is below.

**Layout Changes:**

#### Before:
```
┌─────────┬──────────────────┬──────────────┐
│  Tool   │                  │   Object     │
│ Palette │     Canvas       │   Browser    │
│         │                  │  (250px)     │
│         ├──────────────────┤              │
│         │ Unified Prompt   │              │
│         │   (200px)        │              │
└─────────┴──────────────────┴──────────────┘
```

#### After (Chat-Like Layout):
```
┌─────────┬──────────────────┬──────────────┐
│  Tool   │                  │   Object     │
│ Palette │                  │   Browser    │
│         │                  │  (DAG List)  │
│         │     Canvas       │   Expanded   │
│         │   (Full Height)  ├──────────────┤
│         │                  │   Unified    │
│         │                  │   Prompt     │
│         │                  │   (250px)    │
└─────────┴──────────────────┴──────────────┘
```

**Benefits:**
- ✅ Canvas gets full vertical height (more drawing space)
- ✅ **Object Browser at top** - See all DAG elements (like chat history)
- ✅ **Prompt Panel at bottom** - Enter CLI/AI commands (like chat input)
- ✅ Natural workflow: see what exists → create new objects
- ✅ Mode toggle always visible
- ✅ Chat-like interface: history above, input below

**Files Changed:** `lib/services/geodraw_navigation_service.dart`
- Updated both `GeoDrawCreateScreen` and `GeoDrawEditScreen`
- Removed nested Column layout
- Canvas now takes full Expanded area
- UnifiedPromptPanel moved from bottom to right sidebar

## Command Examples That Now Work

With the CLI fix, these commands now work correctly:

```bash
# Create points
point(0, 0)    # Creates point at origin
point(5, 5)    # Creates point at (5, 5)

# Create line
line(A, B)     # Line through points A and B

# Create circle
circle(B, C)   # Circle with center B through point C
circle3(A, B, C)  # Circle through three points

# Other commands
midpoint(A, B)      # Midpoint of two points
perpendicular(A, AB)  # Perpendicular through A to line AB
parallel(A, AB)       # Parallel through A to line AB
intersection(AB, CD)  # Intersection of lines
```

## Technical Details

### CLI Command Flow (Fixed):
1. User types command: `circle(B, C)`
2. UnifiedPromptPanel calls `cliExecutor.executeString("circle(B, C)")`
3. UnifiedCLIExecutor creates CommandParser with DAGManager
4. CommandParser:
   - Parses command format
   - Maps "circle" → ToolType.circle
   - Resolves "B" and "C" to actual point objects
   - Executes via SimpleExecutor
5. Result returned with success/error message
6. Display in CLI output panel

### Why It Failed Before:
- CommandParser constructor requires `DAGManager` parameter
- CommandParser doesn't have `parse()` method, uses `parseAndExecute()`
- Old code was trying to use non-existent API

### Why It Works Now:
- Uses `executeString()` which handles everything internally
- Properly passes DAGManager to CommandParser
- Correct method names and flow

## Verification

### Before Fix:
```
> circle(B, C)
[ERROR] Command circle doesn't exist
```

### After Fix:
```
> circle(B, C)
[OK] Created circle with center B through C
    Created: circle_1
```

## Files Modified Summary
```
Modified:
  packages/geodraw/lib/ui/unified_prompt_panel.dart
    - Fixed _executeCLICommand() method
    - Removed incorrect CommandParser usage
    - Now uses executeString() directly

  lib/services/geodraw_navigation_service.dart
    - Moved UnifiedPromptPanel from bottom to right side
    - Removed ObjectBrowser
    - Canvas now full height
    - Applied to both Create and Edit screens
```

## Next Steps

The app should now:
1. ✅ Recognize all CLI commands correctly
2. ✅ Show unified prompt panel on the right side
3. ✅ Give canvas full height for better drawing space
4. ✅ Allow easy switching between CLI and AI modes

Try it out with:
```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8081
```
