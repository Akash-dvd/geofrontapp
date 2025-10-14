# Hybrid Backend Implementation Checklist

## ✅ Phase 1: Infrastructure (COMPLETE)

- [x] Create `.env.local` template (Directus + Firebase)
- [x] Create `.env.cloud` template (Hasura + Supabase + Firebase)
- [x] Add environment files to `.gitignore`
- [x] Create `scripts/switch_env.sh` (executable bash script)
- [x] Add `flutter_dotenv` to `pubspec.yaml`
- [x] Add `.env` to Flutter assets
- [x] Create `lib/config/build_flags.dart` (USE_DIRECTUS flag)
- [x] Create `lib/config/env_config.dart` (runtime config)
- [x] Create `.vscode/tasks.json` (Local/Cloud dev tasks)
- [x] Update `lib/main.dart` (dotenv loading, env validation)

## ✅ Phase 2: Service Abstractions (COMPLETE)

- [x] Create `lib/services/auth/auth_provider.dart` (interface)
- [x] Create `lib/services/auth/firebase_auth_provider.dart` (stub)
- [x] Create `lib/services/data/data_provider.dart` (interface)
- [x] Create `lib/services/data/directus_data_provider.dart` (stub)
- [x] Create `lib/services/data/hasura_data_provider.dart` (stub)
- [x] Create `lib/services/data/data_provider_factory.dart` (conditional factory)
- [x] Create `lib/services/app_services.dart` (service locator)
- [x] Create `README_HYBRID.md` (complete documentation)
- [x] Create `HYBRID_IMPLEMENTATION_SUMMARY.md` (change summary)

## 🚧 Phase 3: Firebase Integration (TODO - You)

- [ ] Add `firebase_core` to `pubspec.yaml`
- [ ] Add `firebase_auth` to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Uncomment Firebase initialization in `main.dart`
- [ ] Implement `FirebaseAuthProvider.getIdToken()`
- [ ] Implement `FirebaseAuthProvider.signInWithEmailAndPassword()`
- [ ] Implement `FirebaseAuthProvider.signOut()`
- [ ] Implement `FirebaseAuthProvider.authStateChanges` stream
- [ ] Uncomment `AppServices.initialize()` in `main.dart`
- [ ] Test sign-in flow and token retrieval

## 🚧 Phase 4: Directus Integration (TODO - You)

- [ ] Add `http` package (if not already present)
- [ ] Implement `DirectusDataProvider.fetchProblems()`
- [ ] Implement `DirectusDataProvider.fetchProblemById()`
- [ ] Implement `DirectusDataProvider.createProblem()`
- [ ] Implement `DirectusDataProvider.updateProblem()`
- [ ] Implement `DirectusDataProvider.deleteProblem()`
- [ ] Implement `DirectusDataProvider.uploadImage()`
- [ ] Configure Directus to accept Firebase tokens OR use DIRECTUS_TOKEN fallback
- [ ] Test CRUD operations in local mode

## 🚧 Phase 5: Hasura Integration (TODO - You)

- [ ] Add Hasura JWT configuration (issuer, jwk_url, claims)
- [ ] Set up Firebase custom claims with Hasura roles
- [ ] Create GraphQL client with Firebase token header
- [ ] Implement `HasuraDataProvider.fetchProblems()` (GraphQL query)
- [ ] Implement `HasuraDataProvider.fetchProblemById()` (GraphQL query)
- [ ] Implement `HasuraDataProvider.createProblem()` (GraphQL mutation)
- [ ] Implement `HasuraDataProvider.updateProblem()` (GraphQL mutation)
- [ ] Implement `HasuraDataProvider.deleteProblem()` (GraphQL mutation)
- [ ] Test GraphQL operations with Firebase JWT

## 🚧 Phase 6: Supabase Storage (TODO - You)

- [ ] Add `supabase_flutter` package
- [ ] Create Supabase storage bucket ("problem-images")
- [ ] Configure bucket permissions (authenticated users can upload)
- [ ] Implement `HasuraDataProvider.uploadImage()` with signed URLs
- [ ] Test image upload and retrieval
- [ ] Verify public URL generation

## 🚧 Phase 7: Testing & Validation (TODO - You)

### Local Mode Testing
- [ ] Fill `.env.local` with your credentials
- [ ] Run `./scripts/switch_env.sh local run`
- [ ] Verify app starts with `BuildFlags.useDirectus == true`
- [ ] Sign in with Firebase
- [ ] Test problem CRUD with Directus
- [ ] Test image upload to Directus

### Cloud Mode Testing
- [ ] Fill `.env.cloud` with your credentials
- [ ] Run `./scripts/switch_env.sh cloud run`
- [ ] Verify app starts with `BuildFlags.useDirectus == false`
- [ ] Sign in with Firebase
- [ ] Test problem CRUD with Hasura
- [ ] Test image upload to Supabase
- [ ] Verify Firebase JWT claims include Hasura roles

### Production Build Testing
- [ ] Build web: `./scripts/switch_env.sh cloud build web --release`
- [ ] Build APK: `./scripts/switch_env.sh cloud build apk --release`
- [ ] Run `flutter build web --analyze-size --dart-define=USE_DIRECTUS=false`
- [ ] Verify Directus code is NOT in build output (tree-shaken)
- [ ] Deploy and test production build

## 📝 Phase 8: Documentation & Cleanup (TODO - You)

- [ ] Update main README.md with hybrid backend info
- [ ] Add example Firebase claims JSON
- [ ] Add example Hasura JWT config
- [ ] Document your Directus token strategy
- [ ] Add troubleshooting entries for common issues
- [ ] Create smoke test script (optional)
- [ ] Add CI/CD pipeline entries for cloud builds

## ⚠️ Critical Production Rules

**ALWAYS** follow these rules for production:

1. ✅ Use `--dart-define=USE_DIRECTUS=false` for ALL production builds
2. ✅ Use `.env.cloud` configuration for production
3. ✅ Never commit `.env`, `.env.local`, `.env.cloud` files
4. ✅ Never use `DIRECTUS_TOKEN` in production (development only)
5. ✅ Verify Firebase JWT claims include Hasura roles before deploying
6. ✅ Test Hasura authentication with real Firebase tokens
7. ✅ Configure Supabase storage bucket permissions properly

## 📊 Progress Tracking

**Overall**: 2/8 phases complete (25%)

- ✅ Phase 1: Infrastructure (100%)
- ✅ Phase 2: Service Abstractions (100%)
- 🚧 Phase 3: Firebase Integration (0%)
- 🚧 Phase 4: Directus Integration (0%)
- 🚧 Phase 5: Hasura Integration (0%)
- 🚧 Phase 6: Supabase Storage (0%)
- 🚧 Phase 7: Testing & Validation (0%)
- 🚧 Phase 8: Documentation & Cleanup (0%)

---

**Next Action**: Start with Phase 3 (Firebase Integration) by adding Firebase packages and implementing `FirebaseAuthProvider`.

**Need Help?**: See `README_HYBRID.md` for detailed implementation guide and examples.
