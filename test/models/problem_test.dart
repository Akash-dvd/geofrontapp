import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geoapp/models/problem.dart';

void main() {
  group('Problem Model Tests', () {
    late Problem testProblem;
    late Map<String, dynamic> testJson;

    setUp(() {
      testJson = {
        'id': '1',
        'title': 'Test Problem',
        'description': 'This is a test problem description',
        'difficulty': 'intermediate',
        'category': 'geometry',
        'geometry_data': jsonEncode({
          'points': [
            {'x': 0, 'y': 0},
            {'x': 1, 'y': 1},
          ],
        }),
          'scalar_constraints': {
            'distance': {'points': ['A', 'B'], 'value': 5}
          },
          'object_constraints': {
            'collinear': {
              'points': ['A', 'B', 'C'],
            }
          },
          'scalar_proof': {
            'steps': [
              {'statement': 'AB = 5'}
            ]
          },
          'object_proof': {
            'steps': [
              {'statement': 'Points A, B, C are collinear'}
            ]
          },
        'solution': 'Test solution',
        'created_at': '2025-10-04T10:00:00.000Z',
        'updated_at': '2025-10-04T11:00:00.000Z',
      };

      testProblem = Problem(
        id: '1',
        title: 'Test Problem',
        description: 'This is a test problem description',
        difficulty: ProblemDifficulty.intermediate,
        category: ProblemCategory.geometry,
        geometryData: jsonEncode({
          'points': [
            {'x': 0, 'y': 0},
            {'x': 1, 'y': 1},
          ],
        }),
        scalarConstraints: jsonEncode({
          'distance': {'points': ['A', 'B'], 'value': 5}
        }),
        objectConstraints: jsonEncode({
          'collinear': {
            'points': ['A', 'B', 'C'],
          }
        }),
        scalarProof: jsonEncode({
          'steps': [
            {'statement': 'AB = 5'}
          ]
        }),
        objectProof: jsonEncode({
          'steps': [
            {'statement': 'Points A, B, C are collinear'}
          ]
        }),
        solution: 'Test solution',
        createdAt: DateTime.parse('2025-10-04T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-10-04T11:00:00.000Z'),
      );
    });

    test('should create Problem from JSON correctly', () {
      final problem = Problem.fromJson(testJson);

      expect(problem.id, '1');
      expect(problem.title, 'Test Problem');
      expect(problem.description, 'This is a test problem description');
      expect(problem.difficulty, ProblemDifficulty.intermediate);
      expect(problem.category, ProblemCategory.geometry);
      expect(problem.geometryData, isA<String>());
  expect(problem.scalarConstraints, isA<String>());
  expect(problem.objectConstraints, isA<String>());
  expect(problem.scalarProof, isA<String>());
  expect(problem.objectProof, isA<String>());
      expect(problem.solution, 'Test solution');
      expect(problem.createdAt, DateTime.parse('2025-10-04T10:00:00.000Z'));
      expect(problem.updatedAt, DateTime.parse('2025-10-04T11:00:00.000Z'));
    });

    test('should convert Problem to JSON correctly', () {
      final json = testProblem.toJson();

      expect(json['title'], 'Test Problem');
      expect(json['description'], 'This is a test problem description');
      expect(json['difficulty'], 'intermediate');
      expect(json['category'], 'geometry');
      expect(json['geometry_data'], isA<Map<String, dynamic>>());
  expect(json['scalar_constraints'], isA<Map<String, dynamic>>());
  expect(json['object_constraints'], isA<Map<String, dynamic>>());
  expect(json['scalar_proof'], isA<Map<String, dynamic>>());
  expect(json['object_proof'], isA<Map<String, dynamic>>());
      expect(json['solution'], 'Test solution');
    });

    test('should handle null optional fields correctly', () {
      final jsonWithNulls = {
        'id': '2',
        'title': 'Minimal Problem',
        'description': 'Minimal description',
        'difficulty': 'beginner',
        'category': 'algebra',
        'geometry_data': null,
        'solution': null,
        'scalar_constraints': null,
        'object_constraints': null,
        'scalar_proof': null,
        'object_proof': null,
        'created_at': '2025-10-04T10:00:00.000Z',
        'updated_at': '2025-10-04T10:00:00.000Z',
      };

      final problem = Problem.fromJson(jsonWithNulls);

      expect(problem.geometryData, isNull);
      expect(problem.solution, isNull);
      expect(problem.scalarConstraints, isNull);
      expect(problem.objectConstraints, isNull);
      expect(problem.scalarProof, isNull);
      expect(problem.objectProof, isNull);
    });

    test('should create copy with updated fields', () {
      final updatedProblem = testProblem.copyWith(
        title: 'Updated Title',
        difficulty: ProblemDifficulty.expert,
      );

      expect(updatedProblem.title, 'Updated Title');
      expect(updatedProblem.difficulty, ProblemDifficulty.expert);
      expect(updatedProblem.id, testProblem.id);
      expect(updatedProblem.description, testProblem.description);
    });

    test('should support equality comparison', () {
      final problem1 = Problem(
        id: '1',
        title: 'Same Problem',
        description: 'Same description',
        difficulty: ProblemDifficulty.beginner,
        category: ProblemCategory.geometry,
        createdAt: DateTime.parse('2025-10-04T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-10-04T10:00:00.000Z'),
      );

      final problem2 = Problem(
        id: '1',
        title: 'Same Problem',
        description: 'Same description',
        difficulty: ProblemDifficulty.beginner,
        category: ProblemCategory.geometry,
        createdAt: DateTime.parse('2025-10-04T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-10-04T10:00:00.000Z'),
      );

      expect(problem1, equals(problem2));
    });
  });

  group('ProblemDifficulty Tests', () {
    test('should return correct display names', () {
      expect(ProblemDifficulty.beginner.displayName, 'Beginner');
      expect(ProblemDifficulty.intermediate.displayName, 'Intermediate');
      expect(ProblemDifficulty.advanced.displayName, 'Advanced');
      expect(ProblemDifficulty.expert.displayName, 'Expert');
    });

    test('should parse from string correctly', () {
      expect(
        ProblemDifficulty.fromString('beginner'),
        ProblemDifficulty.beginner,
      );
      expect(
        ProblemDifficulty.fromString('INTERMEDIATE'),
        ProblemDifficulty.intermediate,
      );
      expect(
        ProblemDifficulty.fromString('Advanced'),
        ProblemDifficulty.advanced,
      );
      expect(
        ProblemDifficulty.fromString('invalid'),
        ProblemDifficulty.beginner,
      );
    });
  });

  group('ProblemCategory Tests', () {
    test('should return correct display names', () {
      expect(ProblemCategory.geometry.displayName, 'Geometry');
      expect(ProblemCategory.algebra.displayName, 'Algebra');
      expect(ProblemCategory.trigonometry.displayName, 'Trigonometry');
      expect(ProblemCategory.calculus.displayName, 'Calculus');
      expect(ProblemCategory.proofs.displayName, 'Proofs');
    });

    test('should parse from string correctly', () {
      expect(ProblemCategory.fromString('geometry'), ProblemCategory.geometry);
      expect(ProblemCategory.fromString('ALGEBRA'), ProblemCategory.algebra);
      expect(
        ProblemCategory.fromString('Trigonometry'),
        ProblemCategory.trigonometry,
      );
      expect(ProblemCategory.fromString('invalid'), ProblemCategory.geometry);
    });
  });

  group('ProblemList Tests', () {
    test('should create ProblemList from JSON correctly', () {
      final testData = {
        'problemsCollection': {
          'edges': [
            {
              'node': {
                'id': '1',
                'title': 'Problem 1',
                'description': 'Description 1',
                'difficulty': 'beginner',
                'category': 'geometry',
                'created_at': '2025-10-04T10:00:00.000Z',
                'updated_at': '2025-10-04T10:00:00.000Z',
              },
            },
            {
              'node': {
                'id': '2',
                'title': 'Problem 2',
                'description': 'Description 2',
                'difficulty': 'intermediate',
                'category': 'algebra',
                'created_at': '2025-10-04T10:00:00.000Z',
                'updated_at': '2025-10-04T10:00:00.000Z',
              },
            },
          ],
          'totalCount': 25,
        },
      };

      final problemList = ProblemList.fromJson(testData);

      expect(problemList.problems.length, 2);
      expect(problemList.total, 25);
      expect(problemList.start, 0);
      expect(problemList.limit, 2);
      expect(problemList.hasMore, isTrue);
    });

    test('should infer pageInfo pagination when totalCount missing', () {
      final testData = {
        'problemsCollection': {
          'edges': [
            {
              'node': {
                'id': '1',
                'title': 'Problem 1',
                'description': 'Description 1',
                'difficulty': 'beginner',
                'category': 'geometry',
                'created_at': '2025-10-04T10:00:00.000Z',
                'updated_at': '2025-10-04T10:00:00.000Z',
              },
            },
          ],
          'pageInfo': {
            'hasNextPage': true,
            'hasPreviousPage': false,
          },
        },
      };

      final problemList = ProblemList.fromJson(
        testData,
        offsetHint: 0,
        limitHint: 1,
      );

      expect(problemList.total, greaterThanOrEqualTo(2));
      expect(problemList.hasMore, isTrue);
    });

    test('should correctly determine if there are more problems', () {
      // When total > offset + fetchedCount, hasMore is true
      final problemListWithMore = ProblemList(
        problems: const [], // fetchedCount = 0
        total: 100,
        offset: 0,
        limit: 20,
      );

      // When total == offset + fetchedCount, hasMore is false
      final problemListWithoutMore = ProblemList(
        problems: const [], // fetchedCount = 0
        total: 15,
        offset: 15,
        limit: 20,
      );

      expect(problemListWithMore.hasMore, isTrue);
      expect(problemListWithoutMore.hasMore, isFalse);
    });

    test('should support equality comparison', () {
      final list1 = ProblemList(
        problems: const [],
        total: 10,
        offset: 0,
        limit: 20,
      );

      final list2 = ProblemList(
        problems: const [],
        total: 10,
        offset: 0,
        limit: 20,
      );

      expect(list1, equals(list2));
    });
  });
}
