import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// Import from packages
import 'package:geoapp/geoapp.dart';
import 'package:frontpage/frontpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GraphQL cache
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
