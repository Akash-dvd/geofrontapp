/// GeoFront App - Problem Management Module
///
/// This package contains all the problem management functionality:
/// - Problem list, create, edit, delete
/// - BLoC state management
/// - GraphQL integration with Directus
/// - Theme configuration
library;

// Screens
export 'screens/problem_management_screen.dart';
export 'screens/problem_details_screen.dart';
export 'screens/problem_form_screen.dart';

// BLoC
export 'bloc/problem_bloc.dart';
export 'bloc/problem_event.dart';
export 'bloc/problem_state.dart';

// Models
export 'models/problem.dart';

// Config
export 'config/build_flags.dart';
export 'config/env_config.dart';
export 'config/graphql_config.dart';
export 'package:designsystem/designsystem.dart';

// GraphQL Queries
export 'graphql/directus_problem_queries.dart';
export 'graphql/hasura_problem_queries.dart';

// Services
export 'services/directus_file_service.dart';
export 'services/app_services.dart';

// Auth
export 'services/auth/auth_provider.dart';
export 'services/auth/firebase_auth_provider.dart';

// Data Providers
export 'services/data/data_provider.dart';
export 'services/data/data_provider_factory.dart';
export 'services/data/directus_data_provider.dart';
export 'services/data/hasura_data_provider.dart';
