#!/bin/bash

# Apply permissions using Hasura Metadata API directly
# This bypasses the metadata files and applies permissions via HTTP

HASURA_ENDPOINT="https://premium-turkey-36.hasura.app"
ADMIN_SECRET="AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

echo "🚀 Applying permissions via Metadata API..."
echo ""

# Function to apply permission
apply_permission() {
    local response=$(curl -s -X POST \
        "$HASURA_ENDPOINT/v1/metadata" \
        -H "x-hasura-admin-secret: $ADMIN_SECRET" \
        -H "Content-Type: application/json" \
        -d "$1")
    
    echo "$response" | grep -q "message" && echo "  ❌ Error: $response" || echo "  ✅ Applied"
}

echo "📋 Creating SELECT permission for problems table..."
apply_permission '{
  "type": "pg_create_select_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "columns": ["id","title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","status","image_id","owner_uid","created_at","updated_at"],
      "filter": {
        "_or": [
          {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
          {"status": {"_eq": "published"}}
        ]
      }
    }
  }
}'

echo "📋 Creating INSERT permission for problems table..."
apply_permission '{
  "type": "pg_create_insert_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "set": {"owner_uid": "x-hasura-User-Id", "status": "draft"},
      "columns": ["title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","image_id"]
    }
  }
}'

echo "📋 Creating UPDATE permission for problems table..."
apply_permission '{
  "type": "pg_create_update_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "columns": ["title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","status","image_id"],
      "filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}
    }
  }
}'

echo "📋 Creating DELETE permission for problems table..."
apply_permission '{
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
echo "📋 Creating SELECT permission for images table..."
apply_permission '{
  "type": "pg_create_select_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user",
    "permission": {
      "columns": ["id","storage_key","filename","mime","size","width","height","thumb_key","title","description","owner_uid","created_at","updated_at"],
      "filter": {
        "_or": [
          {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
          {"problems": {"_or": [{"owner_uid": {"_eq": "X-Hasura-User-Id"}}, {"status": {"_eq": "published"}}]}}
        ]
      }
    }
  }
}'

echo "📋 Creating INSERT permission for images table..."
apply_permission '{
  "type": "pg_create_insert_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user",
    "permission": {
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "set": {"owner_uid": "x-hasura-User-Id"},
      "columns": ["storage_key","filename","mime","size","width","height","thumb_key","title","description"]
    }
  }
}'

echo "📋 Creating UPDATE permission for images table..."
apply_permission '{
  "type": "pg_create_update_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user",
    "permission": {
      "columns": ["storage_key","filename","mime","size","width","height","thumb_key","title","description"],
      "filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}
    }
  }
}'

echo "📋 Creating DELETE permission for images table..."
apply_permission '{
  "type": "pg_create_delete_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user",
    "permission": {
      "filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}
    }
  }
}'

echo ""
echo "✅ Done! Check Hasura Console to verify permissions."
