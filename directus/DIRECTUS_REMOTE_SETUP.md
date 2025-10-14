# Directus Remote Setup Guide (192.168.1.3)

## 🔧 Quick Setup Commands

Since Directus is running on remote machine `192.168.1.3`, follow these steps:

---

## Step 1: SSH into Remote Machine

```bash
ssh akash@192.168.1.3
```

---

## Step 2: Check Directus Status

```bash
# Check if Directus container is running
docker ps | grep directus

# Or list all containers
docker ps -a
```

**Expected output:**
```
CONTAINER ID   IMAGE                   STATUS          PORTS
xxxxx          directus/directus       Up X minutes    0.0.0.0:8055->8055/tcp
```

---

## Step 3: Locate Directus Directory

```bash
# Find directus docker-compose.yml location
cd ~/directus
# or
cd /opt/directus
# or wherever you installed it

# Verify files
ls -la
```

**You should see:**
- `docker-compose.yml`
- `data/` folder (database storage)
- possibly `extensions/` folder

---

## Step 4: Backup Current Configuration

```bash
# Backup docker-compose.yml
cp docker-compose.yml docker-compose.yml.backup

# Check current environment variables
docker-compose config
```

---

## Step 5: Update docker-compose.yml for Firebase Auth

Edit the file:
```bash
nano docker-compose.yml
# or
vim docker-compose.yml
```

**Add these Firebase JWT environment variables:**

```yaml
version: '3'
services:
  directus:
    image: directus/directus:latest
    ports:
      - 8055:8055
    environment:
      # Existing variables (keep these)
      KEY: 'your-existing-key'
      SECRET: 'your-existing-secret'
      
      DB_CLIENT: 'postgres'
      DB_HOST: 'database'
      DB_PORT: '5432'
      DB_DATABASE: 'directus'
      DB_USER: 'directus'
      DB_PASSWORD: 'directus'
      
      ADMIN_EMAIL: 'admin@example.com'
      ADMIN_PASSWORD: 'your-admin-password'
      PUBLIC_URL: 'http://192.168.1.3:8055'
      
      # ===== ADD THESE FIREBASE AUTH VARIABLES =====
      AUTH_PROVIDERS: 'jwt'
      AUTH_JWT_SECRET: '__firebase__'
      AUTH_JWT_ISSUER: 'https://securetoken.google.com/aksharaintelligence-41f4a'
      AUTH_JWT_AUDIENCE: 'aksharaintelligence-41f4a'
      AUTH_JWT_PUBLIC_KEY: 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'
      AUTH_JWT_IDENTIFIER_KEY: 'user_id'
      AUTH_JWT_EMAIL_KEY: 'email'
      AUTH_JWT_ALLOW_PUBLIC_REGISTRATION: 'true'
      # AUTH_JWT_DEFAULT_ROLE_ID: 'GET_THIS_FROM_UI'  # Add after getting role UUID
      
      GRAPHQL_ENABLED: 'true'
      
  database:
    image: postgis/postgis:13-master
    environment:
      POSTGRES_DB: 'directus'
      POSTGRES_USER: 'directus'
      POSTGRES_PASSWORD: 'directus'
    volumes:
      - ./data/database:/var/lib/postgresql/data
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X` for nano)

---

## Step 6: Restart Directus

```bash
# Stop containers
docker-compose down

# Start with new configuration
docker-compose up -d

# Check logs to verify Firebase auth is working
docker-compose logs -f directus
```

**Look for in logs:**
- ✅ `JWT authentication enabled`
- ✅ `Public key loaded from Firebase`
- ❌ Any errors related to JWT configuration

Press `Ctrl+C` to exit logs.

---

## Step 7: Get Default Role UUID from Directus Admin

### Option A: Via Browser
1. Open browser: `http://192.168.1.3:8055/admin`
2. Login with admin credentials
3. Go to **Settings** → **Roles & Permissions**
4. Click on your default role (e.g., "User")
5. Copy UUID from URL: `.../settings/roles/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

### Option B: Via Database Query
```bash
# Connect to Directus database
docker exec -it directus-database-1 psql -U directus -d directus

# Query roles
SELECT id, name FROM directus_roles;

# Copy the UUID of your default role
# Exit with \q
```

### Update docker-compose.yml with Role UUID
```bash
nano docker-compose.yml
```

Find and update:
```yaml
AUTH_JWT_DEFAULT_ROLE_ID: 'paste-uuid-here'
```

Restart again:
```bash
docker-compose down && docker-compose up -d
```

---

## Step 8: Verify Schema in Directus Admin UI

Open browser: `http://192.168.1.3:8055/admin`

### Check `problems` Collection

1. Go to **Settings** → **Data Model** → **problems**
2. Verify these fields exist:

**Required fields:**
- ✅ `id` (UUID, Primary Key)
- ✅ `title` (String, Required)
- ✅ `description` (Text, Required)
- ✅ `difficulty` (String, Required)
- ✅ `category` (String, Required)
- ✅ `geometry_data` (JSON)
- ✅ `solution` (Text)
- ✅ `scalar_constraints` (JSON)
- ✅ `object_constraints` (JSON)
- ✅ `scalar_proof` (JSON)
- ✅ `object_proof` (JSON)
- ✅ `thumbnail` (File - M2O relation)
- ✅ `date_created` (Timestamp)
- ✅ `date_updated` (Timestamp)

**New fields to add (if missing):**
- ⚠️ `user_owner` (String) - Firebase user ID
- ⚠️ `status` (String) - "draft" or "published"

### Add Missing Fields

#### Add `user_owner`:
1. Click **Create Field**
2. Type: **String**
3. Field Name: `user_owner`
4. Interface: Input
5. Width: Half
6. Placeholder: "Firebase User ID"
7. Save

#### Add `status`:
1. Click **Create Field**
2. Type: **String**
3. Field Name: `status`
4. Interface: Dropdown
5. Choices:
   - `draft` → Draft
   - `published` → Published
6. Default: `draft`
7. Required: Yes
8. Save

---

## Step 9: Configure Permissions

1. Go to **Settings** → **Roles & Permissions**
2. Find your default role (the one you got UUID from)
3. Click on **problems** collection
4. Configure each permission:

### **Create** Permission
- Filter: `{ "user_owner": { "_eq": "$CURRENT_USER" } }`
- Fields: Allow all except `id`, `date_created`, `date_updated`

### **Read** Permission
- Filter: `{ "_or": [ { "user_owner": { "_eq": "$CURRENT_USER" } }, { "status": { "_eq": "published" } } ] }`
- Fields: Allow all

### **Update** Permission
- Filter: `{ "user_owner": { "_eq": "$CURRENT_USER" } }`
- Fields: Allow all except `id`, `user_owner`, `date_created`, `date_updated`

### **Delete** Permission
- Filter: `{ "user_owner": { "_eq": "$CURRENT_USER" } }`

---

## Step 10: Test Firebase Token Authentication

### From your Windows machine:

```powershell
# Test 1: Verify Directus is accessible
curl http://192.168.1.3:8055/server/health

# Test 2: Get Firebase token from Flutter app (print it)
# Then test with curl:
curl -H "Authorization: Bearer <firebase-token>" http://192.168.1.3:8055/items/problems
```

### If you get 200 response:
✅ Firebase authentication is working!

### If you get 401 Unauthorized:
❌ Check these:
1. Is `AUTH_JWT_ISSUER` correct?
2. Is `AUTH_JWT_AUDIENCE` correct?
3. Is Firebase token expired?
4. Check Directus logs: `docker-compose logs directus`

---

## 🎯 Quick Command Summary

```bash
# SSH into remote machine
ssh akash@192.168.1.3

# Navigate to Directus directory
cd ~/directus  # or /opt/directus

# Backup configuration
cp docker-compose.yml docker-compose.yml.backup

# Edit configuration
nano docker-compose.yml
# Add Firebase auth environment variables (see Step 5)

# Restart Directus
docker-compose down && docker-compose up -d

# Check logs
docker-compose logs -f directus

# Get role UUID via database
docker exec -it directus-database-1 psql -U directus -d directus
SELECT id, name FROM directus_roles;
\q

# Update role UUID in docker-compose.yml
nano docker-compose.yml
# Add: AUTH_JWT_DEFAULT_ROLE_ID: 'uuid-here'

# Final restart
docker-compose down && docker-compose up -d

# Verify health
curl http://localhost:8055/server/health
```

---

## 🐛 Troubleshooting

### Cannot connect to Directus after restart
```bash
# Check container status
docker ps -a

# Check logs for errors
docker-compose logs directus

# If database issues:
docker-compose logs database

# Restart everything
docker-compose restart
```

### Firebase token validation fails
```bash
# Check Directus logs
docker-compose logs directus | grep -i jwt

# Verify Firebase public key is accessible
curl https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com

# Check environment variables
docker-compose exec directus env | grep AUTH_JWT
```

### Permission denied errors
1. Check role permissions in Directus admin UI
2. Verify `$CURRENT_USER` variable in permission filters
3. Check user has correct role assigned
4. View user details in Directus User Directory

---

## ✅ Verification Checklist

After completing all steps:

- [ ] Directus running on `http://192.168.1.3:8055`
- [ ] Firebase JWT environment variables added to docker-compose.yml
- [ ] Default role UUID configured
- [ ] `problems` collection has `user_owner` field
- [ ] `problems` collection has `status` field
- [ ] Permissions configured for authenticated users
- [ ] Can access Directus admin UI
- [ ] Firebase token authentication tested and working

---

## 🚀 Next: Run Flutter App

Once Directus is configured, return to your Windows machine and run:

```powershell
cd C:\Users\skdwi\OneDrive\Documents\Project\flutter\geofrontapp

# Run in local mode (Directus)
flutter run --dart-define=USE_DIRECTUS=true
```

The app will:
1. Sign in with Firebase
2. Get Firebase ID token
3. Send token to Directus at `http://192.168.1.3:8055`
4. Directus validates token and auto-creates user
5. App can now create/read/update/delete problems

---

## 📚 Additional Resources

- See `DIRECTUS_SCHEMA_SETUP.md` for detailed field configurations
- See `DIRECTUS_FIREBASE_AUTH.md` for authentication architecture
- See `HARDCODED_CONFIG_GUIDE.md` for Flutter environment setup
