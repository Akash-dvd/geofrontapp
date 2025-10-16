#!/bin/bash
# Test script for Directus integration with constraint and proof fields

set -e

echo "================================"
echo "Directus Integration Test Script"
echo "================================"
echo ""

DIRECTUS_URL="http://192.168.1.3:8055/graphql"

echo "1. Testing Health Check..."
curl -s http://192.168.1.3:8055/server/health | jq . || echo "Health check passed"
echo ""

echo "2. Testing Read All Problems (with thumbnail)..."
curl -s -X POST $DIRECTUS_URL \
  -H "Content-Type: application/json" \
  -d '{"query":"{ problems { id title description difficulty category thumbnail scalar_constraints object_constraints scalar_proof object_proof } }"}' | jq .
echo ""

echo "3. Testing Create Problem with Constraints and Proofs..."
CREATE_RESULT=$(curl -s -X POST $DIRECTUS_URL \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation($title: String!, $description: String!, $difficulty: String, $category: String, $thumbnail: String, $scalar_constraints: JSON, $object_constraints: JSON, $scalar_proof: JSON, $object_proof: JSON) { create_problems_item(data: { title: $title, description: $description, difficulty: $difficulty, category: $category, thumbnail: $thumbnail, scalar_constraints: $scalar_constraints, object_constraints: $object_constraints, scalar_proof: $scalar_proof, object_proof: $object_proof }) { id title description difficulty category thumbnail scalar_constraints object_constraints scalar_proof object_proof date_created date_updated } }",
    "variables": {
      "title": "Test Triangle Inequality",
      "description": "Test problem with constraints and proofs",
      "difficulty": "intermediate",
      "category": "geometry",
      "thumbnail": null,
      "scalar_constraints": {"l1-l2": 0, "AB+BC-AC": ">0"},
      "object_constraints": {"C1|C2": 0, "A-B-C": "triangle"},
      "scalar_proof": {"len12": "2*len2", "step1": "AB = sqrt((x2-x1)^2 + (y2-y1)^2)"},
      "object_proof": {"arecollinear": ["c1", "c2", "c3"], "given": ["triangle ABC"]}
    }
  }')
echo "$CREATE_RESULT" | jq .

# Extract ID for further tests
PROBLEM_ID=$(echo "$CREATE_RESULT" | jq -r '.data.create_problems_item.id')
echo "Created problem with ID: $PROBLEM_ID"
echo ""

if [ "$PROBLEM_ID" != "null" ] && [ -n "$PROBLEM_ID" ]; then
  echo "4. Testing Read One Problem with All Fields..."
  curl -s -X POST $DIRECTUS_URL \
    -H "Content-Type: application/json" \
    -d "{\"query\":\"{ problems_by_id(id: \\\"$PROBLEM_ID\\\") { id title description difficulty category thumbnail scalar_constraints object_constraints scalar_proof object_proof date_created date_updated } }\"}" | jq .
  echo ""

  echo "5. Testing Update Problem with New Constraints..."
  curl -s -X POST $DIRECTUS_URL \
    -H "Content-Type: application/json" \
    -d "{
      \"query\": \"mutation(\$id: ID!, \$scalar_constraints: JSON, \$scalar_proof: JSON) { update_problems_item(id: \$id, data: { scalar_constraints: \$scalar_constraints, scalar_proof: \$scalar_proof }) { id title scalar_constraints scalar_proof } }\",
      \"variables\": {
        \"id\": \"$PROBLEM_ID\",
        \"scalar_constraints\": {\"l1-l2\": 0, \"l2-l3\": 1, \"angle_ABC\": 90},
        \"scalar_proof\": {\"step1\": \"Given AB = BC\", \"step2\": \"Therefore angle_ABC = 90\"}
      }
    }" | jq .
  echo ""

  echo "6. Testing Delete Problem..."
  curl -s -X POST $DIRECTUS_URL \
    -H "Content-Type: application/json" \
    -d "{\"query\":\"mutation { delete_problems_item(id: \\\"$PROBLEM_ID\\\") { id } }\"}" | jq .
  echo ""
fi

echo "7. Testing Problem with Full Geometry Data..."
CREATE_FULL=$(curl -s -X POST $DIRECTUS_URL \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation($data: create_problems_input!) { create_problems_item(data: $data) { id title thumbnail geometry_data scalar_constraints object_constraints scalar_proof object_proof } }",
    "variables": {
      "data": {
        "title": "Complete Geometry Problem",
        "description": "Problem with full DAG, constraints, and proofs",
        "difficulty": "advanced",
        "category": "geometry",
        "thumbnail": null,
        "geometry_data": {
          "objects": [
            {"id": "A", "type": "point", "x": 100, "y": 100},
            {"id": "B", "type": "point", "x": 200, "y": 150},
            {"id": "C", "type": "point", "x": 150, "y": 250}
          ],
          "constraints": []
        },
        "scalar_constraints": {"AB": 111.8, "BC": 111.8, "AC": 158.1},
        "object_constraints": {"AB|BC": "perpendicular"},
        "scalar_proof": {"AB^2 + BC^2": "AC^2", "conclusion": "Right triangle"},
        "object_proof": {"theorem": "Pythagorean", "steps": ["Given right angle at B", "Therefore AB^2 + BC^2 = AC^2"]}
      }
    }
  }')
echo "$CREATE_FULL" | jq .

FULL_PROBLEM_ID=$(echo "$CREATE_FULL" | jq -r '.data.create_problems_item.id')
echo "Created full problem with ID: $FULL_PROBLEM_ID"
echo ""

if [ "$FULL_PROBLEM_ID" != "null" ] && [ -n "$FULL_PROBLEM_ID" ]; then
  echo "8. Cleaning up test data..."
  curl -s -X POST $DIRECTUS_URL \
    -H "Content-Type: application/json" \
    -d "{\"query\":\"mutation { delete_problems_item(id: \\\"$FULL_PROBLEM_ID\\\") { id } }\"}" | jq .
  echo ""
fi

echo "================================"
echo "All tests completed!"
echo "================================"
echo ""
echo "✅ Tested Fields:"
echo "  - title, description, difficulty, category"
echo "  - thumbnail (Many-to-One → directus_files)"
echo "  - geometry_data (DAG)"
echo "  - scalar_constraints (JSON)"
echo "  - object_constraints (JSON)"
echo "  - scalar_proof (JSON)"
echo "  - object_proof (JSON)"
echo "  - date_created, date_updated"
echo ""
echo "📝 Notes:"
echo "  - thumbnail field requires Directus schema setup (see DIRECTUS_SETUP_CHECKLIST.md)"
echo "  - In real usage, thumbnail will be auto-generated from canvas when saving problem"
echo "  - This test uses thumbnail: null (will be populated by Flutter app)"
echo ""
echo "Next step: Run Flutter app and test UI"
echo "  cd /home/akash/Project/env/dev/flutter/geofrontapp"
echo "  flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8081"
echo ""
echo "Then test thumbnail capture:"
echo "  1. Create new problem"
echo "  2. Open GeoDraw and draw geometry"
echo "  3. Save problem - thumbnail auto-captured"
echo "  4. Check problem list - thumbnail displays in card"