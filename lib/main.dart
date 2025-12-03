import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import from packages
import 'package:geoapp/geoapp.dart';
import 'package:frontpage/frontpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Validate configuration (hardcoded in env_config.dart)
  EnvConfig.validate();

  // 2. debugPrint current mode for debugging
  EnvConfig.printConfig();
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint(
    '🚀 Starting app in ${BuildFlags.useDirectus ? "LOCAL (Directus)" : "CLOUD (Hasura+Supabase)"} mode',
  );
  debugPrint('═══════════════════════════════════════════════════════');

  // 3. Initialize Supabase (shared auth + database)
  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
        detectSessionInUri: true,
      ),
    );
  // Note: SupabaseAuth isn't exported directly from the package's public
  // entrypoint. The supabase_flutter package initializes its internal
  // auth handling during `Supabase.initialize(...)`. If you need to run
  // additional web-specific initialization for PKCE, import the
  // implementation from the package that exposes it or handle PKCE
  // callback detection in your web entrypoint.
    debugPrint('✅ Supabase initialized successfully');
  } on AuthException catch (e) {
    // Handle specific auth errors gracefully
    if (e.message.contains('Code verifier could not be found')) {
      // Silently handle stale OAuth sessions - this is non-critical
      // The app will continue to work, just without the session
      // No need to log this as it's expected when OAuth flow is interrupted
    } else {
      debugPrint('❌ Supabase auth error: ${e.message}');
    }
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
  }

  // 4. Initialize app services (auth + data providers)
  await AppServices.initialize();

  // 5. Initialize GraphQL cache (kept for compatibility)
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
