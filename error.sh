PS C:\Users\skdwi\OneDrive\Documents\Project\flutter\geofrontapp> ^C
PS C:\Users\skdwi\OneDrive\Documents\Project\flutter\geofrontapp> flutter run --dart-define=USE_DIRECTUS=false -d web-server --web-hostname 0.0.0.0 --web-port 8080
Resolving dependencies... (1.2s)
Downloading packages...
  _fe_analyzer_shared 85.0.0 (90.0.0 available)
  _flutterfire_internals 1.3.35 (1.3.63 available)
  analyzer 7.7.1 (8.3.0 available)
  bloc 8.1.4 (9.0.1 available)
  bloc_test 9.1.7 (10.0.0 available)
  build 3.1.0 (4.0.2 available)
  build_resolvers 3.0.3 (3.0.4 available)
  build_runner 2.7.1 (2.9.0 available)
  build_runner_core 9.3.1 (9.3.2 available)
  characters 1.4.0 (1.4.1 available)
  connectivity_plus 6.1.5 (7.0.0 available)
  dart_style 3.1.1 (3.1.2 available)
  firebase_auth 4.16.0 (6.1.1 available)
  firebase_auth_platform_interface 7.3.0 (8.1.3 available)
  firebase_auth_web 5.8.13 (6.0.4 available)
  firebase_core 2.32.0 (4.2.0 available)
  firebase_core_platform_interface 5.4.2 (6.0.2 available)
  firebase_core_web 2.24.0 (3.2.0 available)
  flutter_bloc 8.1.6 (9.1.1 available)
  flutter_dotenv 5.2.1 (6.0.0 available)
  flutter_lints 5.0.0 (6.0.0 available)
  google_fonts 5.1.0 (6.3.2 available)
  gql_dedupe_link 2.0.4-alpha+1715521079596 (4.0.0 available)
  js 0.6.7 (0.7.2 available)
  lints 5.1.1 (6.0.0 available)
  material_color_utilities 0.11.1 (0.13.0 available)
  meta 1.16.0 (1.17.0 available)
  mockito 5.5.0 (5.5.1 available)
  normalize 0.9.1 (0.10.0 available)
  path_provider_android 2.2.18 (2.2.19 available)
  source_gen 3.1.0 (4.0.2 available)
  test 1.26.2 (1.26.3 available)
  test_api 0.7.6 (0.7.7 available)
  test_core 0.6.11 (0.6.12 available)
Got dependencies!
34 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Launching lib\main.dart on Web Server in debug mode...
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:26:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> applyActionCode(AuthJsImpl auth, String oobCode);
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:38:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<ActionCodeInfo> checkActionCode(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:42:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> confirmPasswordReset(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:55:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> setPersistence(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:59:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> createUserWithEmailAndPassword(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:70:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> deleteUser(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:75:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<List> fetchSignInMethodsForEmail(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:82:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl?> getRedirectResult(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:87:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> sendSignInLinkToEmail(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:94:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> sendPasswordResetEmail(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:101:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> signInWithCredential(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:107:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> signInAnonymously(AuthJsImpl auth);
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:110:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> signInWithCustomToken(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:116:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> signInWithEmailAndPassword(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:123:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> signInWithEmailLink(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:130:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<ConfirmationResultJsImpl> signInWithPhoneNumber(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:137:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> signInWithPopup(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:143:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> signInWithRedirect(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:149:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<String> verifyPasswordResetCode(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:155:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> linkWithCredential(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:161:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<ConfirmationResultJsImpl> linkWithPhoneNumber(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:168:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> linkWithPopup(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:174:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> linkWithRedirect(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:180:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> reauthenticateWithCredential(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:186:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<ConfirmationResultJsImpl> reauthenticateWithPhoneNumber(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:193:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserCredentialJsImpl> reauthenticateWithPopup(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:199:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> reauthenticateWithRedirect(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:205:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> sendEmailVerification([
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:211:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> verifyBeforeUpdateEmail(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:218:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<UserJsImpl> unlink(UserJsImpl user, String providerId);
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:221:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> updateEmail(UserJsImpl user, String newEmail);
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:224:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> updatePassword(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:230:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> updatePhoneNumber(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:236:10: Error: Type 'PromiseJsImpl' not found.
external PromiseJsImpl<void> updateProfile(
         ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:276:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<void> signOut();
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:311:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<void> delete();
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:312:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<String> getIdToken([bool? opt_forceRefresh]);
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:313:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<IdTokenResultImpl> getIdTokenResult(
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:315:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<void> reload();
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:468:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<String> verifyPhoneNumber(
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:489:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<String> verify();
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:500:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<num> render();
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:506:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<UserCredentialJsImpl> confirm(String verificationCode);
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:705:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<void> enroll(
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:707:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<MultiFactorSessionJsImpl> getSession();
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:708:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<void> unenroll(
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:735:12: Error: Type 'PromiseJsImpl' not found.
  external PromiseJsImpl<UserCredentialJsImpl> resolveSignIn(
           ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth_interop.dart:790:19: Error: Type 'PromiseJsImpl' not found.
  external static PromiseJsImpl<TotpSecretJsImpl> generateSecret(
                  ^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/utils/utils.dart:11:23: Error: Method not found: 'dartify'.
  return core_interop.dartify(jsObject);
                      ^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/utils/utils.dart:19:23: Error: Method not found: 'jsify'.
  return core_interop.jsify(dartObject, customJsify);
                      ^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:116:28: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
  Future<void> delete() => handleThenable(jsObject.delete());
                           ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:126:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(jsObject.getIdToken(forceRefresh));
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:132:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.linkWithCredential(jsObject, credential))
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:139:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:148:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.linkWithPopup(jsObject, provider.jsObject))
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:153:59: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
  Future<void> linkWithRedirect(AuthProvider provider) => handleThenable(
                                                          ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:160:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:171:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.reauthenticateWithPhoneNumber(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:179:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:186:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:190:28: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
  Future<void> reload() => handleThenable(jsObject.reload());
                           ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:212:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:219:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.verifyBeforeUpdateEmail(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:224:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.unlink(jsObject, providerId))
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:229:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.updateEmail(jsObject, newEmail));
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:235:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.updatePassword(jsObject, newPassword));
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:240:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.updatePhoneNumber(jsObject, phoneCredential));
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:244:7: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.updateProfile(jsObject, profile));
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:251:12: Error: The method 'handleThenable' isn't defined for the
type 'User'.
 - 'User' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
    return handleThenable(promise).then(IdTokenResult._fromJsObject);
           ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:455:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.applyActionCode(jsObject, oobCode));
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:461:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.checkActionCode(jsObject, code));
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:465:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:485:21: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
    final u = await handleThenable(
                    ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:498:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.fetchSignInMethodsForEmail(jsObject, email))
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:511:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.getRedirectResult(jsObject)).then(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:526:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.sendSignInLinkToEmail(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:562:12: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
    return handleThenable(auth_interop.setPersistence(jsObject, instance));
           ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:586:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.sendPasswordResetEmail(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:593:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.signInWithCredential(jsObject, credential))
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:602:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.signInAnonymously(jsObject))
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:613:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.signInWithCustomToken(jsObject, token))
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:640:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.signInWithEmailAndPassword(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:646:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:662:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.signInWithPhoneNumber(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:670:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.signInWithPopup(jsObject, provider.jsObject))
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:674:55: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
  Future signInWithRedirect(AuthProvider provider) => handleThenable(
                                                      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:678:23: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
  Future signOut() => handleThenable(jsObject.signOut());
                      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:696:7: Error: The method 'handleThenable' isn't defined for the
type 'Auth'.
 - 'Auth' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(auth_interop.verifyPasswordResetCode(jsObject, code));
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:989:7: Error: The method 'handleThenable' isn't defined for the
type 'PhoneAuthProvider'.
 - 'PhoneAuthProvider' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(jsObject.verifyPhoneNumber(
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:1016:30: Error: The method 'handleThenable' isn't defined for the
type 'ApplicationVerifier<T>'.
 - 'ApplicationVerifier' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
  Future<String> verify() => handleThenable(jsObject.verify());
                             ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:1072:27: Error: The method 'handleThenable' isn't defined for the
type 'RecaptchaVerifier'.
 - 'RecaptchaVerifier' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
  Future<num> render() => handleThenable(jsObject.render());
                          ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/auth.dart:1093:7: Error: The method 'handleThenable' isn't defined for the
type 'ConfirmationResult'.
 - 'ConfirmationResult' is from 'package:firebase_auth_web/src/interop/auth.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/auth.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(jsObject.confirm(verificationCode))
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/multi_factor.dart:52:7: Error: The method 'handleThenable' isn't defined for
the type 'MultiFactorUser'.
 - 'MultiFactorUser' is from 'package:firebase_auth_web/src/interop/multi_factor.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/multi_factor.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
      handleThenable(jsObject.getSession())
      ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/multi_factor.dart:63:12: Error: The method 'handleThenable' isn't defined for
the type 'MultiFactorUser'.
 - 'MultiFactorUser' is from 'package:firebase_auth_web/src/interop/multi_factor.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/multi_factor.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
    return handleThenable(jsObject.enroll(assertion.jsObject, displayName));
           ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/multi_factor.dart:75:12: Error: The method 'handleThenable' isn't defined for
the type 'MultiFactorUser'.
 - 'MultiFactorUser' is from 'package:firebase_auth_web/src/interop/multi_factor.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/multi_factor.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
    return handleThenable(jsObject.unenroll(multiFactorInfoId));
           ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/multi_factor.dart:150:12: Error: The method 'handleThenable' isn't defined
for the type 'MultiFactorResolver'.
 - 'MultiFactorResolver' is from
 'package:firebase_auth_web/src/interop/multi_factor.dart'
 ('../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/
 src/interop/multi_factor.dart').
Try correcting the name to the name of an existing method, or defining a method named
'handleThenable'.
    return handleThenable(jsObject.resolveSignIn(assertion.jsObject))
           ^^^^^^^^^^^^^^
../../../../../AppData/Local/Pub/Cache/hosted/pub.dev/firebase_auth_web-5.8.13/lib/src
/interop/multi_factor.dart:230:12: Error: Method not found: 'handleThenable'.
    return handleThenable(
           ^^^^^^^^^^^^^^
Waiting for connection from debug service on Web Server...         44.1s
Failed to compile application.
PS C:\Users\skdwi\OneDrive\Documents\Project\flutter\geofrontapp>