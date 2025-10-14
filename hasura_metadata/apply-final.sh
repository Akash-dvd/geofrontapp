#!/bin/bash

# Apply Hasura Permissions - Final Version
# This applies ONLY the permission metadata without touching other config

set -e

HASURA_ENDPOINT="https://premium-turkey-36.hasura.app"
ADMIN_SECRET="AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

echo "🚀 Applying Hasura permissions metadata..."
echo "Endpoint: $HASURA_ENDPOINT"
echo ""

# Apply only the metadata (doesn't export/overwrite)
hasura metadata apply \
    --endpoint "$HASURA_ENDPOINT" \
    --admin-secret "$ADMIN_SECRET" \
    --skip-update-check

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Permissions metadata applied!"
    echo ""
    echo "🔍 Verifying permissions..."
    echo ""
    
    # Check consistency
    hasura metadata ic list \
        --endpoint "$HASURA_ENDPOINT" \
        --admin-secret "$ADMIN_SECRET"
    
    echo ""
    echo "📋 Next steps:"
    echo "1. Go to Hasura Console: https://premium-turkey-36.hasura.app/console"
    echo "2. Click: Data → supabase → public → problems → Permissions"
    echo "3. Check if 'user' role has SELECT, INSERT, UPDATE, DELETE"
    echo "4. Click on SELECT to verify columns and filters are set"
    echo ""
else
    echo ""
    echo "❌ Failed to apply metadata"
    echo "Check the error messages above"
    exit 1
fi
