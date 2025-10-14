/// Unified GraphQL queries that automatically switch between Directus and Hasura
/// Based on BuildFlags.useDirectus compile-time flag
library;

import '../config/build_flags.dart';
import 'directus_problem_queries.dart';
import 'hasura_problem_queries.dart';

/// Unified query interface that delegates to appropriate backend
/// Usage: ProblemQueries.getAllProblems, ProblemQueries.createProblem, etc.
class ProblemQueries {
  /// Get all problems query
  static String get getAllProblems => BuildFlags.useDirectus
      ? DirectusProblemQueries.getAllProblems
      : HasuraProblemQueries.getAllProblems;

  /// Get problem by ID query
  static String get getProblemById => BuildFlags.useDirectus
      ? DirectusProblemQueries.getProblemById
      : HasuraProblemQueries.getProblemById;

  /// Create problem mutation
  static String get createProblem => BuildFlags.useDirectus
      ? DirectusProblemQueries.createProblem
      : HasuraProblemQueries.createProblem;

  /// Update problem mutation
  static String get updateProblem => BuildFlags.useDirectus
      ? DirectusProblemQueries.updateProblem
      : HasuraProblemQueries.updateProblem;

  /// Delete problem mutation
  static String get deleteProblem => BuildFlags.useDirectus
      ? DirectusProblemQueries.deleteProblem
      : HasuraProblemQueries.deleteProblem;
}
