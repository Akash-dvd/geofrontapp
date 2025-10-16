#!/bin/bash

# Drop all permissions for 'user' role
# This cleans up before reapplying permissions

HASURA_ENDPOINT="https://premium-turkey-36.hasura.app"
ADMIN_SECRET="AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

echo "🗑️  Dropping all permissions for 'user' role..."
echo ""

# Function to drop permission
drop_permission() {
    local response=$(curl -s -X POST \
        "$HASURA_ENDPOINT/v1/metadata" \
        -H "x-hasura-admin-secret: $ADMIN_SECRET" \
        -H "Content-Type: application/json" \
        -d "$1")
    
    echo "$response" | grep -q "\"message\":\"success\"" && echo "  ✅ Dropped" || echo "  ⚠️  Not found or already dropped"
}

echo "🗑️  Dropping permissions for problems table..."

echo "  - SELECT permission..."
drop_permission '{
  "type": "pg_drop_select_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user"
  }
}'

echo "  - INSERT permission..."
drop_permission '{
  "type": "pg_drop_insert_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user"
  }
}'

echo "  - UPDATE permission..."
drop_permission '{
  "type": "pg_drop_update_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user"
  }
}'

echo "  - DELETE permission..."
drop_permission '{
  "type": "pg_drop_delete_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user"
  }
}'

echo ""
echo "🗑️  Dropping permissions for images table..."

echo "  - SELECT permission..."
drop_permission '{
  "type": "pg_drop_select_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user"
  }
}'

echo "  - INSERT permission..."
drop_permission '{
  "type": "pg_drop_insert_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user"
  }
}'

echo "  - UPDATE permission..."
drop_permission '{
  "type": "pg_drop_update_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user"
  }
}'

echo "  - DELETE permission..."
drop_permission '{
  "type": "pg_drop_delete_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user"
  }
}'

echo ""
echo "✅ All permissions dropped for 'user' role!"
echo ""
echo "📝 Next steps:"
echo "   Run: ./apply-via-api.sh"
echo "   This will recreate all permissions with thumbnail_id included."
