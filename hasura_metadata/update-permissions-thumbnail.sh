#!/bin/bash

# Update existing permissions to include thumbnail_id column
# This script DROPS and RECREATES permissions with the new column

HASURA_ENDPOINT="https://premium-turkey-36.hasura.app"
ADMIN_SECRET="AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

echo "🚀 Updating permissions to include thumbnail_id..."
echo ""

# Function to run metadata command
run_command() {
    local response=$(curl -s -X POST \
        "$HASURA_ENDPOINT/v1/metadata" \
        -H "x-hasura-admin-secret: $ADMIN_SECRET" \
        -H "Content-Type: application/json" \
        -d "$1")
    
    echo "$response" | grep -q '"message"' && echo "  ⚠️  $response" || echo "  ✅ Done"
}

echo "🗑️  Dropping existing problems permissions..."
run_command '{
  "type": "pg_drop_select_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user"
  }
}'

run_command '{
  "type": "pg_drop_insert_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user"
  }
}'

run_command '{
  "type": "pg_drop_update_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user"
  }
}'

run_command '{
  "type": "pg_drop_delete_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user"
  }
}'

echo ""
echo "✨ Creating new permissions with thumbnail_id..."

echo "📋 SELECT permission..."
run_command '{
  "type": "pg_create_select_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "columns": ["id","title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","status","image_id","thumbnail_id","owner_uid","created_at","updated_at"],
      "filter": {
        "_or": [
          {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
          {"status": {"_eq": "published"}}
        ]
      }
    }
  }
}'

echo "📋 INSERT permission..."
run_command '{
  "type": "pg_create_insert_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "set": {"owner_uid": "x-hasura-User-Id", "status": "draft"},
      "columns": ["title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","image_id","thumbnail_id"]
    }
  }
}'

echo "📋 UPDATE permission..."
run_command '{
  "type": "pg_create_update_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "columns": ["title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","status","image_id","thumbnail_id"],
      "filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}
    }
  }
}'

echo "📋 DELETE permission..."
run_command '{
  "type": "pg_create_delete_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}
    }
  }
}'

echo ""
echo "✅ Permissions updated! thumbnail_id is now included."
echo ""
echo "🧪 Test in your Flutter app now!"
