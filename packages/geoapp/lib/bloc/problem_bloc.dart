import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;

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

      final result = await _graphQLClient.query(
        QueryOptions(
          document: gql(ProblemQueries.getAllProblems),
          variables: {
            'offset': event.start, // Using 'start' from event as offset
            'limit': event.limit,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        emit(
          ProblemError(
            message: result.exception.toString(),
            currentProblems: _allProblems.isNotEmpty ? _allProblems : null,
          ),
        );
        return;
      }

      final problemList = ProblemList.fromJson(result.data!);

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

      final result = await _graphQLClient.query(
        QueryOptions(
          document: gql(ProblemQueries.getAllProblems),
          variables: {'offset': nextOffset, 'limit': _currentLimit},
          fetchPolicy: FetchPolicy.networkOnly,
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

      final problemList = ProblemList.fromJson(result.data!);
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

      // Use REST API for create since GraphQL has schema issues with file relationships
      final response = await http.post(
        Uri.parse('http://192.168.1.3:8055/items/problems'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': event.title,
          'description': event.description,
          'difficulty': event.difficulty.name,
          'category': event.category.name,
          'geometry_data': event.geometryData,
          'solution': event.solution,
          if (event.thumbnailId != null) 'thumbnail': event.thumbnailId,
        }),
      );

      print('DEBUG: REST API response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('DEBUG: REST API error: ${response.body}');
        emit(
          ProblemError(
            message: 'Failed to create problem: ${response.body}',
            currentProblems: _allProblems,
          ),
        );
        return;
      }

      print('DEBUG: Problem created successfully');
      final responseData = json.decode(response.body);
      final newProblem = Problem.fromJson(responseData['data']);
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

      // Use REST API for update since GraphQL has schema issues with file relationships
      final response = await http.patch(
        Uri.parse('http://192.168.1.3:8055/items/problems/${event.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': event.title,
          'description': event.description,
          'difficulty': event.difficulty.name,
          'category': event.category.name,
          'geometry_data': event.geometryData,
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
      final updatedProblem = Problem.fromJson(responseData['data']);
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

      final problem = Problem.fromJson(result.data!['problems_by_id']);
      emit(ProblemDetailsLoaded(problem: problem));
    } catch (e) {
      emit(ProblemError(message: 'Failed to fetch problem: ${e.toString()}'));
    }
  }
}
