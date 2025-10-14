#!/bin/bash

# Simple check to get database name from Hasura

HASURA_ENDPOINT="https://premium-turkey-36.hasura.app"
ADMIN_SECRET="AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

echo "🔍 Fetching database list from Hasura..."
echo ""

# Use metadata API to get database names
curl -s -X POST \
  "$HASURA_ENDPOINT/v1/metadata" \
  -H "x-hasura-admin-secret: $ADMIN_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"type":"export_metadata","version":2,"args":{}}' \
  | jq -r '.sources[] | .name'

echo ""
echo "☝️ The name(s) above is/are your database name(s) in Hasura"
