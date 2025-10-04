import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
  int _currentStart = 0;
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
        _currentStart = 0;
      }

      final result = await _graphQLClient.query(
        QueryOptions(
          document: gql(ProblemQueries.getAllProblems),
          variables: {
            'start': event.start,
            'limit': event.limit,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        emit(ProblemError(
          message: result.exception.toString(),
          currentProblems: _allProblems.isNotEmpty ? _allProblems : null,
        ));
        return;
      }

      final problemList = ProblemList.fromJson(result.data!['problems']);
      
      if (event.refresh) {
        _allProblems = problemList.problems;
      } else {
        _allProblems.addAll(problemList.problems);
      }
      
      _currentStart = problemList.start;
      _currentLimit = problemList.limit;
      _hasMore = problemList.hasMore;
      _total = problemList.total;

      emit(ProblemLoaded(
        problems: List.from(_allProblems),
        hasMore: _hasMore,
        total: _total,
      ));
    } catch (e) {
      emit(ProblemError(
        message: 'Failed to fetch problems: ${e.toString()}',
        currentProblems: _allProblems.isNotEmpty ? _allProblems : null,
      ));
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

      final nextStart = _currentStart + _currentLimit;
      
      final result = await _graphQLClient.query(
        QueryOptions(
          document: gql(ProblemQueries.getAllProblems),
          variables: {
            'start': nextStart,
            'limit': _currentLimit,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        emit(ProblemError(
          message: result.exception.toString(),
          currentProblems: _allProblems,
        ));
        return;
      }

      final problemList = ProblemList.fromJson(result.data!['problems']);
      _allProblems.addAll(problemList.problems);
      _currentStart = problemList.start;
      _hasMore = problemList.hasMore;

      emit(ProblemLoaded(
        problems: List.from(_allProblems),
        hasMore: _hasMore,
        total: _total,
      ));
    } catch (e) {
      emit(ProblemError(
        message: 'Failed to load more problems: ${e.toString()}',
        currentProblems: _allProblems,
      ));
    }
  }

  /// Handle creating a new problem
  Future<void> _onCreateProblem(
    CreateProblem event,
    Emitter<ProblemState> emit,
  ) async {
    try {
      emit(ProblemOperationInProgress(
        operation: 'Creating problem',
        currentProblems: _allProblems,
      ));

      final result = await _graphQLClient.mutate(
        MutationOptions(
          document: gql(ProblemQueries.createProblem),
          variables: {
            'data': {
              'title': event.title,
              'description': event.description,
              'difficulty': event.difficulty.name,
              'category': event.category.name,
              'geometryData': event.geometryData,
              'solution': event.solution,
            },
          },
        ),
      );

      if (result.hasException) {
        emit(ProblemError(
          message: result.exception.toString(),
          currentProblems: _allProblems,
        ));
        return;
      }

      final newProblem = Problem.fromJson(result.data!['createProblem']['data']);
      _allProblems.insert(0, newProblem);
      _total++;

      emit(ProblemOperationSuccess(
        message: 'Problem created successfully',
        problems: List.from(_allProblems),
        hasMore: _hasMore,
        total: _total,
      ));
    } catch (e) {
      emit(ProblemError(
        message: 'Failed to create problem: ${e.toString()}',
        currentProblems: _allProblems,
      ));
    }
  }

  /// Handle updating an existing problem
  Future<void> _onUpdateProblem(
    UpdateProblem event,
    Emitter<ProblemState> emit,
  ) async {
    try {
      emit(ProblemOperationInProgress(
        operation: 'Updating problem',
        currentProblems: _allProblems,
      ));

      final result = await _graphQLClient.mutate(
        MutationOptions(
          document: gql(ProblemQueries.updateProblem),
          variables: {
            'id': event.id,
            'data': {
              'title': event.title,
              'description': event.description,
              'difficulty': event.difficulty.name,
              'category': event.category.name,
              'geometryData': event.geometryData,
              'solution': event.solution,
            },
          },
        ),
      );

      if (result.hasException) {
        emit(ProblemError(
          message: result.exception.toString(),
          currentProblems: _allProblems,
        ));
        return;
      }

      final updatedProblem = Problem.fromJson(result.data!['updateProblem']['data']);
      final index = _allProblems.indexWhere((p) => p.id == event.id);
      if (index != -1) {
        _allProblems[index] = updatedProblem;
      }

      emit(ProblemOperationSuccess(
        message: 'Problem updated successfully',
        problems: List.from(_allProblems),
        hasMore: _hasMore,
        total: _total,
      ));
    } catch (e) {
      emit(ProblemError(
        message: 'Failed to update problem: ${e.toString()}',
        currentProblems: _allProblems,
      ));
    }
  }

  /// Handle deleting a problem
  Future<void> _onDeleteProblem(
    DeleteProblem event,
    Emitter<ProblemState> emit,
  ) async {
    try {
      emit(ProblemOperationInProgress(
        operation: 'Deleting problem',
        currentProblems: _allProblems,
      ));

      final result = await _graphQLClient.mutate(
        MutationOptions(
          document: gql(ProblemQueries.deleteProblem),
          variables: {'id': event.id},
        ),
      );

      if (result.hasException) {
        emit(ProblemError(
          message: result.exception.toString(),
          currentProblems: _allProblems,
        ));
        return;
      }

      _allProblems.removeWhere((problem) => problem.id == event.id);
      _total--;

      emit(ProblemOperationSuccess(
        message: 'Problem deleted successfully',
        problems: List.from(_allProblems),
        hasMore: _hasMore,
        total: _total,
      ));
    } catch (e) {
      emit(ProblemError(
        message: 'Failed to delete problem: ${e.toString()}',
        currentProblems: _allProblems,
      ));
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

      final problem = Problem.fromJson(result.data!['problem']['data']);
      emit(ProblemDetailsLoaded(problem: problem));
    } catch (e) {
      emit(ProblemError(
        message: 'Failed to fetch problem: ${e.toString()}',
      ));
    }
  }
}