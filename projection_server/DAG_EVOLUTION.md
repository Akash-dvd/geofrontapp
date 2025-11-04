# GraphForest Evolution Through Processing Chain

This document tracks how the GraphForest (containing a DAG - Directed Acyclic Graph) structure evolves through each step of the processing chain.

## Initial State (Step 0): Input JSON Payload

**Input:** JSON string or dict
```json
{
  "construction": {
    "type": "construction",
    "version": "1.0",
    "objects": [
      {"id": "point_0", "type": "GeoPointer", "label": "A", ...},
      ...
    ],
    "constraints": [],
    "proofs": []
  },
  "scalarConstraints": [],
  "scalarProof": [],
  "objectProof": [{"name": "areIncident", "nestedArray": ["c1", "l1"]}],
  "objectConstraints": [],
  "proofGoal": "Prove incidence"
}
```

---

## Step 1: GeoAppCodec.encoder

**Function:** `GeoAppCodec.encoder(current_output: JSON, ...) -> GraphForest`

**Input:** JSON payload (string, dict, or bytes)

**Output:** GraphForest object

**GraphForest State After Step 1:**
```python
GraphForest {
  # Core attributes (from __init__)
  symlist: {
    "_oo": GExpr._oo,           # Origin point
    "point_0": GAtom("A", ...), # Mapped from objects
    "line_1": GAtom("l1", ...),
    ...
  },
  
  dag: {                         # The internal DAG structure
    GExpr._oo: {
      'type': 'point',
      'dependency': [],
      'command': 'origin',
      'extra': {'iter': 0}
    },
    GAtom("A", ...): {
      'type': 'point',           # Canonical type
      'dependency': [],          # List of GAtom dependencies
      'command': 'GeoPointer',   # Exact GeoApp type
      'extra': {
        'iter': 0,
        'style': {...},
        'properties': {...}
      }
    },
    ...
  },
  
  appendage: {
    "ScalarConstraints": [...],
    "ScalarProof": [...],
    "ObjectProof": [...],
    "ObjectConstraints": [...]
  }
  
  # No other attributes yet
}
```

**Key Transformations:**
- Converts JSON objects → GAtom objects in `symlist`
- Maps GeoApp types to canonical types (point, line, circle, segment, arc, union)
- Preserves exact type in `command` field
- Extracts constraints/proofs into `appendage`

---

## Step 2: create_dcg

**Function:** `create_dcg(current_output: GraphForest, ...) -> GraphForest`

**Input:** GraphForest from Step 1

**Output:** GraphForest with DCG attribute added

**GraphForest State After Step 2:**
```python
GraphForest {
  # All attributes from Step 1 (unchanged)
  symlist: {...},
  dag: {...},                    # The internal DAG structure
  appendage: {...},
  
  # NEW: DCG (Directed Cyclic Graph)
  dcg: {
    GAtom("A", ...): [GAtom("B", ...), GAtom("C", ...)],
    GAtom("l1", ...): [GAtom("A", ...), GExpr._oo],
    GExpr._oo: [GAtom("l1", ...), ...],
    ...
  }
}
```

**Key Transformations:**
- Creates a Directed Cyclic Graph from the internal DAG structure (`graph_forest.dag`)
- `dcg` is a dictionary mapping GAtoms to lists of connected GAtoms
- Represents cyclic relationships in the geometric construction
- Used for finding circular dependencies and relationships

**Algorithm:**
- `DCG.DAGParser(graph_forest)` processes the internal DAG and creates cyclic connections
- Handles special cases for lines defined by two points, etc.

---

## Step 3: QGraph.create_qgraph_on_dag

**Function:** `QGraph.create_qgraph_on_dag(current_output: GraphForest, ...) -> GraphForest`

**Input:** GraphForest from Step 2 (with DCG)

**Output:** GraphForest with QGraph attributes added

**GraphForest State After Step 3:**
```python
GraphForest {
  # All attributes from Steps 1 & 2 (unchanged)
  symlist: {...},
  dag: {...},                    # The internal DAG structure
  appendage: {...},
  dcg: {...},
  
  # NEW: QGraph attributes (for solver)
  qgraph: {
    "ScalarQGraphs": [{}],              # Currently empty structure
    "ObjectQGraphs": [
      {
        "assertion": {
          'type': 'assertion',
          'dependency': [GAtom(...), GAtom(...)],  # From ObjectProof
          'command': 'areIncident',
          'extra': {'iter': 0}
        },
        GAtom("c1", ...): {              # Subgraph node
          'type': 'circle',
          'dependency': [GAtom(...), ...],
          'command': 'GeoCircle2P',
          'extra': {...}
        },
        GAtom("l1", ...): {              # Subgraph node
          'type': 'line',
          'dependency': [GAtom(...), ...],
          'command': 'GeoLine2P',
          'extra': {...}
        },
        ...                               # All dependencies recursively included
      },
      ...                                 # One ObjectQGraph per ObjectProof entry
    ]
  },
  
  p2cMap: [],                            # Problem-to-Configuration mapping (isomorphism tracking)
  c2pMap: [],                            # Configuration-to-Problem mapping
  
  ScalarProof: [...],                    # Copy of appendage["ScalarProof"]
  ObjectProof: [...]                     # Copy of appendage["ObjectProof"]
}
```

**Key Transformations:**
- **Filters/Trims internal DAG**: Only includes nodes relevant to proof goals
- Creates **ObjectQGraphs**: One subgraph per `ObjectProof` entry
  - Each subgraph contains:
    - `"assertion"`: The proof goal with its dependencies
    - Recursive dependency tree: All GAtoms needed to prove the assertion
  - Irrelevant/unconnected branches are **trimmed out**
  
- **ScalarQGraphs**: Currently just empty structure `[{}]`

**Algorithm:**
- For each `ObjectProof` entry:
  1. Create assertion entry with proof goal dependencies
  2. Call `get_subgraph_recursive()` for each dependency
  3. Recursively traverse dependency graph from proof goals
  4. Only include nodes reachable through dependencies
  5. Handle `p2cMap` flags for limiting dependencies

**Filtering Logic:**
- `get_subgraph_recursive()` only includes:
  - Proof goal nodes (from `ObjectProof.nestedArray`)
  - All their dependencies (recursively)
  - Stops at `p2cMap` boundaries if configured
  - Ignores unconnected construction nodes

---

## Step 4: GeoAppCodec.decoder

**Function:** `GeoAppCodec.decoder(current_input: GraphForest, ...) -> str`

**Input:** GraphForest from Step 3 (with DCG and QGraph)

**Output:** JSON string (can be pretty or compact)

**GraphForest State:**
- **Unchanged** - GraphForest is read-only in decoder
- Uses `graph_forest.symlist`, `graph_forest.dag`, `graph_forest.appendage` to rebuild JSON
- Does NOT use `graph_forest.dcg` or `graph_forest.qgraph` (those are solver-internal)

**Output JSON:**
```json
{
  "type": "construction",
  "version": "1.0",
  "objects": [
    {
      "id": "point_0",
      "type": "GeoPointer",
      "label": "A",
      "dependencies": [],
      "visible": true,
      "style": {...},
      "properties": {...}
    },
    ...
  ],
  "constraints": [...],
  "proofs": [...]
}
```

**Key Transformations:**
- Reverses encoder process:
  - `symlist` (id -> GAtom) → `objects` array
  - `dag[gatom]` → extracts `type`, `command`, `dependencies`, `extra`
  - `appendage` → `constraints` and `proofs` arrays
- Uses `command` field (exact GeoApp type) for `type` in output
- Reconstructs labels from GAtom `mv.name` if available

---

## Summary: GraphForest Evolution Flow

```
Step 0: JSON Payload
  ↓
Step 1: encoder()
  → GraphForest { symlist, dag, appendage }
  ↓
Step 2: create_dcg()
  → GraphForest { symlist, dag, appendage, dcg }
  ↓
Step 3: create_qgraph_on_dag()
  → GraphForest { symlist, dag, appendage, dcg, qgraph, p2cMap, c2pMap, ScalarProof, ObjectProof }
  ↓
Step 4: decoder()
  → JSON string (output to client)
```

## Attributes Summary

| Step | Attribute | Type | Purpose |
|------|-----------|------|---------|
| 1 | `symlist` | dict | Maps object IDs → GAtom objects |
| 1 | `dag` | dict | Maps GAtom → construction data (type, deps, command, extra) - the internal DAG structure |
| 1 | `appendage` | dict | Constraints and proofs from input |
| 2 | `dcg` | dict | Directed Cyclic Graph (cyclic relationships) |
| 3 | `qgraph` | dict | Query graphs (filtered subgraphs for solver) |
| 3 | `p2cMap` | list | Problem-to-Configuration isomorphism mappings |
| 3 | `c2pMap` | list | Configuration-to-Problem isomorphism mappings |
| 3 | `ScalarProof` | list | Scalar proof goals (copy from appendage) |
| 3 | `ObjectProof` | list | Object proof goals (copy from appendage) |

## Key Design Points

1. **In-place Modification**: Each step modifies the GraphForest object and returns it
2. **Monadic Chain**: GraphForest flows through chain, each step adding attributes
3. **Filtering**: Step 3 (QGraph) filters to only relevant nodes for proofs
4. **Round-trip**: Step 4 reverses Step 1, creating a complete encode→process→decode cycle
5. **Solver Separation**: `dcg` and `qgraph` are solver-internal, not in decoder output

