# Directus Firebase Authentication Setup

## Overview

✅ **Directus can validate standard Firebase tokens** without custom claims
✅ **Same token works for both Directus (local) and Hasura (cloud)**
✅ **No need to modify Firebase token structure for Directus**

---

## How It Works

### Standard Firebase Token Structure
```json
{
  "iss": "https://securetoken.google.com/aksharaintelligence-41f4a",
  "aud": "aksharaintelligence-41f4a",
  "auth_time": 1760349877,
  "user_id": "wPeibNo8zydCSPGvi8q5ECELQZI3",
  "sub": "wPeibNo8zydCSPGvi8q5ECELQZI3",
  "email": "test@example.com",
  "email_verified": true,
  "firebase": {
    "sign_in_provider": "password",
    "identities": {
      "email": ["test@example.com"]
    }
  },
  "exp": 1760353477,
  "iat": 1760349877
}
```

### For Hasura (Cloud Mode)
You'll add custom claims via Firebase Admin SDK:
```json
{
  "https://hasura.io/jwt/claims": {
    "x-hasura-default-role": "user",
    "x-hasura-allowed-roles": ["user"],
    "x-hasura-user-id": "wPeibNo8zydCSPGvi8q5ECELQZI3"
  }
}
```

### For Directus (Local Mode)
Uses the **standard fields** - no custom claims needed:
- `user_id` → User identifier
- `email` → Email address
- `email_verified` → Verification status

---

## Directus Configuration Options

### Option 1: JWT Validation (Recommended)

Configure Directus to validate Firebase tokens using Firebase's JWK endpoint.

#### 1. Set Environment Variables

Add to your `directus/docker-compose.yml` or `.env`:

```yaml
services:
  directus:
    environment:
      # Enable JWT authentication
      AUTH_PROVIDERS: jwt
      
      # Firebase JWT configuration
      AUTH_JWT_SECRET: __firebase__
      AUTH_JWT_ISSUER: https://securetoken.google.com/aksharaintelligence-41f4a
      AUTH_JWT_AUDIENCE: aksharaintelligence-41f4a
      AUTH_JWT_PUBLIC_KEY: https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
      
      # Map Firebase claims to Directus user fields
      AUTH_JWT_IDENTIFIER_KEY: user_id
      AUTH_JWT_EMAIL_KEY: email
      
      # Auto-create users on first login
      AUTH_JWT_ALLOW_PUBLIC_REGISTRATION: true
      AUTH_JWT_DEFAULT_ROLE_ID: <your-default-role-uuid>
```

#### 2. How Directus Uses the Token

When your Flutter app sends:
```http
Authorization: Bearer <firebase-token>
```

Directus will:
1. **Verify** the token signature using Firebase's public keys
2. **Extract** `user_id` and `email` from the token
3. **Find or create** a Directus user with that `external_identifier`
4. **Grant access** based on the user's Directus role

---

### Option 2: Custom Authentication Endpoint (More Control)

Create a Directus extension that validates Firebase tokens and creates sessions.

#### Create Extension: `extensions/endpoints/firebase-auth/index.js`

```javascript
export default {
  id: 'firebase-auth',
  handler: (router, { services, exceptions }) => {
    const { UsersService, AuthenticationService } = services;
    const { InvalidCredentialsException } = exceptions;

    router.post('/', async (req, res) => {
      const { firebaseToken } = req.body;

      if (!firebaseToken) {
        throw new InvalidCredentialsException('Firebase token required');
      }

      try {
        // Verify Firebase token
        const admin = require('firebase-admin');
        
        // Initialize Firebase Admin (once)
        if (!admin.apps.length) {
          admin.initializeApp({
            projectId: 'aksharaintelligence-41f4a',
          });
        }

        // Verify the token
        const decodedToken = await admin.auth().verifyIdToken(firebaseToken);
        const { uid, email, email_verified } = decodedToken;

        // Create or get Directus user
        const usersService = new UsersService({ schema: req.schema });
        
        let user = await usersService.readByQuery({
          filter: { external_identifier: { _eq: uid } },
          limit: 1,
        });

        if (user.length === 0) {
          // Create new user
          user = await usersService.createOne({
            email: email,
            external_identifier: uid,
            email_verified: email_verified,
            role: '<default-role-uuid>', // Your default role
            status: 'active',
          });
        } else {
          user = user[0];
        }

        // Create Directus session
        const authService = new AuthenticationService({ schema: req.schema });
        const { accessToken, refreshToken } = await authService.login(
          'default',
          { email: user.email },
          { session: true }
        );

        res.json({
          success: true,
          directus_token: accessToken,
          refresh_token: refreshToken,
          user: {
            id: user.id,
            email: user.email,
            role: user.role,
          },
        });
      } catch (error) {
        console.error('Firebase auth error:', error);
        throw new InvalidCredentialsException('Invalid Firebase token');
      }
    });
  },
};
```

#### Install Dependencies

```bash
cd directus
npm install firebase-admin
```

#### Use in Flutter App

```dart
// 1. Get Firebase token
final firebaseToken = await FirebaseAuth.instance.currentUser?.getIdToken();

// 2. Exchange for Directus token
final response = await http.post(
  Uri.parse('http://192.168.1.3:8055/firebase-auth'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({'firebaseToken': firebaseToken}),
);

final data = json.decode(response.body);
final directusToken = data['directus_token'];

// 3. Use Directus token for API calls
final problemsResponse = await http.get(
  Uri.parse('http://192.168.1.3:8055/items/problems'),
  headers: {'Authorization': 'Bearer $directusToken'},
);
```

---

### Option 3: Simple Token Passthrough (Development Only)

For quick local development without auth complexity:

```yaml
# directus/docker-compose.yml
services:
  directus:
    environment:
      # Allow public access (development only!)
      PUBLIC_URL: http://192.168.1.3:8055
      ADMIN_EMAIL: admin@example.com
      ADMIN_PASSWORD: admin123
      
      # Disable auth for local dev
      AUTH_DISABLE_DEFAULT: false
```

Then use a static admin token:
```dart
// DirectusDataProvider
Map<String, String> get _headers {
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer <your-directus-admin-token>',
  };
}
```

⚠️ **Only for development!** Never use in production.

---

## Recommended Approach for Your Setup

Based on your requirements:

### 🎯 **Use Option 1 (JWT Validation)** for the best experience:

1. **Directus validates Firebase tokens directly** using Firebase's public keys
2. **No token exchange needed** - single token for everything
3. **Auto-creates users** on first login
4. **Production-ready** and secure

### Configuration Steps:

1. **Update `directus/docker-compose.yml`:**

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
      
      # Firebase Authentication
      AUTH_PROVIDERS: 'jwt'
      AUTH_JWT_SECRET: '__firebase__'
      AUTH_JWT_ISSUER: 'https://securetoken.google.com/aksharaintelligence-41f4a'
      AUTH_JWT_AUDIENCE: 'aksharaintelligence-41f4a'
      AUTH_JWT_PUBLIC_KEY: 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'
      AUTH_JWT_IDENTIFIER_KEY: 'user_id'
      AUTH_JWT_EMAIL_KEY: 'email'
      AUTH_JWT_ALLOW_PUBLIC_REGISTRATION: 'true'
      AUTH_JWT_DEFAULT_ROLE_ID: 'REPLACE_WITH_YOUR_ROLE_UUID'
      
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

2. **Get the default role UUID:**

```bash
# Start Directus first
cd directus
docker-compose up -d

# Log in to Directus admin panel: http://192.168.1.3:8055
# Go to Settings → Roles → Copy the UUID of your default role
# Update AUTH_JWT_DEFAULT_ROLE_ID in docker-compose.yml
```

3. **Flutter App Code (No Changes Needed!):**

Your `DirectusDataProvider` already passes the Firebase token:

```dart
Map<String, String> get _headers {
  final token = _idToken.isNotEmpty ? _idToken : _staticToken;
  return {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}
```

That's it! Directus will validate the Firebase token automatically.

---

## Testing the Setup

### 1. Sign in with Firebase in your Flutter app:
```dart
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'test@example.com',
  password: 'password123',
);
```

### 2. Get the token:
```dart
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
print('Firebase Token: $token');
```

### 3. Test Directus API:
```bash
curl -H "Authorization: Bearer <firebase-token>" \
  http://192.168.1.3:8055/items/problems
```

### 4. Check Directus Users:
- Go to http://192.168.1.3:8055/admin
- Navigate to User Directory
- You should see your Firebase user auto-created!

---

## Summary

| Aspect | Directus (Local) | Hasura (Cloud) |
|--------|------------------|----------------|
| **Token Source** | Standard Firebase JWT | Firebase JWT + Custom Claims |
| **Validation** | Firebase JWK endpoint | Firebase JWK endpoint |
| **User ID Field** | `user_id` | `x-hasura-user-id` |
| **Custom Claims** | ❌ Not needed | ✅ Required |
| **Auto-create Users** | ✅ Yes | ✅ Via Hasura triggers |

**Bottom line:** Your standard Firebase token works perfectly with Directus. No modifications needed! 🎉
