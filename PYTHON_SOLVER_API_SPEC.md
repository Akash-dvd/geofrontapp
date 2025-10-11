# Python Solver Server API Specification

## Overview

The Python Solver Server is a GraphQL API that provides:
1. **Constraint Solving** - Validate and prove geometric constraints
2. **AI/NLP** - Convert natural language to GeoDraw CLI commands
3. **Proof Generation** - Generate step-by-step mathematical proofs

**Server:** `http://192.168.1.3:5000/graphql`

---

## Quick Start

### Installation

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Linux/Mac
# venv\Scripts\activate   # On Windows

# Install dependencies
pip install ariadne uvicorn sympy numpy openai python-dotenv

# Create .env file
cat > .env << EOF
OPENAI_API_KEY=your_api_key_here  # Optional, for AI features
HOST=0.0.0.0
PORT=5000
EOF

# Run server
python server/main.py
```

### Test Endpoint

```bash
curl -X POST http://192.168.1.3:5000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ solverStatus { online version } }"}'
```

Expected response:
```json
{
  "data": {
    "solverStatus": {
      "online": true,
      "version": "1.0.0"
    }
  }
}
```

---

## GraphQL Schema

### Complete Schema Definition

```graphql
# ============================================
# Entry Points
# ============================================

type Query {
  """Check if solver service is online"""
  solverStatus: SolverStatus!
  
  """Get available constraint types"""
  constraintTypes: [ConstraintTypeInfo!]!
}

type Mutation {
  """
  Solve geometric constraints and generate proof
  Returns both scalar (algebraic) and object (geometric) proofs
  """
  solveConstraints(input: SolverInput!): SolverResult!
  
  """
  Generate CLI commands from natural language description
  Uses AI/NLP to parse intent and create valid GeoDraw commands
  """
  generateCommands(input: AIGenerateInput!): AIGenerateResult!
  
  """
  Validate a list of CLI commands without executing
  Checks syntax and logical consistency
  """
  validateCommands(commands: [String!]!): ValidationResult!
}

# ============================================
# Solver Types
# ============================================

input SolverInput {
  """
  GeoDraw DAG JSON containing all geometric objects
  Format: { nodes: [...], edges: [...], metadata: {...} }
  """
  constructionData: JSON!
  
  """Numerical constraints (distances, angles, ratios)"""
  scalarConstraints: ScalarConstraintsInput
  
  """Geometric constraints (parallel, perpendicular, tangent)"""
  objectConstraints: ObjectConstraintsInput
  
  """Statement to prove (e.g., 'Triangle ABC is equilateral')"""
  proofGoal: String!
}

input ScalarConstraintsInput {
  distances: [DistanceConstraint!]
  angles: [AngleConstraint!]
  ratios: [RatioConstraint!]
  equations: [String!]
}

input DistanceConstraint {
  id: String!
  from: String!  # Point ID
  to: String!    # Point ID
  value: Float!
}

input AngleConstraint {
  id: String!
  points: [String!]!  # Exactly 3 point IDs [P1, vertex, P2]
  value: Float!
  unit: AngleUnit!
}

input RatioConstraint {
  id: String!
  numerator: [String!]!    # 2 point IDs
  denominator: [String!]!  # 2 point IDs
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
  id: String!
  line1: String!  # Line ID
  line2: String!  # Line ID
}

input PerpendicularConstraint {
  id: String!
  line1: String!
  line2: String!
}

input TangentConstraint {
  id: String!
  circle: String!  # Circle ID
  line: String!    # Line ID
  point: String!   # Point ID on tangent
}

input ConcurrentConstraint {
  id: String!
  lines: [String!]!  # 3+ line IDs
  point: String!     # Intersection point ID
}

input CollinearConstraint {
  id: String!
  points: [String!]!  # 3+ point IDs
}

input CyclicConstraint {
  id: String!
  points: [String!]!  # 4+ point IDs
  circle: String      # Optional circle ID
}

type SolverResult {
  """Whether all constraints were satisfied"""
  success: Boolean!
  
  """Human-readable error message"""
  errorMessage: String
  
  """Error classification"""
  errorType: SolverErrorType
  
  """
  Algebraic/numerical proof in Markdown format
  Shows coordinate calculations and numerical verifications
  """
  scalarProof: String
  
  """
  Geometric proof in Markdown format
  Uses geometric theorems and logical reasoning
  """
  objectProof: String
  
  """Detailed results for each constraint"""
  constraintResults: [ConstraintResult!]!
  
  """Step-by-step construction with explanations"""
  constructionSteps: [ConstructionStep!]!
  
  """Computation time in milliseconds"""
  computationTime: Float!
}

type ConstraintResult {
  """Constraint identifier"""
  id: String!
  
  """Constraint type (distance, angle, parallel, etc.)"""
  type: String!
  
  """Whether constraint was satisfied within tolerance"""
  satisfied: Boolean!
  
  """Computed value (for scalar constraints)"""
  actualValue: Float
  
  """Expected value (for scalar constraints)"""
  expectedValue: Float
  
  """Tolerance used for comparison"""
  tolerance: Float
  
  """Human-readable explanation"""
  explanation: String!
}

type ConstructionStep {
  """Step number (1-indexed)"""
  stepNumber: Int!
  
  """CLI command that creates this step"""
  command: String!
  
  """Human-readable description"""
  description: String!
  
  """Diagram markup or reference (optional)"""
  visualization: String
  
  """Theorem or property applied"""
  theoremApplied: String
  
  """Justification for this step"""
  justification: String!
}

enum SolverErrorType {
  """Not enough constraints to determine solution"""
  UNDER_CONSTRAINED
  
  """Too many independent constraints"""
  OVER_CONSTRAINED
  
  """Constraints are mutually incompatible"""
  CONTRADICTORY
  
  """Construction data is malformed or invalid"""
  INVALID_CONSTRUCTION
  
  """Timeout during solving"""
  TIMEOUT
}

enum AngleUnit {
  DEGREES
  RADIANS
}

type SolverStatus {
  """Whether service is running"""
  online: Boolean!
  
  """Semantic version string"""
  version: String!
  
  """Uptime in seconds"""
  uptime: Int!
  
  """Number of requests processed"""
  requestCount: Int!
}

type ConstraintTypeInfo {
  """Type name (distance, angle, parallel, etc.)"""
  name: String!
  
  """Human-readable description"""
  description: String!
  
  """Example usage"""
  example: String!
}

# ============================================
# AI/NLP Types
# ============================================

input AIGenerateInput {
  """
  Natural language description of desired construction
  Example: "Create an equilateral triangle with side length 100"
  """
  description: String!
  
  """
  Optional context from current construction
  Format: { objects: [...], lastCommand: "..." }
  """
  context: JSON
  
  """Maximum number of commands to generate (default: 20)"""
  maxCommands: Int
}

type AIGenerateResult {
  """Whether generation succeeded"""
  success: Boolean!
  
  """Error message if failed"""
  errorMessage: String
  
  """List of CLI commands to execute"""
  commands: [String!]!
  
  """Natural language explanation of what will happen"""
  explanation: String!
  
  """Confidence score from 0 to 1"""
  confidence: Float!
  
  """Alternative interpretations (if any)"""
  alternatives: [AIAlternative!]!
}

type AIAlternative {
  """Alternative command sequence"""
  commands: [String!]!
  
  """Explanation of alternative"""
  explanation: String!
  
  """Confidence for this alternative"""
  confidence: Float!
}

type ValidationResult {
  """Whether all commands are syntactically valid"""
  valid: Boolean!
  
  """List of errors found"""
  errors: [CommandError!]!
  
  """List of warnings (non-fatal issues)"""
  warnings: [CommandWarning!]!
}

type CommandError {
  """The problematic command"""
  command: String!
  
  """Line number (1-indexed)"""
  line: Int!
  
  """Error message"""
  message: String!
  
  """Error category"""
  category: ErrorCategory!
}

type CommandWarning {
  """The command with warning"""
  command: String!
  
  """Line number (1-indexed)"""
  line: Int!
  
  """Warning message"""
  message: String!
}

enum ErrorCategory {
  SYNTAX_ERROR
  UNDEFINED_REFERENCE
  TYPE_MISMATCH
  DUPLICATE_NAME
  INVALID_ARGUMENT
}

# ============================================
# Utility Types
# ============================================

"""
JSON scalar for arbitrary JSON data
Used for construction data and context
"""
scalar JSON
```

---

## Example Requests

### 1. Check Server Status

**Request:**
```graphql
query {
  solverStatus {
    online
    version
    uptime
    requestCount
  }
}
```

**Response:**
```json
{
  "data": {
    "solverStatus": {
      "online": true,
      "version": "1.0.0",
      "uptime": 3600,
      "requestCount": 42
    }
  }
}
```

---

### 2. Solve Constraints (Equilateral Triangle)

**Request:**
```graphql
mutation {
  solveConstraints(input: {
    constructionData: {
      nodes: [
        { id: "A", type: "point", x: 0, y: 0 },
        { id: "B", type: "point", x: 5, y: 0 },
        { id: "C", type: "point", x: 2.5, y: 4.33 }
      ]
    },
    scalarConstraints: {
      distances: [
        { id: "d1", from: "A", to: "B", value: 5.0 },
        { id: "d2", from: "B", to: "C", value: 5.0 },
        { id: "d3", from: "C", to: "A", value: 5.0 }
      ]
    },
    proofGoal: "Triangle ABC is equilateral"
  }) {
    success
    scalarProof
    objectProof
    constraintResults {
      id
      satisfied
      actualValue
      expectedValue
    }
    computationTime
  }
}
```

**Response:**
```json
{
  "data": {
    "solveConstraints": {
      "success": true,
      "scalarProof": "## Proof: Triangle ABC is Equilateral\n\n**Given:**\n- Points A(0, 0), B(5, 0), C(2.5, 4.33)\n\n**To Prove:** All sides equal\n\n**Calculations:**\n1. |AB| = √((5-0)² + (0-0)²) = 5.0 ✓\n2. |BC| = √((2.5-5)² + (4.33-0)²) = 5.0 ✓\n3. |CA| = √((0-2.5)² + (0-4.33)²) = 5.0 ✓\n\n**Conclusion:** All sides equal 5.0, therefore triangle is equilateral. ∎",
      "objectProof": "## Geometric Proof\n\n**Given:** Triangle ABC with AB = BC = CA\n\n**Theorem:** If all sides of a triangle are equal, it is equilateral.\n\n**Proof:** By definition of equilateral triangle. ∎",
      "constraintResults": [
        { "id": "d1", "satisfied": true, "actualValue": 5.0, "expectedValue": 5.0 },
        { "id": "d2", "satisfied": true, "actualValue": 5.0, "expectedValue": 5.0 },
        { "id": "d3", "satisfied": true, "actualValue": 5.0, "expectedValue": 5.0 }
      ],
      "computationTime": 15.3
    }
  }
}
```

---

### 3. Generate Commands from Natural Language

**Request:**
```graphql
mutation {
  generateCommands(input: {
    description: "Create an equilateral triangle with side length 100"
  }) {
    success
    commands
    explanation
    confidence
  }
}
```

**Response:**
```json
{
  "data": {
    "generateCommands": {
      "success": true,
      "commands": [
        "point A at 0 0",
        "point B at 100 0",
        "point C at 50 86.6",
        "segment AB from A to B",
        "segment BC from B to C",
        "segment CA from C to A"
      ],
      "explanation": "Creates an equilateral triangle with vertices A, B, C where each side is 100 units long. Point C is positioned at the apex using the formula for equilateral triangle height: h = (√3/2) × side ≈ 86.6.",
      "confidence": 0.95
    }
  }
}
```

---

### 4. Validate Commands

**Request:**
```graphql
mutation {
  validateCommands(commands: [
    "point A at 0 0",
    "point B at 100 0",
    "line l1 through A B",
    "line l2 through X Y"  # Error: X and Y undefined
  ]) {
    valid
    errors {
      command
      line
      message
      category
    }
  }
}
```

**Response:**
```json
{
  "data": {
    "validateCommands": {
      "valid": false,
      "errors": [
        {
          "command": "line l2 through X Y",
          "line": 4,
          "message": "Undefined reference: X",
          "category": "UNDEFINED_REFERENCE"
        },
        {
          "command": "line l2 through X Y",
          "line": 4,
          "message": "Undefined reference: Y",
          "category": "UNDEFINED_REFERENCE"
        }
      ]
    }
  }
}
```

---

## Python Implementation Structure

### Project Structure

```
solver-server/
├── server/
│   ├── __init__.py
│   ├── main.py              # Entry point, ASGI app
│   ├── schema.py            # GraphQL schema definition
│   ├── resolvers/
│   │   ├── __init__.py
│   │   ├── query.py         # Query resolvers
│   │   └── mutation.py      # Mutation resolvers
│   ├── solver/
│   │   ├── __init__.py
│   │   ├── constraint_solver.py  # Core solving logic
│   │   ├── proof_generator.py    # Proof formatting
│   │   └── validator.py          # Constraint validation
│   ├── ai/
│   │   ├── __init__.py
│   │   ├── nlp_parser.py         # NLP → commands
│   │   └── llm_client.py         # OpenAI/local LLM client
│   └── utils/
│       ├── __init__.py
│       └── geometry.py           # Geometry utilities
├── tests/
│   ├── test_solver.py
│   ├── test_ai.py
│   └── test_validation.py
├── requirements.txt
├── .env.example
└── README.md
```

### Key Dependencies

```txt
# requirements.txt
ariadne==0.23.0          # GraphQL server
uvicorn[standard]==0.30.0 # ASGI server
sympy==1.12              # Symbolic mathematics
numpy==1.26.0            # Numerical computations
openai==1.0.0            # Optional: OpenAI API
python-dotenv==1.0.0     # Environment variables
pytest==7.4.0            # Testing
```

### Example: Main Server

```python
# server/main.py
import os
from ariadne import QueryType, MutationType, make_executable_schema, load_schema_from_path
from ariadne.asgi import GraphQL
from dotenv import load_dotenv
import uvicorn

# Load environment variables
load_dotenv()

# Load GraphQL schema
type_defs = load_schema_from_path("server/schema.graphql")

# Initialize resolvers
query = QueryType()
mutation = MutationType()

@query.field("solverStatus")
def resolve_solver_status(_, info):
    return {
        "online": True,
        "version": "1.0.0",
        "uptime": 0,  # TODO: track actual uptime
        "requestCount": 0,  # TODO: track requests
    }

@mutation.field("solveConstraints")
async def resolve_solve_constraints(_, info, input):
    from server.solver.constraint_solver import solve
    return await solve(input)

@mutation.field("generateCommands")
async def resolve_generate_commands(_, info, input):
    from server.ai.nlp_parser import generate
    return await generate(input)

@mutation.field("validateCommands")
async def resolve_validate_commands(_, info, commands):
    from server.solver.validator import validate
    return validate(commands)

# Create executable schema
schema = make_executable_schema(type_defs, query, mutation)

# Create GraphQL app
app = GraphQL(schema, debug=True)

if __name__ == "__main__":
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 5000))
    
    print(f"🚀 Solver server starting on http://{host}:{port}/graphql")
    uvicorn.run(app, host=host, port=port)
```

---

## Testing

### Using curl

```bash
# Test solver status
curl -X POST http://192.168.1.3:5000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ solverStatus { online version } }"}'

# Test command generation
curl -X POST http://192.168.1.3:5000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation($input: AIGenerateInput!) { generateCommands(input: $input) { success commands explanation } }",
    "variables": {
      "input": {
        "description": "Create a square with side 50"
      }
    }
  }'
```

### Using Python Client

```python
import requests

url = "http://192.168.1.3:5000/graphql"

query = """
query {
  solverStatus {
    online
    version
  }
}
"""

response = requests.post(url, json={"query": query})
print(response.json())
```

---

## Docker Deployment (Optional)

### Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server/ server/

EXPOSE 5000

CMD ["python", "-m", "server.main"]
```

### docker-compose.yml Addition

```yaml
services:
  # ... existing services ...
  
  solver:
    build: ./solver-server
    ports:
      - "5000:5000"
    environment:
      - HOST=0.0.0.0
      - PORT=5000
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    networks:
      - geofrontapp-network

networks:
  geofrontapp-network:
    driver: bridge
```

---

## Security Considerations

1. **Rate Limiting** - Add rate limiting to prevent abuse
2. **Input Validation** - Validate all inputs before processing
3. **Timeout Protection** - Set maximum computation time
4. **API Keys** - Protect AI endpoints with authentication
5. **CORS** - Configure CORS for Flutter app origin

---

## Next Steps

1. Create Python project structure
2. Implement basic GraphQL server
3. Add constraint solver logic
4. Integrate AI/NLP module
5. Write comprehensive tests
6. Deploy to 192.168.1.3:5000
7. Test with Flutter app
