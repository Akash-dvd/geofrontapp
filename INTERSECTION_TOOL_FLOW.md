# Intersection Tool Flow

Complete flow of the Intersection Tool from button press to calculation completion.

---

## **Phase 1: Tool Selection (Button Press)**

### 1.1 User Clicks Intersection Tool Icon
- **Location**: `packages/geodraw/lib/ui/tool_palette.dart`
- **File**: `_ToolButton` widget (lines ~220-336)
- **Action**: User clicks the intersection tool icon in the tool palette
- **Trigger**: `onToolSelected(entry.toolType!)` callback is called with `ToolType.intersection`

### 1.2 Tool Manager Receives Selection
- **Location**: `packages/geodraw/lib/tools/tool_manager.dart`
- **Method**: `ToolManager.selectTool(ToolType.intersection)` (lines 46-56)
- **Actions**:
  1. Resets the current active tool (if any)
  2. Sets `_activeToolType = ToolType.intersection`
  3. Calls `_createTool(ToolType.intersection)` to instantiate the tool
  4. Notifies state change: "Select two objects to find intersection"

### 1.3 Tool Instance Creation
- **Location**: `packages/geodraw/lib/tools/tool_manager.dart`
- **Method**: `ToolManager._createTool()` (lines 69-299)
- **Case**: `case ToolType.intersection:` (line 231)
- **Creation**: Instantiates `_IntersectionTool` class
  ```dart
  return _IntersectionTool(
    dagManager: dagManager,
    commandHistory: commandHistory,
    onObjectCreated: onObjectCreated,
    onObjectSelected: onObjectSelected,
    onToolStateChanged: onToolStateChanged,
    createFreePoint: _createFreePoint,
  );
  ```

### 1.4 UnifiedTool Initialization
- **Location**: `packages/geodraw/lib/tools/unified_tool.dart`
- **Constructor**: `UnifiedTool.__init__()` (lines 26-34)
- **Initialization**:
  1. Creates `SimpleExecutor` instance for command execution
  2. Creates `ToolVerifier` instance with command name "intersection"
  3. `ToolVerifier` loads the command schema from `CommandRegistry`
  4. Schema defines: 2 arguments (GeoLine, GeoCircle, or GeoPoint each)

---

## **Phase 2: First Object Selection (First Click)**

### 2.1 Pointer Event Received
- **Location**: `packages/geodraw/lib/tools/unified_tool.dart`
- **Method**: `UnifiedTool.handleInput()` (lines 39-43)
- **Event**: `PointerDownEvent` is received from the canvas
- **Action**: Calls `_handleClick(event.position)`

### 2.2 Click Processing
- **Location**: `packages/geodraw/lib/tools/unified_tool.dart`
- **Method**: `UnifiedTool._handleClick()` (lines 74-97)
- **Steps**:
  1. Gets next constraint from schema: `verifier.schema.nextConstraint(verifier.arguments)`
     - Currently `verifier.arguments` is empty `[]`
     - Returns first constraint: `TypeConstraint.geometry(allowedTypes: {GeoLine, GeoCircle, GeoPoint})`
  2. Creates history marker (for undo support)
     - `_ensureHistoryMarker()` creates a checkpoint in DAG
  3. Searches for nearby objects:
     - `dagManager.proximitySearch(position, threshold: 15.0)` 
     - Finds all geometry objects within 15 pixels of click position
  4. Validates objects:
     - Loops through nearby objects
     - Checks if object type matches constraint: `nextConstraint.accepts(obj)`
     - Accepts: `GeoLine`, `GeoCircle`, or `GeoPoint`
     - Selects first matching object
  5. If no object found: `createObjectAtPosition(position)` returns `null`
     - For intersection tool, this always returns `null` (cannot create new objects)

### 2.3 Argument Addition
- **Location**: `packages/geodraw/lib/tools/unified_tool.dart`
- **Method**: `UnifiedTool._addArgument()` (lines 99-115)
- **Steps**:
  1. Calls `verifier.addArgument(selectedObject)`
     - Validates argument against schema
     - Adds to `verifier.arguments` list: `[firstObject]`
  2. Updates UI state:
     - `notifyStateChanged(verifier.nextArgumentDescription)`
     - Message: "Select second object"
  3. Checks completion:
     - `verifier.isComplete` returns `false` (need 2 arguments, only have 1)
     - Tool remains active, waiting for second object

---

## **Phase 3: Second Object Selection (Second Click)**

### 3.1 Second Pointer Event
- **Same flow as Phase 2.1-2.2**
- User clicks on second object (e.g., another line or circle)
- `proximitySearch()` finds nearby objects
- First matching object is selected

### 3.2 Second Argument Added
- **Location**: `packages/geodraw/lib/tools/unified_tool.dart`
- **Method**: `UnifiedTool._addArgument()` (lines 99-115)
- **Steps**:
  1. `verifier.addArgument(secondObject)` is called
     - Validates: must be `GeoLine`, `GeoCircle`, or `GeoPoint`
     - Adds to `verifier.arguments`: `[firstObject, secondObject]`
  2. Updates state: "Command complete" (or similar)
  3. Completion check:
     - `verifier.isComplete` returns `true` (have 2 arguments)
     - **Triggers command execution**: `_executeCommand()`

---

## **Phase 4: Command Execution**

### 4.1 Command Execution Trigger
- **Location**: `packages/geodraw/lib/tools/unified_tool.dart`
- **Method**: `UnifiedTool._executeCommand()` (lines 117-160)
- **Pre-execution**:
  1. Validates: `verifier.isComplete` must be `true`
  2. Creates argument snapshot for history
  3. Stores history marker reference

### 4.2 SimpleExecutor Invocation
- **Location**: `packages/geodraw/lib/core/command/simple_executor.dart`
- **Method**: `SimpleExecutor.execute()` 
- **Action**: 
  ```dart
  final result = await executor.execute(
    commandName: 'intersection',
    arguments: verifier.arguments, // [firstObject, secondObject]
  );
  ```
- **Internal Steps**:
  1. Looks up command definition: `registry.definitionByName('intersection')`
  2. Validates arguments against command schema
  3. Creates execution context (`CommandExecutionContext`)
  4. Calls command executor function

### 4.3 Command Registry Execution
- **Location**: `packages/geodraw/lib/core/command/command_registry.dart`
- **Method**: Intersection command executor (lines 1837-1913)
- **Steps**:
  1. **Argument Extraction**:
     ```dart
     final first = arguments[0] as GeometryObject;   // e.g., GeoLine
     final second = arguments[1] as GeometryObject; // e.g., GeoCircle
     ```
  2. **Label Generation**:
     - Checks for provided label (optional 3rd argument)
     - If none: generates label via `_nextIntersectionLabel()` → `"Int1"`, `"Int2"`, etc.
  3. **Object Type Detection**:
     - Determines combination: line-line, line-circle, circle-line, or circle-circle
     - Routes to appropriate calculation method

---

## **Phase 5: Intersection Calculation**

### 5.1 Calculation Method Selection
- **Location**: `packages/geodraw/lib/core/command/command_registry.dart`
- **Lines**: 1857-1895
- **Routes based on object types**:

#### **Case 1: Line-Line Intersection** (lines 1857-1869)
```dart
if (first is GeoLine && second is GeoLine) {
  final lineIntersection = GeoIntersection.lineLine(...);
  if (lineIntersection == null) {
    // Parallel lines - no intersection
    return ExecutionResult.error('Lines are parallel - no intersection found');
  }
  intersection = lineIntersection;
}
```

#### **Case 2: Line-Circle Intersection** (lines 1870-1876 or 1877-1883)
```dart
else if (first is GeoLine && second is GeoCircle) {
  intersection = GeoIntersection.lineCircle(
    id: context.generateId('intersection'),
    label: label,
    line: first,
    circle: second,
  );
}
// Also handles circle-line (reversed order)
```

#### **Case 3: Circle-Circle Intersection** (lines 1884-1890)
```dart
else if (first is GeoCircle && second is GeoCircle) {
  intersection = GeoIntersection.circleCircle(...);
}
```

### 5.2 Geometric Calculation Details

#### **Line-Line Intersection** (`GeoIntersection.lineLine()`)
- **Location**: `packages/geodraw/lib/models/simple_lists/geo_intersection.dart` (lines 80-124)
- **Steps**:
  1. **Wedge Product Check**:
     ```dart
     final wedge = line1.multivector ^ line2.multivector;
     if (wedge.isZero()) {
       return null; // Lines are parallel
     }
     ```
  2. **Intersection Calculation**:
     ```dart
     final intersectionMv = constructLineLineIntersection(
       line1.multivector,
       line2.multivector,
     );
     ```
     - Calls `geocalc` function from `packages/geocalc/lib/definitions.dart`
     - Uses multivector geometric algebra
  3. **Validation**:
     - Checks if point lies on both lines: `isPointOnLine(intersectionMv, line1.multivector)`
     - Checks if point is finite: `_isFinitePoint(intersectionMv)`
  4. **Point Creation**:
     ```dart
     final point = _pointFromMultivector(
       idSeed: id,
       index: 0,
       label: label,
       multivector: intersectionMv,
       color: color,
       visible: visible,
     );
     ```
  5. **Return GeoIntersection**:
     - Creates `GeoIntersection` with 1 point in `objects` list
     - Dependencies: `[line1.id, line2.id]`

#### **Line-Circle Intersection** (`GeoIntersection.lineCircle()`)
- **Location**: `packages/geodraw/lib/models/simple_lists/geo_intersection.dart` (lines 127-176)
- **Steps**:
  1. **Calculation**:
     ```dart
     final intersections = constructLineCircleIntersection(
       line.multivector,
       circle.multivector,
     );
     ```
     - Returns list of up to 2 `Multivector` points
  2. **Validation Loop**:
     - For each candidate intersection point:
       - Checks if finite: `_isFinitePoint(candidate)`
       - Verifies on line: `isPointOnLine(candidate, line.multivector)`
       - Verifies on circle: `isPointOnCircle(candidate, circle.multivector)`
       - Checks for duplicates: `_containsPoint(points, candidate)`
  3. **Point Creation**:
     - Creates `GeoPointer` for each valid intersection
     - Labels: `"Int1"` for single, `"Int1_1"`, `"Int1_2"` for multiple
  4. **Return GeoIntersection**:
     - Contains list of 0-2 points
     - Dependencies: `[line.id, circle.id]`

#### **Circle-Circle Intersection** (`GeoIntersection.circleCircle()`)
- **Location**: `packages/geodraw/lib/models/simple_lists/geo_intersection.dart` (lines 179-228)
- **Steps**: Similar to line-circle but:
  - Calls `constructCircleCircleIntersection(circle1.multivector, circle2.multivector)`
  - Validates points on both circles
  - Returns up to 2 intersection points

### 5.3 Object Registration
- **Location**: `packages/geodraw/lib/core/command/command_registry.dart` (line 1897)
- **Action**:
  ```dart
  context.dagManager.addObject(intersection, intersection.dependencies);
  ```
- **What Happens**:
  1. Adds `GeoIntersection` object to DAG (Directed Acyclic Graph)
  2. Records dependencies (the two input objects)
  3. DAG manages object relationships and update propagation

---

## **Phase 6: Result Handling**

### 6.1 Success Result Creation
- **Location**: `packages/geodraw/lib/core/command/command_registry.dart` (lines 1899-1908)
- **Action**:
  ```dart
  final count = intersection.objects.length;
  final message = count == 0
      ? 'Created ${intersection.label} (no intersections found)'
      : 'Created ${intersection.label} with $count intersection${count == 1 ? '' : 's'}';
  
  return ExecutionResult.successful(
    objectId: intersection.id,
    message: message,
    object: intersection,
  );
  ```

### 6.2 Result Propagation
- **Location**: `packages/geodraw/lib/tools/unified_tool.dart` (lines 137-144)
- **On Success**:
  1. Extracts geometry object: `result.object as GeometryObject`
  2. Calls callback: `onObjectCreated?.call(geometry, geometry.dependencies)`
     - Notifies UI to display new intersection points
  3. Updates tool state: `notifyStateChanged(result.message)`
     - Example: "Created Int1 with 2 intersections"
  4. Records command in history (for undo/redo)
  5. Resets tool state: `_resetInternal(rollback: false)`
     - Clears verifier arguments
     - Tool ready for next intersection operation

### 6.3 Error Handling
- **Location**: `packages/geodraw/lib/tools/unified_tool.dart` (lines 146-148, 58-62)
- **On Error**:
  1. Records error in history
  2. Rolls back DAG to history marker (undo any partial changes)
  3. Resets verifier: `verifier.reset()`
  4. Updates state: `notifyStateChanged('Error: ${result.message}')`
  5. Tool remains active for retry

---

## **Phase 7: UI Update**

### 7.1 Canvas Redraw
- The `GeoIntersection` object is now in the DAG
- Canvas automatically redraws when DAG changes
- Intersection points are displayed:
  - Color: Orange (default)
  - Style: Points from `GeoIntersection.objects` list
  - Labels: As assigned during calculation

### 7.2 Tool State Reset
- **Location**: `packages/geodraw/lib/tools/unified_tool.dart` (lines 64-72)
- **Action**: `_resetInternal(rollback: false)`
  - Clears `verifier.arguments` → `[]`
  - Clears history marker
  - Updates state: "Select two objects to find intersection"
- Tool is ready for another intersection operation

---

## **Summary Flow Diagram**

```
User Clicks Icon
    ↓
ToolManager.selectTool(ToolType.intersection)
    ↓
_createTool() → _IntersectionTool instance
    ↓
UnifiedTool initialized (creates ToolVerifier + SimpleExecutor)
    ↓
User Clicks First Object
    ↓
_handleClick() → proximitySearch() → finds object
    ↓
_addArgument(firstObject) → verifier.arguments = [firstObject]
    ↓
State: "Select second object"
    ↓
User Clicks Second Object
    ↓
_addArgument(secondObject) → verifier.arguments = [firstObject, secondObject]
    ↓
verifier.isComplete == true
    ↓
_executeCommand()
    ↓
SimpleExecutor.execute(commandName: 'intersection', arguments: [...])
    ↓
CommandRegistry executor function
    ↓
Detect object types → Route to calculation method
    ↓
GeoIntersection.lineLine() / lineCircle() / circleCircle()
    ↓
constructLineLineIntersection() [geocalc]
    ↓
Create GeoPointer objects from Multivector results
    ↓
Create GeoIntersection with points list
    ↓
dagManager.addObject(intersection, dependencies)
    ↓
Return ExecutionResult.successful
    ↓
onObjectCreated callback → UI updates
    ↓
notifyStateChanged("Created Int1 with 2 intersections")
    ↓
Reset tool → Ready for next operation
```

---

## **Key Data Structures**

### **ToolVerifier**
- Maintains: `arguments` list (selected objects)
- Validates against: `CommandSchema`
- Tracks: argument count and types

### **GeoIntersection**
- Type: `GenSimpleGeometryObjectList<GeoPoint>`
- Contains:
  - `objects`: List of intersection points (0-2 points)
  - `dependencies`: IDs of input objects [first.id, second.id]
  - `id`: Unique identifier
  - `label`: Display name ("Int1", etc.)

### **ExecutionResult**
- Contains:
  - `success`: Boolean
  - `object`: Created geometry object (GeoIntersection)
  - `message`: User-facing message
  - `objectId`: ID of created object

---

## **Error Scenarios**

1. **Parallel Lines**: `lineLine()` returns `null` → Error: "Lines are parallel - no intersection found"
2. **No Nearby Objects**: Click on empty space → No object selected, tool waits
3. **Invalid Type**: Click on unsupported object → Validation error
4. **Calculation Failure**: Geometric calculation throws exception → Caught and returned as error

---

## **Mathematical Backend**

- **Library**: `packages/geocalc/lib/definitions.dart`
- **Functions**:
  - `constructLineLineIntersection(Multivector, Multivector) → Multivector`
  - `constructLineCircleIntersection(Multivector, Multivector) → List<Multivector>`
  - `constructCircleCircleIntersection(Multivector, Multivector) → List<Multivector>`
- **Method**: Multivector Geometric Algebra (GA)
- **Coordinates**: Results in multivector form, extracted as `(x, y)` for point creation

---

**End of Flow Documentation**

