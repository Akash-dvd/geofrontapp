#!/bin/bash

# Hasura Permissions Setup Script
# This script applies all permissions metadata to Hasura Cloud

set -e  # Exit on error

# Configuration
HASURA_ENDPOINT="https://premium-turkey-36.hasura.app"

# Check if admin secret is provided
if [ -z "$HASURA_GRAPHQL_ADMIN_SECRET" ]; then
    echo "Error: HASURA_GRAPHQL_ADMIN_SECRET environment variable not set"
    echo "Usage: export HASURA_GRAPHQL_ADMIN_SECRET='your-admin-secret'"
    echo "       ./apply-permissions.sh"
    exit 1
fi

echo "🚀 Applying Hasura metadata..."
echo "Endpoint: $HASURA_ENDPOINT"
echo ""

# Apply metadata
hasura metadata apply \
    --endpoint "$HASURA_ENDPOINT" \
    --admin-secret "$HASURA_GRAPHQL_ADMIN_SECRET"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Permissions applied successfully!"
    echo ""
    echo "Configured:"
    echo "  - problems table permissions (user role)"
    echo "  - images table permissions (user role)"
    echo "  - Relationships (problems.image, images.problems)"
    echo "  - Auto-set owner_uid from JWT"
    echo "  - Auto-set status = 'draft' on INSERT"
else
    echo ""
    echo "❌ Failed to apply metadata"
    exit 1
fi
