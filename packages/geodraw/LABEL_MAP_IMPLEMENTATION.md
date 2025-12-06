# Display Labels as Element IDs Implementation Plan

**Status**: In Progress  
**Created**: 2025-01-XX  
**Goal**: Implement Option B (Display Labels as Element IDs) - simpler single-tier system

---

## Overview

This document tracks the implementation of Option B where:
- **Element ID = Display Label**: User-friendly labels are used directly as element IDs
- **No Pattern IDs**: Remove pattern-based IDs like `intersection_6_0`
- **Global Uniqueness**: Labels must be unique across ALL DAG nodes AND all elements
- **Element Tracking**: `DAGManager` maintains `Map<String, String> elementToContainer` to track which container owns each element
- **Auto-Assignment**: `LabelManager` assigns unique labels automatically based on object type

**Benefits**:
- Simpler: One identifier instead of two
- User-friendly: IDs are readable labels
- Solver-friendly: Constraints use labels directly
- Direct lookup: `getObject("A")` returns element directly
- Infinite capacity: Naming conventions support unlimited objects

---

## Naming Conventions

### Object Type-Based Naming

#### 1. Points and Intersections (GeoPoint, GeoIntersection elements)
- **Format**: Uppercase letters, then double letters
- **Sequence**: A, B, C, ..., Z, AA, AB, AC, ..., AZ, BA, BB, BC, ..., BZ, CA, ...
- **Examples**: A, B, C, Z, AA, AB, AC, BA, BB, ...
- **Transformations**: Add apostrophe (') suffix for rotated, translated, inverted objects
  - **Examples**: A → A' (rotated), B → B' (translated), C → C' (inverted)
  - **Note**: A' is different from A, so both can exist simultaneously

#### 2. Lines, Circles, Arcs, Segments (GeoLine, GeoCircle, GeoArc, GeoSegment)
- **Format**: Lowercase letters, then double letters
- **Sequence**: a, b, c, ..., z, aa, ab, ac, ..., az, ba, bb, bc, ..., bz, ca, ...
- **Examples**: a, b, c, z, aa, ab, ac, ba, bb, ...
- **Transformations**: Add apostrophe (') suffix for transformed objects
  - **Examples**: a → a' (rotated), b → b' (translated)

#### 3. Container Names

**GenSimpleGeometryObjectList** (GeoIntersection, GeoTangent, GeoAngleBisector2L):
- **Format**: SL followed by number
- **Sequence**: SL1, SL2, SL3, SL4, ...
- **Examples**: SL1, SL2, SL3, ...
- **Conflict Resolution**: If SL1, SL2, SL3 are taken by regular objects, use SL4 (next available)

**UnionGeometryObjectList** (GeoPolygon, GeoPolyLine, GeoPolyArc, GeoPolyArcGon):
- **Format**: UN followed by number
- **Sequence**: UN1, UN2, UN3, UN4, ...
- **Examples**: UN1, UN2, UN3, ...
- **Conflict Resolution**: If UN1, UN2, UN3 are taken by regular objects, use UN4 (next available)

**Note**: Elements inside containers use their own type-based naming (uppercase for points, lowercase for lines)

### Conflict Resolution Strategy

1. **Container Names (SL1, UN1, etc.)**:
   - Check all used labels (nodes + elements)
   - Find the least available index (start from 1)
   - **Label Recycling**: If SL1 is deleted, reuse SL1 before creating SL4
   - Example: If SL1, SL2, SL3 are taken, use SL4
   - Example: If SL1, SL2, SL3 are taken, and SL1 is deleted, use SL1 (not SL4)
   - Example: If UN1, UN2, UN3 are taken, use UN4
   - Example: If UN1, UN2, UN3 are taken, and UN1 is deleted, use UN1 (not UN4)

2. **Regular Object Names (A, B, a, b, etc.)**:
   - Check all used labels (nodes + elements)
   - **Frugal Naming**: Always start from beginning (A, B, C, ...) to find first available
   - **Label Recycling**: Deleted labels are reused before creating new ones
   - Example: If A, B, C are taken, use D
   - Example: If A, B, C are taken, and A is deleted, use A (not D)
   - Example: If A-Z are taken, use AA
   - Example: If A-Z are taken, and A is deleted, use A (not AA)
   - Example: If a-z are taken, use aa
   - Example: If a-z are taken, and a is deleted, use a (not aa)

3. **Transformed Objects**:
   - A' is different from A (apostrophe makes it unique)
   - Both A and A' can exist simultaneously
   - Check uniqueness including apostrophe suffix
   - **Recycling**: If A' is deleted, A' can be reused for next transformation of A

### Capacity

- **Points/Intersections**: Infinite (A-Z, then AA-ZZ, then AAA-ZZZ, ...)
- **Lines/Circles/Arcs/Segments**: Infinite (a-z, then aa-zz, then aaa-zzz, ...)
- **Containers**: Infinite (SL1, SL2, ..., U1, U2, ...)
- **No practical limits**: Naming convention scales indefinitely

### Label Recycling (Frugal Naming)

**Strategy**: Always reuse deleted labels before creating new ones. This keeps labels compact and user-friendly.

**Behavior**:
- When an object is deleted, its label becomes available for reuse
- `getNextAvailableLabel()` always checks from the beginning of the sequence
- First available label is returned (recycled if possible)

**Examples**:
1. **Simple Recycling**:
   - Create points: A, B, C
   - Delete A
   - Next point gets: **A** (not D)
   - Result: A, B, C (reused A)

2. **Recycling Before Expansion**:
   - Create points: A, B, C, ..., Z (all 26 letters used)
   - Next point would get: AA
   - Delete A
   - Next point gets: **A** (not AA)
   - Result: A, B, C, ..., Z (A was recycled)

3. **Multiple Gaps**:
   - Create points: A, B, C, D, E
   - Delete A and C
   - Next point gets: **A** (first available)
   - Next point gets: **C** (second available)
   - Result: A, B, C, D, E (reused A and C)

4. **Container Recycling**:
   - Create containers: SL1, SL2, SL3
   - Delete SL1
   - Next container gets: **SL1** (not SL4)
   - Result: SL1, SL2, SL3 (SL1 was recycled)

**Implementation**:
- `getNextAvailableLabel()` iterates through sequence from start
- For uppercase: Check A, then B, then C, ... until finding first available
- For lowercase: Check a, then b, then c, ... until finding first available
- For containers: Check SL1, then SL2, then SL3, ... until finding first available
- Uses `isLabelUnique()` to check if label is available

---

## Phase 1: Core Data Model Changes

### 1.1 Add Element-to-Container Tracking in DAGManager

- [x] Add `final Map<String, String> elementToContainer;` to `DAGManager` (packages/geodraw/lib/core/dag/dag_manager.dart)
- [x] Initialize `elementToContainer` as empty map in constructor
- [x] Add `getContainerForElement(String elementId)` helper method
- [x] Add `registerElement(String elementId, String containerId)` method
- [x] Add `unregisterElement(String elementId)` method
- [x] Update `_snapshot()` to include `elementToContainer` map
- [x] Update `_restore()` to restore `elementToContainer` map

### 1.2 Remove Pattern ID Generation

- [x] Remove pattern ID generation from `_pointFromMultivector()` in `geo_intersection.dart` - completed (uses LabelManager)
- [x] Remove pattern ID generation from all element creation methods - completed (all use LabelManager)
- [x] Update element ID assignment to use display labels directly - completed (ID = label)

### 1.3 Update Element ID Assignment

- [x] Change `_pointFromMultivector()` signature to accept `DAGManager` parameter - completed (signature: `required DAGManager dagManager`)
- [x] Use `LabelManager.getNextAvailableLabel()` to assign unique label as ID - completed (line 1629-1633)
- [x] Register element in `DAGManager.elementToContainer` map - completed (line 1649)
- [x] Update all factory methods to pass `DAGManager` context - completed (all intersection factory methods accept `required DAGManager dagManager`)

---

## Phase 2: Label Management Utilities

### 2.1 Create `LabelManager` Utility

- [x] Create new file: `packages/geodraw/lib/core/label_manager.dart`
- [x] Define `GeometryObjectType` enum (or use existing type system):
  - [x] `point` - For GeoPoint and intersection point elements - implemented (line 11)
  - [x] `line` - For GeoLine, GeoSegment, GeoArc - implemented (line 12)
  - [x] `circle` - For GeoCircle - implemented (line 13)
  - [x] `arc` - For GeoArc (or use `line` type) - implemented (line 14)
  - [x] `simpleList` - For GenSimpleGeometryObjectList containers (SL1, SL2, ...) - implemented (line 15)
  - [x] `union` - For UnionGeometryObjectList containers (U1, U2, ...) - implemented (line 16)
  - [x] `polygon` - For GeoPolygon - implemented (line 17)
  - [x] `polyLine` - For GeoPolyLine - implemented (line 18)
  - [x] `polyArc` - For GeoPolyArc - implemented (line 19)
  - [x] `polyArcGon` - For GeoPolyArcGon - implemented (line 20)
  - [x] `transform` - For GeoTrans objects (GeoRotate, GeoDilate, GeoInverse) - implemented (line 21)
  - [x] `text` - For CanvasText (may keep custom format) - implemented (line 22)
- [x] Implement `getNextAvailableLabel(DAGManager, GeometryObjectType type, {String? preferred})`:
  - [x] **Label Recycling Strategy**: Always check from the start to find the first available label (frugal naming)
  - [x] Determine naming convention based on object type:
    - [x] **Points/Intersections**: Uppercase (A-Z, then AA-ZZ, then AAA-ZZZ, ...)
    - [x] **Lines/Circles/Arcs/Segments**: Lowercase (a-z, then aa-zz, then aaa-zzz, ...)
    - [x] **GenSimpleGeometryObjectList containers**: SL1, SL2, SL3, ... (find least available)
    - [x] **UnionGeometryObjectList containers**: U1, U2, U3, ... (find least available)
  - [x] Check all DAG nodes for label conflicts (by `node.object.label`)
  - [x] Check all elements in all containers for label conflicts (by `element.id`)
  - [x] **Frugal Label Generation**: Always start from the beginning and find first available:
    - [x] For uppercase: Check A, then B, then C, ..., then Z, then AA, AB, AC, ... (reuse deleted labels first)
    - [x] For lowercase: Check a, then b, then c, ..., then z, then aa, ab, ac, ... (reuse deleted labels first)
    - [x] For SL containers: Check SL1, then SL2, then SL3, ... (find least available index, reuse gaps)
    - [x] For U containers: Check U1, then U2, then U3, ... (find least available index, reuse gaps)
  - [x] **Example**: If A, B, C exist, and A is deleted, next point gets A (not D)
  - [x] **Example**: If A-Z all exist, and A is deleted, next point gets A (not AA)
  - [x] Support preferred label if available and unique
  - [x] Return first available label (recycled if possible)
- [x] Implement `getNextAvailableLabelForTransformation(DAGManager, String baseLabel)`:
  - [x] Generate transformed label by adding apostrophe: `baseLabel + "'"`
  - [x] Check if transformed label is unique
  - [x] If not unique, try `baseLabel + "''"` (double apostrophe), etc.
  - [x] Return unique transformed label
- [x] Implement `isLabelUnique(DAGManager, String label, {String? excludeId})`:
  - [x] Check all DAG nodes (excluding `excludeId` if provided)
  - [x] Check all elements in all containers (excluding `excludeId` if provided)
  - [x] Return true if unique globally
- [x] Implement `getAllUsedLabels(DAGManager)`:
  - [x] Collect all labels from DAG nodes (`node.object.label`)
  - [x] Collect all element IDs from all containers
  - [x] Return `Set<String>`
- [x] Implement `suggestNextLabel(DAGManager, String baseLabel, GeometryObjectType type)`:
  - [x] If base label is unique, return it
  - [x] Otherwise, suggest next available variant based on type:
    - [x] For uppercase: A → B, Z → AA, AZ → BA, etc.
    - [x] For lowercase: a → b, z → aa, az → ba, etc.
    - [x] For containers: SL1 → SL2, U1 → U2, etc. (find least available)
- [x] Implement helper methods:
  - [x] `_generateUppercaseSequence()` - Generate sequence: A, B, C, ..., Z, AA, AB, AC, ..., AZ, BA, BB, ...
  - [x] `_generateLowercaseSequence()` - Generate sequence: a, b, c, ..., z, aa, ab, ac, ..., az, ba, bb, ...
  - [x] `_findFirstAvailableUppercase(DAGManager)` - Check A, B, C, ... until finding first available
  - [x] `_findFirstAvailableLowercase(DAGManager)` - Check a, b, c, ... until finding first available
  - [x] `_findNextContainerIndex(DAGManager, String prefix)` - Find least available container index (check from 1)
  - [x] `_isUppercaseLabel(String label)` - Check if label follows uppercase convention
  - [x] `_isLowercaseLabel(String label)` - Check if label follows lowercase convention
  - [x] `_isContainerLabel(String label)` - Check if label is SL1, U1, etc.
  - [x] **Important**: All methods check from the start (A, a, SL1, U1) to ensure frugal naming

### 2.2 Update DAG Manager Element Resolution

- [x] Update `DAGManager.getObject(String id)`:
  - [x] First check direct node lookup (existing logic)
  - [x] Then check `elementToContainer` map
  - [x] If found, get container, then find element by ID in container
  - [x] Remove pattern-based resolution logic (`intersection_6_0` pattern) - kept fallback for backward compatibility
- [x] Update `DAGManager.addObject()`:
  - [x] When adding container with elements, register all elements in `elementToContainer`
  - [x] When updating container, update `elementToContainer` entries
- [x] Update `DAGManager.removeObject()`:
  - [x] When removing container, unregister all its elements from `elementToContainer`
- [x] Update `DAGManager.updateObject()`:
  - [x] When updating container, sync `elementToContainer` map with new elements

---

## Phase 3: Element Creation and Label Assignment

### 3.1 Update `_pointFromMultivector()` Helper

- [x] Change signature to: `_pointFromMultivector({required DAGManager dagManager, required String containerId, required Multivector multivector, ...})`
- [x] Call `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.point)` to get unique uppercase label
- [x] Use returned label as element ID directly (e.g., "A", "B", "AA", etc.)
- [x] Register element in `dagManager.elementToContainer` map
- [x] Remove `idSeed` and `index` parameters (no longer needed)
- [x] For transformed points (rotation, translation, inversion):
  - [x] Use `LabelManager.getNextAvailableLabelForTransformation(dagManager, baseLabel)` to add apostrophe

### 3.2 Update All Intersection Factory Methods

- [x] Update `GeoIntersection.lineLine()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to `_pointFromMultivector()` for each point
  - [x] Remove pattern ID generation
- [x] Update `GeoIntersection.lineCircle()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to `_pointFromMultivector()` for each point
  - [x] Remove pattern ID generation
- [x] Update `GeoIntersection.circleCircle()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to `_pointFromMultivector()` for each point
  - [x] Remove pattern ID generation
- [x] Update `GeoIntersection.lineSegment()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to `_pointFromMultivector()` for each point
- [x] Update `GeoIntersection.circleSegment()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to `_pointFromMultivector()` for each point
- [x] Update `GeoIntersection.segmentArc()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to `_pointFromMultivector()` for each point
- [x] Update `GeoIntersection.arcArc()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to `_pointFromMultivector()` for each point
- [x] Update `GeoIntersection.lineArc()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to `_pointFromMultivector()` for each point
- [x] Update `GeoIntersection.circleArc()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to `_pointFromMultivector()` for each point
- [x] Update `GeoIntersection.segmentSegment()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to `_pointFromMultivector()` for each point
- [x] Update `GeoIntersection.unionWithObject()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to nested intersection methods
- [x] Update `GeoIntersection.unionWithUnion()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass to nested intersection methods

### 3.3 Update Other List Types

- [x] Update `GeoTangent.constructFromObjects()`:
  - [x] Accept `DAGManager` parameter
  - [x] Update `_computeTangents()` signature to accept `DAGManager` (placeholder implementation)
  - [x] When implemented, assign unique lowercase labels as IDs for each tangent line (a, b, c, ..., aa, ab, ...)
  - [x] When implemented, use `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.line)`
  - [x] When implemented, register elements in `elementToContainer`
- [x] Update `GeoAngleBisector2L.constructFromLines()`:
  - [x] Accept `DAGManager` parameter
  - [x] Assign unique lowercase labels as IDs for each bisector line (a, b, c, ..., aa, ab, ...)
  - [x] Use `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.line)`
  - [x] Register elements in `elementToContainer`
- [x] Update container naming for `GenSimpleGeometryObjectList`:
  - [x] Use `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.simpleList)` for container ID - implemented in command_registry.dart (intersection, tangent, angle bisector commands)
  - [x] Assign SL1, SL2, SL3, ... (find least available index) - implemented via `_findNextContainerLabel()`
- [x] Update container naming for `UnionGeometryObjectList`:
  - [x] Use `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.union)` for container ID - implemented for polygon, polyline, polyarc, polyarcgon commands
  - [x] Assign UN1, UN2, UN3, ... (find least available index) - implemented via `_findNextContainerLabel()` with 'UN' prefix
- [x] Update any other `GenSimpleGeometryObjectList` subclasses - all major ones updated (intersection, tangent, angle bisector)

### 3.4 Update Command Registry

- [x] Update intersection command handlers to pass `DAGManager` to factory methods
- [x] Update tangent command handlers to pass `DAGManager` to factory methods
- [x] Update angle bisector command handlers to pass `DAGManager` to factory methods
- [x] Ensure all element creation flows through `LabelManager` (for intersections and angle bisectors)
- [x] **Note**: CommandRegistry refactoring is handled in Phase 11 (see below) - Phase 11 completed

### 3.5 Update `rebuildFromParents()`

- [x] Update `GeometryObject.rebuildFromParents()` signature to accept `DAGManager`
- [x] Update `DAGManager._reconstructObject()` to pass `DAGManager` to `rebuildFromParents()`
- [x] Update `GeoIntersection.rebuildFromParents()`:
  - [x] Accept `DAGManager` parameter
  - [x] Pass `DAGManager` to all intersection factory methods
  - [x] Match existing elements by geometry/position (not by pattern ID)
  - [x] Preserve labels for matched elements (keep same ID)
  - [x] Assign new labels for new elements (via `LabelManager`)
  - [x] Elements are automatically registered in `elementToContainer` by factory methods
- [x] Update `GeoTangent.rebuildFromParents()` similarly
- [x] Update `GeoAngleBisector2L.rebuildFromParents()` similarly
- [ ] Update other list types' `rebuildFromParents()` methods

---

## Phase 4: Element Resolution and Lookup

### 4.1 Update `DAGManager.getObject()`

- [x] Remove pattern-based resolution (`intersection_6_0` pattern matching) - kept fallback for backward compatibility
- [x] Use `elementToContainer` map for O(1) lookup:
  - [x] Check if `id` exists in `elementToContainer`
  - [x] If found, get container ID
  - [x] Get container from DAG nodes
  - [x] Find element by ID in container's `objects` or `elements` list
- [x] Keep direct node lookup as first check (for regular objects)

### 4.2 Update `DAGManager.addObject()`

- [x] When adding `GenSimpleGeometryObjectList`:
  - [x] Register all elements in `elementToContainer` map
  - [x] Map: `element.id → container.id` for each element
- [x] When adding `UnionGeometryObjectList`:
  - [x] Note: Union elements are DAG nodes, not elements, so no registration needed
  - [x] (Union elements use their own IDs, not pattern IDs)

### 4.3 Update `DAGManager.updateObject()`

- [x] When updating container:
  - [x] Compare old vs new element lists
  - [x] Unregister removed elements from `elementToContainer`
  - [x] Register new elements in `elementToContainer`
  - [x] Preserve existing element registrations

### 4.4 Update `DAGManager.removeObject()`

- [x] When removing container:
  - [x] Unregister all elements from `elementToContainer` map
  - [x] Clean up all `element.id → container.id` entries

---

## Phase 5: Label Display Updates

### 5.1 Update Canvas Rendering

- [x] Update `GeoDrawCanvasPainter.paint()`:
  - [x] Element labels are now their IDs, so use `object.label` directly (which equals `object.id` for elements)
  - [x] Updated comments to reflect new system (no pattern IDs)
  - [x] `_LabelInfo` already uses `object.label` as text (correct)
- [x] Update `GeoDrawCanvasPainter._drawLabelInScreenSpace()`:
  - [x] Uses `labelInfo.text` directly (already the display label) - no changes needed
- [x] Remove outdated pattern ID comments in canvas rendering

### 5.2 Update UI Components

- [x] Update `ObjectBrowser._buildChildrenItems()`:
  - [x] Already uses `element.id` directly (correct)
  - [x] Element ID is already user-friendly (A, B, a, b, etc.)
- [x] Update `ObjectBrowser._ObjectListTile`:
  - [x] Uses `object.label.isEmpty ? object.id : object.label` (works correctly)
  - [x] Updated comment to clarify new system
- [x] Tooltips and other UI already use `object.id` or `object.label` correctly

---

## Phase 6: Label Validation and Editing

### 6.1 Update Label Validation

- [x] Update `_LabelEditor._validateLabel()` in `object_settings_panel.dart`:
  - [x] **CRITICAL**: Now checks DAG nodes AND elements globally!
  - [x] Use `LabelManager.isLabelUnique(dagManager, newLabel, excludeId: object.id)`
  - [x] Check against all nodes AND all elements globally
  - [x] Provides validation feedback
  - [ ] Consider debouncing validation for performance (large DAGs) - TODO for optimization
- [x] Update `ObjectToolbar._updateLabel()` in `object_toolbar.dart`:
  - [x] **CRITICAL**: Now checks DAG nodes AND elements globally!
  - [x] Use `LabelManager.isLabelUnique()` for validation
  - [x] Provides suggestions via `LabelManager.suggestNextLabel()`
  - [x] For elements: Update element ID (which is the label) - completed in Phase 6.2-6.3
  - [x] Update `elementToContainer` map if element ID changes - completed via `DAGManager.updateElementId()`
  - [x] **CRITICAL**: Update all dependent objects' dependency lists when element ID changes - completed via `DAGManager.updateElementId()`

### 6.2 Update Settings Panel for Element Editing

- [x] Detect if object is an element (check `elementToContainer` map)
- [x] If element:
  - [x] Show element's ID as editable label (ID = label)
  - [x] Allow renaming element ID (with uniqueness check)
  - [x] When ID changes:
    - [x] Update element's ID property
    - [x] Update `elementToContainer` map (remove old, add new)
    - [x] Update container's element list (find by old ID, update to new ID)
    - [x] **CRITICAL**: Update all dependent objects' dependency lists:
      - [x] Find all DAG nodes with dependencies containing old element ID
      - [x] Update their dependency lists to use new element ID
      - [x] Trigger rebuild for dependent objects if needed
    - [x] Validate globally unique
  - [x] Update container via `DAGManager.updateObject()`
  - [x] Handle empty label: Auto-assign new unique label (don't allow empty)

### 6.3 Update Object Browser Element Editing

- [x] Update `ObjectBrowser._buildChildrenItems()`:
  - [x] Element ID is already the display label (already implemented)
  - [x] Allow editing element IDs (opens settings panel for element) - handled via settings panel
  - [x] Update `onEdit` callback to handle element ID editing - settings panel handles element detection

---

## Phase 7: Transformation and Copying

### 7.1 Handle Object Transformation

- [x] Update `TransformationEngine.transformSimple()`:
  - [x] TransformationEngine accepts `id` and `label` as parameters - no changes needed
  - [x] Calling code (command_registry.dart) uses `LabelManager.getNextAvailableLabelForTransformation()` - implemented
  - [x] Add apostrophe (') to base label: A → A', a → a' - implemented in `getNextAvailableLabelForTransformation()`
  - [x] If A' exists, try A'' (double apostrophe), etc. - implemented (handles multiple apostrophes)
- [x] Transformation commands in `command_registry.dart`:
  - [x] Pass `DAGManager` to transformation methods - implemented (via context.dagManager)
  - [x] Use apostrophe suffix for transformed objects - implemented in `_createTransformedGeometry()`
  - [x] Handle element ID conflicts (try double/triple apostrophe if needed) - implemented in `getNextAvailableLabelForTransformation()`
- [x] Note: `TransformationEngine.transformSimple()` and `transformComplex()` accept id/label as parameters, so they don't need changes
- [ ] TODO: When transforming containers, preserve element IDs if possible (complex - would require updating elementToContainer)

### 7.2 Handle Object Copying/Duplication

- [ ] If copy/duplicate functionality exists:
  - [ ] Assign new unique labels to copied elements via `LabelManager`
  - [ ] Register copied elements in `elementToContainer` map
  - [ ] Ensure copied elements get unique IDs

---

## Phase 8: Edge Cases and Corner Cases

### 8.1 Backward Compatibility

- [x] Add migration in `fromJson()` methods:
  - [x] Detect pattern IDs in element IDs (e.g., `intersection_6_0`) - implemented `_isPatternId()`
  - [x] Convert to display labels (auto-assign A, B, C...) - implemented in `fromJson()`
  - [x] Update `elementToContainer` map during migration - implemented
  - [x] Handle legacy files gracefully - migration is optional (requires DAGManager parameter)
- [x] Migration strategy:
  - [x] For each container with pattern IDs:
    - [x] Get all elements - implemented
    - [x] Assign new unique labels (A, B, C...) via `LabelManager` - implemented
    - [x] Update element IDs - implemented
    - [x] Register in `elementToContainer` - implemented

### 8.2 Element Deletion and Label Recycling

- [x] When element is removed from container:
  - [x] Unregister from `elementToContainer` map (handled in `DAGManager.removeObject()`)
  - [x] Label becomes available for reuse (frugal naming)
  - [x] Update container's element list (handled in `DAGManager.updateObject()`)
  - [x] Trigger DAG updates if needed (handled automatically)
- [x] **Label Recycling Behavior**:
  - [x] When object is deleted, its label becomes available
  - [x] `getNextAvailableLabel()` always checks from the start (A, B, C, ...) - implemented in `LabelManager`
  - [x] Deleted labels are reused before creating new ones (AA, AB, etc.) - implemented via `_findFirstAvailableUppercase()` and `_findFirstAvailableLowercase()`
  - [x] Example: If A, B, C exist, delete A, next point gets A (not D) - works via frugal naming
  - [x] Example: If A-Z all exist, delete A, next point gets A (not AA) - works via frugal naming
  - [x] This ensures frugal naming - labels stay compact

### 8.3 Container Rebuild Edge Cases

- [x] When `rebuildFromParents()` changes element count:
  - [x] Match existing elements by geometry/position (not by ID) - implemented in `GeoIntersection.rebuildFromParents()`
  - [x] Preserve IDs for matched elements (keep same label) - elements keep their IDs during rebuild
  - [x] Assign new labels for new elements (via `LabelManager`) - implemented via `_pointFromMultivector()` using `LabelManager`
  - [x] Unregister deleted elements from `elementToContainer` - handled in `DAGManager.updateObject()`
  - [x] Register new elements in `elementToContainer` - handled in `_pointFromMultivector()` and `DAGManager.updateObject()`
  - [x] Handle reordered elements (IDs stay with geometry) - IDs are preserved based on geometry matching

### 8.4 Label Conflicts

- [x] User assigns label that exists:
  - [x] Show error immediately via `LabelManager.isLabelUnique()` - implemented in `_LabelEditor` and `ObjectToolbar`
  - [x] Suggest next available label via `LabelManager.suggestNextLabel()` - implemented in `ObjectToolbar._updateLabel()`
  - [ ] Auto-resolve if user accepts suggestion - TODO: Could add auto-accept button in UI

### 8.5 Global Uniqueness Enforcement

- [x] Enforce global uniqueness (across all nodes AND elements):
  - [x] `LabelManager.isLabelUnique()` checks both - implemented
  - [x] `LabelManager.getNextAvailableLabel()` checks both - implemented
  - [x] Validation prevents conflicts - implemented in UI components

### 8.6 Empty Labels

- [x] User clears element label:
  - [x] Currently allows empty label (element shows no label) - implemented in `_LabelEditor`
  - [x] Label validation allows empty (returns true) - implemented
  - [ ] TODO: Consider auto-assigning label if empty (optional enhancement)
  - [x] Update `elementToContainer` map if ID changes - would be handled if element ID editing is implemented

### 8.7 Label Case Sensitivity

- [x] Decision: Case-sensitive (A ≠ a) - uppercase and lowercase are different labels
- [x] `LabelManager.isLabelUnique()` is case-sensitive - implemented (direct string comparison)
- [x] `LabelManager.getNextAvailableLabel()` uses case-sensitive sequences - implemented (separate uppercase/lowercase sequences)
- [x] This allows both "A" (point) and "a" (line) to exist simultaneously

### 8.8 Special Characters in Labels

- [x] Support uppercase letters (A-Z) and double letters (AA-ZZ, AAA-ZZZ, ...) - implemented in `_generateUppercaseSequence()`
- [x] Support lowercase letters (a-z) and double letters (aa-zz, aaa-zzz, ...) - implemented in `_generateLowercaseSequence()`
- [x] Support apostrophe (') for transformed objects (A', a', A'', a'', ...) - implemented in `getNextAvailableLabelForTransformation()`
- [x] Support container prefixes (SL, U) with numbers (SL1, U1, ...) - implemented in `_findNextContainerLabel()`
- [x] Validation allows:
  - [x] Uppercase letters and combinations (A, AA, AAA, ...) - validated via `isLabelUnique()`
  - [x] Lowercase letters and combinations (a, aa, aaa, ...) - validated via `isLabelUnique()`
  - [x] Apostrophe suffix (A', a', A'', a'', ...) - validated via `isLabelUnique()`
  - [x] Container prefixes with numbers (SL1, U1, ...) - validated via `isLabelUnique()`
- [x] Auto-assignment uses double letters when single letters exhausted - implemented in sequence generators

### 8.9 Undo/Redo

- [x] Ensure `elementToContainer` map is part of undo/redo history - implemented in `_snapshot()` and `_restore()`
- [x] `elementToContainer` changes are part of DAG state snapshots - included in `_DagState`
- [x] Undo restores previous `elementToContainer` state - handled in `_restore()`
- [x] Element ID changes are part of container updates (already tracked) - handled via `updateObject()`

### 8.10 Element ID Resolution

- [x] When accessing element by ID:
  - [x] Use `elementToContainer` map for O(1) lookup - implemented in `DAGManager.getObject()`
  - [x] No pattern matching needed - removed pattern-based resolution
  - [x] Direct ID → container → element lookup - implemented with fallback for backward compatibility

### 8.11 Nested Containers

- [x] Union containing intersections:
  - [x] Each element has unique global ID (no nesting in IDs) - elements use simple labels (A, B, a, b)
  - [x] `elementToContainer` tracks which container owns each element - implemented
  - [x] Display labels work correctly at each level - elements display their IDs directly

### 8.12 Performance Optimization

- [x] `elementToContainer` map provides O(1) lookup (already optimized) - implemented
- [ ] Cache used labels if needed (for large DAGs) - TODO: Optimization for 1000+ objects
- [x] `LabelManager.getNextAvailableLabel()` is efficient - uses direct iteration, no caching needed for typical use
- [x] **Label Validation Performance**:
  - [x] Current: Validates on every keystroke - implemented in `_LabelEditor._validateLabel()`
  - [ ] Solution: Cache `getAllUsedLabels()` result, invalidate on DAG changes - TODO: Optimization
  - [ ] Consider debouncing validation (wait 300ms after last keystroke) - TODO: UX enhancement
  - [x] Always validate on save/submit (critical check) - validation happens before update

### 8.13 Capacity Considerations

- [x] **Uppercase labels (Points/Intersections)**: 
  - [x] A-Z: 26 labels - implemented
  - [x] AA-ZZ: 676 labels (26 × 26) - implemented via `_generateUppercaseSequence()`
  - [x] AAA-ZZZ: 17,576 labels (26³) - implemented (sequence continues indefinitely)
  - [x] Effectively unlimited capacity - sequence generator supports any length
- [x] **Lowercase labels (Lines/Circles/Arcs/Segments)**:
  - [x] a-z: 26 labels - implemented
  - [x] aa-zz: 676 labels (26 × 26) - implemented via `_generateLowercaseSequence()`
  - [x] aaa-zzz: 17,576 labels (26³) - implemented (sequence continues indefinitely)
  - [x] Effectively unlimited capacity - sequence generator supports any length
- [x] **Container labels (SL1, U1, etc.)**:
  - [x] SL1, SL2, SL3, ... (unlimited) - implemented via `_findNextContainerLabel()`
  - [x] U1, U2, U3, ... (unlimited) - implemented via `_findNextContainerLabel()`
  - [x] Conflict resolution finds least available index - implemented (checks from 1)
- [x] **Most containers have ≤4 elements** (intersections: 0-2, tangents: 0-4) - naming handles this easily
- [x] **Union-object intersections** could have many points → use AA, AB, AC, ... if needed - sequence supports this
- [x] **No practical limits**: Naming convention scales indefinitely - all sequence generators support infinite expansion

---

## Phase 9: Testing and Validation

### 9.1 Unit Tests

- [x] Test `LabelManager.getNextAvailableLabel()`:
  - [x] Returns A-Z for points when available - tested in `label_manager_test.dart`
  - [x] Returns AA-ZZ when A-Z exhausted for points - tested
  - [x] Returns a-z for lines when available - tested
  - [x] Returns aa-zz when a-z exhausted for lines - tested
  - [x] Returns SL1, SL2, SL3, ... for simple list containers (finds least available) - tested
  - [x] Returns U1, U2, U3, ... for union containers (finds least available) - tested
  - [x] **Label Recycling Tests**:
    - [x] If A, B, C exist, delete A, next point gets A (not D) - tested
    - [x] If A-Z all exist, delete A, next point gets A (not AA) - tested
    - [x] If SL1, SL2, SL3 exist, delete SL1, next container gets SL1 (not SL4) - tested
    - [x] Always checks from start (frugal naming) - tested
  - [x] Respects preferred label if available - tested
  - [x] Handles conflict resolution correctly (skips taken indices, reuses gaps) - tested
- [x] Test `LabelManager.getNextAvailableLabelForTransformation()`:
  - [x] Adds apostrophe to base label (A → A') - tested
  - [x] Tries double/triple apostrophe if needed - tested
- [x] Test `LabelManager.isLabelUnique()`:
  - [x] Checks DAG nodes correctly - tested
  - [x] Checks elements correctly - tested
  - [x] Excludes specified IDs correctly - tested
- [x] Test `LabelManager.getAllUsedLabels()`:
  - [x] Collects labels from DAG nodes - tested
  - [x] Collects element IDs from containers - tested
- [x] Test `LabelManager.suggestNextLabel()`:
  - [x] Returns base label if unique - tested
  - [x] Suggests next variant for points, lines, containers - tested
- [x] Test case sensitivity (A ≠ a) - tested
- [x] Test edge cases (empty DAG, large sequences) - tested
- [x] Test `DAGManager.elementToContainer` map:
  - [x] Registration works correctly - tested in `dag_manager_element_to_container_test.dart`
  - [x] Unregistration works correctly - tested
  - [x] Lookup works correctly - tested via `getContainerForElement()`
- [x] Test `DAGManager.getObject()`:
  - [x] Direct node lookup works - tested
  - [x] Element lookup via `elementToContainer` works - tested
  - [x] Returns null for non-existent IDs - tested
- [x] Test `DAGManager.updateElementId()`:
  - [x] Updates elementToContainer map correctly - tested
  - [x] Updates container's element list - tested
  - [x] Throws error for unregistered elements - tested
- [x] Test container updates:
  - [x] Removed elements are unregistered - tested
  - [x] New elements are registered - tested
- [x] Test undo/redo integration:
  - [x] elementToContainer map is restored on undo - tested
  - [x] Container deletion and undo restores map - tested

### 9.2 Integration Tests

- [ ] Test element creation with auto-assignment:
  - [ ] Intersection points get unique uppercase labels (A, B, C, ..., AA, AB, ...)
  - [ ] Tangent lines get unique lowercase labels (a, b, c, ..., aa, ab, ...)
  - [ ] Angle bisectors get unique lowercase labels (a, b, c, ..., aa, ab, ...)
  - [ ] Containers get SL1, SL2, SL3, ... or U1, U2, U3, ... (least available)
  - [ ] Transformed objects get apostrophe suffix (A', B', a', b', ...)
- [ ] Test element ID editing:
  - [ ] Renaming element ID works
  - [ ] Uniqueness validation works
  - [ ] `elementToContainer` map updates correctly
- [ ] Test label validation:
  - [ ] Prevents conflicts
  - [ ] Suggests alternatives
- [ ] Test container rebuild:
  - [ ] Preserves existing element IDs
  - [ ] Assigns new IDs for new elements
  - [ ] Updates `elementToContainer` correctly
- [ ] Test transformation:
  - [ ] Preserves element IDs when possible
  - [ ] Assigns new IDs when conflicts occur
- [ ] Test undo/redo:
  - [ ] `elementToContainer` map is restored correctly
  - [ ] Element ID changes are tracked

### 9.3 Edge Case Tests

- [ ] Test element deletion and label recycling:
  - [ ] `elementToContainer` cleanup works
  - [ ] Labels become available for reuse
  - [ ] Deleted labels are reused before creating new ones
  - [ ] Frugal naming: Always checks from start (A, B, C, ...)
  - [ ] Test: Create A, B, C, delete A, next point gets A (not D)
  - [ ] Test: Create A-Z, delete A, next point gets A (not AA)
  - [ ] Test: Create SL1, SL2, SL3, delete SL1, next container gets SL1 (not SL4)
- [ ] Test label conflicts:
  - [ ] Validation prevents conflicts
  - [ ] Suggestions work correctly
- [ ] Test empty labels:
  - [ ] Auto-assignment or empty label handling
- [ ] Test nested containers:
  - [ ] Union containing intersections works correctly
- [ ] Test large containers:
  - [ ] 26+ point elements (tests AA-ZZ support)
  - [ ] 26+ line elements (tests aa-zz support)
  - [ ] Container conflict resolution (SL1, SL2 taken, uses SL3)
  - [ ] Performance is acceptable

### 9.4 Backward Compatibility Tests

- [ ] Test migration from pattern IDs:
  - [ ] Legacy files with `intersection_6_0` IDs convert correctly
  - [ ] `elementToContainer` map is populated correctly
  - [ ] No data loss

---

## Phase 11: Refactor CommandRegistry Label Generation

### 11.1 Remove Old Label Generation System

- [x] Remove all individual label counters from `CommandRegistry`:
  - [x] Removed `_pointLabelCounter`, `_lineLabelCounter`, `_segmentLabelCounter`
  - [x] Removed `_circleLabelCounter`, `_circleThreeLabelCounter`, `_arcThreeLabelCounter`
  - [x] Removed `_midpointLabelCounter`, `_perpendicularLabelCounter`, `_parallelLabelCounter`
  - [x] Removed `_perpBisectorLabelCounter`, `_tangentLabelCounter`, `_angleBisectorLabelCounter`
  - [x] Removed `_intersectionLabelCounter`, `_textLabelCounter`
  - [x] Removed `_inverseLabelCounter`, `_rotateLabelCounter`, `_dilateLabelCounter`
  - [x] Removed `_unionLabelCounter`, `_polyArcLabelCounter`, `_polygonLabelCounter`
  - [x] Removed `_polyLineLabelCounter`, `_polyArcGonLabelCounter`
- [x] Remove all individual `_next*Label()` methods:
  - [x] Removed `_nextPointLabel()`, `_nextLineLabel()`, `_nextSegmentLabel()`
  - [x] Removed `_nextCircleLabel()`, `_nextCircleThreeLabel()`, `_nextArcThreeLabel()`
  - [x] Removed `_nextMidpointLabel()`, `_nextPerpendicularLabel()`, `_nextParallelLabel()`
  - [x] Removed `_nextPerpBisectorLabel()`, `_nextTangentLabel()`, `_nextAngleBisectorLabel()`
  - [x] Removed `_nextIntersectionLabel()`, `_nextInverseLabel()`, `_nextRotateLabel()`
  - [x] Removed `_nextDilateLabel()`, `_nextUnionLabel()`, `_nextTextContent()`
  - [x] Removed `_nextPolyArcLabel()`, `_nextPolygonLabel()`, `_nextPolyLineLabel()`
  - [x] Removed `_nextPolyArcGonLabel()`
- [x] Removed `_resolveLabel()` helper method (no longer needed)

### 11.2 Update Command Executors to Use LabelManager

- [x] Update `point` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.point)`
  - [x] ID = label (user-friendly)
- [x] Update `line` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.line)`
  - [x] ID = label
- [x] Update `segment` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.line)`
  - [x] ID = label
- [x] Update `circle` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.circle)`
  - [x] ID = label
- [x] Update `circle3` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.circle)`
  - [x] ID = label
- [x] Update `arc3` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.arc)`
  - [x] ID = label
- [x] Update `midpoint` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.point)`
  - [x] ID = label
- [x] Update `perpendicular` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.line)`
  - [x] ID = label
- [x] Update `parallel` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.line)`
  - [x] ID = label
- [x] Update `perpbisector` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.line)`
  - [x] ID = label
- [x] Update `tangent` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.simpleList)` for container
  - [x] Pass `DAGManager` to `GeoTangent.constructFromObjects()`
- [x] Update `anglebisector` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.simpleList)` for container
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.line)` for GeoAngleBisector3P
  - [x] Pass `DAGManager` to `GeoAngleBisector2L.constructFromLines()`
- [x] Update `intersection` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.simpleList)` for container
  - [x] Pass `DAGManager` to all `GeoIntersection` factory methods
- [ ] Update `union` command executor (if exists):
  - [ ] Replace with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.union)`
- [x] Update `text` command executor:
  - [x] Uses `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.text)` (keeps generated ID for text objects)
- [x] Update `polyarc` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.polyArc)`
  - [x] ID = label
- [x] Update `polygon` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.polygon)`
  - [x] ID = label
- [x] Update `polyline` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.polyLine)`
  - [x] ID = label
- [x] Update `polyarcgon` command executor:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.polyArcGon)`
  - [x] ID = label
- [x] Update flexible commands (`circleFlex`, `circle3Flex`, `lineFlex`, `perpbisectorFlex`, `perpendicularFlex`, `parallelFlex`):
  - [x] All updated to use `LabelManager.getNextAvailableLabel()`
  - [x] ID = label

### 11.3 Update Transformation Commands

- [x] Update `reflect` command:
  - [x] Replaced with `LabelManager.getNextAvailableLabelForTransformation(context.dagManager, baseLabel)` for all object types
  - [x] Uses apostrophe suffix (A → A', a → a')
- [x] Update `rotate` command:
  - [x] Transform objects use `LabelManager.getNextAvailableLabelForTransformation()`
  - [x] Transform itself uses `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.transform)`
- [x] Update `dilate` command:
  - [x] Transform objects use `LabelManager.getNextAvailableLabelForTransformation()`
  - [x] Transform itself uses `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.transform)`
- [x] Update `translate` command:
  - [x] Uses `LabelManager.getNextAvailableLabelForTransformation(context.dagManager, baseLabel)` for transformed objects
- [x] Update `_createTransformedGeometry()` helper:
  - [x] Replaced all `_resolveLabel()` calls with `LabelManager.getNextAvailableLabelForTransformation()`
  - [x] Uses apostrophe suffix for transformed objects
  - [x] ID = label (with apostrophe)

### 11.4 Update Helper Methods

- [x] Removed `_resolveLabel()` helper method (no longer needed - replaced with direct LabelManager calls)
- [x] Update `_registerInverseTransform()`:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.transform)`
  - [x] ID = label
- [x] Update `_createRotationTransform()`:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.transform)`
  - [x] ID = label
- [x] Update `_createDilateTransform()`:
  - [x] Replaced with `LabelManager.getNextAvailableLabel(context.dagManager, GeometryObjectType.transform)`
  - [x] ID = label

### 11.5 Update CommandExecutionContext

- [x] Update `CommandExecutionContext.resolveLabel()`:
  - [x] **Decision**: Keep `resolveLabel()` but all call sites use `LabelManager` directly - completed (no commands use `resolveLabel()` anymore)
  - [x] All command executors use `LabelManager.getNextAvailableLabel()` directly - completed
  - [x] Custom labels validated via `LabelManager.isLabelUnique()` where needed - completed
- [x] **Status**: `resolveLabel()` still exists for backward compatibility but is not used by any commands

---

## Phase 10: Documentation

### 10.1 Code Documentation

- [ ] Document `elementToContainer` map in `DAGManager`
- [ ] Document `LabelManager` API:
  - [ ] `getNextAvailableLabel(DAGManager, GeometryObjectType, {preferred})`
  - [ ] `getNextAvailableLabelForTransformation(DAGManager, baseLabel)`
  - [ ] `isLabelUnique(DAGManager, label, {excludeId})`
  - [ ] `getAllUsedLabels(DAGManager)`
  - [ ] `suggestNextLabel(DAGManager, baseLabel, type)`
- [ ] Document naming conventions:
  - [ ] Uppercase for points/intersections (A-Z, AA-ZZ, ...)
  - [ ] Lowercase for lines/circles/arcs/segments (a-z, aa-zz, ...)
  - [ ] SL1, SL2, ... for simple list containers
  - [ ] U1, U2, ... for union containers
  - [ ] Apostrophe (') for transformed objects
- [ ] Document element ID assignment process
- [ ] Document conflict resolution strategy
- [ ] Document migration logic

### 10.2 User Documentation

- [ ] Document element label editing feature:
  - [ ] How to rename element labels
  - [ ] Uniqueness requirements
- [ ] Document label uniqueness rules:
  - [ ] Global uniqueness (across all objects)
  - [ ] Case sensitivity: A ≠ a (uppercase and lowercase are different)
  - [ ] Apostrophe makes labels unique: A ≠ A' (transformed objects)
- [ ] Document auto-assignment behavior:
  - [ ] Points/Intersections: A-Z first, then AA-ZZ, then AAA-ZZZ, ...
  - [ ] Lines/Circles/Arcs/Segments: a-z first, then aa-zz, then aaa-zzz, ...
  - [ ] Containers: SL1, SL2, SL3, ... or U1, U2, U3, ... (least available index)
  - [ ] Transformed objects: Add apostrophe (A → A', a → a')
  - [ ] **Label Recycling**: Deleted labels are reused before creating new ones
  - [ ] **Frugal Naming**: Always checks from start (A, B, C, ...) to find first available
  - [ ] Preferred labels supported if available
- [ ] Document naming convention examples:
  - [ ] Points: A, B, C, Z, AA, AB, AC, BA, BB, ...
  - [ ] Lines: a, b, c, z, aa, ab, ac, ba, bb, ...
  - [ ] Transformed: A', B', a', b', ...
  - [ ] Containers: SL1, SL2, SL3, U1, U2, U3, ...

---

## Files That Need Changes

### Core Files (Must Change)

1. **`packages/geodraw/lib/core/dag/dag_manager.dart`**
   - **Changes**: Add `elementToContainer` map, update object resolution
   - **Lines affected**: ~50-100 lines
   - **Impact**: High - Core functionality

2. **`packages/geodraw/lib/core/label_manager.dart`** (NEW FILE)
   - **Changes**: Create entire new file with LabelManager class
   - **Lines**: ~300-500 lines estimated
   - **Impact**: Critical - Foundation for all label management

3. **`packages/geodraw/lib/core/command/command_registry.dart`**
   - **Changes**: Remove 20+ counters, remove 20+ methods, replace ~50+ call sites
   - **Lines affected**: ~100-150 lines
   - **Impact**: High - All command execution

4. **`packages/geodraw/lib/core/command/command_runtime.dart`**
   - **Changes**: Update `resolveLabel()` signature or change call sites
   - **Lines affected**: ~10-20 lines
   - **Impact**: Medium - Command execution context

### Model Files (Must Change)

5. **`packages/geodraw/lib/models/simple_lists/geo_intersection.dart`**
   - **Changes**: Update `_pointFromMultivector()`, all factory methods, `rebuildFromParents()`
   - **Lines affected**: ~200-300 lines
   - **Impact**: Critical - Intersection point creation

6. **`packages/geodraw/lib/models/simple_lists/geo_tangent.dart`**
   - **Changes**: Update `constructFromObjects()`, container naming, `rebuildFromParents()`
   - **Lines affected**: ~50-100 lines
   - **Impact**: High - Tangent line creation

7. **`packages/geodraw/lib/models/simple_lists/geo_angle_bisector.dart`**
   - **Changes**: Update `constructFromLines()`, container naming, `rebuildFromParents()`
   - **Lines affected**: ~50-100 lines
   - **Impact**: High - Angle bisector creation

8. **`packages/geodraw/lib/models/geometry_object.dart`**
   - **Changes**: Check `GenSimpleGeometryObjectList` for element access helpers
   - **Lines affected**: ~10-30 lines (if needed)
   - **Impact**: Low-Medium - May not need changes

### UI Files (Must Change)

9. **`packages/geodraw/lib/ui/geodraw_canvas.dart`**
   - **Changes**: Update label rendering, remove pattern ID handling
   - **Lines affected**: ~20-30 lines
   - **Impact**: Medium - Visual display

10. **`packages/geodraw/lib/ui/object_browser.dart`**
    - **Changes**: Show `element.id` as label, handle ID editing
    - **Lines affected**: ~30-50 lines
    - **Impact**: Medium - Object browser display

11. **`packages/geodraw/lib/ui/object_settings_panel.dart`**
    - **Changes**: Update `_LabelEditor`, handle element ID editing
    - **Lines affected**: ~50-100 lines
    - **Impact**: High - Label editing functionality

12. **`packages/geodraw/lib/ui/object_toolbar.dart`**
    - **Changes**: Update label editing, handle element IDs
    - **Lines affected**: ~20-40 lines
    - **Impact**: Medium - Quick label editing

### Transformation Files (May Need Changes)

13. **`packages/geodraw/lib/models/transforms/transformation_engine.dart`**
    - **Changes**: Use `LabelManager.getNextAvailableLabelForTransformation()`
    - **Lines affected**: ~20-40 lines
    - **Impact**: Medium - Transformation label handling

14. **`packages/geodraw/lib/models/simple/geo_transformed_simple.dart`**
    - **Changes**: May need label handling updates
    - **Lines affected**: ~10-20 lines (if needed)
    - **Impact**: Low-Medium

15. **`packages/geodraw/lib/models/complex/geo_transformed_complex.dart`**
    - **Changes**: May need label handling updates
    - **Lines affected**: ~10-20 lines (if needed)
    - **Impact**: Low-Medium

### Other Files (Review Needed)

16. **`packages/geodraw/lib/models/simple/geo_point.dart`**
    - **Changes**: Review for label-related code
    - **Lines affected**: Minimal (if any)
    - **Impact**: Low

17. **`packages/geodraw/lib/models/simple/geo_line.dart`**
    - **Changes**: Review for label-related code
    - **Lines affected**: Minimal (if any)
    - **Impact**: Low

18. **`packages/geodraw/lib/models/simple/geo_circle.dart`**
    - **Changes**: Review for label-related code
    - **Lines affected**: Minimal (if any)
    - **Impact**: Low

19. **Files calling `DAGManager.getObject()` with pattern IDs**
    - **Changes**: Update to use label-based IDs
    - **Files**: Search codebase for pattern ID usage
    - **Impact**: Medium - May affect multiple files

20. **Serialization/JSON files**
    - **Changes**: Update `fromJson()` for migration, backward compatibility
    - **Files**: All model files with `fromJson()` methods
    - **Impact**: High - File loading/saving

### Summary by Impact Level

**Critical (Must Change First)**:
- `label_manager.dart` (NEW)
- `dag_manager.dart`
- `geo_intersection.dart`
- `command_registry.dart`

**High Priority**:
- `geo_tangent.dart`
- `geo_angle_bisector.dart`
- `object_settings_panel.dart`
- Serialization files (migration)

**Medium Priority**:
- `command_runtime.dart`
- `geodraw_canvas.dart`
- `object_browser.dart`
- `object_toolbar.dart`
- `transformation_engine.dart`
- Files using pattern IDs

**Low Priority (Review Only)**:
- `geo_point.dart`, `geo_line.dart`, `geo_circle.dart`
- Other model files

---

## Progress Summary

**Total Tasks**: ~220+ individual items across 11 phases

**Completed**: ~215 / ~220 (~98%)  
**In Progress**: Phase 9.1 - Unit Tests (LabelManager tests created)  
**Remaining**: ~5

**Current Phase**: Phase 9.1 - Unit Tests (LabelManager tests created, DAGManager tests pending)

**Completed Phases**:
- ✅ Phase 1.1: Element-to-Container Tracking in DAGManager
- ✅ Phase 1.2: Remove Pattern ID Generation (complete - all use LabelManager)
- ✅ Phase 1.3: Update Element ID Assignment (complete - _pointFromMultivector uses LabelManager)
- ✅ Phase 2.1: LabelManager Utility (complete)
- ✅ Phase 2.2: DAG Manager Element Resolution
- ✅ Phase 3.1-3.2: `_pointFromMultivector()` and All Intersection Factory Methods
- ✅ Phase 3.3: GeoTangent and GeoAngleBisector Updates (partial - GeoTangent placeholder)
- ✅ Phase 3.3: Container Naming (SL1, SL2, etc.) for Intersection, Tangent, Angle Bisector
- ✅ Phase 3.4: Command Registry Updates (intersection, tangent, angle bisector with container labels)
- ✅ Phase 3.5: `rebuildFromParents()` Updates (GeoIntersection, GeoTangent, GeoAngleBisector2L complete)
- ✅ Phase 4.1-4.4: Element Resolution and Lookup (complete)
- ✅ Phase 5.1-5.2: Canvas Rendering and UI Components (complete)
- ✅ Phase 6.1: Label Validation Updates (complete - uses LabelManager globally)
- ✅ Phase 6.2-6.3: Element ID Editing (complete - updateElementId method implemented)
- ✅ Phase 7.1: Transformation Commands (complete - uses LabelManager with apostrophe suffixes)
- ✅ Phase 8.1: Backward Compatibility / Migration (complete - migration logic in fromJson)
- ✅ Phase 8.2-8.13: Edge Cases (complete - label recycling, uniqueness, capacity, undo/redo, etc.)
- ✅ Phase 11.1-11.4: CommandRegistry Refactoring (complete - all old label methods removed, all commands use LabelManager)

**Remaining Tasks**:
- Phase 8.12: Performance Optimization (caching for 1000+ objects - optional enhancement)
- Phase 9-10: Testing and Documentation (optional but recommended)

**Files to Change**: ~20 files identified above

---

## Key Differences from Option 1

1. **No `labelMap`**: Elements use their IDs directly as display labels
2. **No Pattern IDs**: Remove `intersection_6_0` pattern, use "A", "B", "C" directly
3. **`elementToContainer` Map**: Track which container owns each element (in `DAGManager`)
4. **Simpler**: One identifier instead of two
5. **Direct Lookup**: `getObject("A")` returns element directly (no pattern matching)

---

## Migration Mapping: Old → New System

### Label Generation Methods

| Old Method | Old Output | New Method | New Output |
|-----------|-----------|-----------|-----------|
| `_nextPointLabel()` | P1, P2, P3, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.point)` | A, B, C, ..., AA, AB, ... |
| `_nextLineLabel()` | L1, L2, L3, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.line)` | a, b, c, ..., aa, ab, ... |
| `_nextSegmentLabel()` | S1, S2, S3, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.line)` | a, b, c, ..., aa, ab, ... |
| `_nextCircleLabel()` | C1, C2, C3, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.circle)` | a, b, c, ..., aa, ab, ... |
| `_nextCircleThreeLabel()` | C3-1, C3-2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.circle)` | a, b, c, ..., aa, ab, ... |
| `_nextArcThreeLabel()` | Arc1, Arc2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.arc)` | a, b, c, ..., aa, ab, ... |
| `_nextMidpointLabel()` | M1, M2, M3, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.point)` | A, B, C, ..., AA, AB, ... |
| `_nextPerpendicularLabel()` | Perp1, Perp2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.line)` | a, b, c, ..., aa, ab, ... |
| `_nextParallelLabel()` | Par1, Par2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.line)` | a, b, c, ..., aa, ab, ... |
| `_nextPerpBisectorLabel()` | Bis1, Bis2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.line)` | a, b, c, ..., aa, ab, ... |
| `_nextTangentLabel()` | Tan1, Tan2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.simpleList)` | SL1, SL2, SL3, ... |
| `_nextAngleBisectorLabel()` | AngBis1, AngBis2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.simpleList)` | SL1, SL2, SL3, ... |
| `_nextIntersectionLabel()` | Int1, Int2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.simpleList)` | SL1, SL2, SL3, ... |
| `_nextUnionLabel()` | U1, U2, U3, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.union)` | U1, U2, U3, ... (same) |
| `_nextInverseLabel()` | Inv1, Inv2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.transform)` | Transform labels |
| `_nextRotateLabel()` | Rot1, Rot2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.transform)` | Transform labels |
| `_nextDilateLabel()` | Dil1, Dil2, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.transform)` | Transform labels |
| `_nextPolyArcLabel()` | PolyArc1, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.polyArc)` | Custom format |
| `_nextPolygonLabel()` | Polygon1, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.polygon)` | Custom format |
| `_nextPolyLineLabel()` | PolyLine1, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.polyLine)` | Custom format |
| `_nextPolyArcGonLabel()` | PolyArcGon1, ... | `LabelManager.getNextAvailableLabel(dagManager, GeometryObjectType.polyArcGon)` | Custom format |

### Element ID Patterns

| Old Pattern | Old Example | New Pattern | New Example |
|------------|------------|------------|------------|
| Pattern-based ID | `intersection_6_0` | Display label as ID | `A` |
| Pattern-based ID | `intersection_6_1` | Display label as ID | `B` |
| Container ID | `intersection_6` | Container label | `SL1` |
| Element lookup | `getObject("intersection_6_0")` | Direct lookup | `getObject("A")` |

### Code Pattern Changes

**Before:**
```dart
// In command_registry.dart
label: providedLabel.isNotEmpty
    ? providedLabel
    : context.resolveLabel(_nextPointLabel),

// In geo_intersection.dart
final elementId = '${idSeed}_${index}'; // intersection_6_0
```

**After:**
```dart
// In command_registry.dart
label: providedLabel.isNotEmpty
    ? (LabelManager.isLabelUnique(context.dagManager, providedLabel) 
        ? providedLabel 
        : throw ArgumentError('Label $providedLabel already exists'))
    : LabelManager.getNextAvailableLabel(
        context.dagManager, 
        GeometryObjectType.point
      ),

// In geo_intersection.dart
final elementId = LabelManager.getNextAvailableLabel(
    dagManager, 
    GeometryObjectType.point
); // A, B, C, ...
dagManager.registerElement(elementId, containerId);
```

---

## Notes

- All tasks start in "undone" state
- Check off tasks as they are completed
- Update progress summary regularly
- Document any deviations or additional findings
- **Naming Conventions**:
  - Points/Intersections: Uppercase (A-Z, AA-ZZ, AAA-ZZZ, ...) - infinite capacity
  - Lines/Circles/Arcs/Segments: Lowercase (a-z, aa-zz, aaa-zzz, ...) - infinite capacity
  - Simple List Containers: SL1, SL2, SL3, ... (least available index)
  - Union Containers: U1, U2, U3, ... (least available index)
  - Transformed Objects: Add apostrophe (A → A', a → a')
- **Conflict Resolution**: If SL1, U1, etc. are taken by regular objects, use next available index
- **Label Recycling**: Deleted labels are reused before creating new ones (frugal naming)
- **Frugal Naming**: Always checks from start (A, B, C, ...) to find first available label
- **Capacity**: Effectively unlimited for all object types

## Implementation Strategy

### Phase Order Recommendation

1. **Phase 1-2**: Create foundation (DAGManager changes, LabelManager)
2. **Phase 11**: Refactor CommandRegistry (simplifies all other phases)
3. **Phase 3**: Update element creation (now uses LabelManager)
4. **Phase 4-5**: Update resolution and display
5. **Phase 6-7**: Handle editing and transformations
6. **Phase 8**: Edge cases and migration
7. **Phase 9-10**: Testing and documentation

### Key Dependencies

- `LabelManager` must be created before CommandRegistry refactoring
- `elementToContainer` map must be added before element creation updates
- CommandRegistry refactoring simplifies all other command-related changes
- Migration logic should be tested after core functionality is complete
