# Command System

This folder contains the command system that powers GeoDraw's CLI, AI, and Tool Palette interfaces.

## Structure

```
command/
├── command.dart           # Main export file
├── command_schema.dart    # Type validation & schema definitions
├── command_parser.dart    # String command parser
├── simple_executor.dart   # Command execution engine
├── object_resolver.dart   # String→object resolution & name mapping
├── tool_verifier.dart     # Tool Palette incremental validation
├── cli_verifier.dart      # CLI batch validation
├── ai_verifier.dart       # AI batch validation
├── docs/                  # Documentation
└── examples/              # Runnable examples
```

## Core Files

### command.dart
Main entry point - re-exports all core modules:
- `command_schema.dart`
- `simple_executor.dart`
- `command_parser.dart`
- `tool_verifier.dart`
- `cli_verifier.dart`
- `ai_verifier.dart`
- `object_resolver.dart`

### command_schema.dart
Type validation system:
- `TypeConstraint` - Defines allowed types for arguments
- `CommandSchema` - Schema definition for each command
- `CommandSchemaRegistry` - Registry of all command schemas
- `ClassTree` - Runtime inheritance checking
- `ValidationResult` - Validation result with error messages

### simple_executor.dart
Command execution:
- `SimpleExecutor` - Directly executes commands and creates geometry objects
- `ExecutionResult` - Execution result with object ID and message
- Creates objects in DAG without unnecessary wrappers

### command_parser.dart
String command parsing:
- `CommandParser` - Parses and executes string commands
- Format: `"command(arg1, arg2, ...)"`
- Resolves string arguments to objects using `ObjectResolver`
- Uses `SimpleExecutor` for execution

### Verifiers
Three input-specific verifiers for different use cases:

**tool_verifier.dart** - Tool Palette (incremental):
- `ToolVerifier` - Validates arguments one at a time as user clicks
- `addArgument()` - Add and validate next argument
- `isComplete` - Check if all required arguments provided

**cli_verifier.dart** - CLI (batch):
- `CLIVerifier.verifyCommand()` - Validates complete command at once
- All arguments provided together

**ai_verifier.dart** - AI (batch):
- `AIVerifier.verifyCommand()` - Validates single command
- `AIVerifier.verifyBatch()` - Validates multiple commands
- `AIVerifier.verifyBatchStrict()` - Fails fast on first error

### object_resolver.dart
Utility classes:
- `ObjectResolver` - Resolves string IDs/labels to geometry objects
- `CommandNameMapper` - Maps command names ↔ ToolType enum

## Usage

### Basic Import
```dart
import 'package:geodraw/command/command.dart';
```

This gives you access to all core classes.

### Quick Start

**CLI/AI Interface (via CommandParser):**
```dart
final parser = CommandParser(dagManager);
final result = await parser.parseAndExecute("line(A, B)");
if (result.success) {
  print('Created ${result.objectId}');
}
```

**CLI Interface (direct validation):**
```dart
// Validate arguments
final validation = CLIVerifier.verifyCommand(ToolType.line, [pointA, pointB]);
if (validation.isValid) {
  // Execute
  final executor = SimpleExecutor(dagManager);
  final result = await executor.execute(
    type: ToolType.line,
    arguments: [pointA, pointB],
  );
}
```

**AI Interface (batch validation):**
```dart
// Validate entire batch
final commands = [
  (type: ToolType.point, args: [0, 0]),
  (type: ToolType.point, args: [10, 10]),
  (type: ToolType.line, args: [point1, point2]),
];
final validation = AIVerifier.verifyBatchStrict(commands);

// Execute if valid
if (validation.isValid) {
  final executor = SimpleExecutor(dagManager);
  for (final cmd in commands) {
    await executor.execute(type: cmd.type, arguments: cmd.args);
  }
}
```

**Tool Palette (incremental validation):**
```dart
final verifier = ToolVerifier(ToolType.line);

// First click
verifier.addArgument(pointA);

// Second click
verifier.addArgument(pointB);

// Check if ready to execute
if (verifier.isComplete) {
  final executor = SimpleExecutor(dagManager);
  final result = await executor.execute(
    type: ToolType.line,
    arguments: verifier.arguments,
  );
}
```

## Key Concepts

### Single Source of Truth
All three interfaces (CLI, AI, Tool Palette) share the same foundation:
- Same type validation (`CommandSchema`)
- Same execution logic (`SimpleExecutor`)
- Same object creation rules
- Input-specific verifiers for different use cases

### Type Safety
Commands are validated before execution:
- **Parse time**: `CommandParser` validates command names
- **Pre-execution**: Verifiers validate argument types and count
- **Execution time**: `SimpleExecutor` creates objects in DAG

### Three Validation Modes
- **Incremental** (Tool Palette): `ToolVerifier` validates arguments one at a time
- **Batch** (CLI): `CLIVerifier` validates complete command at once
- **Batch** (AI): `AIVerifier` validates multiple commands together

## Adding New Commands

1. Add `ToolType` enum value in `tools/tool.dart`
2. Register schema in `CommandSchemaRegistry` (`command_schema.dart`)
3. Add execution case in `SimpleExecutor._executeCommand()` (`simple_executor.dart`)
4. Add command name mapping in `CommandNameMapper` (`object_resolver.dart`)
5. Create tool class for Tool Palette if needed

## Architecture Benefits

- **No unnecessary wrappers**: Direct execution without command objects
- **Input-specific validation**: Each interface uses appropriate verifier
- **Simple and direct**: Clear execution path from validation to object creation
- **Type-safe**: Schema-based validation ensures correct argument types
- **Reusable**: Same executor and schemas for all interfaces
