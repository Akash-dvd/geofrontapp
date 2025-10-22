import 'dart:convert';

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
  final String? geometryData;
  final String? solution;
  final String? scalarConstraints;
  final String? objectConstraints;
  final String? scalarProof;
  final String? objectProof;
  final String? thumbnailId; // Directus file ID for canvas thumbnail
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Create Problem from GraphQL response (supports both Hasura and Directus formats)
  factory Problem.fromJson(Map<String, dynamic> json) {
    // Handle both Hasura (created_at) and Directus (date_created) formats
    final dateCreated =
        json['created_at'] as String? ?? json['date_created'] as String?;
    final dateUpdated =
        json['updated_at'] as String? ?? json['date_updated'] as String?;

    return Problem(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: ProblemDifficulty.fromString(json['difficulty'] as String),
      category: ProblemCategory.fromString(json['category'] as String),
  geometryData: _normalizeJsonField(json['geometry_data']),
      solution: json['solution'] as String?,
  scalarConstraints: _normalizeJsonField(json['scalar_constraints']),
  objectConstraints: _normalizeJsonField(json['object_constraints']),
  scalarProof: _normalizeJsonField(json['scalar_proof']),
  objectProof: _normalizeJsonField(json['object_proof']),
      thumbnailId: json['thumbnail_id'] != null
          ? json['thumbnail_id'] as String?
          : (json['thumbnail'] != null
              ? (json['thumbnail'] is String
                  ? json['thumbnail'] as String
                  : (json['thumbnail'] as Map<String, dynamic>)['id']
                      as String?)
              : null),
      createdAt:
          dateCreated != null ? DateTime.parse(dateCreated) : DateTime.now(),
      updatedAt:
          dateUpdated != null ? DateTime.parse(dateUpdated) : DateTime.now(),
    );
  }

  /// Convert Problem to JSON for GraphQL mutations (Directus format)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'category': category.name,
    'geometry_data': _decodeJsonField(geometryData),
      'solution': solution,
    'scalar_constraints': _decodeJsonField(scalarConstraints),
    'object_constraints': _decodeJsonField(objectConstraints),
    'scalar_proof': _decodeJsonField(scalarProof),
    'object_proof': _decodeJsonField(objectProof),
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
    String? geometryData,
    String? solution,
  String? scalarConstraints,
  String? objectConstraints,
  String? scalarProof,
  String? objectProof,
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

String? _normalizeJsonField(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
}

dynamic _decodeJsonField(String? value) {
  if (value == null) {
    return null;
  }

  try {
    return jsonDecode(value);
  } catch (_) {
    return value;
  }
}

/// Data structure for paginated problem results (Directus format)
class ProblemList extends Equatable {
  const ProblemList({
    required this.problems,
    required this.total,
    required this.offset,
    required this.limit,
    this.hasNextPage,
  });

  final List<Problem> problems;
  final int total;
  final int offset;
  final int limit;
  final bool? hasNextPage;

  bool get hasMore {
    if (hasNextPage != null) {
      return hasNextPage!;
    }
    return offset + problems.length < total;
  }

  // For backward compatibility with existing code
  int get start => offset;

  factory ProblemList.fromJson(
    Map<String, dynamic> json, {
    int? offsetHint,
    int? limitHint,
  }) {
    if (json.containsKey('problemsCollection')) {
      final collection = json['problemsCollection'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final edges = collection['edges'] as List<dynamic>? ?? const [];
      final problems = edges
          .map((edge) => Problem.fromJson(
                (edge as Map<String, dynamic>)['node'] as Map<String, dynamic>,
              ))
          .toList();
      final pageInfo = collection['pageInfo'] as Map<String, dynamic>?;
      final nextPage = pageInfo != null
          ? pageInfo['hasNextPage'] as bool?
          : null;
      final total = collection['totalCount'] as int? ??
          _inferTotal(
            offsetHint: offsetHint,
            limitHint: limitHint,
            fetchedCount: problems.length,
            hasNextPage: nextPage,
          );
      return ProblemList(
        problems: problems,
        total: total,
        offset: offsetHint ?? 0,
        limit: limitHint ?? problems.length,
        hasNextPage: nextPage,
      );
    }

    if (json.containsKey('problems')) {
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
        offset: offsetHint ?? 0,
        limit: limitHint ?? problemsData.length,
        hasNextPage: null,
      );
    }

    throw ArgumentError('Unsupported problem list response structure: $json');
  }

  @override
  List<Object?> get props => [problems, total, offset, limit, hasNextPage];
}

int _inferTotal({
  int? offsetHint,
  int? limitHint,
  required int fetchedCount,
  bool? hasNextPage,
}) {
  final baseOffset = offsetHint ?? 0;
  if (hasNextPage == true) {
    final inferredLimit = limitHint ?? fetchedCount;
    return baseOffset + fetchedCount + inferredLimit;
  }

  return baseOffset + fetchedCount;
}
