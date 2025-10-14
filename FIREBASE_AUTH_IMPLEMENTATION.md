# Firebase Authentication Implementation Guide

## Overview

The `FirebaseAuthProvider` now supports **three authentication methods**:
1. 🔐 **Email/Password** - Traditional account creation and sign-in
2. 🔵 **Google Sign-In** - OAuth with Google accounts
3. 👤 **Anonymous** - Guest access without credentials

All three methods are available in **both local (Directus) and cloud (Hasura)** modes.

## Authentication Methods Comparison

| Feature | Email/Password | Google Sign-In | Anonymous |
|---------|---------------|----------------|-----------|
| **User Account** | Permanent | Permanent | Temporary (can upgrade) |
| **Credentials** | Email + Password | Google OAuth | None |
| **Email Verified** | Optional | Yes (from Google) | No |
| **Display Name** | Optional | Yes (from Google) | No |
| **Profile Photo** | No | Yes (from Google) | No |
| **Password Reset** | Yes | N/A | N/A |
| **Account Linking** | N/A | From Anonymous | From Anonymous |
| **Use Case** | Standard registration | Quick sign-in | Guest/trial access |

## Dependencies Required

Add these to `packages/geoapp/pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.3
  google_sign_in: ^6.2.2
```

Then run:
```powershell
cd packages/geoapp
flutter pub get
```

## Interface Methods

### Core User Information

```dart
// Get Firebase ID token (JWT) for API authentication
Future<String?> getIdToken({bool forceRefresh = false});

// User identifiers
String? get currentUserId;           // Firebase UID
String? get currentUserEmail;        // Email (null for anonymous)
String? get currentUserDisplayName;  // Name (from Google or profile)

// Status checks
bool get isAuthenticated;  // Any user signed in
bool get isAnonymous;      // Signed in anonymously
```

### Email/Password Methods

```dart
// Sign in existing user
await AppServices.auth.signInWithEmailAndPassword(
  'user@example.com',
  'password123',
);

// Create new account
await AppServices.auth.createUserWithEmailAndPassword(
  'newuser@example.com',
  'password123',
);

// Password recovery
await AppServices.auth.sendPasswordResetEmail('user@example.com');

// Update credentials
await AppServices.auth.updateEmail('newemail@example.com');
await AppServices.auth.updatePassword('newPassword456');
```

### Google Sign-In Methods

```dart
// Sign in with Google (opens OAuth flow)
await AppServices.auth.signInWithGoogle();
// Opens Google account picker
// Returns when user completes sign-in or cancels
```

### Anonymous Methods

```dart
// Sign in anonymously (guest access)
await AppServices.auth.signInAnonymously();

// Later, upgrade anonymous account to permanent
// Option 1: Link to email/password
await AppServices.auth.linkAnonymousToEmailPassword(
  'user@example.com',
  'password123',
);

// Option 2: Link to Google
await AppServices.auth.linkAnonymousToGoogle();
```

### Sign Out

```dart
// Sign out (works for all auth methods)
await AppServices.auth.signOut();
```

### State Management

```dart
// Listen to auth state changes
AppServices.auth.authStateChanges.listen((userId) {
  if (userId != null) {
    print('User signed in: $userId');
  } else {
    print('User signed out');
  }
});

// Get detailed user metadata
final metadata = await AppServices.auth.getUserMetadata();
print('Created: ${metadata['creationTime']}');
print('Last sign-in: ${metadata['lastSignInTime']}');
print('Providers: ${metadata['providers']}'); // e.g., ['password', 'google.com']
```

## Implementation Steps

### Step 1: Add Firebase Dependencies

**File: `packages/geoapp/pubspec.yaml`**
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.8.1       # ← Add
  firebase_auth: ^5.3.3       # ← Add
  google_sign_in: ^6.2.2      # ← Add
  # ... other dependencies
```

### Step 2: Configure Firebase Project

#### A. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Enable:
   - ✅ Email/Password
   - ✅ Google
   - ✅ Anonymous

#### B. Google Sign-In Configuration

**Android** (`android/app/build.gradle`):
```gradle
// No additional config needed if using firebase_auth
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

**Web** (`web/index.html`):
Add Google Sign-In meta tag:
```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

### Step 3: Implement Firebase Auth Provider

**File: `packages/geoapp/lib/services/auth/firebase_auth_provider.dart`**

Uncomment all the TODO sections and add imports:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_provider.dart';

class FirebaseAuthProvider implements AuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Uncomment all method implementations...
}
```

### Step 4: Initialize Firebase in Main App

**File: `lib/main.dart`**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:geoapp/geoapp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment
  await dotenv.load(fileName: ".env");
  EnvConfig.validate();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: EnvConfig.firebaseApiKey,
      authDomain: EnvConfig.firebaseAuthDomain,
      projectId: EnvConfig.firebaseProjectId,
      storageBucket: EnvConfig.firebaseStorageBucket,
      messagingSenderId: EnvConfig.firebaseMessagingSenderId,
      appId: EnvConfig.firebaseAppId,
    ),
  );

  // Initialize app services (creates auth provider)
  await AppServices.initialize();

  runApp(const GeoFrontApp());
}
```

## Usage Examples

### Example 1: Sign-In Screen with Multiple Options

```dart
class SignInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Email/Password Form
        ElevatedButton(
          onPressed: () async {
            await AppServices.auth.signInWithEmailAndPassword(
              emailController.text,
              passwordController.text,
            );
          },
          child: Text('Sign In with Email'),
        ),

        // Google Sign-In Button
        ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text('Sign In with Google'),
          onPressed: () async {
            await AppServices.auth.signInWithGoogle();
          },
        ),

        // Anonymous/Guest Access
        TextButton(
          onPressed: () async {
            await AppServices.auth.signInAnonymously();
          },
          child: Text('Continue as Guest'),
        ),
      ],
    );
  }
}
```

### Example 2: Guest to Permanent Account Conversion

```dart
class UpgradeAccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (AppServices.auth.isAnonymous) ...[
          Text('You\'re currently signed in as a guest'),
          
          // Option 1: Link to email/password
          ElevatedButton(
            onPressed: () async {
              await AppServices.auth.linkAnonymousToEmailPassword(
                emailController.text,
                passwordController.text,
              );
              // Guest account is now permanent with email/password
            },
            child: Text('Create Account with Email'),
          ),

          // Option 2: Link to Google
          ElevatedButton(
            onPressed: () async {
              await AppServices.auth.linkAnonymousToGoogle();
              // Guest account is now permanent with Google
            },
            child: Text('Link Google Account'),
          ),
        ],
      ],
    );
  }
}
```

### Example 3: Auth State Listener in BLoC

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  late final StreamSubscription<String?> _authSubscription;

  AuthBloc() : super(AuthInitial()) {
    // Listen to auth state changes
    _authSubscription = AppServices.auth.authStateChanges.listen((userId) {
      if (userId != null) {
        add(UserSignedIn(userId));
      } else {
        add(UserSignedOut());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
```

### Example 4: Protected Route with Auth Check

```dart
class ProtectedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!AppServices.auth.isAuthenticated) {
      return SignInScreen();
    }

    if (AppServices.auth.isAnonymous) {
      return Column(
        children: [
          Text('Limited features for guests'),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UpgradeAccountScreen()),
            ),
            child: Text('Upgrade Account'),
          ),
        ],
      );
    }

    // Full access for authenticated users
    return FullFeaturedScreen();
  }
}
```

## Error Handling

All auth methods throw exceptions on failure. Always wrap in try-catch:

```dart
try {
  await AppServices.auth.signInWithEmailAndPassword(email, password);
  // Success
} on FirebaseAuthException catch (e) {
  // Handle specific Firebase errors
  switch (e.code) {
    case 'user-not-found':
      showError('No user found with this email');
      break;
    case 'wrong-password':
      showError('Incorrect password');
      break;
    case 'email-already-in-use':
      showError('Email is already registered');
      break;
    default:
      showError('Authentication failed: ${e.message}');
  }
} catch (e) {
  // Handle other errors
  showError('Unexpected error: $e');
}
```

## Firebase Token Flow (Both Backends)

```
┌──────────────────────────────────────────────┐
│  User Signs In (Email/Google/Anonymous)     │
└─────────────────┬────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  Firebase Authentication                     │
│  - Validates credentials                     │
│  - Creates user session                      │
│  - Issues JWT (ID token)                     │
└─────────────────┬────────────────────────────┘
                  │
                  │ Firebase ID Token (JWT)
                  │ {
                  │   "uid": "abc123",
                  │   "email": "user@example.com",
                  │   "email_verified": true,
                  │   "firebase": {
                  │     "sign_in_provider": "google.com"
                  │   }
                  │ }
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
  ┌──────────┐        ┌──────────┐
  │ Directus │        │  Hasura  │
  │ GraphQL  │        │ GraphQL  │
  │          │        │          │
  │ Header:  │        │ Header:  │
  │ Bearer   │        │ Bearer   │
  │ <token>  │        │ <token>  │
  └──────────┘        └──────────┘
```

## Testing Checklist

- [ ] Email/Password sign-in works
- [ ] Email/Password account creation works
- [ ] Password reset email received
- [ ] Google Sign-In opens OAuth flow
- [ ] Google Sign-In completes successfully
- [ ] Anonymous sign-in works
- [ ] Anonymous to email/password linking works
- [ ] Anonymous to Google linking works
- [ ] Sign-out clears session
- [ ] Auth state changes stream works
- [ ] ID token retrieval works
- [ ] GraphQL requests include Bearer token
- [ ] Both local (Directus) and cloud (Hasura) modes work

## Security Best Practices

1. **Never store passwords** - Firebase handles this
2. **Use forceRefresh** when token might be expired:
   ```dart
   final token = await AppServices.auth.getIdToken(forceRefresh: true);
   ```
3. **Handle anonymous linking carefully** - Once linked, cannot unlink
4. **Validate email on sign-up** - Send verification email
5. **Use strong password rules** - Firebase enforces minimum 6 characters
6. **Rate limit sign-in attempts** - Firebase has built-in protection
7. **Monitor auth logs** - Check Firebase Console for suspicious activity

## Next Steps

1. ✅ Interface defined with all three methods
2. ✅ Firebase implementation stubbed with TODOs
3. ⏭️ Add Firebase dependencies to pubspec.yaml
4. ⏭️ Configure Firebase Console (enable auth methods)
5. ⏭️ Uncomment implementation in `firebase_auth_provider.dart`
6. ⏭️ Initialize Firebase in `main.dart`
7. ⏭️ Create sign-in UI screens
8. ⏭️ Test all authentication flows

---

**All three authentication methods ready to implement!** 🚀
