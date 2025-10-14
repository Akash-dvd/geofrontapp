# Solver System Implementation Plan

## Current State Analysis

### ✅ What Exists
- **GeoDraw Package**: Fully functional with interactive tools, CLI, and AI panels
- **DAGManager**: Has placeholder `constraints` list (currently unused)
- **Problem Model**: Has `geometryData` field for storing GeoDraw constructions
- **Directus Backend**: Running with GraphQL at `http://192.168.1.3:8055/graphql`
- **geocalc Package**: Multivector-based geometric algebra calculations

### ❌ What's Missing
- **No solver system** - Constraint solving not implemented
- **No constraint storage** - Database has no constraint fields
- **No proof storage** - Database has no proof fields
- **No Python GraphQL server** - Solver backend doesn't exist yet
- **No constraint extraction** - Can't extract constraints from DAG

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter GeoFrontApp                      │
│  ┌──────────────┐  ┌───────────────┐  ┌─────────────────┐  │
│  │   GeoDraw    │  │  Problem Mgmt │  │ Constraint      │  │
│  │   Canvas     │──│     BLoC      │──│ Extraction      │  │
│  │ (DAGManager) │  └───────────────┘  └─────────────────┘  │
│  └──────────────┘          │                    │           │
└────────────────────────────│────────────────────│───────────┘
                             │                    │
                    ┌────────▼────────┐  ┌────────▼──────────┐
                    │    Directus     │  │  Python Solver    │
                    │   GraphQL API   │  │   GraphQL API     │
                    │  192.168.1.3    │  │  192.168.1.3      │
                    │    :8055        │  │     :5000         │
                    └─────────────────┘  └───────────────────┘
                             │                    │
                    ┌────────▼────────┐  ┌────────▼──────────┐
                    │   PostgreSQL    │  │  Solver Engine    │
                    │   (Problems,    │  │  (Constraint      │
                    │   Constraints,  │  │   Solving,        │
                    │   Proofs)       │  │   AI NLP)         │
                    └─────────────────┘  └───────────────────┘
```

---

## Data Model

### Directus Schema Updates

#### Problems Collection - New Fields

| Field Name | Type | Description |
|------------|------|-------------|
| `scalar_constraints` | JSON | Numerical constraints (distances, angles, ratios) |
| `object_constraints` | JSON | Geometric constraints (parallel, perpendicular, tangent) |
| `scalar_proof` | TEXT | Step-by-step scalar/algebraic proof |
| `object_proof` | TEXT | Step-by-step geometric proof |

### Constraint Format

#### Scalar Constraints (JSON)
```json
{
  "distances": [
    {"id": "d1", "from": "A", "to": "B", "value": 5.0},
    {"id": "d2", "from": "B", "to": "C", "value": 5.0}
  ],
  "angles": [
    {"id": "a1", "points": ["B", "A", "C"], "value": 60.0, "unit": "degrees"}
  ],
  "ratios": [
    {"id": "r1", "numerator": ["A", "B"], "denominator": ["C", "D"], "value": 2.0}
  ],
  "equations": [
    {"id": "eq1", "expression": "distance(A, B) + distance(B, C) = distance(A, C)"}
  ]
}
```

#### Object Constraints (JSON)
```json
{
  "parallel": [
    {"id": "p1", "line1": "L1", "line2": "L2"}
  ],
  "perpendicular": [
    {"id": "perp1", "line1": "L3", "line2": "L4"}
  ],
  "tangent": [
    {"id": "t1", "circle": "C1", "line": "L5", "point": "P1"}
  ],
  "concurrent": [
    {"id": "con1", "lines": ["L1", "L2", "L3"], "point": "P"}
  ],
  "collinear": [
    {"id": "col1", "points": ["A", "B", "C"]}
  ],
  "cyclic": [
    {"id": "cyc1", "points": ["A", "B", "C", "D"], "circle": "C1"}
  ]
}
```

### Proof Format

#### Scalar Proof (TEXT - Markdown/HTML)
```
## Proof: Triangle ABC is Equilateral

**Given:**
- Triangle ABC with AB = BC = CA = 5

**To Prove:** 
- All angles equal 60°

**Construction:**
1. Construct triangle ABC with vertices at:
   - A(0, 0)
   - B(5, 0)
   - C(2.5, 4.33)

2. Calculate distances:
   - |AB| = √((5-0)² + (0-0)²) = 5 ✓
   - |BC| = √((2.5-5)² + (4.33-0)²) = 5 ✓
   - |CA| = √((0-2.5)² + (0-4.33)²) = 5 ✓

3. Calculate angles using law of cosines:
   - ∠ABC = arccos((AB² + BC² - CA²)/(2·AB·BC)) = 60° ✓
   - ∠BCA = arccos((BC² + CA² - AB²)/(2·BC·CA)) = 60° ✓
   - ∠CAB = arccos((CA² + AB² - BC²)/(2·CA·AB)) = 60° ✓

**Conclusion:** All sides equal and all angles equal 60°, therefore triangle ABC is equilateral. ∎
```

#### Object Proof (TEXT - Markdown/HTML)
```
## Proof: Lines L1 and L2 are Perpendicular

**Given:**
- Line L1 through points A and B
- Line L2 constructed perpendicular to L1 at point P

**To Prove:**
- L1 ⊥ L2

**Proof:**
1. **Construction Method:** Line L2 was constructed using the perpendicular line tool,
   which employs the geometric property that a line perpendicular to another forms 90° angles.

2. **Direction Vectors:**
   - Let v₁ = direction vector of L1 = B - A
   - Let v₂ = direction vector of L2 = Q - P (where Q is any point on L2)

3. **Orthogonality Check:**
   - For perpendicular lines: v₁ · v₂ = 0
   - Calculate: v₁ · v₂ = (v₁ₓ · v₂ₓ) + (v₁ᵧ · v₂ᵧ) = 0 ✓

4. **Angle Verification:**
   - angle(L1, L2) = arccos((v₁ · v₂)/(|v₁| · |v₂|)) = arccos(0) = 90° ✓

**Conclusion:** By construction and verification, L1 ⊥ L2. ∎
```

---

## Python Solver Server Specification

### Server Details
- **Host:** `192.168.1.3`
- **Port:** `5000`
- **Protocol:** GraphQL over HTTP
- **Framework:** Python (e.g., Ariadne, Strawberry, or Graphene)

### GraphQL API Schema

```graphql
# ============================================
# Solver Operations
# ============================================

type Query {
  """Check solver health status"""
  solverStatus: SolverStatus!
}

type Mutation {
  """
  Solve geometric constraints and return proof
  """
  solveConstraints(input: SolverInput!): SolverResult!
  
  """
  Generate construction commands from natural language
  """
  generateCommands(input: AIGenerateInput!): AIGenerateResult!
  
  """
  Validate construction commands
  """
  validateCommands(commands: [String!]!): ValidationResult!
}

# ============================================
# Solver Types
# ============================================

input SolverInput {
  """GeoDraw construction data (DAG JSON)"""
  constructionData: JSON!
  
  """Scalar constraints (distances, angles, ratios)"""
  scalarConstraints: ScalarConstraintsInput!
  
  """Object constraints (parallel, perpendicular, etc)"""
  objectConstraints: ObjectConstraintsInput!
  
  """What to prove"""
  proofGoal: String!
}

input ScalarConstraintsInput {
  distances: [DistanceConstraint!]
  angles: [AngleConstraint!]
  ratios: [RatioConstraint!]
  equations: [String!]
}

input DistanceConstraint {
  from: String!
  to: String!
  value: Float!
}

input AngleConstraint {
  points: [String!]!  # 3 points: vertex in middle
  value: Float!
  unit: AngleUnit!
}

input RatioConstraint {
  numerator: [String!]!
  denominator: [String!]!
  value: Float!
}

input ObjectConstraintsInput {
  parallel: [ParallelConstraint!]
  perpendicular: [PerpendicularConstraint!]
  tangent: [TangentConstraint!]
  concurrent: [ConcurrentConstraint!]
  collinear: [CollinearConstraint!]
  cyclic: [CyclicConstraint!]
}

input ParallelConstraint {
  line1: String!
  line2: String!
}

input PerpendicularConstraint {
  line1: String!
  line2: String!
}

input TangentConstraint {
  circle: String!
  line: String!
  point: String!
}

input ConcurrentConstraint {
  lines: [String!]!
  point: String!
}

input CollinearConstraint {
  points: [String!]!
}

input CyclicConstraint {
  points: [String!]!
  circle: String!
}

type SolverResult {
  """Whether solving succeeded"""
  success: Boolean!
  
  """Error message if failed"""
  errorMessage: String
  
  """Type of error: under_constrained, over_constrained, contradictory, invalid"""
  errorType: SolverErrorType
  
  """Scalar proof (algebraic/numerical)"""
  scalarProof: String
  
  """Object proof (geometric reasoning)"""
  objectProof: String
  
  """Constraint satisfaction details"""
  constraintResults: [ConstraintResult!]!
  
  """Intermediate construction steps"""
  constructionSteps: [ConstructionStep!]!
}

type ConstraintResult {
  id: String!
  type: String!
  satisfied: Boolean!
  actualValue: Float
  expectedValue: Float
  tolerance: Float
}

type ConstructionStep {
  stepNumber: Int!
  command: String!
  description: String!
  visualization: String  # Optional diagram markup
  theoremApplied: String
}

enum SolverErrorType {
  UNDER_CONSTRAINED
  OVER_CONSTRAINED
  CONTRADICTORY
  INVALID_CONSTRUCTION
}

enum AngleUnit {
  DEGREES
  RADIANS
}

type SolverStatus {
  online: Boolean!
  version: String!
  uptime: Int!
}

# ============================================
# AI/NLP Types
# ============================================

input AIGenerateInput {
  """Natural language description"""
  description: String!
  
  """Context from existing construction"""
  context: JSON
}

type AIGenerateResult {
  """Whether generation succeeded"""
  success: Boolean!
  
  """Error message if failed"""
  errorMessage: String
  
  """Generated CLI commands"""
  commands: [String!]!
  
  """Explanation of what will be constructed"""
  explanation: String!
  
  """Confidence score (0-1)"""
  confidence: Float!
}

type ValidationResult {
  """Whether commands are valid"""
  valid: Boolean!
  
  """Error messages for invalid commands"""
  errors: [CommandError!]!
}

type CommandError {
  command: String!
  line: Int!
  message: String!
}

scalar JSON
```

---

## Implementation Tasks

### Phase 1: Database Schema (Week 1)

#### Task 1.1: Update Directus Schema
- [ ] Add `scalar_constraints` field (JSON type)
- [ ] Add `object_constraints` field (JSON type)
- [ ] Add `scalar_proof` field (TEXT type)
- [ ] Add `object_proof` field (TEXT type)
- [ ] Update Public role permissions for new fields
- [ ] Test manual CRUD via Directus admin UI

#### Task 1.2: Update Problem Model
```dart
class Problem {
  // ... existing fields ...
  final Map<String, dynamic>? scalarConstraints;
  final Map<String, dynamic>? objectConstraints;
  final String? scalarProof;
  final String? objectProof;
}
```

#### Task 1.3: Update GraphQL Queries
- Update `getAllProblems`, `getProblemById`, `createProblem`, `updateProblem`
- Add new fields to all queries and mutations

---

### Phase 2: Constraint System (Week 2-3)

#### Task 2.1: Constraint Extractor
```dart
class ConstraintExtractor {
  ScalarConstraints extractScalarConstraints(DAGManager dag);
  ObjectConstraints extractObjectConstraints(DAGManager dag);
}
```

Features:
- Extract distances from point pairs
- Extract angles from point triplets
- Detect parallel lines
- Detect perpendicular lines
- Detect tangent circles
- Detect concurrent lines
- Detect collinear points

#### Task 2.2: Constraint UI
- Add constraint panel to GeoDraw screens
- Show detected constraints
- Allow manual constraint addition
- Visual constraint indicators on canvas

---

### Phase 3: Solver Service (Week 4)

#### Task 3.1: Create SolverService
```dart
class SolverService {
  final String endpoint = 'http://192.168.1.3:5000/graphql';
  
  Future<SolverResult> solveConstraints({
    required Map<String, dynamic> constructionData,
    required Map<String, dynamic> scalarConstraints,
    required Map<String, dynamic> objectConstraints,
    required String proofGoal,
  });
}
```

#### Task 3.2: Update AIService Configuration
```dart
// Change from:
AIServiceConfig.development() // http://localhost:3000

// To:
AIServiceConfig(
  apiEndpoint: 'http://192.168.1.3:5000/graphql',
)
```

#### Task 3.3: Solver Integration in BLoC
```dart
// In ProblemBloc
on<ProblemSolveRequested>((event, emit) async {
  final solverResult = await solverService.solveConstraints(...);
  
  if (solverResult.success) {
    // Update problem with proofs
    final updatedProblem = problem.copyWith(
      scalarProof: solverResult.scalarProof,
      objectProof: solverResult.objectProof,
    );
    // Save to database
  } else {
    // Show error
  }
});
```

---

### Phase 4: Python Solver Server (Week 5-8)

#### Task 4.1: Server Setup
```python
# server/main.py
from ariadne import QueryType, MutationType, make_executable_schema
from ariadne.asgi import GraphQL
import uvicorn

# GraphQL type definitions
type_defs = """
  type Query { ... }
  type Mutation { ... }
  ...
"""

# Resolvers
query = QueryType()
mutation = MutationType()

@mutation.field("solveConstraints")
async def resolve_solve_constraints(_, info, input):
    # Constraint solving logic
    pass

@mutation.field("generateCommands")
async def resolve_generate_commands(_, info, input):
    # AI/NLP logic
    pass

schema = make_executable_schema(type_defs, query, mutation)
app = GraphQL(schema)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)
```

#### Task 4.2: Constraint Solver Engine
- Implement geometric constraint solver (e.g., using SymPy)
- Support distance, angle, ratio constraints
- Support parallel, perpendicular, tangent constraints
- Generate step-by-step proofs

#### Task 4.3: AI/NLP Module
- Integrate LLM (OpenAI API, local LLM, or Ollama)
- Parse natural language to CLI commands
- Validate generated commands
- Generate explanations

---

### Phase 5: UI Integration (Week 9)

#### Task 5.1: Proof Viewer
- Create proof display widget
- Render markdown/HTML proofs
- Show step-by-step construction
- Visual diagram references

#### Task 5.2: Constraint Editor
- UI for adding constraints
- Constraint validation
- Visual feedback on canvas

#### Task 5.3: Solve Button
- Add "Solve" button to problem screens
- Show solving progress
- Display results
- Save proofs to database

---

## Configuration Management

### Development Environment Variables

Create `.env` file:
```env
# Directus
DIRECTUS_URL=http://192.168.1.3:8055
DIRECTUS_GRAPHQL_URL=http://192.168.1.3:8055/graphql

# Python Solver
SOLVER_URL=http://192.168.1.3:5000
SOLVER_GRAPHQL_URL=http://192.168.1.3:5000/graphql

# AI/NLP
AI_ENDPOINT=http://192.168.1.3:5000/graphql
AI_MODEL=gpt-4  # or local model
```

### Flutter Configuration
```dart
class AppConfig {
  static const directusUrl = String.fromEnvironment(
    'DIRECTUS_URL',
    defaultValue: 'http://192.168.1.3:8055',
  );
  
  static const solverUrl = String.fromEnvironment(
    'SOLVER_URL',
    defaultValue: 'http://192.168.1.3:5000',
  );
}
```

---

## Testing Strategy

### Unit Tests
- Constraint extraction logic
- GraphQL query/mutation formatting
- Proof parsing and rendering

### Integration Tests
- SolverService with mock Python server
- AIService with mock NLP endpoint
- Full problem CRUD with constraints

### End-to-End Tests
1. Create problem with GeoDraw
2. Add constraints
3. Solve constraints
4. Verify proofs stored
5. Load and display proofs

---

## Timeline Summary

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Phase 1: Database | 1 week | Updated schema, models, queries |
| Phase 2: Constraints | 2 weeks | Extraction, UI, validation |
| Phase 3: Solver Service | 1 week | Flutter integration |
| Phase 4: Python Server | 4 weeks | Solver engine, AI/NLP |
| Phase 5: UI Integration | 1 week | Proof viewer, editor |
| **Total** | **9 weeks** | Full solver system |

---

## Next Immediate Steps

1. **Update Directus schema** - Add 4 new fields to problems collection
2. **Update Problem model** - Add constraint/proof fields
3. **Update GraphQL queries** - Include new fields
4. **Create SOLVER_API_SPEC.md** - Detailed Python server API documentation
5. **Create constraint extraction system** - Build `ConstraintExtractor` class

---

## Notes

- **Solver is NOT fully developed** - Currently no solver exists
- Python GraphQL server needs to be built from scratch
- AI endpoint and solver endpoint will both be on `192.168.1.3:5000`
- Configuration can be changed in future via environment variables
- Directus stores construction + constraints + proofs
- Python server does the solving and proof generation
