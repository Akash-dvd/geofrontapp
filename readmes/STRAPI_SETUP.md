# Strapi Backend Setup Guide for GeoFrontApp

## Overview

This guide will help you set up a Strapi CMS backend for GeoFrontApp. The backend provides a GraphQL API for problem management (CRUD operations) for geometry problems.

---

## Prerequisites

- Node.js 18.x or 20.x (LTS version)
- PostgreSQL 14+ or SQLite (for development)
- npm or yarn package manager

---

## Quick Start

### 1. Create Strapi Project

```bash
# Navigate to your project directory
cd /home/akash/Project/infra/portainer/data

# Create new Strapi project
npx create-strapi-app@latest geofrontapp-backend --quickstart

# Or with PostgreSQL:
npx create-strapi-app@latest geofrontapp-backend \
  --dbclient=postgres \
  --dbhost=localhost \
  --dbport=5432 \
  --dbname=geofrontapp \
  --dbusername=postgres \
  --dbpassword=your_password
```

### 2. Start Strapi

```bash
cd geofrontapp-backend
npm run develop
```

Strapi will start on `http://localhost:1337`

### 3. Create Admin Account

1. Open browser to `http://localhost:1337/admin`
2. Create your admin account (first time only)
3. You'll be redirected to the admin panel

---

## Content Type Configuration

### 1. Create Problem Content Type

In the Strapi admin panel:

1. **Go to Content-Type Builder** (left sidebar)
2. **Click "Create new collection type"**
3. **Display name:** `Problem`
4. **Click "Continue"**

### 2. Add Fields

Add the following fields to the Problem content type:

#### Text Fields

1. **title** (Text - Short text)
   - Type: Text
   - Name: `title`
   - Advanced Settings:
     - Required field: ✅
     - Unique field: ❌
     - Max length: 200

2. **description** (Text - Long text)
   - Type: Text
   - Name: `description`
   - Advanced Settings:
     - Required field: ✅

3. **solution** (Rich text)
   - Type: Rich text
   - Name: `solution`
   - Advanced Settings:
     - Required field: ❌

#### Enumeration Fields

4. **difficulty** (Enumeration)
   - Type: Enumeration
   - Name: `difficulty`
   - Values (add these):
     - `beginner`
     - `intermediate`
     - `advanced`
     - `expert`
   - Advanced Settings:
     - Required field: ✅
     - Default value: `beginner`

5. **category** (Enumeration)
   - Type: Enumeration
   - Name: `category`
   - Values (add these):
     - `geometry`
     - `algebra`
     - `trigonometry`
     - `calculus`
     - `proofs`
   - Advanced Settings:
     - Required field: ✅
     - Default value: `geometry`

#### JSON Field

6. **geometryData** (JSON)
   - Type: JSON
   - Name: `geometryData`
   - Advanced Settings:
     - Required field: ❌

### 3. Save Content Type

1. Click **"Save"** button
2. Strapi will restart automatically

---

## Enable GraphQL Plugin

### 1. Install GraphQL Plugin

```bash
cd geofrontapp-backend
npm install @strapi/plugin-graphql
```

### 2. Enable Plugin

Edit `config/plugins.js` (create if doesn't exist):

```javascript
module.exports = {
  graphql: {
    enabled: true,
    config: {
      endpoint: '/graphql',
      shadowCRUD: true,
      playgroundAlways: true,
      depthLimit: 10,
      amountLimit: 100,
      apolloServer: {
        tracing: false,
      },
    },
  },
};
```

### 3. Restart Strapi

```bash
npm run develop
```

GraphQL Playground will be available at: `http://localhost:1337/graphql`

---

## Configure Permissions

### 1. Set Public Permissions (for Development)

In Strapi Admin Panel:

1. Go to **Settings** → **Users & Permissions Plugin** → **Roles**
2. Click **Public** role
3. Expand **Problem** permissions
4. Check these permissions:
   - ✅ `find` (Read all problems)
   - ✅ `findOne` (Read one problem)
   - ✅ `create` (Create problem)
   - ✅ `update` (Update problem)
   - ✅ `delete` (Delete problem)
5. Click **Save**

**Note:** For production, you should use authenticated requests instead of public permissions.

---

## Test GraphQL API

### 1. Open GraphQL Playground

Navigate to: `http://localhost:1337/graphql`

### 2. Test Queries

#### Create a Problem

```graphql
mutation {
  createProblem(data: {
    title: "Prove Triangle Inequality"
    description: "Prove that the sum of any two sides of a triangle is greater than the third side."
    difficulty: intermediate
    category: geometry
    solution: "Using geometric construction and algebraic manipulation..."
  }) {
    data {
      id
      attributes {
        title
        description
        difficulty
        category
        createdAt
      }
    }
  }
}
```

#### Fetch All Problems

```graphql
query {
  problems {
    data {
      id
      attributes {
        title
        description
        difficulty
        category
        createdAt
        updatedAt
      }
    }
  }
}
```

#### Fetch One Problem

```graphql
query {
  problem(id: "1") {
    data {
      id
      attributes {
        title
        description
        difficulty
        category
        geometryData
        solution
      }
    }
  }
}
```

#### Update Problem

```graphql
mutation {
  updateProblem(id: "1", data: {
    solution: "Complete proof with step-by-step construction..."
  }) {
    data {
      id
      attributes {
        title
        solution
      }
    }
  }
}
```

#### Delete Problem

```graphql
mutation {
  deleteProblem(id: "1") {
    data {
      id
    }
  }
}
```

---

## Configure CORS

Edit `config/middlewares.js`:

```javascript
module.exports = [
  'strapi::errors',
  {
    name: 'strapi::security',
    config: {
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'connect-src': ["'self'", 'https:'],
          'img-src': ["'self'", 'data:', 'blob:', 'https:'],
          'media-src': ["'self'", 'data:', 'blob:'],
          upgradeInsecureRequests: null,
        },
      },
    },
  },
  {
    name: 'strapi::cors',
    config: {
      enabled: true,
      origin: ['http://localhost:8081', 'http://0.0.0.0:8081'],
      credentials: true,
    },
  },
  'strapi::poweredBy',
  'strapi::logger',
  'strapi::query',
  'strapi::body',
  'strapi::session',
  'strapi::favicon',
  'strapi::public',
];
```

---

## Production Setup (Optional)

### 1. PostgreSQL Database

Create database:

```bash
sudo -u postgres psql
CREATE DATABASE geofrontapp;
CREATE USER geofrontapp_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE geofrontapp TO geofrontapp_user;
\q
```

### 2. Configure Database

Edit `config/database.js`:

```javascript
module.exports = ({ env }) => ({
  connection: {
    client: 'postgres',
    connection: {
      host: env('DATABASE_HOST', 'localhost'),
      port: env.int('DATABASE_PORT', 5432),
      database: env('DATABASE_NAME', 'geofrontapp'),
      user: env('DATABASE_USERNAME', 'geofrontapp_user'),
      password: env('DATABASE_PASSWORD', 'secure_password'),
      ssl: env.bool('DATABASE_SSL', false),
    },
  },
});
```

### 3. Environment Variables

Create `.env` file:

```env
HOST=0.0.0.0
PORT=1337
APP_KEYS=your-app-keys-here
API_TOKEN_SALT=your-api-token-salt
ADMIN_JWT_SECRET=your-admin-jwt-secret
JWT_SECRET=your-jwt-secret

DATABASE_CLIENT=postgres
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=geofrontapp
DATABASE_USERNAME=geofrontapp_user
DATABASE_PASSWORD=secure_password
DATABASE_SSL=false
```

Generate secrets:

```bash
# Generate random secrets
openssl rand -base64 32
```

---

## Docker Setup (Alternative)

Create `docker-compose.yml` in your project root:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:14-alpine
    container_name: geofrontapp_postgres
    environment:
      POSTGRES_DB: geofrontapp
      POSTGRES_USER: geofrontapp_user
      POSTGRES_PASSWORD: secure_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  strapi:
    image: strapi/strapi:latest
    container_name: geofrontapp_strapi
    depends_on:
      - postgres
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: postgres
      DATABASE_PORT: 5432
      DATABASE_NAME: geofrontapp
      DATABASE_USERNAME: geofrontapp_user
      DATABASE_PASSWORD: secure_password
      JWT_SECRET: your-jwt-secret-here
      ADMIN_JWT_SECRET: your-admin-jwt-secret-here
      APP_KEYS: your-app-keys-here
    ports:
      - "1337:1337"
    volumes:
      - ./geofrontapp-backend:/srv/app

volumes:
  postgres_data:
```

Start with Docker:

```bash
docker-compose up -d
```

---

## Verify Setup

### 1. Check Strapi is Running

```bash
curl http://localhost:1337/_health
```

Should return: `{"status":"ok"}`

### 2. Check GraphQL Endpoint

```bash
curl -X POST http://localhost:1337/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { types { name } } }"}'
```

Should return GraphQL schema information.

### 3. Test from Flutter App

Your Flutter app is already configured to connect to `http://localhost:1337/graphql`

Check `lib/config/graphql_config.dart`:

```dart
static const String _strapiEndpoint = 'http://localhost:1337/graphql';
```

---

## Troubleshooting

### Issue: Port 1337 already in use

```bash
# Find process using port 1337
lsof -ti:1337 | xargs kill -9
```

### Issue: GraphQL plugin not working

```bash
# Reinstall plugin
npm uninstall @strapi/plugin-graphql
npm install @strapi/plugin-graphql
npm run build
npm run develop
```

### Issue: CORS errors

Make sure CORS is configured in `config/middlewares.js` to allow your Flutter app's origin.

### Issue: Permission denied errors

Check that Problem content type has proper permissions in:
**Settings** → **Users & Permissions** → **Roles** → **Public**

---

## Next Steps

1. ✅ Start Strapi backend
2. ✅ Create Problem content type
3. ✅ Enable GraphQL plugin
4. ✅ Configure permissions
5. ✅ Test GraphQL API
6. ✅ Connect Flutter app (already done)
7. 🔄 Create sample problems
8. 🔄 Test CRUD operations from Flutter app

---

## Resources

- [Strapi Documentation](https://docs.strapi.io/)
- [Strapi GraphQL Plugin](https://docs.strapi.io/dev-docs/plugins/graphql)
- [GraphQL Flutter Documentation](https://pub.dev/packages/graphql_flutter)

---

## Support

If you encounter issues:

1. Check Strapi logs: `npm run develop` (terminal output)
2. Check Flutter app logs: Browser console or `flutter run` output
3. Verify GraphQL queries in GraphQL Playground
4. Check Strapi admin panel for content type configuration

Your GeoFrontApp is already configured to connect to Strapi at `http://localhost:1337/graphql`!
