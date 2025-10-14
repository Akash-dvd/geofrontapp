# Directus Web UI Setup Checklist

## 🌐 Access Directus Admin Panel

Open in browser: **http://192.168.1.3:8055/admin**

Login with your admin credentials.

---

## ✅ Step 1: Check/Update Problems Collection Schema

### Navigate to Data Model
1. Click **Settings** (⚙️ icon in sidebar)
2. Click **Data Model**
3. Click on **problems** collection

### Verify Existing Fields

Check if these fields exist:

| Field | Type | Required | Status |
|-------|------|----------|--------|
| `id` | UUID | ✅ | Should exist |
| `title` | String | ✅ | Should exist |
| `description` | Text | ✅ | Should exist |
| `difficulty` | String | ✅ | Should exist |
| `category` | String | ✅ | Should exist |
| `geometry_data` | JSON | ❌ | Should exist |
| `solution` | Text | ❌ | Should exist |
| `scalar_constraints` | JSON | ❌ | Should exist |
| `object_constraints` | JSON | ❌ | Should exist |
| `scalar_proof` | JSON | ❌ | Should exist |
| `object_proof` | JSON | ❌ | Should exist |
| `thumbnail` | File | ❌ | Should exist (M2O to directus_files) |
| `date_created` | Timestamp | Auto | Should exist |
| `date_updated` | Timestamp | Auto | Should exist |

---

## ✅ Step 2: Add New Fields (If Missing)

### Add `user_owner` Field

**Purpose:** Stores the Firebase user ID who created the problem

1. Click **"Create Field"** button (top right)
2. Select **String** type
3. **Field Name:** `user_owner`
4. Click **Continue**
5. **Interface:** Input (default)
6. **Display Options:**
   - Width: **Half**
   - Placeholder: `Firebase User ID`
   - Icon: `person`
7. **Validation:**
   - Required: **No** (leave unchecked)
   - Max Length: Leave empty
8. Click **Save**

### Add `status` Field

**Purpose:** Track if problem is draft or published

1. Click **"Create Field"** button
2. Select **String** type
3. **Field Name:** `status`
4. Click **Continue**
5. **Interface:** Dropdown
6. **Choices:**
   - Add choice: Key: `draft`, Text: `Draft`
   - Add choice: Key: `published`, Text: `Published`
7. **Display Options:**
   - Width: **Half**
   - Default: `draft`
   - Icon: `check_circle`
8. **Validation:**
   - Required: **Yes** (check the box)
9. Click **Save**

---

## ✅ Step 3: Get Default Role UUID

### Method 1: Via URL
1. Click **Settings** → **Roles & Permissions**
2. Click on your default user role (e.g., "User" or "Public")
3. Look at the browser URL bar:
   ```
   http://192.168.1.3:8055/admin/settings/roles/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
                                                 ^^^^^^^^^^^^^ This is your UUID ^^^^^^^^^^^^^
   ```
4. **Copy this UUID** - you'll need it for Docker configuration later

### Method 2: Via Database (if needed)
SSH to remote machine and run:
```bash
docker exec -it directus-database-1 psql -U directus -d directus
SELECT id, name FROM directus_roles;
\q
```

📝 **Write down your Role UUID:** `____________________________________`

---

## ✅ Step 4: Configure Permissions for Authenticated Users

### Navigate to Permissions
1. Click **Settings** → **Roles & Permissions**
2. Find your default user role (the one you got UUID from)
3. Click on **problems** collection row

### Configure CREATE Permission

1. Click **"Create"** tab
2. **Custom Access:**
   - **Item Permissions:** Enable
   - **Filter:** Click "Custom"
   - Add filter rule:
     ```
     user_owner
     Equal To
     $CURRENT_USER
     ```
     *(This means: can only create if they're the owner)*

3. **Field Permissions:**
   - Click **"All"** to allow all fields
   - Then **uncheck** these system fields:
     - `id`
     - `date_created`
     - `date_updated`
   
4. Click **"Save"** (checkmark icon)

### Configure READ Permission

1. Click **"Read"** tab
2. **Custom Access:**
   - **Item Permissions:** Enable
   - **Filter:** Click "Custom"
   - Add filter group with **"OR"** logic:
     ```
     OR:
       - user_owner Equal To $CURRENT_USER
       - status Equal To "published"
     ```
     *(This means: can read own problems OR published problems)*

3. **Field Permissions:**
   - Select **"All"** (users can see all fields)

4. Click **"Save"**

### Configure UPDATE Permission

1. Click **"Update"** tab
2. **Custom Access:**
   - **Item Permissions:** Enable
   - **Filter:** Click "Custom"
   - Add filter rule:
     ```
     user_owner
     Equal To
     $CURRENT_USER
     ```

3. **Field Permissions:**
   - Click **"All"**
   - Then **uncheck** these protected fields:
     - `id`
     - `user_owner` (prevent ownership transfer)
     - `date_created`
     - `date_updated`

4. Click **"Save"**

### Configure DELETE Permission

1. Click **"Delete"** tab
2. **Custom Access:**
   - **Item Permissions:** Enable
   - **Filter:** Click "Custom"
   - Add filter rule:
     ```
     user_owner
     Equal To
     $CURRENT_USER
     ```

3. Click **"Save"**

---

## ✅ Step 5: Update Docker Configuration (Optional but Recommended)

If you want Directus to automatically create users from Firebase tokens, you need to update the Docker configuration on the remote machine.

### SSH to Remote Machine
```bash
ssh akash@192.168.1.3
cd ~/directus  # or wherever docker-compose.yml is located
```

### Edit docker-compose.yml
```bash
nano docker-compose.yml
```

### Add Firebase JWT Configuration

Find the `environment:` section under `directus:` service and add:

```yaml
environment:
  # ... existing environment variables ...
  
  # ===== ADD THESE FOR FIREBASE AUTH =====
  AUTH_PROVIDERS: 'jwt'
  AUTH_JWT_SECRET: '__firebase__'
  AUTH_JWT_ISSUER: 'https://securetoken.google.com/aksharaintelligence-41f4a'
  AUTH_JWT_AUDIENCE: 'aksharaintelligence-41f4a'
  AUTH_JWT_PUBLIC_KEY: 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'
  AUTH_JWT_IDENTIFIER_KEY: 'user_id'
  AUTH_JWT_EMAIL_KEY: 'email'
  AUTH_JWT_ALLOW_PUBLIC_REGISTRATION: 'true'
  AUTH_JWT_DEFAULT_ROLE_ID: 'PASTE_YOUR_ROLE_UUID_HERE'  # From Step 3
  
  GRAPHQL_ENABLED: 'true'
```

### Restart Directus
```bash
docker-compose down
docker-compose up -d

# Check logs
docker-compose logs -f directus
# Look for: "JWT authentication enabled"
# Press Ctrl+C to exit
```

---

## ✅ Step 6: Test the Setup

### Test 1: Manual Test in Directus UI

1. Go to **Content** → **problems**
2. Click **"Create Item"**
3. Fill in test data:
   - Title: `Test Problem`
   - Description: `Test description`
   - Difficulty: `beginner`
   - Category: `Geometry`
   - Status: `draft`
   - user_owner: `test-user-id`
4. Click **"Save"**
5. ✅ If saved successfully, schema is correct!

### Test 2: From Flutter App (After Step 5)

Run your Flutter app and it should:
1. ✅ Sign in with Firebase
2. ✅ Get Firebase token
3. ✅ Send token to Directus
4. ✅ Directus validates and creates user automatically
5. ✅ App can create/read/update problems

---

## 📋 Quick Verification Checklist

Before running Flutter app, verify in Directus UI:

- [ ] Logged into Directus admin: `http://192.168.1.3:8055/admin`
- [ ] `problems` collection exists
- [ ] `user_owner` field added (String type)
- [ ] `status` field added (String dropdown: draft/published)
- [ ] Default role UUID copied (from Step 3)
- [ ] CREATE permission configured (user_owner = $CURRENT_USER)
- [ ] READ permission configured (user_owner = $CURRENT_USER OR status = published)
- [ ] UPDATE permission configured (user_owner = $CURRENT_USER)
- [ ] DELETE permission configured (user_owner = $CURRENT_USER)
- [ ] (Optional) Docker configuration updated with Firebase JWT settings
- [ ] (Optional) Directus restarted after Docker config changes

---

## 🎯 What Each Configuration Does

### `user_owner` Field
- Stores Firebase user ID: `wPeibNo8zydCSPGvi8q5ECELQZI3`
- Used to track who created each problem
- Used in permission filters to restrict access

### `status` Field
- Values: `draft` or `published`
- Drafts: only visible to owner
- Published: visible to everyone
- Controlled by user via metadata form

### Permissions
- **$CURRENT_USER**: Special variable = logged-in user's Firebase ID
- CREATE: Can only create with your user_owner
- READ: Can see your own OR published problems
- UPDATE: Can only edit your own problems
- DELETE: Can only delete your own problems

---

## 🐛 Troubleshooting

### "Cannot find field user_owner" error in Flutter
- ✅ Verify field exists in Directus Data Model
- ✅ Check field name is exactly `user_owner` (lowercase, underscore)
- ✅ Restart Flutter app after adding field

### "Permission denied" when creating problem
- ✅ Check CREATE permission filter is set correctly
- ✅ Verify `user_owner` field is being set in the request
- ✅ Check user has correct role assigned

### Firebase token rejected
- ⚠️ You need to complete Step 5 (Docker configuration)
- ✅ Check `AUTH_JWT_ISSUER` matches Firebase project
- ✅ Check `AUTH_JWT_AUDIENCE` matches Firebase project ID
- ✅ Restart Directus after config changes

### User not auto-created
- ⚠️ Need Step 5 + restart Directus
- ✅ Check `AUTH_JWT_ALLOW_PUBLIC_REGISTRATION: 'true'`
- ✅ Check `AUTH_JWT_DEFAULT_ROLE_ID` is valid UUID
- ✅ Check Directus logs: `docker-compose logs directus`

---

## 🚀 Next Steps

### If you completed Steps 1-4 (UI only):
You can **run the Flutter app now**, but you'll need to:
- Use a static admin token OR
- Implement token exchange endpoint

### If you completed Steps 1-5 (UI + Docker):
You can **run the Flutter app** with full Firebase authentication:

```powershell
cd C:\Users\skdwi\OneDrive\Documents\Project\flutter\geofrontapp
flutter run --dart-define=USE_DIRECTUS=true
```

The app will authenticate with Firebase tokens directly! 🎉

---

## 📚 Related Documentation

- `DIRECTUS_FIREBASE_AUTH.md` - Detailed Firebase authentication options
- `DIRECTUS_REMOTE_SETUP.md` - Complete SSH setup guide
- `DIRECTUS_SCHEMA_SETUP.md` - Detailed schema documentation
- `HARDCODED_CONFIG_GUIDE.md` - Flutter environment configuration
