#!/bin/bash
# Test the exact GraphQL mutation that's failing

echo "Testing CreateProblem mutation with thumbnail..."
echo ""

curl -s -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation CreateProblem($title: String!, $description: String!, $difficulty: String!, $category: String!, $thumbnail: create_directus_files_input) { create_problems_item(data: { title: $title, description: $description, difficulty: $difficulty, category: $category, thumbnail: $thumbnail }) { id title thumbnail { id } } }",
    "variables": {
      "title": "Test Problem",
      "description": "Test Description",
      "difficulty": "beginner",
      "category": "geometry",
      "thumbnail": {
        "id": "d4428061-5c50-4b34-b09c-664983b6b65d"
      }
    }
  }' | jq '.'

echo ""
echo "If you see INTERNAL_SERVER_ERROR, check Directus logs:"
echo "  docker logs strapi-cms-1 2>&1 | tail -50"
