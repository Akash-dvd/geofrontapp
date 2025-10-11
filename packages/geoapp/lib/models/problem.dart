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
    this.scalarConstraints,
    this.objectConstraints,
    this.scalarProof,
    this.objectProof,
    this.thumbnailId,
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
  final Map<String, dynamic>? scalarConstraints;
  final Map<String, dynamic>? objectConstraints;
  final Map<String, dynamic>? scalarProof;
  final Map<String, dynamic>? objectProof;
  final String? thumbnailId; // Directus file ID for canvas thumbnail
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Create Problem from GraphQL response (Directus format)
  factory Problem.fromJson(Map<String, dynamic> json) {
    final dateCreated = json['date_created'] as String?;
    final dateUpdated = json['date_updated'] as String?;

    return Problem(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: ProblemDifficulty.fromString(json['difficulty'] as String),
      category: ProblemCategory.fromString(json['category'] as String),
      geometryData: json['geometry_data'] as Map<String, dynamic>?,
      solution: json['solution'] as String?,
      scalarConstraints: json['scalar_constraints'] as Map<String, dynamic>?,
      objectConstraints: json['object_constraints'] as Map<String, dynamic>?,
      scalarProof: json['scalar_proof'] as Map<String, dynamic>?,
      objectProof: json['object_proof'] as Map<String, dynamic>?,
      thumbnailId: json['thumbnail'] != null
          ? (json['thumbnail'] is String
                ? json['thumbnail'] as String
                : (json['thumbnail'] as Map<String, dynamic>)['id'] as String?)
          : null,
      createdAt: dateCreated != null
          ? DateTime.parse(dateCreated)
          : DateTime.now(),
      updatedAt: dateUpdated != null
          ? DateTime.parse(dateUpdated)
          : DateTime.now(),
    );
  }

  /// Convert Problem to JSON for GraphQL mutations (Directus format)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'category': category.name,
      'geometry_data': geometryData,
      'solution': solution,
      'scalar_constraints': scalarConstraints,
      'object_constraints': objectConstraints,
      'scalar_proof': scalarProof,
      'object_proof': objectProof,
      'thumbnail': thumbnailId,
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
    Map<String, dynamic>? scalarConstraints,
    Map<String, dynamic>? objectConstraints,
    Map<String, dynamic>? scalarProof,
    Map<String, dynamic>? objectProof,
    String? thumbnailId,
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
      scalarConstraints: scalarConstraints ?? this.scalarConstraints,
      objectConstraints: objectConstraints ?? this.objectConstraints,
      scalarProof: scalarProof ?? this.scalarProof,
      objectProof: objectProof ?? this.objectProof,
      thumbnailId: thumbnailId ?? this.thumbnailId,
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
    scalarConstraints,
    objectConstraints,
    scalarProof,
    objectProof,
    thumbnailId,
    createdAt,
    updatedAt,
  ];
}

/// Data structure for paginated problem results (Directus format)
class ProblemList extends Equatable {
  const ProblemList({
    required this.problems,
    required this.total,
    required this.offset,
    required this.limit,
  });

  final List<Problem> problems;
  final int total;
  final int offset;
  final int limit;

  bool get hasMore => offset + problems.length < total;

  // For backward compatibility with existing code
  int get start => offset;

  factory ProblemList.fromJson(Map<String, dynamic> json) {
    final problemsData = json['problems'] as List<dynamic>;

    // problems_aggregated is an array with one element containing count
    final aggregatedList = json['problems_aggregated'] as List<dynamic>?;
    final count = aggregatedList != null && aggregatedList.isNotEmpty
        ? (aggregatedList[0] as Map<String, dynamic>)['count']['id'] as int
        : problemsData.length;

    return ProblemList(
      problems: problemsData
          .map((item) => Problem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: count,
      offset: 0, // Directus doesn't return offset, will be managed by BLoC
      limit: problemsData.length,
    );
  }

  @override
  List<Object?> get props => [problems, total, offset, limit];
}
