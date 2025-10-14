import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// Import from packages
import 'package:geoapp/geoapp.dart';
import 'package:frontpage/frontpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Validate configuration (hardcoded in env_config.dart)
  EnvConfig.validate();

  // 2. Print current mode for debugging
  EnvConfig.printConfig();
  debugPrint(
    '🚀 Starting app in ${BuildFlags.useDirectus ? "LOCAL (Directus)" : "CLOUD (Hasura+Supabase)"} mode',
  );

  // 4. Initialize Firebase (always required for auth)
  // TODO: Initialize Firebase with EnvConfig values
  // await Firebase.initializeApp(
  //   options: FirebaseOptions(
  //     apiKey: EnvConfig.firebaseApiKey,
  //     authDomain: EnvConfig.firebaseAuthDomain,
  //     projectId: EnvConfig.firebaseProjectId,
  //     storageBucket: EnvConfig.firebaseStorageBucket,
  //     messagingSenderId: EnvConfig.firebaseMessagingSenderId,
  //     appId: EnvConfig.firebaseAppId,
  //   ),
  // );

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
