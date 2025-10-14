# Directus Schema Setup for GeoFront App

## 🎯 Quick Start Checklist

- [x] Directus URL: `http://192.168.1.3:8055`
- [x] Firebase Project: `aksharaintelligence-41f4a`
- [ ] Configure Directus to accept Firebase tokens
- [ ] Create/verify `problems` collection schema
- [ ] Add `user_owner` field for multi-user support
- [ ] Set up permissions for authenticated users
- [ ] Test with Flutter app

---

## 🔐 Authentication Strategy

### Standard Firebase Token (No Custom Claims for Directus)

✅ **Your standard Firebase token works as-is:**
```json
{
  "user_id": "wPeibNo8zydCSPGvi8q5ECELQZI3",
  "email": "test@example.com",
  "email_verified": true
}
```

❌ **Hasura claims are ONLY for Hasura** (ignored by Directus):
```json
{
  "https://hasura.io/jwt/claims": { ... }  // ← Directus doesn't need this
}
```

See `DIRECTUS_FIREBASE_AUTH.md` for detailed Firebase + Directus integration options.

---

## 📋 Step 1: Verify/Update Problems Collection Schema

### Open Directus Admin Panel

```bash
# Start Directus if not running
cd directus
docker-compose up -d

# Open in browser
http://192.168.1.3:8055/admin
```

### Required Fields in `problems` Collection

| Field Name | Type | Interface | Required | Notes |
|------------|------|-----------|----------|-------|
| `id` | UUID | Primary Key | ✅ | Auto-generated |
| `title` | String | Input | ✅ | Problem title |
| `description` | Text | Textarea | ✅ | Problem description |
| `difficulty` | String | Dropdown | ✅ | Values: beginner, intermediate, advanced, expert |
| `category` | String | Input | ✅ | e.g., "Geometry", "Algebra" |
| `geometry_data` | JSON | Input (code) | ❌ | GeoDraw canvas state |
| `solution` | Text | Textarea | ❌ | Solution text |
| `scalar_constraints` | JSON | Input (code) | ❌ | Solver constraints |
| `object_constraints` | JSON | Input (code) | ❌ | Object constraints |
| `scalar_proof` | JSON | Input (code) | ❌ | Proof data |
| `object_proof` | JSON | Input (code) | ❌ | Proof data |
| `thumbnail` | File (M2O) | Image | ❌ | Relation to `directus_files` |
| `user_owner` | String | Input | ❌ | **NEW**: Firebase user ID |
| `status` | String | Dropdown | ✅ | **NEW**: draft, published |
| `date_created` | Timestamp | Datetime | Auto | Creation timestamp |
| `date_updated` | Timestamp | Datetime | Auto | Last update timestamp |

---

## 📋 Step 2: Add Missing Fields

### Add `user_owner` Field

1. Go to **Settings** → **Data Model** → **problems**
2. Click **Create Field**
3. Select **String** type
4. Configure:
   - **Field Name**: `user_owner`
   - **Interface**: Input (default)
   - **Options**:
     - Width: Half
     - Placeholder: `Firebase User ID`
     - Icon: `person`
   - **Validation**: Leave optional
5. Click **Save**

### Add `status` Field

1. Click **Create Field**
2. Select **String** type
3. Configure:
   - **Field Name**: `status`
   - **Interface**: Dropdown
   - **Options**:
     - Choices:
       - `draft` → Draft
       - `published` → Published
     - Default: `draft`
     - Width: Half
     - Icon: `check_circle`
   - **Validation**: Required
4. Click **Save**

---

## 📋 Step 3: Configure Permissions

### For Authenticated Users (Firebase Token Holders)

1. Go to **Settings** → **Roles & Permissions**
2. Find or create a role (e.g., "User" or "Authenticated")
3. Click on **problems** collection
4. Set permissions:

#### **Create** Permission
```json
{
  "_and": [
    {
      "user_owner": {
        "_eq": "$CURRENT_USER"
      }
    }
  ]
}
```

#### **Read** Permission
```json
{
  "_or": [
    {
      "user_owner": {
        "_eq": "$CURRENT_USER"
      }
    },
    {
      "status": {
        "_eq": "published"
      }
    }
  ]
}
```
**Explanation**: Users can read their own problems OR published problems.

#### **Update** Permission
```json
{
  "_and": [
    {
      "user_owner": {
        "_eq": "$CURRENT_USER"
      }
    }
  ]
}
```

#### **Delete** Permission
```json
{
  "_and": [
    {
      "user_owner": {
        "_eq": "$CURRENT_USER"
      }
    }
  ]
}
```

### Field Permissions

For each permission level, ensure these fields are accessible:

**Create**: Allow all fields except `id`, `date_created`, `date_updated`
**Read**: Allow all fields
**Update**: Allow all fields except `id`, `user_owner`, `date_created`, `date_updated`
**Delete**: N/A

---

## 📋 Step 4: Configure Firebase JWT Validation

Update your `directus/docker-compose.yml`:

```yaml
version: '3'
services:
  directus:
    image: directus/directus:latest
    ports:
      - 8055:8055
    environment:
      KEY: '255d861b-5ea1-5996-9aa3-922530ec40b1'
      SECRET: '6116487b-cda1-52c2-b5b5-c8022c45e263'
      
      DB_CLIENT: 'postgres'
      DB_HOST: 'database'
      DB_PORT: '5432'
      DB_DATABASE: 'directus'
      DB_USER: 'directus'
      DB_PASSWORD: 'directus'
      
      ADMIN_EMAIL: 'admin@example.com'
      ADMIN_PASSWORD: 'admin123'
      PUBLIC_URL: 'http://192.168.1.3:8055'
      
      # ===== Firebase JWT Authentication =====
      AUTH_PROVIDERS: 'jwt'
      AUTH_JWT_SECRET: '__firebase__'
      AUTH_JWT_ISSUER: 'https://securetoken.google.com/aksharaintelligence-41f4a'
      AUTH_JWT_AUDIENCE: 'aksharaintelligence-41f4a'
      AUTH_JWT_PUBLIC_KEY: 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'
      AUTH_JWT_IDENTIFIER_KEY: 'user_id'
      AUTH_JWT_EMAIL_KEY: 'email'
      AUTH_JWT_ALLOW_PUBLIC_REGISTRATION: 'true'
      AUTH_JWT_DEFAULT_ROLE_ID: 'YOUR_ROLE_UUID_HERE'  # Get from Directus UI
      
      # GraphQL support
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

**Get the Role UUID:**
1. Go to **Settings** → **Roles & Permissions**
2. Click on your default role (e.g., "User")
3. Copy the UUID from the URL: `http://192.168.1.3:8055/admin/settings/roles/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
4. Paste it into `AUTH_JWT_DEFAULT_ROLE_ID`

---

## 📋 Step 5: Restart Directus

```bash
cd directus
docker-compose down
docker-compose up -d

# Check logs
docker-compose logs -f directus
```

---

## 🧪 Step 6: Test the Setup

### Test 1: Firebase Login → Directus Auto-User-Creation

1. Run your Flutter app
2. Sign in with Firebase (email/password)
3. Check Directus Users:
   ```bash
   # Open Directus admin panel
   http://192.168.1.3:8055/admin
   
   # Navigate to: User Directory
   # You should see your Firebase user auto-created!
   ```

### Test 2: Create Problem with Firebase Token

```dart
// In your Flutter app
final firebaseToken = await FirebaseAuth.instance.currentUser?.getIdToken();

final response = await http.post(
  Uri.parse('http://192.168.1.3:8055/items/problems'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $firebaseToken',
  },
  body: json.encode({
    'title': 'Test Problem',
    'description': 'Test description',
    'difficulty': 'beginner',
    'category': 'Geometry',
    'user_owner': FirebaseAuth.instance.currentUser!.uid,
    'status': 'draft',
  }),
);
```

### Test 3: Query Problems

```bash
# Get Firebase token from Flutter app (print it)
curl -H "Authorization: Bearer <firebase-token>" \
  http://192.168.1.3:8055/items/problems
```

---

## 📋 Summary Checklist

Before running your Flutter app:

- [ ] ✅ Directus running on `http://192.168.1.3:8055`
- [ ] ✅ `problems` collection has all required fields
- [ ] ✅ `user_owner` field added (String type)
- [ ] ✅ `status` field added (String dropdown: draft/published)
- [ ] ✅ Firebase JWT validation configured in `docker-compose.yml`
- [ ] ✅ Default role UUID configured
- [ ] ✅ Permissions set for authenticated users
- [ ] ✅ Directus restarted with new configuration

---

## 🚀 Next Steps

1. **Run Flutter App in Local Mode:**
   ```bash
   flutter run --dart-define=USE_DIRECTUS=true
   ```

2. **Test GeoDraw-First Workflow:**
   - Sign in with Firebase
   - Draw geometry on canvas
   - Save with metadata
   - Verify problem created in Directus

3. **Check Directus Admin Panel:**
   - Verify problem appears with correct `user_owner`
   - Check thumbnail uploaded correctly
   - Verify `geometry_data` JSON saved

---

## 🐛 Troubleshooting

### "Invalid token" error
- Verify `AUTH_JWT_ISSUER` matches your Firebase project
- Check `AUTH_JWT_AUDIENCE` matches your Firebase project ID
- Ensure Firebase token not expired (refresh it)

### "Permission denied" error
- Check role permissions in Directus admin
- Verify `user_owner` field set correctly
- Ensure `$CURRENT_USER` variable works in permission rules

### User not auto-created
- Check `AUTH_JWT_ALLOW_PUBLIC_REGISTRATION: 'true'`
- Verify `AUTH_JWT_DEFAULT_ROLE_ID` is a valid UUID
- Check Directus logs: `docker-compose logs -f directus`

---

See also:
- `DIRECTUS_FIREBASE_AUTH.md` - Detailed Firebase authentication setup
- `HARDCODED_CONFIG_GUIDE.md` - Environment configuration guide

Directus can validate Firebase JWT tokens directly without custom claims.

1. **Open Directus Admin Panel**: `http://192.168.1.3:8055/admin`

2. **Install Firebase Auth Extension** (if available) or configure JWT manually

3. **Configure Environment Variables** in your Directus `docker-compose.yml`:

```yaml
services:
  directus:
    environment:
      # Existing variables...
      
      # Firebase JWT Configuration
      AUTH_PROVIDERS: "firebase"
      AUTH_FIREBASE_ENABLED: "true"
      AUTH_FIREBASE_PROJECT_ID: "aksharaintelligence-41f4a"
      AUTH_FIREBASE_ISSUER: "https://securetoken.google.com/aksharaintelligence-41f4a"
      AUTH_FIREBASE_AUDIENCE: "aksharaintelligence-41f4a"
      
      # Allow public registration from Firebase tokens
      AUTH_FIREBASE_ALLOW_PUBLIC_REGISTRATION: "true"
      AUTH_FIREBASE_DEFAULT_ROLE_ID: "<your-directus-role-uuid>"
      
      # JWT Secret (Directus will fetch Firebase public keys automatically)
      AUTH_FIREBASE_JWK_URL: "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"
```

### Option B: Simple Static Token for Local Dev (Quick Start)

If you want to test quickly without Firebase integration:

1. **Generate a static admin token** in Directus:
   - Go to User Directory → Your Admin User
   - Create a new "Static Token"
   - Copy the token

2. **Update `env_config.dart`**:
```dart
static const String? _directusToken = 'your-static-token-here';
```

**⚠️ Warning**: Static tokens bypass authentication. Only use for local development!

---

## 📋 Step 3: Directus Permissions Setup

### For Firebase-Authenticated Users

1. **Create a "User" Role** (if not exists):
   - Settings → Access Control → Roles
   - Create new role: "User"
   - Copy the Role UUID

2. **Set Permissions for "problems" Collection**:
   
   **CREATE Permission**:
   - Role: User
   - Fields: All except `id`, `date_created`, `date_updated`
   - Custom Access: `{ "user_owner": { "_eq": "$CURRENT_USER" } }`
   - Field Presets: `{ "user_owner": "$CURRENT_USER" }`
   
   **READ Permission**:
   - Role: User
   - Fields: All
   - Custom Access: `{ "user_owner": { "_eq": "$CURRENT_USER" } }`
   
   **UPDATE Permission**:
   - Role: User
   - Fields: All except `id`, `date_created`, `date_updated`, `user_owner`
   - Custom Access: `{ "user_owner": { "_eq": "$CURRENT_USER" } }`
   
   **DELETE Permission**:
   - Role: User
   - Custom Access: `{ "user_owner": { "_eq": "$CURRENT_USER" } }`

3. **File Upload Permissions** (directus_files):
   - CREATE: Allow all authenticated users
   - READ: Allow own files only
   - DELETE: Allow own files only

---

## 📋 Step 4: Database Schema Migration

### SQL to Add New Fields

If you need to add the `user_owner` field to existing collection:

```sql
-- Add user_owner field to problems table
ALTER TABLE problems 
ADD COLUMN user_owner UUID;

-- Create index for faster queries
CREATE INDEX idx_problems_user_owner ON problems(user_owner);

-- Add status field
ALTER TABLE problems 
ADD COLUMN status VARCHAR(50) DEFAULT 'draft';
```

Or use Directus Admin UI:
1. Settings → Data Model → problems collection
2. Click "+ Create Field"
3. Field Name: `user_owner`, Type: UUID, Interface: Input
4. Field Name: `status`, Type: String, Interface: Dropdown
   - Choices: `draft`, `published`
   - Default: `draft`

---

## 📋 Step 5: Test the Setup

### 1. Start Directus

```powershell
cd directus
docker-compose up -d
```

### 2. Verify Directus is Running

```powershell
curl http://192.168.1.3:8055/server/health
```

Expected response: `{"status":"ok"}`

### 3. Test Firebase Token Flow (After Firebase SDK Integration)

```dart
// In your app code
final firebaseToken = await FirebaseAuth.instance.currentUser?.getIdToken();

// Make Directus API call
final response = await http.get(
  Uri.parse('http://192.168.1.3:8055/items/problems'),
  headers: {
    'Authorization': 'Bearer $firebaseToken',
  },
);
```

---

## 🔍 Directus vs Hasura JWT Claims

### Firebase Token Structure

When Firebase generates a JWT token, it looks like this:

```json
{
  "iss": "https://securetoken.google.com/aksharaintelligence-41f4a",
  "aud": "aksharaintelligence-41f4a",
  "auth_time": 1697203200,
  "user_id": "abc123xyz",
  "sub": "abc123xyz",
  "iat": 1697203200,
  "exp": 1697206800,
  "email": "user@example.com",
  "email_verified": true,
  "firebase": {
    "identities": {
      "email": ["user@example.com"]
    },
    "sign_in_provider": "password"
  },
  
  // Hasura-specific custom claims (only needed for Hasura cloud mode)
  "https://hasura.io/jwt/claims": {
    "x-hasura-default-role": "user",
    "x-hasura-allowed-roles": ["user", "admin"],
    "x-hasura-user-id": "abc123xyz"
  }
}
```

### What Each Backend Uses:

**Directus (Local)**:
- ✅ Validates: `iss`, `aud`, `exp`, `iat` (standard JWT fields)
- ✅ Extracts: `user_id` or `sub` for user identification
- ❌ Ignores: `https://hasura.io/jwt/claims` (not needed)

**Hasura (Cloud)**:
- ✅ Validates: `iss`, `aud`, `exp`, `iat` (standard JWT fields)
- ✅ Requires: `https://hasura.io/jwt/claims` for authorization
- ✅ Extracts: `x-hasura-user-id`, `x-hasura-default-role`, etc.

### Adding Hasura Claims to Firebase (For Cloud Deployment)

You'll add these claims using Firebase Admin SDK (server-side):

```javascript
// Firebase Cloud Function or Admin SDK
const admin = require('firebase-admin');

// Set custom claims when user registers
admin.auth().setCustomUserClaims(uid, {
  'https://hasura.io/jwt/claims': {
    'x-hasura-default-role': 'user',
    'x-hasura-allowed-roles': ['user'],
    'x-hasura-user-id': uid,
  }
});
```

**For now**: You don't need custom claims for local Directus development. Just use standard Firebase authentication.

---

## 🚀 Quick Start Commands

### Start Directus
```powershell
cd C:\Users\skdwi\OneDrive\Documents\Project\flutter\geofrontapp\directus
docker-compose up -d
```

### Check Directus Logs
```powershell
docker-compose logs -f directus
```

### Access Directus Admin
Open browser: http://192.168.1.3:8055/admin

### Run Flutter App in Local Mode
```powershell
flutter run --dart-define=USE_DIRECTUS=true
```

---

## 📝 Next Steps

1. ✅ **Update `env_config.dart`** - Done!
2. ⏳ **Configure Directus with Firebase JWT** - Follow Option A above
3. ⏳ **Add `user_owner` field to problems collection** - Use SQL or Admin UI
4. ⏳ **Set up permissions** - Follow Step 3
5. ⏳ **Implement Firebase SDK** - In `FirebaseAuthProvider`
6. ⏳ **Test authentication flow** - Sign in → Get token → Call Directus

---

## 🔧 Troubleshooting

### "Invalid token" error from Directus
- Check that `AUTH_FIREBASE_PROJECT_ID` matches your Firebase project
- Verify Firebase token hasn't expired (1 hour lifetime)
- Check Directus logs: `docker-compose logs directus`

### "Permission denied" error
- Verify user role has correct permissions on `problems` collection
- Check that `user_owner` field is being set correctly

### Can't connect to Directus
- Verify Directus is running: `docker ps | grep directus`
- Check network: `ping 192.168.1.3`
- Verify port 8055 is not blocked by firewall

---

## 📚 Reference

- [Directus Authentication Docs](https://docs.directus.io/configuration/authentication)
- [Firebase JWT Structure](https://firebase.google.com/docs/auth/admin/verify-id-tokens)
- [Hasura JWT Configuration](https://hasura.io/docs/latest/auth/authentication/jwt/)

