import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import from packages
import 'package:geoapp/geoapp.dart';
import 'package:frontpage/frontpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Validate configuration (hardcoded in env_config.dart)
  EnvConfig.validate();

  // 2. Print current mode for debugging
  EnvConfig.printConfig();
  print('═══════════════════════════════════════════════════════');
  print(
    '🚀 Starting app in ${BuildFlags.useDirectus ? "LOCAL (Directus)" : "CLOUD (Hasura+Supabase)"} mode',
  );
  print('═══════════════════════════════════════════════════════');

  // 3. Initialize Firebase (always required for auth)
  try {
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
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  // 4. Sign in anonymously if not already authenticated (for cloud mode)
  if (!BuildFlags.useDirectus) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('🔐 No user signed in, signing in anonymously...');
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        print('✅ Signed in anonymously: ${userCredential.user?.uid}');
      } else {
        print('✅ User already signed in: ${user.uid}');
        print('   Anonymous: ${user.isAnonymous}');
        print('   Email: ${user.email ?? 'N/A'}');
      }
    } catch (e) {
      print('❌ Anonymous sign-in failed: $e');
    }
  }

  // 5. Initialize app services (auth + data providers)
  // await AppServices.initialize();

  // 6. Initialize GraphQL cache (kept for compatibility)
  await initHiveForFlutter();

  runApp(const GeoFrontApp());
}

class GeoFrontApp extends StatelessWidget {
  const GeoFrontApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create GraphQL client once
    final graphQLClient = GraphQLConfig.createClient();

    return GraphQLConfig.createProvider(
      child: BlocProvider(
        create: (context) => ProblemBloc(graphQLClient: graphQLClient),
        child: MaterialApp(
          title: 'GeoFront App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system, // Automatically follows system theme
          home:
              const FrontPage(), // Start with FrontPage instead of ProblemManagementScreen
        ),
      ),
    );
  }
}
