# Unified Command System

## Problem Statement

You identified that there are **three ways to CRUD the DAG**:
1. **AI** - Natural language input
2. **CLI** - Text commands  
3. **Tool Palette** - Interactive UI clicks

Each needs to:
- Validate argument types at runtime (Dart can't check subtypes at compile time)
- Handle the same geometric constructions
- Provide clear error messages

## Solution

A **unified type system** where:

```
Command = ToolType + Arguments
```

### Key Components

#### 1. **ToolType** - Unified Command Identifier
All three interfaces use the same `ToolType` enum as the command identifier:
- `ToolType.line` → Create line
- `ToolType.circle` → Create circle
- `ToolType.midpoint` → Create midpoint
- etc.

#### 2. **CommandSchema** - Argument Type Definitions
Each command has a schema defining:
- What types are allowed for each argument (union of types)
- Whether arguments are optional
- Human-readable descriptions

```dart
ToolType.line → CommandSchema(
  argumentTypes: [
    TypeConstraint.point,  // Arg 1: union(GeoPointer, GeoMidpoint, GeoInvPoint, ...)
    TypeConstraint.point,  // Arg 2: union(GeoPointer, GeoMidpoint, GeoInvPoint, ...)
  ]
)
```

#### 3. **ClassTree** - Runtime Type Checking
Since Dart can't check subclass relationships at compile time, we maintain an explicit inheritance tree:

```
GeoPointer → GeoPoint → GeometryObject → CanvasObject → Object
```

**Validation Rule**: If supplied object's superclass ∈ allowed types → VALID ✅

#### 4. **UnifiedCommand** - Encapsulation
Wraps command + arguments with validation:
- **Batch Mode** (AI/CLI): All arguments supplied at once
- **Incremental Mode** (Tool Palette): Arguments added one by one

## Architecture

```
┌─────────────┐
│  ToolType   │  (Unified identifier)
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ CommandSchema   │  (Defines argument types)
│  - argumentTypes│
│  - validate()   │
└──────┬──────────┘
       │
       ▼
┌──────────────────┐
│ UnifiedCommand   │  (Encapsulates command + args)
│  - type          │
│  - arguments     │
│  - validate()    │
└──────┬───────────┘
       │
       ▼
┌─────────────┐
│  ClassTree  │  (Runtime type checking)
│  - isSubtype│
└─────────────┘
```

## Usage Comparison

### CLI/AI (Batch Mode)
```dart
// All arguments provided at once
final cmd = UnifiedCommand.fromBatch(
  type: ToolType.line,
  arguments: [pointA, pointB],
);

// Validate & execute
if (cmd.validate().isValid) {
  executor.execute(cmd);
}
```

### Tool Palette (Incremental Mode)
```dart
// Start with no arguments
var cmd = UnifiedCommand.forToolPalette(ToolType.line);

// User clicks first point
cmd = cmd.addArgument(pointA);
print(cmd.nextArgumentDescription); // "Need: Any point"

// User clicks second point
cmd = cmd.addArgument(pointB);
print(cmd.isComplete); // true

// Execute
executor.execute(cmd);
```

## Type Validation Example

```dart
// Command expects: TypeConstraint.point = union(GeoPointer, GeoMidpoint, GeoInvPoint)
// User supplies: GeoMidpoint

// Validation:
// 1. Check if GeoMidpoint ∈ {GeoPointer, GeoMidpoint, GeoInvPoint} → NO
// 2. Check superclass: GeoMidpoint → GeoPoint
// 3. Check if GeoPoint ∈ constraint.allowedTypes → YES ✅
// Result: VALID
```

## Files

- `command_schema.dart` - Type constraints, schema definitions, class tree
- `unified_command.dart` - Command encapsulation with batch/incremental modes
- `command.dart` - Library exports
- `example_usage.dart` - Working examples for all three interfaces
- `UNIFIED_COMMAND_USAGE.md` - Detailed usage guide

## Benefits

✅ **Single Source of Truth**: One command definition for all interfaces  
✅ **Type Safety**: Runtime validation catches errors before execution  
✅ **Incremental Building**: Tool Palette can validate each step  
✅ **Clear Errors**: Specific feedback about what went wrong  
✅ **Extensible**: Easy to add new commands  

## Next Steps

1. ✅ Type constraint system implemented
2. ✅ Command schema registry implemented
3. ✅ Class tree for inheritance checking implemented
4. ✅ Unified command with batch/incremental modes implemented
5. 🔄 Integrate with existing CommandExecutor
6. 🔄 Create CLI adapter
7. 🔄 Create AI adapter  
8. 🔄 Update Tool Palette to use incremental mode
