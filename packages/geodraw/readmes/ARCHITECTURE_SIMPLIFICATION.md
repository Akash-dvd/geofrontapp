# Architecture Simplification Proposal

## Current Problems

1. **Too Many Layers**: Input → Adapter → UnifiedCommand → Executor → Class → geocalc
2. **Pointless Wrapping**: UnifiedCommand just wraps type+args, then gets unwrapped
3. **Duplicate Logic**: Each adapter does the same: parse → resolve → wrap → execute
4. **Unnecessary Abstraction**: Classes already have clean factory methods

## Simplified Design

### Core Principle
**Command/Tool → Direct Factory Call → DAG Update → Rerender**

### What We Keep
- ✅ Geometry classes with `.fromPoints()` / `.fromLine()` factories
- ✅ geocalc for all math (multivector as sole source)
- ✅ DAGManager for graph management
- ✅ ObjectResolver for string→object lookup
- ✅ CommandNameMapper for string→ToolType mapping

### What We Remove/Simplify
- ❌ UnifiedCommand wrapper (just call factories directly)
- ❌ UnifiedCommandExecutor (logic moves to SimpleExecutor)
- ❌ AIAdapter/CLIAdapter (merge into one SimpleExecutor)
- ❌ UnifiedTool base class (tools call SimpleExecutor directly)

## New Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  SIMPLIFIED FLOW                        │
└─────────────────────────────────────────────────────────┘

Input Sources:
  - AI Panel:   "line(A, B)"
  - CLI Panel:  "line(A, B)" 
  - Tool Click: line_tool + click(p1) + click(p2)
                       ↓
                [Input Parser]
        - Parse command name → ToolType
        - Parse/resolve arguments → [GeoPoint, GeoPoint]
                       ↓
                [SimpleExecutor]
        - Map ToolType to factory method
        - Generate ID/label
        - Call: GeoLine2P.fromPoints(id, label, p1, p2)
                       ↓
           [Geometry Class Factory]
        - Call geocalc: constructLineFrom2Points(p1.mv, p2.mv)
        - Return constructed object with multivector
                       ↓
              [DAGManager.addObject]
        - Add to DAG with dependencies
        - Trigger rerender
                       ↓
                   [Canvas]
        - Render all objects
```

## SimpleExecutor Implementation

```dart
class SimpleExecutor {
  final DAGManager dagManager;
  final ObjectResolver resolver;
  int _idCounter = 0;
  int _labelCounter = 0;

  SimpleExecutor(this.dagManager) 
    : resolver = ObjectResolver(dagManager);

  /// Execute from any source (AI, CLI, Tool)
  Future<ExecutionResult> execute({
    required ToolType type,
    required List<dynamic> arguments,
    String? customLabel,
  }) async {
    try {
      // Generate ID/label
      final id = _generateId(type.name);
      final label = customLabel ?? _generateLabel(type);
      
      // Call appropriate factory method
      final result = switch (type) {
        ToolType.point => _createPoint(id, label, arguments),
        ToolType.line => _createLine(id, label, arguments),
        ToolType.circle => _createCircle(id, label, arguments),
        ToolType.circleThreePoints => _createCircle3P(id, label, arguments),
        ToolType.midpoint => _createMidpoint(id, label, arguments),
        ToolType.perpendicular => _createPerpendicular(id, label, arguments),
        ToolType.parallel => _createParallel(id, label, arguments),
        ToolType.perpBisector => _createPerpBisector(id, label, arguments),
        _ => throw UnimplementedError('$type not implemented'),
      };
      
      // Add to DAG
      dagManager.addObject(result.object, result.dependencies);
      
      return ExecutionResult.success(
        objectId: result.object.id,
        message: 'Created ${result.object.label}',
      );
    } catch (e) {
      return ExecutionResult.error(e.toString());
    }
  }

  // Direct factory calls
  _ConstructionResult _createLine(String id, String label, List<dynamic> args) {
    final p1 = args[0] as GeoPoint;
    final p2 = args[1] as GeoPoint;
    final line = GeoLine2P.fromPoints(id: id, label: label, p1: p1, p2: p2);
    return _ConstructionResult(line, [p1.id, p2.id]);
  }

  _ConstructionResult _createPerpendicular(String id, String label, List<dynamic> args) {
    final line = args[0] as GeoLine;
    final point = args[1] as GeoPoint;
    final perpLine = GeoPerpendicularLine.fromLine(
      id: id, label: label, line: line, point: point,
    );
    return _ConstructionResult(perpLine, [line.id, point.id]);
  }
  
  // ... etc for other types
}

class _ConstructionResult {
  final GeometryObject object;
  final List<String> dependencies;
  _ConstructionResult(this.object, this.dependencies);
}
```

## Benefits

1. **Fewer Lines of Code**: ~50% reduction
2. **Clearer Flow**: Input → Parse → Call Factory → DAG → Render
3. **No Indirection**: Direct calls to factory methods
4. **Single Responsibility**: 
   - Parser: string → type+args
   - SimpleExecutor: type+args → object → DAG
   - Classes: geometric construction
   - geocalc: math
5. **Easy to Test**: Each layer is simple and focused
6. **Easy to Extend**: Add new command = add new case to switch + factory method

## Migration Path

1. Create SimpleExecutor
2. Update AI Panel to use SimpleExecutor
3. Update CLI Panel to use SimpleExecutor  
4. Update Tools to use SimpleExecutor
5. Remove UnifiedCommand, UnifiedCommandExecutor, adapters
6. Profit! 🎉

## Example Usage

```dart
// From AI
final executor = SimpleExecutor(dagManager);
final result = await executor.execute(
  type: ToolType.line,
  arguments: [pointA, pointB],
);

// From CLI
final args = resolver.resolveArguments(['A', 'B']); // strings → objects
final result = await executor.execute(
  type: ToolType.line,
  arguments: args,
);

// From Tool
final result = await executor.execute(
  type: ToolType.line,
  arguments: [clickedPoint1, clickedPoint2],
);
```

All three use cases = same simple executor!
