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
export 'config/app_theme.dart';
export 'config/graphql_config.dart';

// Services
export 'services/directus_file_service.dart';
