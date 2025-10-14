#!/bin/bash

# Check and reload metadata to fix inconsistencies

HASURA_ENDPOINT="https://premium-turkey-36.hasura.app"
ADMIN_SECRET="AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

echo "🔍 Checking inconsistent metadata..."
echo ""

hasura metadata ic list \
    --endpoint "$HASURA_ENDPOINT" \
    --admin-secret "$ADMIN_SECRET"

echo ""
echo "🔄 Reloading metadata..."
echo ""

hasura metadata reload \
    --endpoint "$HASURA_ENDPOINT" \
    --admin-secret "$ADMIN_SECRET"

echo ""
echo "✅ Checking again..."
echo ""

hasura metadata ic list \
    --endpoint "$HASURA_ENDPOINT" \
    --admin-secret "$ADMIN_SECRET"

echo ""
echo "If inconsistencies remain, we need to re-apply the metadata."
