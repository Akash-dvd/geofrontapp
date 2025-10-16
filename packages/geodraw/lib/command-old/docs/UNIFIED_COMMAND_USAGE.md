# Unified Command System

## Overview

The unified command system provides **type-safe argument validation** across three different interfaces:
1. **AI** - Natural language → commands (batch mode)
2. **CLI** - Text commands (batch mode) 
3. **Tool Palette** - Interactive UI (incremental mode)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    ToolType (Enum)                      │
│            Unified Command Identifier                    │
└────────────┬────────────────────────────────────────────┘
             │
   ┌─────────┴─────────┐
   │  CommandSchema     │  ← Defines argument types
   │  - argumentTypes   │     (union of allowed types)
   │  - validate()      │
   └─────────┬──────────┘
             │
   ┌─────────┴──────────┐
   │  UnifiedCommand    │  ← Encapsulates command + args
   │  - type           │
   │  - arguments      │
   │  - validate()     │
   └─────────┬──────────┘
             │
   ┌─────────┴──────────┐
   │    ClassTree       │  ← Runtime type checking
   │  - isSubtypeOf()  │     (handles inheritance)
   └────────────────────┘
```

## Type System

### Class Tree (Inheritance Hierarchy)

```
Object
 └─ CanvasObject
     └─ GeometryObject
         ├─ GeoPoint
         │   ├─ GeoPointer (free point)
         │   ├─ GeoMidpoint
         │   └─ GeoInvPoint
         ├─ GeoLine
         │   ├─ GeoLine2P
         │   ├─ GeoPerpendicularBisector
         │   ├─ GeoPerpendicularLine
         │   └─ GeoParallelLine
         └─ GeoCircle
             ├─ GeoCircle2P
             ├─ GeoCircle3P
             └─ GeoInvCircle
```

### Type Constraints

Arguments are validated using **union types**:

```dart
TypeConstraint.point = union(GeoPointer, GeoMidpoint, GeoInvPoint)
TypeConstraint.line = union(GeoLine2P, GeoPerpendicularBisector, ...)
TypeConstraint.circle = union(GeoCircle2P, GeoCircle3P, GeoInvCircle)
```

**Validation Rule**: If supplied type's superclass ∈ union → VALID ✅

Example:
```dart
// Command expects: TypeConstraint.point
// User supplies: GeoMidpoint
// Check: GeoMidpoint → GeoPoint ∈ {GeoPoint} → ✅ VALID
```

## Usage Examples

### 1. CLI Interface (Batch Mode)

```dart
// Parse command string
final parser = CommandParser();
final cliCommand = parser.parse('line(A, B)');

// Convert to unified command
final pointA = dagManager.getObject('A') as GeoPoint;
final pointB = dagManager.getObject('B') as GeoPoint;

final unifiedCommand = UnifiedCommand.fromBatch(
  type: ToolType.line,
  arguments: [pointA, pointB],
);

// Validate and execute
final validation = unifiedCommand.validate();
if (validation.isValid) {
  executor.execute(unifiedCommand);
} else {
  print('Errors: ${validation.errors}');
}
```

### 2. AI Interface (Batch Mode)

```dart
// AI generates command sequence
final aiResponse = await aiService.generateCommands(
  'Create a triangle with vertices at A, B, and C'
);

// Convert AI commands to unified commands
for (final cmdString in aiResponse.commands) {
  // Parse: "line(A, B, AB)"
  final parts = _parseAICommand(cmdString);
  
  final objects = parts.args.map((arg) => 
    dagManager.getObjectByLabel(arg)
  ).toList();
  
  final unifiedCommand = UnifiedCommand.fromBatch(
    type: _mapToToolType(parts.name), // "line" → ToolType.line
    arguments: objects,
  );
  
  // Validate and execute
  if (unifiedCommand.validate().isValid) {
    executor.execute(unifiedCommand);
  }
}
```

### 3. Tool Palette Interface (Incremental Mode)

```dart
// User selects "Line" tool
var command = UnifiedCommand.forToolPalette(ToolType.line);

// UI shows: "Need: Any point"
print(command.nextArgumentDescription);
print('Progress: ${command.progress}'); // 0/2

// User clicks first point
final click1 = event.position;
final nearbyObjects = dagManager.proximitySearch(click1);
final point1 = nearbyObjects.whereType<GeoPoint>().firstOrNull;

if (point1 != null) {
  // Validate type before adding
  final canAdd = command.nextArgumentType?.accepts(point1.runtimeType);
  if (canAdd == true) {
    command = command.addArgument(point1);
  }
}

// UI shows: "Need: Any point"
print(command.nextArgumentDescription);
print('Progress: ${command.progress}'); // 1/2

// User clicks second point
final point2 = ...; // similar logic
command = command.addArgument(point2);

// Command is complete
print(command.isComplete); // true
print('Progress: ${command.progress}'); // 2/2 - Command complete

// Execute
executor.execute(command);
```

## Type Validation Examples

### ✅ Valid Cases

```dart
// 1. Exact type match
CommandSchema(
  argumentTypes: [TypeConstraint.point],
).validate([GeoPointer(...)]) // ✅ VALID

// 2. Subtype match
CommandSchema(
  argumentTypes: [TypeConstraint.point],
).validate([GeoMidpoint(...)]) // ✅ VALID (GeoMidpoint extends GeoPoint)

// 3. Union match
CommandSchema(
  argumentTypes: [TypeConstraint.simpleGeometry], // union(Point, Line, Circle)
).validate([GeoLine2P(...)]) // ✅ VALID
```

### ❌ Invalid Cases

```dart
// 1. Wrong type
CommandSchema(
  argumentTypes: [TypeConstraint.point],
).validate([GeoLine2P(...)]) // ❌ INVALID

// 2. Too few arguments
CommandSchema(
  argumentTypes: [TypeConstraint.point, TypeConstraint.point],
).validate([pointA]) // ❌ INVALID

// 3. Too many arguments  
CommandSchema(
  argumentTypes: [TypeConstraint.point],
).validate([pointA, pointB]) // ❌ INVALID
```

## Command Registry

All commands are registered with their schemas:

```dart
ToolType.line → CommandSchema(
  argumentTypes: [TypeConstraint.point, TypeConstraint.point],
  description: 'Create a line through two points',
)

ToolType.circle → CommandSchema(
  argumentTypes: [TypeConstraint.point, TypeConstraint.point],
  description: 'Create circle with center and point',
)

ToolType.perpendicular → CommandSchema(
  argumentTypes: [TypeConstraint.line, TypeConstraint.point],
  description: 'Create perpendicular line through point',
)
```

## Benefits

1. **Type Safety**: Runtime validation catches type errors before execution
2. **Single Source of Truth**: One schema definition for all interfaces
3. **Incremental Building**: Tool Palette can validate each step
4. **Clear Error Messages**: Specific feedback about what's wrong
5. **Extensibility**: Easy to add new commands with proper validation

## Adding New Commands

```dart
// 1. Add to ToolType enum
enum ToolType {
  // ... existing
  tangent, // NEW
}

// 2. Register schema
CommandSchemaRegistry._schemas[ToolType.tangent] = CommandSchema(
  commandType: ToolType.tangent,
  argumentTypes: [
    TypeConstraint.circle,  // First arg: circle
    TypeConstraint.point,   // Second arg: point
  ],
  description: 'Create tangent line from point to circle',
  createsObject: true,
);

// 3. Add to ClassTree if new types introduced
ClassTree.register(GeoTangentLine, {
  GeoLine, GeometryObject, CanvasObject, Object
});
```

## Implementation Status

- ✅ Type constraint system
- ✅ Command schema registry  
- ✅ Class tree for inheritance checking
- ✅ Unified command with batch/incremental modes
- ✅ Validation system
- 🔄 Executor integration (TODO)
- 🔄 CLI adapter (TODO)
- 🔄 AI adapter (TODO)
- 🔄 Tool Palette adapter (TODO)
