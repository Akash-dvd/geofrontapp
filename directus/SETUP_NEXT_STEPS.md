# 🚀 Next Steps: Complete Directus Setup

## ✅ Docker Configuration Updated!

Your `directus/docker-compose.yml` now has Firebase JWT authentication configured.

---

## 📋 Step-by-Step Instructions

### Step 1: SSH to Remote Machine and Restart Directus

```bash
# From your Windows PowerShell
ssh akash@192.168.1.3

# Navigate to directus folder
cd ~/directus
# OR wherever your docker-compose.yml is located

# Restart Directus with new configuration
docker-compose down
docker-compose up -d

# Check logs to verify Firebase auth is enabled
docker-compose logs -f directus
```

**Look for in logs:**
- ✅ `JWT authentication enabled`
- ✅ `Firebase public key loaded`
- ✅ No errors related to JWT configuration

Press `Ctrl+C` to exit logs.

---

### Step 2: Get Role UUID from Directus Admin UI

**Open in browser:** http://192.168.1.3:8055/admin

1. Login with admin credentials:
   - Email: `admin@example.com`
   - Password: `geofrontapp_admin_2025`

2. Go to **Settings** (⚙️) → **Roles & Permissions**

3. Find or create your default user role:
   - If you don't have a "User" role, create one:
     - Click **"Create Role"**
     - Name: `User`
     - Description: `Default role for authenticated users`
     - Click **Save**

4. Click on the role name to open it

5. **Copy the UUID from the browser URL:**
   ```
   http://192.168.1.3:8055/admin/settings/roles/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
                                                   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
                                                   COPY THIS UUID
   ```

6. 📝 **Write it down:** `____________________________________`
d9682cff-6f6e-4f09-9e1d-47f9e90784eb
---

### Step 3: Update docker-compose.yml with Role UUID

```bash
# Still on remote machine (192.168.1.3)
cd ~/directus

# Edit docker-compose.yml
nano docker-compose.yml

# Find this line:
# AUTH_JWT_DEFAULT_ROLE_ID: "your-role-uuid-here"

# Uncomment and replace with your UUID:
AUTH_JWT_DEFAULT_ROLE_ID: "paste-your-uuid-here"

# Save and exit (Ctrl+O, Enter, Ctrl+X)

# Restart Directus again
docker-compose down
docker-compose up -d
```

---

### Step 4: Add Required Fields to Problems Collection

**In Directus Admin UI:** http://192.168.1.3:8055/admin

1. Go to **Settings** → **Data Model** → **problems**

2. **Add `user_owner` field:**
   - Click **"Create Field"**
   - Type: **String**
   - Field Name: `user_owner`
   - Interface: Input
   - Width: Half
   - Placeholder: `Firebase User ID`
   - Icon: `person`
   - Required: No
   - Click **Save**

3. **Add `status` field:**
   - Click **"Create Field"**
   - Type: **String**
   - Field Name: `status`
   - Interface: Dropdown
   - Choices:
     - `draft` → Draft
     - `published` → Published
   - Default: `draft`
   - Width: Half
   - Icon: `check_circle`
   - Required: Yes
   - Click **Save**

---

### Step 5: Configure Permissions

**Still in Directus Admin UI:**

1. Go to **Settings** → **Roles & Permissions**
2. Click on your **User** role
3. Find **problems** collection and click on it

#### Configure CREATE Permission:

**1. Field Permissions:**
- Select **Custom** 
- Check all fields EXCEPT: `id`, `date_created`, `date_updated`
- Click **Save**

**2. Field Validation:**
- Leave as **All fields**
- Click **Save**

**3. Field Presets:** ⭐ **IMPORTANT!**

In the Field Presets textbox, enter this JSON:

```json
{
    "user_owner": "$CURRENT_USER",
    "status": "draft"
}
```

Then click **Save**

> **Important:** The preset field expects a complete JSON object with all field-value pairs!
> 
> **Why presets?** They automatically fill `user_owner` with the Firebase user ID and set `status` to `draft`. Without this, users would get permission denied!

#### Configure READ Permission:

**1. Field Permissions:**
- Select **All**
- Click **Save**

#### Configure UPDATE Permission:

**1. Field Permissions:**
- Select **Custom**
- Check all fields EXCEPT: `id`, `user_owner`, `date_created`, `date_updated`
- Click **Save**

#### Configure DELETE Permission:

**1. Field Permissions:**
- Select **All** (doesn't matter for delete)
- Click **Save**

---

## ✅ Verification Checklist

Before running Flutter app:

- [ ] SSH'd to 192.168.1.3 and restarted Directus
- [ ] Checked logs for "JWT authentication enabled"
- [ ] Got role UUID from Directus admin UI
- [ ] Updated `AUTH_JWT_DEFAULT_ROLE_ID` in docker-compose.yml
- [ ] Restarted Directus after UUID update
- [ ] Added `user_owner` field to problems collection
- [ ] Added `status` field to problems collection
- [ ] Configured CREATE permission (user_owner = $CURRENT_USER)
- [ ] Configured READ permission (user_owner = $CURRENT_USER OR status = published)
- [ ] Configured UPDATE permission (user_owner = $CURRENT_USER)
- [ ] Configured DELETE permission (user_owner = $CURRENT_USER)

---

## 🧪 Test Setup

### Quick Test from Windows PowerShell:

```powershell
# Test 1: Check Directus health
curl http://192.168.1.3:8055/server/health

# Should return: {"status":"ok"}
```

### Test from Flutter App:

```powershell
cd C:\Users\skdwi\OneDrive\Documents\Project\flutter\geofrontapp

# Run app in local mode
flutter run --dart-define=USE_DIRECTUS=true -d chrome
```

**What should happen:**
1. ✅ App launches
2. ✅ You see sign-in screen with 3 options:
   - Email/Password
   - Google Sign-In
   - Continue as Guest (Anonymous)
3. ✅ Sign in with any method
4. ✅ Firebase generates token
5. ✅ Token sent to Directus at 192.168.1.3:8055
6. ✅ Directus validates token
7. ✅ User auto-created in Directus
8. ✅ You can create/view problems!

---

## 🐛 Troubleshooting

### Error: "Invalid token"
```bash
# Check Directus logs
ssh akash@192.168.1.3
cd ~/directus
docker-compose logs directus | grep -i jwt
```

**Fix:**
- Verify `AUTH_JWT_ISSUER` matches: `https://securetoken.google.com/aksharaintelligence-41f4a`
- Verify `AUTH_JWT_AUDIENCE` matches: `aksharaintelligence-41f4a`
- Ensure Firebase token not expired (try signing in again)

### Error: "Permission denied"
- Check role permissions in Directus admin UI
- Verify `user_owner` field is set correctly in the problem data
- Check `$CURRENT_USER` variable in permission filters

### User not auto-created
```bash
# Check if PUBLIC_REGISTRATION is enabled
docker exec -it geofrontapp_directus env | grep AUTH_JWT

# Should show:
# AUTH_JWT_ALLOW_PUBLIC_REGISTRATION=true
```

### Container not starting
```bash
# Check full logs
docker-compose logs directus

# If syntax error in docker-compose.yml:
docker-compose config  # Validates YAML syntax
```

---

## 🎉 Success!

Once everything is set up, all three Firebase authentication methods will work:
- ✅ Email/Password sign-in
- ✅ Google Sign-In
- ✅ Anonymous sign-in

**With just ONE Directus configuration!** 🚀

---

## 📚 Related Docs

- `DIRECTUS_UI_CHECKLIST.md` - Detailed UI setup guide
- `FIREBASE_AUTH_METHODS_EXPLAINED.md` - How all 3 auth methods work
- `DIRECTUS_QUICK_START.md` - 5-minute quick reference
