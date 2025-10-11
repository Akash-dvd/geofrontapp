# Unified Command System - Refactor Summary

## Overview
Successfully eliminated adapter bloat by creating lightweight utilities (`ObjectResolver`, `CommandNameMapper`) that allow CLI and AI to be thin wrappers around the unified command system.

## Architecture Changes

### Before (Bloated Adapters)
```
CLI Input → CLIAdapter (175 lines)
                ├─ Map command names (switch statement)
                ├─ Resolve objects (_findObject loop)
                ├─ Parse arguments
                └─ Convert to UnifiedCommand

AI Input → AIAdapter (198 lines)
               ├─ Map command names (switch statement)
               ├─ Resolve objects (_findObject loop)
               ├─ Parse arguments (regex + split)
               └─ Convert to UnifiedCommand
```

**Problem**: Both adapters duplicated command name mapping, object resolution, and argument parsing.

### After (Thin Wrappers)
```
CLI Input → CLIAdapter (65 lines)
                ├─ CommandNameMapper.toToolType()
                ├─ ObjectResolver.resolveArguments()
                └─ UnifiedCommand.fromBatch()

AI Input → AIAdapter (130 lines)
               ├─ Parse format (regex)
               ├─ CommandNameMapper.toToolType()
               ├─ ObjectResolver.resolveArguments()
               └─ UnifiedCommand.fromBatch()
```

**Result**: Single source of truth for object resolution and command mapping.

## File Changes

### Created
- **`command/object_resolver.dart`** (97 lines)
  - `ObjectResolver`: Resolve string IDs/labels → actual objects
  - `CommandNameMapper`: Bidirectional string ↔ ToolType mapping
  - Supports aliases: perp, para, perpbis, mid, intersect

### Simplified
- **`cli/cli_adapter.dart`**: 175 → 65 lines (**110 lines removed**)
  - Removed: `_mapCommandNameToToolType()`, `_resolveObjectReferences()`, `_findObject()`
  - Now: 4 steps (map → resolve → create → execute)

- **`ai/ai_adapter.dart`**: 198 → 130 lines (**68 lines removed**)
  - Removed: `_mapCommandNameToToolType()`, `_findObject()`
  - Simplified: `_parseAndResolveArgs()` uses `ObjectResolver.resolve()`
  - Kept: `_splitArguments()` (AI-specific regex parsing)

### Total Code Reduction
**178 lines removed** from adapters, replaced with **97 lines** of reusable utilities.
**Net reduction: 81 lines** with cleaner architecture.

## Responsibilities

### UnifiedCommand (unchanged)
- Encapsulates command type + arguments
- Validates argument types against schema
- Supports batch mode (CLI/AI) and incremental mode (Tool Palette)

### UnifiedCommandExecutor (unchanged)
- Executes validated commands
- Creates objects in DAG
- Returns success/failure results

### ObjectResolver (new utility)
```dart
class ObjectResolver {
  dynamic resolve(String idOrLabel);
  List<dynamic> resolveArguments(List<dynamic> args);
  Map<String, dynamic> resolveAll();
}
```
- Resolves strings → objects by ID or label
- Returns original string if object not found (for labels)

### CommandNameMapper (new utility)
```dart
class CommandNameMapper {
  static ToolType? toToolType(String name);
  static String? fromToolType(ToolType type);
  static bool isValid(String name);
}
```
- Maps command name strings → ToolType enum
- Supports 14 name variations (including aliases)
- Bidirectional mapping

### CLIAdapter (simplified)
```dart
executeCommand(Command cliCommand) {
  final toolType = CommandNameMapper.toToolType(cliCommand.name);
  final resolvedArgs = resolver.resolveArguments(cliCommand.arguments);
  final unifiedCommand = UnifiedCommand.fromBatch(toolType, resolvedArgs);
  return executor.execute(unifiedCommand);
}
```
- **Only** parses CLI command structure
- Delegates resolution/mapping to utilities

### AIAdapter (simplified)
```dart
executeCommand(String commandString) {
  final match = RegExp(r'^(\w+)\((.*)\)$').firstMatch(commandString);
  final toolType = CommandNameMapper.toToolType(match.group(1));
  final args = _parseAndResolveArgs(match.group(2));
  final unifiedCommand = UnifiedCommand.fromBatch(toolType, args);
  return executor.execute(unifiedCommand);
}
```
- **Only** parses AI command format (regex)
- Delegates resolution/mapping to utilities

## Benefits

1. **Single Source of Truth**
   - Command names defined once in `CommandNameMapper`
   - Object resolution logic in `ObjectResolver`
   - No duplication across interfaces

2. **Easier Maintenance**
   - Add new command? Update `CommandNameMapper` (1 place)
   - Change resolution logic? Update `ObjectResolver` (1 place)
   - Previously: Update 2 adapters + keep in sync

3. **Cleaner Code**
   - Adapters are now thin wrappers (original intent)
   - Each component has clear responsibility
   - Tool Palette already used UnifiedCommand directly (no adapter needed)

4. **Testability**
   - Can test `ObjectResolver` independently
   - Can test `CommandNameMapper` independently
   - Adapters are now simple integration tests

## Workflow

### CLI Example
```bash
$ line(A, B)
```
1. CLI parser → `Command{name: "line", arguments: ["A", "B"]}`
2. `CommandNameMapper.toToolType("line")` → `ToolType.line`
3. `ObjectResolver.resolveArguments(["A", "B"])` → `[GeoPoint A, GeoPoint B]`
4. `UnifiedCommand.fromBatch(ToolType.line, [A, B])`
5. `UnifiedCommandExecutor.execute()` → creates line

### AI Example
```json
"line(A, B)"
```
1. Regex parse → `{command: "line", args: "A, B"}`
2. `CommandNameMapper.toToolType("line")` → `ToolType.line`
3. Split args → `["A", "B"]`
4. `ObjectResolver.resolve("A")` → `GeoPoint A`
5. `ObjectResolver.resolve("B")` → `GeoPoint B`
6. `UnifiedCommand.fromBatch(ToolType.line, [A, B])`
7. `UnifiedCommandExecutor.execute()` → creates line

### Tool Palette Example
```dart
// Click 1
tool.command.addArgument(GeoPoint A);
// Click 2
tool.command.addArgument(GeoPoint B);
tool.command.validate(); // ✓
executor.execute(tool.command);
```
No adapter needed - direct `UnifiedCommand` usage.

## Next Steps

### Completed ✅
- Created `ObjectResolver` utility
- Created `CommandNameMapper` utility
- Simplified `CLIAdapter` (175 → 65 lines)
- Simplified `AIAdapter` (198 → 130 lines)
- All compilation errors resolved

### Future Improvements
1. **Update CommandParser** to output `ToolType` directly
   - Parser should use `CommandNameMapper` internally
   - CLI won't need to map command names at all

2. **Add Comprehensive Tests**
   - Test `ObjectResolver` with various ID/label formats
   - Test `CommandNameMapper` with all aliases
   - Integration tests: same command works in CLI, AI, Tool Palette

3. **Documentation**
   - Add API docs to `ObjectResolver`
   - Add examples for each command alias
   - Document workflow for adding new commands

## Migration Notes

### For Developers Adding New Commands
**Old way** (required changes in 3 places):
1. Add to `CLIAdapter._mapCommandNameToToolType()`
2. Add to `AIAdapter._mapCommandNameToToolType()`
3. Add to Tool Palette tool list

**New way** (1 place):
1. Add to `CommandNameMapper` mapping
2. Tool Palette automatically uses same mapping

### Backwards Compatibility
- All existing CLI commands work unchanged
- All existing AI commands work unchanged
- Tool Palette uses same UnifiedCommand system
- No breaking changes to external APIs

## Code Quality Metrics

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| CLI Adapter LOC | 175 | 65 | -63% |
| AI Adapter LOC | 198 | 130 | -34% |
| Total Adapter LOC | 373 | 195 | -48% |
| Utility LOC | 0 | 97 | +97 |
| Net Change | 373 | 292 | -22% |
| Duplication | High | None | ✓ |
| Testability | Medium | High | ✓ |

## Summary

Successfully eliminated adapter bloat by extracting common functionality into reusable utilities. The unified command system now has clear separation of concerns:

- **UnifiedCommand**: Command definition + validation
- **UnifiedCommandExecutor**: Execution logic
- **ObjectResolver**: String → object resolution
- **CommandNameMapper**: String → ToolType mapping
- **CLIAdapter**: CLI-specific parsing
- **AIAdapter**: AI-specific parsing
- **Tool Palette**: Direct UnifiedCommand usage (no adapter)

This architecture makes the system easier to maintain, test, and extend.
