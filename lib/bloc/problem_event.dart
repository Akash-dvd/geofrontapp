import 'package:equatable/equatable.dart';

import '../models/problem.dart';

/// Abstract base class for all Problem events
abstract class ProblemEvent extends Equatable {
  const ProblemEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch problems list with optional pagination
class FetchProblems extends ProblemEvent {
  const FetchProblems({
    this.start = 0,
    this.limit = 20,
    this.refresh = false,
  });

  final int start;
  final int limit;
  final bool refresh;

  @override
  List<Object?> get props => [start, limit, refresh];
}

/// Event to create a new problem
class CreateProblem extends ProblemEvent {
  const CreateProblem({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    this.geometryData,
    this.solution,
  });

  final String title;
  final String description;
  final ProblemDifficulty difficulty;
  final ProblemCategory category;
  final Map<String, dynamic>? geometryData;
  final String? solution;

  @override
  List<Object?> get props => [
        title,
        description,
        difficulty,
        category,
        geometryData,
        solution,
      ];
}

/// Event to update an existing problem
class UpdateProblem extends ProblemEvent {
  const UpdateProblem({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    this.geometryData,
    this.solution,
  });

  final String id;
  final String title;
  final String description;
  final ProblemDifficulty difficulty;
  final ProblemCategory category;
  final Map<String, dynamic>? geometryData;
  final String? solution;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        difficulty,
        category,
        geometryData,
        solution,
      ];
}

/// Event to delete a problem
class DeleteProblem extends ProblemEvent {
  const DeleteProblem({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Event to fetch a specific problem by ID
class FetchProblemById extends ProblemEvent {
  const FetchProblemById({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Event to load more problems (pagination)
class LoadMoreProblems extends ProblemEvent {
  const LoadMoreProblems();
}