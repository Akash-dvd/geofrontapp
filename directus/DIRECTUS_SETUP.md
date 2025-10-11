# Directus Backend Setup for GeoFrontApp

## Overview
Directus is a modern, open-source data platform with built-in GraphQL support. Much easier to set up than Strapi!

---

## Quick Start

### 1. Start Directus with Docker

```bash
cd /home/akash/Project/env/dev/flutter/geofrontapp/directus
docker compose up -d
```

Wait ~30 seconds for containers to be healthy.

### 2. Access Directus Admin

Open browser to: **http://192.168.1.3:8055**

**Login with:**
- Email: `admin@example.com`
- Password: `geofrontapp_admin_2025`

---

## Create Problem Collection

### 1. Create Collection

1. Click **"Settings"** (gear icon) in sidebar
2. Click **"Data Model"**
3. Click **"Create Collection"** button
4. **Collection Name:** `problems`
5. Click **"Create"** (leave other settings as default)

### 2. Add Fields

Now add fields to the `problems` collection:

#### Title (String)
1. Click **"New Field"** in `problems` collection
2. Choose **"Input"** → **"Text Input"**
3. **Key:** `title`
4. **Interface:** Standard
5. Click **"Continue"**
6. **Validation:**
   - Required: ✅
   - Max Length: 200
7. Click **"Save"**

#### Description (Text)
1. Click **"New Field"**
2. Choose **"Input"** → **"Textarea"**
3. **Key:** `description`
4. Click **"Continue"**
5. **Validation:**
   - Required: ✅
6. Click **"Save"**

#### Solution (Rich Text)
1. Click **"New Field"**
2. Choose **"Input"** → **"WYSIWYG"**
3. **Key:** `solution`
4. Click **"Continue"**
5. **Validation:**
   - Required: ❌ (optional)
6. Click **"Save"**

#### Difficulty (Dropdown)
1. Click **"New Field"**
2. Choose **"Selection"** → **"Dropdown"**
3. **Key:** `difficulty`
4. Click **"Continue"**
5. **Choices:**
   - `beginner` → Beginner
   - `intermediate` → Intermediate
   - `advanced` → Advanced
   - `expert` → Expert
6. **Validation:**
   - Required: ✅
   - Default: `beginner`
7. Click **"Save"**

#### Category (Dropdown)
1. Click **"New Field"**
2. Choose **"Selection"** → **"Dropdown"**
3. **Key:** `category`
4. Click **"Continue"**
5. **Choices:**
   - `geometry` → Geometry
   - `algebra` → Algebra
   - `trigonometry` → Trigonometry
   - `calculus` → Calculus
   - `proofs` → Proofs
6. **Validation:**
   - Required: ✅
   - Default: `geometry`
7. Click **"Save"**

#### Geometry Data (JSON)
1. Click **"New Field"**
2. Choose **"Input"** → **"JSON"**
3. **Key:** `geometry_data`
4. Click **"Continue"**
5. **Validation:**
   - Required: ❌ (optional)
6. Click **"Save"**

### 3. Set Permissions for Public Access

**Step-by-step for Directus 11.2.1:**

1. Click **"Settings"** (⚙️ gear icon) in the left sidebar (bottom)
2. Under "Access Control" section, click **"Roles & Permissions"**
3. Click on the **"Public"** role (it's a default role)
4. Scroll down to find **"problems"** collection in the list
5. Click the **row** for "problems" to expand permissions
6. Enable all CRUD operations by clicking the icons:
   - ✅ **Create** (plus icon `➕`)
   - ✅ **Read** (eye icon `👁`)
   - ✅ **Update** (pencil icon `✏️`)
   - ✅ **Delete** (trash icon `🗑`)
7. Click **"Save"** button (top right corner)

**What this does:** Allows unauthenticated users (your Flutter app) to perform CRUD operations on problems without requiring login tokens.

**Alternative:** If "Public" role doesn't appear, you may need to:
- Click "Create Role" button
- Name it "Public"
- Toggle "Public Role" switch ON
- Then set permissions as above

---

## GraphQL API

### GraphQL Endpoint
**URL:** `http://192.168.1.3:8055/graphql`

GraphQL is **already enabled** in Directus! No plugin installation needed. 🎉

### Test GraphQL

**Option 1: GraphiQL Playground (Recommended)**
1. Login to Directus admin: **http://192.168.1.3:8055**
2. Click **Settings** (⚙️) → **GraphQL**
3. You'll see the interactive GraphiQL playground

**Option 2: Direct API Testing with curl**
The endpoint `http://192.168.1.3:8055/graphql` expects POST requests with a query string.

#### Test: Read All Problems

```bash
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ problems { id title description difficulty category } }"}'
```

---

## CRUD Testing with curl

### Create a Problem

```bash
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { create_problems_item(data: { title: \"Prove Triangle Inequality\", description: \"Prove that the sum of any two sides of a triangle is greater than the third side.\", difficulty: \"intermediate\", category: \"geometry\", solution: \"<p>Using geometric construction...</p>\" }) { id title description difficulty category solution date_created date_updated } }"
  }'
```

### Read All Problems

```bash
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ problems { id title description difficulty category solution geometry_data date_created date_updated } }"
  }'
```

### Read One Problem by ID

```bash
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ problems_by_id(id: \"1\") { id title description difficulty category solution geometry_data } }"
  }'
```

### Update a Problem

```bash
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { update_problems_item(id: \"1\", data: { solution: \"<p>Complete proof with step-by-step construction...</p>\" }) { id title solution } }"
  }'
```

### Delete a Problem

```bash
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { delete_problems_item(id: \"1\") { id } }"
  }'
```

---

## GraphQL Queries (for GraphiQL Playground)

If you prefer using the GraphiQL playground (Settings → GraphQL), use these queries:

### Create a Problem

```graphql
mutation {
  create_problems_item(data: {
    title: "Prove Triangle Inequality"
    description: "Prove that the sum of any two sides of a triangle is greater than the third side."
    difficulty: "intermediate"
    category: "geometry"
    solution: "<p>Using geometric construction and algebraic manipulation...</p>"
  }) {
    id
    title
    description
    difficulty
    category
    solution
    date_created
    date_updated
  }
}
```

### Fetch All Problems

```graphql
query {
  problems {
    id
    title
    description
    difficulty
    category
    solution
    geometry_data
    date_created
    date_updated
  }
}
```

### Fetch One Problem

```graphql
query {
  problems_by_id(id: "1") {
    id
    title
    description
    difficulty
    category
    solution
    geometry_data
  }
}
```

### Update Problem

```graphql
mutation {
  update_problems_item(id: "1", data: {
    solution: "<p>Complete proof with step-by-step construction...</p>"
  }) {
    id
    title
    solution
  }
}
```

### Delete Problem

```graphql
mutation {
  delete_problems_item(id: "1") {
    id
  }
}
```

---

## Update Flutter App Configuration

Update your Flutter app to use Directus GraphQL endpoint:

### 1. Edit `lib/config/graphql_config.dart`

```dart
class GraphQLConfig {
  // Change from Strapi to Directus
  static const String _directusEndpoint = 'http://192.168.1.3:8055/graphql';
  
  static HttpLink get httpLink => HttpLink(_directusEndpoint);
  
  static GraphQLClient get client => GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(),
      );
}
```

### 2. Update GraphQL Queries

Directus uses slightly different query names:

**Old (Strapi):**
```graphql
query {
  problems {
    data {
      id
      attributes {
        title
      }
    }
  }
}
```

**New (Directus):**
```graphql
query {
  problems {
    id
    title
    description
    difficulty
    category
  }
}
```

---

## Directus vs Strapi Comparison

| Feature | Directus | Strapi |
|---------|----------|--------|
| Setup Time | 2 minutes | 20+ minutes |
| GraphQL | Built-in ✅ | Requires plugin |
| Admin UI | Modern, intuitive | Complex |
| Docker | Perfect support | Version issues |
| Node.js | Any version | Requires 18+ |
| Database | Wraps existing DB | Owns DB |
| Learning Curve | Easy | Steep |

---

## Useful Directus Features

### 1. API Explorer
- Go to **Settings** → **API Explorer**
- See all your API endpoints
- Copy example queries

### 2. Data Studio
- Click **"Content"** in sidebar
- Click **"problems"**
- Add/edit/delete problems via UI

### 3. Flows (Webhooks)
- Create automated workflows
- Trigger on data changes
- Send notifications

### 4. File Uploads
- Built-in file management
- S3-compatible storage
- Image transformations

---

## Environment Variables

Create `.env` file if you want to customize:

```env
# Security (CHANGE IN PRODUCTION!)
KEY=your-random-key-min-32-chars-long
SECRET=your-random-secret-min-32-chars-long

# Admin
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=geofrontapp_admin_2025

# Database
DB_CLIENT=pg
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=geofrontapp
DB_USER=geofrontapp_user
DB_PASSWORD=geofrontapp_password_2025

# URLs
PUBLIC_URL=http://192.168.1.3:8055

# CORS
CORS_ENABLED=true
CORS_ORIGIN=http://192.168.1.3:8081

# GraphQL
GRAPHQL_ENABLED=true
GRAPHQL_INTROSPECTION=true
```

Generate random keys:
```bash
openssl rand -base64 32
```

---

## Useful Commands

### Start Directus
```bash
cd /home/akash/Project/env/dev/flutter/geofrontapp/directus
docker compose up -d
```

### Stop Directus
```bash
docker compose down
```

### View Logs
```bash
docker compose logs -f directus
```

### Restart
```bash
docker compose restart directus
```

### Reset Everything
```bash
docker compose down -v  # Warning: deletes all data!
docker compose up -d
```

### Check Health
```bash
curl http://192.168.1.3:8055/server/health
```

---

## Troubleshooting

### Port 8055 already in use
```bash
lsof -ti:8055 | xargs kill -9
```

### Database connection issues
```bash
# Check postgres is running
docker compose ps postgres

# Check logs
docker compose logs postgres
```

### Reset admin password
```bash
docker compose exec directus npx directus users update \
  --email admin@example.com \
  --password new_password_here
```

---

## Next Steps

1. ✅ Start Directus: `docker compose up -d`
2. ✅ Login: http://192.168.1.3:8055
3. ✅ Create `problems` collection with fields
4. ✅ Set Public permissions
5. ✅ Test GraphQL: http://192.168.1.3:8055/graphql
6. ✅ Update Flutter app to use Directus endpoint
7. 🔄 Create sample problems
8. 🔄 Test CRUD from Flutter app

---

## Resources

- [Directus Documentation](https://docs.directus.io/)
- [Directus GraphQL API](https://docs.directus.io/reference/graphql.html)
- [Docker Installation](https://docs.directus.io/self-hosted/docker-guide.html)

---

## Summary

**Directus is MUCH easier than Strapi:**
- ✅ No plugin installation needed
- ✅ GraphQL built-in
- ✅ Perfect Docker support
- ✅ Modern admin UI
- ✅ Works on any Node.js version
- ✅ Ready in 2 minutes vs 20+ minutes

**Your GeoFrontApp will connect to:** `http://192.168.1.3:8055/graphql`
