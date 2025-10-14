# 🎯 Quick Start: Directus Setup in 5 Minutes

## Step 1: Open Directus Admin
**http://192.168.1.3:8055/admin** → Login

---

## Step 2: Add Two New Fields to `problems` Collection

### Settings ⚙️ → Data Model → problems → Create Field

#### Field 1: `user_owner`
```
Type:        String
Name:        user_owner
Interface:   Input
Width:       Half
Icon:        person
Required:    No
```

#### Field 2: `status`  
```
Type:        String
Name:        status
Interface:   Dropdown
Choices:     draft, published
Default:     draft
Width:       Half
Icon:        check_circle
Required:    Yes
```

---

## Step 3: Get Role UUID

Settings ⚙️ → Roles & Permissions → Click on "User" role

Copy UUID from URL:
```
http://192.168.1.3:8055/admin/settings/roles/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
                                                 ^^^^^^ COPY THIS UUID ^^^^^^
```

📝 UUID: `____________________________________`

---

## Step 4: Set Permissions

Settings ⚙️ → Roles & Permissions → Your role → Click `problems` collection

### ✅ CREATE
Filter: `user_owner` = `$CURRENT_USER`
Fields: All except (id, date_created, date_updated)

### ✅ READ
Filter: `user_owner` = `$CURRENT_USER` **OR** `status` = `published`
Fields: All

### ✅ UPDATE  
Filter: `user_owner` = `$CURRENT_USER`
Fields: All except (id, user_owner, date_created, date_updated)

### ✅ DELETE
Filter: `user_owner` = `$CURRENT_USER`

---

## Step 5: Configure Firebase Auth (SSH Required)

```bash
ssh akash@192.168.1.3
cd ~/directus
nano docker-compose.yml
```

Add to `environment:`:
```yaml
AUTH_PROVIDERS: 'jwt'
AUTH_JWT_SECRET: '__firebase__'
AUTH_JWT_ISSUER: 'https://securetoken.google.com/aksharaintelligence-41f4a'
AUTH_JWT_AUDIENCE: 'aksharaintelligence-41f4a'
AUTH_JWT_PUBLIC_KEY: 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'
AUTH_JWT_IDENTIFIER_KEY: 'user_id'
AUTH_JWT_EMAIL_KEY: 'email'
AUTH_JWT_ALLOW_PUBLIC_REGISTRATION: 'true'
AUTH_JWT_DEFAULT_ROLE_ID: 'YOUR_UUID_FROM_STEP_3'
GRAPHQL_ENABLED: 'true'
```

Restart:
```bash
docker-compose down && docker-compose up -d
```

---

## ✅ Done! Now Run Flutter App

```powershell
flutter run --dart-define=USE_DIRECTUS=true
```

---

## 📚 Full Guides Available

- `DIRECTUS_UI_CHECKLIST.md` - Step-by-step UI guide with screenshots
- `DIRECTUS_FIREBASE_AUTH.md` - Authentication architecture explained
- `DIRECTUS_REMOTE_SETUP.md` - Complete SSH setup commands

**Need help?** Check the troubleshooting sections in the full guides!
