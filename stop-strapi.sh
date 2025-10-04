#!/bin/bash

# Strapi Backend Stop Script
# This script stops Strapi and PostgreSQL containers

set -e

echo "🛑 Stopping GeoFrontApp Strapi Backend..."
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found in current directory"
    exit 1
fi

# Stop services
echo "📦 Stopping services..."
docker compose down 2>/dev/null || docker-compose down

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Strapi Backend Stopped"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Note: Your data is preserved in Docker volumes"
echo ""
echo "To start again: ./start-strapi.sh"
echo "To remove all data: docker compose down -v"
echo ""
