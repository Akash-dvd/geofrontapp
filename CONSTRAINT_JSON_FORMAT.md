# Constraint and Proof JSON Format

## Overview

All 4 fields are **JSON** type:
- `scalar_constraints` - Numerical relationships between objects
- `object_constraints` - Geometric relationships  
- `scalar_proof` - Algebraic/numerical proof
- `object_proof` - Geometric proof

---

## Format Examples

### scalar_constraints

**Format:** Key-value pairs where keys describe the constraint and values are the expected result.

```json
{
  "l1-l2": 0,
  "angle_ABC": 90,
  "ratio_AB_CD": 2
}
```

**Examples:**
- `"l1-l2": 0` - Distance between l1 and l2 is 0 (parallel lines at same position)
- `"AB-CD": 5` - Distance between AB and CD is 5
- `"angle_ABC": 60` - Angle ABC is 60 degrees
- `"len_AB": 10` - Length of AB is 10

### object_constraints

**Format:** Key-value pairs describing geometric relationships.

```json
{
  "C1|C2": 0,
  "L1||L2": true,
  "L3⊥L4": true
}
```

**Examples:**
- `"C1|C2": 0` - Circles C1 and C2 intersect
- `"L1||L2": true` - Lines L1 and L2 are parallel
- `"L3⊥L4": true` - Lines L3 and L4 are perpendicular
- `"tangent_C1_L1": true` - Circle C1 is tangent to line L1

### scalar_proof

**Format:** Mathematical expressions showing relationships.

```json
{
  "len12": "2*len2",
  "area_ABC": "0.5*base*height",
  "angle_sum": "180"
}
```

**Examples:**
- `"len12": "2*len2"` - Length 12 equals twice length 2
- `"AB": "sqrt(x^2 + y^2)"` - Length AB derived from coordinates
- `"angle_A": "180 - angle_B - angle_C"` - Angle sum in triangle

### object_proof

**Format:** Geometric facts and theorems applied.

```json
{
  "arecollinear": ["c1", "c2", "c3"],
  "isconcurrent": ["L1", "L2", "L3"],
  "theorem": "SAS congruence"
}
```

**Examples:**
- `"arecollinear": ["A", "B", "C"]` - Points A, B, C are collinear
- `"isconcurrent": ["L1", "L2", "L3"]` - Lines meet at one point
- `"parallel": ["L1", "L2"]` - Lines L1 and L2 are parallel
- `"theorem": "Pythagorean theorem"` - Which theorem was used

---

## Complete Example

```json
{
  "id": "problem_123",
  "title": "Prove Triangle is Equilateral",
  "description": "Given triangle ABC with all sides equal to 5",
  
  "scalar_constraints": {
    "AB": 5,
    "BC": 5,
    "CA": 5
  },
  
  "object_constraints": {
    "is_triangle": true,
    "sides_equal": ["AB", "BC", "CA"]
  },
  
  "scalar_proof": {
    "AB": "5",
    "BC": "5", 
    "CA": "5",
    "angle_A": "60",
    "angle_B": "60",
    "angle_C": "60",
    "angle_sum": "180"
  },
  
  "object_proof": {
    "conclusion": "equilateral",
    "reason": "All sides equal",
    "theorem": "Definition of equilateral triangle"
  }
}
```

---

## Usage in Flutter

### Reading Proofs

```dart
// Access scalar proof
final scalarProof = problem.scalarProof;
if (scalarProof != null) {
  final len12 = scalarProof['len12']; // "2*len2"
  final angleSum = scalarProof['angle_sum']; // "180"
}

// Access object proof
final objectProof = problem.objectProof;
if (objectProof != null) {
  final collinearPoints = objectProof['arecollinear'] as List<dynamic>;
  // ["c1", "c2", "c3"]
  
  final theorem = objectProof['theorem'] as String?;
  // "SAS congruence"
}
```

### Setting Proofs

```dart
final updatedProblem = problem.copyWith(
  scalarProof: {
    'len12': '2*len2',
    'angle_ABC': '90',
  },
  objectProof: {
    'arecollinear': ['A', 'B', 'C'],
    'theorem': 'Pythagorean theorem',
  },
);
```

### Saving to Database

```dart
// The toJson() method automatically includes proofs
final variables = problem.toJson();

// GraphQL mutation
await client.mutate(
  MutationOptions(
    document: gql(ProblemQueries.updateProblem),
    variables: {
      'id': problem.id,
      ...variables,
    },
  ),
);
```

---

## Directus Configuration

When creating fields in Directus:

1. **All 4 fields** use **JSON** type
2. Select **"Input (JSON)"** interface
3. Check **"Allow NULL"** 
4. No need for validation schema

The JSON data will be stored as-is and returned in the same format.

---

## Python Solver Integration

The solver will receive constraints and return proofs in this format:

**Input to Solver:**
```json
{
  "constructionData": { /* GeoDraw DAG */ },
  "scalarConstraints": {
    "AB": 5,
    "BC": 5
  },
  "objectConstraints": {
    "L1||L2": true
  },
  "proofGoal": "Prove triangle is isosceles"
}
```

**Output from Solver:**
```json
{
  "success": true,
  "scalarProof": {
    "AB": "5",
    "BC": "5",
    "conclusion": "AB = BC"
  },
  "objectProof": {
    "theorem": "Definition of isosceles",
    "sides_equal": ["AB", "BC"]
  }
}
```

---

## Benefits of JSON Format

1. **Flexible Structure** - Can store any key-value pairs
2. **Easy Parsing** - Direct Map<String, dynamic> in Dart
3. **Queryable** - Can use JSON operators in SQL/GraphQL
4. **Extensible** - Add new fields without schema changes
5. **Type-Safe** - Dart handles JSON naturally

---

## Notes

- Keys can use any string format (underscores, hyphens, symbols)
- Values can be numbers, strings, booleans, arrays, or nested objects
- No fixed schema required - flexibility for different proof types
- Both constraints and proofs use consistent JSON format
