import 'package:equatable/equatable.dart';

import '../models/problem.dart';

/// Abstract base class for all Problem states
abstract class ProblemState extends Equatable {
  const ProblemState();

  @override
  List<Object?> get props => [];
}

/// Initial state when BLoC is first created
class ProblemInitial extends ProblemState {
  const ProblemInitial();
}

/// State when loading problems (first load)
class ProblemLoading extends ProblemState {
  const ProblemLoading();
}

/// State when loading more problems (pagination)
class ProblemLoadingMore extends ProblemState {
  const ProblemLoadingMore({required this.currentProblems});
  
  final List<Problem> currentProblems;

  @override
  List<Object?> get props => [currentProblems];
}

/// State when problems are successfully loaded
class ProblemLoaded extends ProblemState {
  const ProblemLoaded({
    required this.problems,
    required this.hasMore,
    required this.total,
  });

  final List<Problem> problems;
  final bool hasMore;
  final int total;

  @override
  List<Object?> get props => [problems, hasMore, total];
}

/// State when a specific problem is loaded
class ProblemDetailsLoaded extends ProblemState {
  const ProblemDetailsLoaded({required this.problem});

  final Problem problem;

  @override
  List<Object?> get props => [problem];
}

/// State when a problem operation is in progress (create/update/delete)
class ProblemOperationInProgress extends ProblemState {
  const ProblemOperationInProgress({
    required this.operation,
    this.currentProblems,
  });

  final String operation;
  final List<Problem>? currentProblems;

  @override
  List<Object?> get props => [operation, currentProblems];
}

/// State when a problem operation succeeds
class ProblemOperationSuccess extends ProblemState {
  const ProblemOperationSuccess({
    required this.message,
    required this.problems,
    required this.hasMore,
    required this.total,
  });

  final String message;
  final List<Problem> problems;
  final bool hasMore;
  final int total;

  @override
  List<Object?> get props => [message, problems, hasMore, total];
}

/// State when an error occurs
class ProblemError extends ProblemState {
  const ProblemError({
    required this.message,
    this.currentProblems,
  });

  final String message;
  final List<Problem>? currentProblems;

  @override
  List<Object?> get props => [message, currentProblems];
}