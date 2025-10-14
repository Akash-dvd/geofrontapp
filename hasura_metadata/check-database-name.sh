#!/bin/bash

# Check current Hasura configuration

set -e

HASURA_ENDPOINT="https://premium-turkey-36.hasura.app"
ADMIN_SECRET="AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

echo "🔍 Checking Hasura metadata..."
echo ""

# Export current metadata to see actual database name
hasura metadata export \
    --endpoint "$HASURA_ENDPOINT" \
    --admin-secret "$ADMIN_SECRET"

echo ""
echo "✅ Metadata exported to metadata/ folder"
echo ""
echo "Check metadata/databases/databases.yaml to see your actual database name"
echo ""
echo "Current databases:"
cat metadata/databases/databases.yaml
