import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/build_flags.dart';
import '../config/env_config.dart';
import '../graphql/problem_queries.dart';
import '../models/problem.dart';
import 'problem_event.dart';
import 'problem_state.dart';

/// BLoC for managing Problem-related state and operations
/// Follows constitutional requirement for BLoC state management
class ProblemBloc extends Bloc<ProblemEvent, ProblemState> {
  ProblemBloc({required GraphQLClient graphQLClient})
      : _graphQLClient = graphQLClient,
        super(const ProblemInitial()) {
    on<FetchProblems>(_onFetchProblems);
    on<LoadMoreProblems>(_onLoadMoreProblems);
    on<CreateProblem>(_onCreateProblem);
    on<UpdateProblem>(_onUpdateProblem);
    on<DeleteProblem>(_onDeleteProblem);
    on<FetchProblemById>(_onFetchProblemById);
  }

  final GraphQLClient _graphQLClient;
  List<Problem> _allProblems = [];
  int _currentOffset = 0;
  int _currentLimit = 20;
  bool _hasMore = true;
  int _total = 0;

  /// Handle fetching problems list
  Future<void> _onFetchProblems(
    FetchProblems event,
    Emitter<ProblemState> emit,
  ) async {
    try {
      if (event.refresh || state is ProblemInitial) {
        emit(const ProblemLoading());
        _allProblems.clear();
        _currentOffset = 0;
      }

      final result = await _runWithAuthRetry(
        () => _graphQLClient.query(
          QueryOptions(
            document: gql(ProblemQueries.getAllProblems),
            variables: {
              'offset': event.start, // Using 'start' from event as offset
              'limit': event.limit,
            },
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        ),
      );

      if (result.hasException) {
        emit(
          ProblemError(
            message: _formatErrorMessage(result.exception),
            currentProblems: _allProblems.isNotEmpty ? _allProblems : null,
          ),
        );
        return;
      }

      final problemList = ProblemList.fromJson(
        result.data!,
        offsetHint: event.start,
        limitHint: event.limit,
      );

      if (event.refresh) {
        _allProblems = problemList.problems;
        _currentOffset = 0;
      } else {
        _allProblems.addAll(problemList.problems);
        _currentOffset = event.start;
      }

      _currentLimit = problemList.limit;
      _hasMore = problemList.hasMore;
      _total = problemList.total;

      emit(
        ProblemLoaded(
          problems: List.from(_allProblems),
          hasMore: _hasMore,
          total: _total,
        ),
      );
    } catch (e) {
      emit(
        ProblemError(
          message: 'Failed to fetch problems: ${e.toString()}',
          currentProblems: _allProblems.isNotEmpty ? _allProblems : null,
        ),
      );
    }
  }

  /// Handle loading more problems (pagination)
  Future<void> _onLoadMoreProblems(
    LoadMoreProblems event,
    Emitter<ProblemState> emit,
  ) async {
    if (!_hasMore) return;

    try {
      emit(ProblemLoadingMore(currentProblems: _allProblems));

      final nextOffset = _currentOffset + _currentLimit;

      final result = await _runWithAuthRetry(
        () => _graphQLClient.query(
          QueryOptions(
            document: gql(ProblemQueries.getAllProblems),
            variables: {'offset': nextOffset, 'limit': _currentLimit},
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        ),
      );

      if (result.hasException) {
        emit(
          ProblemError(
            message: _formatErrorMessage(result.exception),
            currentProblems: _allProblems,
          ),
        );
        return;
      }

      final problemList = ProblemList.fromJson(
        result.data!,
        offsetHint: nextOffset,
        limitHint: _currentLimit,
      );
      _allProblems.addAll(problemList.problems);
      _currentOffset = nextOffset;
      _hasMore = problemList.hasMore;

      emit(
        ProblemLoaded(
          problems: List.from(_allProblems),
          hasMore: _hasMore,
          total: _total,
        ),
      );
    } catch (e) {
      emit(
        ProblemError(
          message: 'Failed to load more problems: ${e.toString()}',
          currentProblems: _allProblems,
        ),
      );
    }
  }

  /// Handle creating a new problem using REST API
  Future<void> _onCreateProblem(
    CreateProblem event,
    Emitter<ProblemState> emit,
  ) async {
    try {
      print('DEBUG: BLoC received CreateProblem event');
      print('DEBUG: Title: ${event.title}');
      print('DEBUG: ThumbnailId: ${event.thumbnailId}');

      emit(
        ProblemOperationInProgress(
          operation: 'Creating problem',
          currentProblems: _allProblems,
        ),
      );

      // Use GraphQL mutation (works for both Hasura and Directus)
      final useDirectus = BuildFlags.useDirectus;
      final variables = <String, dynamic>{};

      if (useDirectus) {
        variables.addAll({
          'title': event.title,
          'description': event.description,
          'difficulty': event.difficulty.name,
          'category': event.category.name,
          'solution': event.solution,
        });

        if (event.geometryData != null) {
          try {
            variables['geometry_data'] = jsonDecode(event.geometryData!);
          } catch (error) {
            emit(
              ProblemError(
                message: 'Failed to serialize geometry data: $error',
                currentProblems: _allProblems,
              ),
            );
            return;
          }
        }

        if (event.thumbnailId != null) {
          variables['thumbnail'] = event.thumbnailId;
        }
      } else {
        final insertObject = <String, dynamic>{
          'title': event.title,
          'description': event.description,
          'difficulty': event.difficulty.name,
          'category': event.category.name,
          'geometry_data': event.geometryData,
          'solution': event.solution,
          'thumbnail_id': event.thumbnailId,
        };

        variables['object'] = _sanitizeJsonMap(
          insertObject,
          coerceRootToJson: true,
        );
      }

      final result = await _runWithAuthRetry(
        () => _graphQLClient.mutate(
          MutationOptions(
            document: gql(ProblemQueries.createProblem),
            variables: variables,
          ),
        ),
      );

      if (result.hasException) {
        print('DEBUG: GraphQL error: ${result.exception.toString()}');
        emit(
          ProblemError(
            message:
                'Failed to create problem: ${_formatErrorMessage(result.exception)}',
            currentProblems: _allProblems,
          ),
        );
        return;
      }

      print('DEBUG: Problem created successfully');
      // Handle response from both Hasura and Directus
      Map<String, dynamic>? problemData;

      if (useDirectus) {
        problemData =
            result.data?['create_problems_item'] as Map<String, dynamic>?;
      } else {
        final supabaseRecords = result.data?['insertIntoproblemsCollection']
            ?['records'] as List<dynamic>?;
        if (supabaseRecords != null && supabaseRecords.isNotEmpty) {
          problemData = supabaseRecords.first as Map<String, dynamic>;
        }
      }

      if (problemData == null) {
        print('DEBUG: No problem data in response');
        emit(
          ProblemError(
            message: 'Failed to create problem: No data returned',
            currentProblems: _allProblems,
          ),
        );
        return;
      }

      final newProblem = Problem.fromJson(problemData);
      print(
        'DEBUG: New problem ID: ${newProblem.id}, ThumbnailId: ${newProblem.thumbnailId}',
      );

      _allProblems.insert(0, newProblem);
      _total++;

      emit(
        ProblemOperationSuccess(
          message: 'Problem created successfully',
          problems: List.from(_allProblems),
          hasMore: _hasMore,
          total: _total,
        ),
      );

      print('DEBUG: ProblemOperationSuccess emitted');
    } catch (e) {
      emit(
        ProblemError(
          message: 'Failed to create problem: ${e.toString()}',
          currentProblems: _allProblems,
        ),
      );
    }
  }

  /// Handle updating an existing problem using REST API
  Future<void> _onUpdateProblem(
    UpdateProblem event,
    Emitter<ProblemState> emit,
  ) async {
    try {
      emit(
        ProblemOperationInProgress(
          operation: 'Updating problem',
          currentProblems: _allProblems,
        ),
      );

      late final Problem updatedProblem;

      if (BuildFlags.useDirectus) {
        final baseUrl = EnvConfig.directusUrl;
        final uri = Uri.parse('$baseUrl/items/problems/${event.id}');
        final response = await http.patch(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'title': event.title,
            'description': event.description,
            'difficulty': event.difficulty.name,
            'category': event.category.name,
            if (event.geometryData != null)
              'geometry_data': jsonDecode(event.geometryData!),
            'solution': event.solution,
            if (event.thumbnailId != null) 'thumbnail': event.thumbnailId,
          }),
        );

        if (response.statusCode != 200) {
          emit(
            ProblemError(
              message: 'Failed to update problem: ${response.body}',
              currentProblems: _allProblems,
            ),
          );
          return;
        }

        final responseData = json.decode(response.body);
        updatedProblem = Problem.fromJson(responseData['data']);
      } else {
        final updateValues = <String, dynamic>{
          'title': event.title,
          'description': event.description,
          'difficulty': event.difficulty.name,
          'category': event.category.name,
          'geometry_data': event.geometryData,
          'solution': event.solution,
        };

        if (event.thumbnailId != null) {
          updateValues['thumbnail_id'] = event.thumbnailId;
        }

        final result = await _runWithAuthRetry(
          () => _graphQLClient.mutate(
            MutationOptions(
              document: gql(ProblemQueries.updateProblem),
              variables: {
                'id': event.id,
                'values': _sanitizeJsonMap(
                  updateValues,
                  coerceRootToJson: true,
                ),
              },
            ),
          ),
        );

        if (result.hasException) {
          emit(
            ProblemError(
              message:
                  'Failed to update problem: ${_formatErrorMessage(result.exception)}',
              currentProblems: _allProblems,
            ),
          );
          return;
        }

        Map<String, dynamic>? problemData;

        final supabasePayload =
            result.data?['updateproblemsCollection'] as Map<String, dynamic>?;
        if (supabasePayload != null) {
          final records = supabasePayload['records'] as List<dynamic>?;
          if (records != null && records.isNotEmpty) {
            problemData = records.first as Map<String, dynamic>;
          }
        }

        if (problemData == null) {
          emit(
            ProblemError(
              message: 'Failed to update problem: No data returned',
              currentProblems: _allProblems,
            ),
          );
          return;
        }

        updatedProblem = Problem.fromJson(problemData);
      }
      final index = _allProblems.indexWhere((p) => p.id == event.id);
      if (index != -1) {
        _allProblems[index] = updatedProblem;
      }

      emit(
        ProblemOperationSuccess(
          message: 'Problem updated successfully',
          problems: List.from(_allProblems),
          hasMore: _hasMore,
          total: _total,
        ),
      );
    } catch (e) {
      emit(
        ProblemError(
          message: 'Failed to update problem: ${e.toString()}',
          currentProblems: _allProblems,
        ),
      );
    }
  }

  /// Handle deleting a problem
  Future<void> _onDeleteProblem(
    DeleteProblem event,
    Emitter<ProblemState> emit,
  ) async {
    try {
      emit(
        ProblemOperationInProgress(
          operation: 'Deleting problem',
          currentProblems: _allProblems,
        ),
      );

      final result = await _graphQLClient.mutate(
        MutationOptions(
          document: gql(ProblemQueries.deleteProblem),
          variables: {'id': event.id},
        ),
      );

      if (result.hasException) {
        emit(
          ProblemError(
            message: result.exception.toString(),
            currentProblems: _allProblems,
          ),
        );
        return;
      }

      var deleteSucceeded = false;

      if (BuildFlags.useDirectus) {
        final directusPayload =
            result.data?['delete_problems_item'] as Map<String, dynamic>?;
        deleteSucceeded = directusPayload != null;
      } else {
        final supabasePayload = result.data?['deleteFromproblemsCollection']
            as Map<String, dynamic>?;
        final affected = supabasePayload?['affectedCount'] as int? ?? 0;
        deleteSucceeded = affected > 0;
      }

      if (!deleteSucceeded) {
        emit(
          ProblemError(
            message: 'Failed to delete problem: No confirmation returned',
            currentProblems: _allProblems,
          ),
        );
        return;
      }

      _allProblems.removeWhere((problem) => problem.id == event.id);
      _total--;

      emit(
        ProblemOperationSuccess(
          message: 'Problem deleted successfully',
          problems: List.from(_allProblems),
          hasMore: _hasMore,
          total: _total,
        ),
      );
    } catch (e) {
      emit(
        ProblemError(
          message: 'Failed to delete problem: ${e.toString()}',
          currentProblems: _allProblems,
        ),
      );
    }
  }

  /// Handle fetching a specific problem by ID
  Future<void> _onFetchProblemById(
    FetchProblemById event,
    Emitter<ProblemState> emit,
  ) async {
    try {
      emit(const ProblemLoading());

      final result = await _graphQLClient.query(
        QueryOptions(
          document: gql(ProblemQueries.getProblemById),
          variables: {'id': event.id},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        emit(ProblemError(message: result.exception.toString()));
        return;
      }

      Map<String, dynamic>? problemData;

      if (BuildFlags.useDirectus) {
        problemData = result.data?['problems_by_id'] as Map<String, dynamic>?;
      } else {
        final collection =
            result.data?['problemsCollection'] as Map<String, dynamic>?;
        final edges = collection?['edges'] as List<dynamic>?;
        if (edges != null && edges.isNotEmpty) {
          problemData = edges.first['node'] as Map<String, dynamic>;
        }
      }

      if (problemData == null) {
        emit(
          ProblemError(
            message: 'Problem not found',
            currentProblems: _allProblems.isNotEmpty ? _allProblems : null,
          ),
        );
        return;
      }

      final problem = Problem.fromJson(problemData);
      emit(ProblemDetailsLoaded(problem: problem));
    } catch (e) {
      emit(ProblemError(message: 'Failed to fetch problem: ${e.toString()}'));
    }
  }
}

Future<QueryResult> _runWithAuthRetry(
  Future<QueryResult> Function() operation,
) async {
  var result = await operation();
  if (!_shouldAttemptRefresh(result.exception)) {
    return result;
  }

  final didRefresh = await _refreshSupabaseSession();
  if (!didRefresh) {
    return result;
  }

  return await operation();
}

bool _shouldAttemptRefresh(OperationException? exception) {
  if (BuildFlags.useDirectus || exception == null) {
    return false;
  }
  final message = exception.toString().toLowerCase();
  return message.contains('invalid or expired supabase token');
}

Future<bool> _refreshSupabaseSession() async {
  try {
    final auth = Supabase.instance.client.auth;
    final response = await auth.refreshSession();
    if (response.session != null) {
      debugPrint('♻️ Refreshed Supabase session for GraphQL request');
      return true;
    }
  } catch (e) {
    debugPrint('❌ Failed to refresh Supabase session: $e');
  }
  return false;
}

String _formatErrorMessage(OperationException? exception) {
  if (exception == null) {
    return 'Unknown error occurred';
  }

  if (_shouldAttemptRefresh(exception)) {
    return 'Session expired. Please sign in again.';
  }

  return exception.toString();
}

Map<String, dynamic> _sanitizeJsonMap(
  Map<String, dynamic> source, {
  bool coerceRootToJson = false,
}) {
  final result = <String, dynamic>{};
  source.forEach((key, value) {
    if (value == null) {
      return;
    }
    result[key] = _coerceJsonValue(value);
  });
  if (!coerceRootToJson) {
    return result;
  }

  try {
    final encoded = jsonEncode(result);
    return Map<String, dynamic>.from(jsonDecode(encoded) as Map);
  } catch (_) {
    return result;
  }
}

dynamic _coerceJsonValue(dynamic value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is Iterable) {
    return value.map(_coerceJsonValue).toList();
  }
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), _coerceJsonValue(val)),
    );
  }

  try {
    final encoded = jsonEncode(value);
    return jsonDecode(encoded);
  } catch (_) {
    return value.toString();
  }
}
