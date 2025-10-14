# Firebase Authentication Methods with Directus

## 🎯 The Key Concept

**Firebase handles ALL authentication methods. Directus only validates the resulting JWT token.**

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Flutter App                         │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Email/Pass   │  │ Google Login │  │  Anonymous   │    │
│  │   Sign-In    │  │   Sign-In    │  │   Sign-In    │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                  │                  │             │
│         └──────────────────┴──────────────────┘             │
│                            ↓                                │
│              ┌─────────────────────────┐                   │
│              │  Firebase SDK            │                   │
│              │  Handles Authentication  │                   │
│              └────────────┬─────────────┘                   │
│                           ↓                                 │
│              ┌─────────────────────────┐                   │
│              │  Firebase ID Token       │                   │
│              │  (JWT - Same format     │                   │
│              │   for all 3 methods!)   │                   │
│              └────────────┬─────────────┘                   │
└─────────────────────────┼─────────────────────────────────┘
                          ↓
            ┌─────────────────────────┐
            │   Send to Directus:     │
            │   Authorization: Bearer │
            │   <firebase-token>      │
            └────────────┬─────────────┘
                         ↓
         ┌───────────────────────────────────┐
         │       Directus Backend            │
         │  (Validates token signature       │
         │   using Firebase's public keys)   │
         │                                   │
         │  ✅ Doesn't care HOW user         │
         │     authenticated!                │
         │  ✅ Only verifies token is valid  │
         │  ✅ Extracts user_id and email    │
         └───────────────────────────────────┘
```

---

## ✅ The Answer: YES, All Three Work with Same Config!

Your `docker-compose.yml` only needs this:

```yaml
environment:
  # Firebase JWT Validation
  AUTH_PROVIDERS: 'jwt'
  AUTH_JWT_SECRET: '__firebase__'
  AUTH_JWT_ISSUER: 'https://securetoken.google.com/aksharaintelligence-41f4a'
  AUTH_JWT_AUDIENCE: 'aksharaintelligence-41f4a'
  AUTH_JWT_PUBLIC_KEY: 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'
  AUTH_JWT_IDENTIFIER_KEY: 'user_id'
  AUTH_JWT_EMAIL_KEY: 'email'
  AUTH_JWT_ALLOW_PUBLIC_REGISTRATION: 'true'
  AUTH_JWT_DEFAULT_ROLE_ID: 'your-role-uuid'
```

**This ONE configuration works for ALL three authentication methods!**

---

## 🔍 How Each Method Works

### Method 1: Email/Password

**Flutter App:**
```dart
// User signs in with email/password
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123',
);

// Get Firebase token
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
```

**Firebase Token Generated:**
```json
{
  "iss": "https://securetoken.google.com/aksharaintelligence-41f4a",
  "aud": "aksharaintelligence-41f4a",
  "user_id": "abc123xyz",
  "email": "user@example.com",
  "email_verified": true,
  "firebase": {
    "sign_in_provider": "password",  // ← Shows email/password used
    "identities": {
      "email": ["user@example.com"]
    }
  }
}
```

**Directus receives this token and:**
- ✅ Validates signature using Firebase public keys
- ✅ Extracts `user_id` = "abc123xyz"
- ✅ Extracts `email` = "user@example.com"
- ✅ Creates/finds Directus user with `external_identifier` = "abc123xyz"
- ✅ Grants access!

---

### Method 2: Google Sign-In

**Flutter App:**
```dart
// User signs in with Google
await FirebaseAuth.instance.signInWithGoogle();

// Get Firebase token (SAME method as email/password!)
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
```

**Firebase Token Generated:**
```json
{
  "iss": "https://securetoken.google.com/aksharaintelligence-41f4a",
  "aud": "aksharaintelligence-41f4a",
  "user_id": "xyz789abc",
  "email": "user@gmail.com",
  "email_verified": true,
  "firebase": {
    "sign_in_provider": "google.com",  // ← Shows Google used
    "identities": {
      "google.com": ["1234567890"],
      "email": ["user@gmail.com"]
    }
  },
  "name": "User Name",
  "picture": "https://..."
}
```

**Directus receives this token and:**
- ✅ Validates signature (same Firebase public keys)
- ✅ Extracts `user_id` = "xyz789abc"
- ✅ Extracts `email` = "user@gmail.com"
- ✅ Creates/finds Directus user with `external_identifier` = "xyz789abc"
- ✅ Grants access!

**Directus doesn't care it was Google!** It just validates the Firebase token.

---

### Method 3: Anonymous Sign-In

**Flutter App:**
```dart
// User signs in anonymously
await FirebaseAuth.instance.signInAnonymously();

// Get Firebase token (SAME method again!)
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
```

**Firebase Token Generated:**
```json
{
  "iss": "https://securetoken.google.com/aksharaintelligence-41f4a",
  "aud": "aksharaintelligence-41f4a",
  "user_id": "anon123xyz",
  "firebase": {
    "sign_in_provider": "anonymous",  // ← Shows anonymous used
    "identities": {}  // ← No email!
  }
}
```

**Directus receives this token and:**
- ✅ Validates signature (same Firebase public keys)
- ✅ Extracts `user_id` = "anon123xyz"
- ⚠️ No email (anonymous user)
- ✅ Creates/finds Directus user with `external_identifier` = "anon123xyz"
- ✅ Grants access!

**Special note for anonymous users:** You may want to handle them differently in Directus permissions.

---

## 🎯 The Magic: Firebase Token is Always the Same Format

**All three methods produce a Firebase JWT token with:**
- ✅ Same signature algorithm (RS256)
- ✅ Same issuer (`https://securetoken.google.com/...`)
- ✅ Same audience (your project ID)
- ✅ Same validation endpoint (Firebase JWK URL)
- ✅ Same `user_id` field
- ✅ (Usually) same `email` field (except anonymous)

**Directus configuration doesn't need to know HOW the user authenticated.** It only needs to:
1. Validate the token signature
2. Extract `user_id` and `email`
3. Find/create the user
4. Grant access based on role

---

## 🔧 What You Need to Do

### 1. Enable All Methods in Firebase Console

You already did this! Check in Firebase Console → Authentication → Sign-in method:
- ✅ Email/Password: Enabled
- ✅ Google: Enabled
- ✅ Anonymous: Enabled

### 2. Configure Directus Once (All Methods Work)

```yaml
# directus/docker-compose.yml
services:
  directus:
    environment:
      # ... other settings ...
      
      # This ONE configuration handles ALL three auth methods!
      AUTH_PROVIDERS: 'jwt'
      AUTH_JWT_SECRET: '__firebase__'
      AUTH_JWT_ISSUER: 'https://securetoken.google.com/aksharaintelligence-41f4a'
      AUTH_JWT_AUDIENCE: 'aksharaintelligence-41f4a'
      AUTH_JWT_PUBLIC_KEY: 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'
      AUTH_JWT_IDENTIFIER_KEY: 'user_id'
      AUTH_JWT_EMAIL_KEY: 'email'
      AUTH_JWT_ALLOW_PUBLIC_REGISTRATION: 'true'
      AUTH_JWT_DEFAULT_ROLE_ID: 'your-role-uuid'
```

### 3. Flutter App Code (Same for All Methods)

```dart
// Your DirectusDataProvider doesn't change!
Map<String, String> get _headers {
  final token = _idToken.isNotEmpty ? _idToken : _staticToken;
  return {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}

// Works for:
// - Email/password users
// - Google sign-in users  
// - Anonymous users
// ALL automatically!
```

---

## 🧪 Test All Three Methods

### Test 1: Email/Password
```dart
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'test@example.com',
  password: 'password123',
);

final token = await FirebaseAuth.instance.currentUser?.getIdToken();
print('Token: $token');

// Test Directus API
final response = await http.get(
  Uri.parse('http://192.168.1.3:8055/items/problems'),
  headers: {'Authorization': 'Bearer $token'},
);
print(response.statusCode); // Should be 200!
```

### Test 2: Google Sign-In
```dart
// Assuming you have google_sign_in package configured
await FirebaseAuth.instance.signInWithGoogle();

final token = await FirebaseAuth.instance.currentUser?.getIdToken();
print('Token: $token');

// Same Directus API call - works!
final response = await http.get(
  Uri.parse('http://192.168.1.3:8055/items/problems'),
  headers: {'Authorization': 'Bearer $token'},
);
print(response.statusCode); // Should be 200!
```

### Test 3: Anonymous Sign-In
```dart
await FirebaseAuth.instance.signInAnonymously();

final token = await FirebaseAuth.instance.currentUser?.getIdToken();
print('Token: $token');

// Same Directus API call - works!
final response = await http.get(
  Uri.parse('http://192.168.1.3:8055/items/problems'),
  headers: {'Authorization': 'Bearer $token'},
);
print(response.statusCode); // Should be 200!
```

**All three should work with the SAME Directus configuration!**

---

## 🎨 Optional: Handle Anonymous Users Differently

If you want to give anonymous users limited permissions:

### Option 1: Create Separate Role for Anonymous Users

1. In Directus: Create "Anonymous" role with limited permissions
2. In Flutter: Detect anonymous users and set a custom claim
3. Configure Directus to use different role for anonymous

### Option 2: Use Permissions to Restrict Anonymous

In Directus permissions, add filter:
```json
{
  "_and": [
    { "user_owner": { "_eq": "$CURRENT_USER" } },
    { "email": { "_nnull": true } }  // ← Only users with email
  ]
}
```

This prevents anonymous users (who have no email) from accessing certain data.

---

## 📋 Summary Table

| Auth Method | Firebase Handles | Token Format | Directus Config | Works? |
|-------------|------------------|--------------|-----------------|--------|
| **Email/Password** | ✅ Yes | Standard JWT | Same config | ✅ Yes |
| **Google Sign-In** | ✅ Yes | Standard JWT | Same config | ✅ Yes |
| **Anonymous** | ✅ Yes | Standard JWT | Same config | ✅ Yes |

**One `docker-compose.yml` configuration = All three methods work!** 🎉

---

## 🚀 For Cloud Mode (Hasura)

**Same story!** All three Firebase auth methods work with Hasura too.

The only difference: You need to add Hasura-specific custom claims for role-based access control.

```json
{
  "https://hasura.io/jwt/claims": {
    "x-hasura-default-role": "user",
    "x-hasura-allowed-roles": ["user"],
    "x-hasura-user-id": "user_id_here"
  }
}
```

But Hasura still validates the Firebase token the same way!

---

## ✅ Bottom Line

**YES! With just the `docker-compose.yml` settings, all three authentication methods work:**

1. ✅ Email/Password
2. ✅ Google Sign-In  
3. ✅ Anonymous

**Because:**
- Firebase handles authentication
- All methods produce the same token format
- Directus only validates the token signature
- Directus doesn't care HOW the user authenticated

**You only configure Directus ONCE and all methods work!** 🎯
