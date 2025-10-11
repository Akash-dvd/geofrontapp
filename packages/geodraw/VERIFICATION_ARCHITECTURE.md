## Input-Specific Verification Architecture

### Problem
Different input sources provide arguments in different ways:
- **Tool Palette**: Arguments arrive **sequentially** (one click at a time)
- **CLI**: Arguments provided **all at once** (complete command string)
- **AI**: Batch of commands provided **all at once** (multiple complete commands)

Each needs its own validation strategy.

### Solution: Three Verifiers

#### 1. ToolVerifier (`command/tool_verifier.dart`)
**For**: Tool Palette sequential input

**Validates**: Each argument as it arrives
- Maintains state of collected arguments
- Checks if next argument matches expected type
- Tracks completion status
- Provides user-friendly descriptions of what's needed next

**Usage**:
```dart
class UnifiedTool {
  final ToolVerifier verifier = ToolVerifier(type);
  
  void onClick(GeometryObject obj) {
    final result = verifier.addArgument(obj);
    if (result.isValid && verifier.isComplete) {
      execute();
    }
  }
}
```

#### 2. CLIVerifier (`command/cli_verifier.dart`)
**For**: CLI complete command input

**Validates**: All arguments together at once
- Receives complete argument list
- Validates entire command in single call
- Uses CommandSchema validation

**Usage**:
```dart
class CLIAdapter {
  Future<ExecutionResult> executeCommand(Command cmd) async {
    final validation = CLIVerifier.verifyCommand(
      cmd.toolType,
      cmd.arguments,
    );
    
    if (!validation.isValid) {
      return ExecutionResult.error(validation.errors.join(', '));
    }
    
    // Execute...
  }
}
```

#### 3. AIVerifier (`command/ai_verifier.dart`)
**For**: AI batch command input

**Validates**: Each command independently
- Can validate individual commands
- Can validate entire batch
- Provides strict mode (stops at first error)

**Usage**:
```dart
class AIAdapter {
  Future<List<ExecutionResult>> executeBatch(List<String> commands) async {
    // Validation happens in parser for each command
    return await parser.parseAndExecuteBatch(commands);
  }
}
```

### Architecture Flow

```
TOOL PALETTE:
User Click → ToolVerifier.addArgument() → Validate → Add → Check Complete → Execute

CLI:
"command(a,b,c)" → Parse → CLIVerifier.verifyCommand() → Validate All → Execute

AI:
["cmd1(a,b)", "cmd2(c,d)"] → Parse Each → AIVerifier.verifyCommand() → Execute Each
```

### Key Differences

| Aspect | ToolVerifier | CLIVerifier | AIVerifier |
|--------|--------------|-------------|------------|
| **State** | Stateful (accumulates args) | Stateless | Stateless |
| **Timing** | Per-argument | All-at-once | Per-command |
| **Errors** | Per-argument feedback | Complete validation | Per-command or batch |
| **Use Case** | Interactive clicking | Command strings | Batch processing |

### Benefits

1. **Clear Separation**: Each input source has dedicated verification logic
2. **Appropriate Validation**: Timing matches how arguments arrive
3. **Better UX**: Tool palette gets immediate per-click feedback
4. **Type Safety**: All use CommandSchema for consistent type checking
5. **Maintainability**: Each verifier focused on single input source
