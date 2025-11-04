# Naming Proposal for DAG Structure

## Current Structure Analysis

### Current Naming:
```python
class DAG:
    symlist: {}          # Maps id -> GAtom
    construction: {}      # Maps GAtom -> {type, dependency, command, extra}
    appendage: {}        # Constraints and proofs
    dcg: {}              # Directed Cyclic Graph (added later)
    qgraph: {}           # Query graphs (added later)
```

### Problem:
- The class `DAG` contains multiple graphs/structures:
  - `construction` is the actual **Directed Acyclic Graph** (DAG)
  - But the overall class may represent a **forest** (set of disconnected graphs)
- `construction` is a dictionary that represents a graph where:
  - Nodes = GAtoms (keys)
  - Edges = dependencies (each node → list of dependency GAtoms)
  - If there are disconnected components, it's a **forest**, not a single DAG

## Proposed Renaming Options

### Option 1: Rename `construction` → `dag` (Simple)
**Class:** `DAG` (stays the same)
**Attribute:** `construction` → `dag`

```python
class DAG:
    symlist: {}      # Maps id -> GAtom
    dag: {}          # The actual Directed Acyclic Graph (was construction)
    appendage: {}    # Constraints and proofs
    dcg: {}          # Directed Cyclic Graph
    qgraph: {}       # Query graphs
```

**Pros:**
- Clear that `dag` is the DAG (Directed Acyclic Graph)
- Minimal changes

**Cons:**
- `dag.dag` might be confusing (the DAG object has a `dag` attribute)
- Doesn't address the forest/set-of-graphs issue

---

### Option 2: Rename class to `Construction` or `GeometryConstruction`
**Class:** `DAG` → `Construction` or `GeometryConstruction`
**Attribute:** `construction` → `dag`

```python
class Construction:  # or GeometryConstruction
    symlist: {}      # Maps id -> GAtom
    dag: {}          # The actual Directed Acyclic Graph
    appendage: {}    # Constraints and proofs
    dcg: {}          # Directed Cyclic Graph
    qgraph: {}       # Query graphs
```

**Pros:**
- `construction.dag` is clearer than `dag.dag`
- Class name reflects that it's a construction (which may be a forest)

**Cons:**
- Requires renaming class throughout codebase
- More disruptive changes

---

### Option 3: Rename class to `GraphForest` or `DAGForest`
**Class:** `DAG` → `GraphForest` or `DAGForest`
**Attribute:** `construction` → `dag`

```python
class GraphForest:  # or DAGForest
    symlist: {}      # Maps id -> GAtom
    dag: {}          # The actual Directed Acyclic Graph (or forest)
    appendage: {}    # Constraints and proofs
    dcg: {}          # Directed Cyclic Graph
    qgraph: {}       # Query graphs
```

**Pros:**
- Accurately represents that it may contain multiple disconnected graphs (forest)
- Clear distinction between the container (forest) and the graph structure (`dag`)

**Cons:**
- May be too technical/confusing
- Requires renaming class throughout codebase

---

### Option 4: Keep `DAG` class, rename `construction` → `graph` or `graph_dict`
**Class:** `DAG` (stays the same)
**Attribute:** `construction` → `graph` or `graph_dict`

```python
class DAG:
    symlist: {}      # Maps id -> GAtom
    graph: {}        # The graph structure (DAG or forest)
    appendage: {}    # Constraints and proofs
    dcg: {}          # Directed Cyclic Graph
    qgraph: {}       # Query graphs
```

**Pros:**
- Generic name `graph` works for both DAG and forest
- `dag.graph` is reasonably clear
- Minimal semantic change

**Cons:**
- `graph` is less specific than `dag`

---

## Recommendation

**Recommended: Option 1** - Rename `construction` → `dag`

### Rationale:
1. **Minimal disruption**: Only attribute rename, class stays `DAG`
2. **Semantic clarity**: `dag.dag` might look odd but is actually clear (the DAG's DAG)
3. **Terminology alignment**: The attribute `dag` correctly names what it is - a Directed Acyclic Graph
4. **Already established**: The term "DAG" is well-established in the codebase

### Implementation:
```python
class DAG:
    def __init__(self, symlst, dag, appendage):  # Changed: cons → dag
        self.symlist = symlst
        self.dag = dag                            # Changed: construction → dag
        self.appendage = appendage
```

### Alternative if `dag.dag` is too confusing:
Use **Option 4** - rename `construction` → `graph`:
- More generic and works for forests too
- `dag.graph` is clear and acceptable

---

## Summary

| Aspect | Current | Proposed (Option 1) | Proposed (Option 4) |
|--------|---------|---------------------|---------------------|
| Class | `DAG` | `DAG` | `DAG` |
| Graph attribute | `construction` | `dag` | `graph` |
| Readability | `dag.construction` | `dag.dag` | `dag.graph` |
| Semantics | Unclear | Clear (DAG's DAG) | Generic (works for forest) |

**Final Recommendation:** Use **Option 4** (`construction` → `graph`) if `dag.dag` feels too repetitive, otherwise **Option 1** (`construction` → `dag`).

