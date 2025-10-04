#!/bin/bash

# Strapi Backend Quick Start Script
# This script starts Strapi and PostgreSQL using Docker Compose

set -e

echo "🚀 Starting GeoFrontApp Strapi Backend..."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null && ! docker-compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found in current directory"
    exit 1
fi

# Stop any running services
echo "📦 Stopping any running services..."
docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true

# Start services
echo "🔧 Starting PostgreSQL and Strapi..."
docker compose up -d 2>/dev/null || docker-compose up -d

# Wait for services to be healthy
echo ""
echo "⏳ Waiting for services to start..."
sleep 5

# Check PostgreSQL
echo "🔍 Checking PostgreSQL..."
for i in {1..30}; do
    if docker compose exec -T postgres pg_isready -U geofrontapp_user &>/dev/null || \
       docker-compose exec -T postgres pg_isready -U geofrontapp_user &>/dev/null; then
        echo "✅ PostgreSQL is ready"
        break
    fi
    echo "   Waiting for PostgreSQL... ($i/30)"
    sleep 2
done

# Check Strapi
echo "🔍 Checking Strapi..."
for i in {1..60}; do
    if curl -s http://localhost:1337/_health | grep -q "ok"; then
        echo "✅ Strapi is ready"
        break
    fi
    echo "   Waiting for Strapi... ($i/60)"
    sleep 3
done

# Display status
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Strapi Backend is Running!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Access Points:"
echo "   Admin Panel:       http://localhost:1337/admin"
echo "   GraphQL Playground: http://localhost:1337/graphql"
echo "   API:               http://localhost:1337/api"
echo "   Health Check:      http://localhost:1337/_health"
echo ""
echo "📊 Database:"
echo "   PostgreSQL:        localhost:5432"
echo "   Database:          geofrontapp"
echo "   User:              geofrontapp_user"
echo ""
echo "📝 Next Steps:"
echo "   1. Open http://localhost:1337/admin"
echo "   2. Create your admin account (first time only)"
echo "   3. Follow STRAPI_SETUP.md to configure content types"
echo "   4. Start Flutter app:"
echo "      flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8081"
echo ""
echo "💡 Useful Commands:"
echo "   View logs:    docker compose logs -f strapi"
echo "   Stop services: docker compose down"
echo "   Restart:      docker compose restart"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
