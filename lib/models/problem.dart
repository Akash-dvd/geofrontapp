import 'package:equatable/equatable.dart';

/// Enum for problem difficulty levels
enum ProblemDifficulty {
  beginner,
  intermediate,
  advanced,
  expert;

  String get displayName {
    switch (this) {
      case ProblemDifficulty.beginner:
        return 'Beginner';
      case ProblemDifficulty.intermediate:
        return 'Intermediate';
      case ProblemDifficulty.advanced:
        return 'Advanced';
      case ProblemDifficulty.expert:
        return 'Expert';
    }
  }

  static ProblemDifficulty fromString(String value) {
    return ProblemDifficulty.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProblemDifficulty.beginner,
    );
  }
}

/// Enum for problem categories
enum ProblemCategory {
  geometry,
  algebra,
  trigonometry,
  calculus,
  proofs;

  String get displayName {
    switch (this) {
      case ProblemCategory.geometry:
        return 'Geometry';
      case ProblemCategory.algebra:
        return 'Algebra';
      case ProblemCategory.trigonometry:
        return 'Trigonometry';
      case ProblemCategory.calculus:
        return 'Calculus';
      case ProblemCategory.proofs:
        return 'Proofs';
    }
  }

  static ProblemCategory fromString(String value) {
    return ProblemCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProblemCategory.geometry,
    );
  }
}

/// Domain model for a Problem
class Problem extends Equatable {
  const Problem({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    this.geometryData,
    this.solution,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final ProblemDifficulty difficulty;
  final ProblemCategory category;
  final Map<String, dynamic>? geometryData;
  final String? solution;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Create Problem from GraphQL response
  factory Problem.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>;
    
    return Problem(
      id: json['id'] as String,
      title: attributes['title'] as String,
      description: attributes['description'] as String,
      difficulty: ProblemDifficulty.fromString(attributes['difficulty'] as String),
      category: ProblemCategory.fromString(attributes['category'] as String),
      geometryData: attributes['geometryData'] as Map<String, dynamic>?,
      solution: attributes['solution'] as String?,
      createdAt: DateTime.parse(attributes['createdAt'] as String),
      updatedAt: DateTime.parse(attributes['updatedAt'] as String),
    );
  }

  /// Convert Problem to JSON for GraphQL mutations
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'category': category.name,
      'geometryData': geometryData,
      'solution': solution,
    };
  }

  /// Create a copy of Problem with updated fields
  Problem copyWith({
    String? id,
    String? title,
    String? description,
    ProblemDifficulty? difficulty,
    ProblemCategory? category,
    Map<String, dynamic>? geometryData,
    String? solution,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Problem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      geometryData: geometryData ?? this.geometryData,
      solution: solution ?? this.solution,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        difficulty,
        category,
        geometryData,
        solution,
        createdAt,
        updatedAt,
      ];
}

/// Data structure for paginated problem results
class ProblemList extends Equatable {
  const ProblemList({
    required this.problems,
    required this.total,
    required this.start,
    required this.limit,
  });

  final List<Problem> problems;
  final int total;
  final int start;
  final int limit;

  bool get hasMore => start + limit < total;

  factory ProblemList.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    final meta = json['meta']['pagination'] as Map<String, dynamic>;

    return ProblemList(
      problems: data.map((item) => Problem.fromJson(item)).toList(),
      total: meta['total'] as int,
      start: meta['start'] as int,
      limit: meta['limit'] as int,
    );
  }

  @override
  List<Object?> get props => [problems, total, start, limit];
}