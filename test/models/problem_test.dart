import 'package:flutter_test/flutter_test.dart';
import 'package:geofrontapp/models/problem.dart';

void main() {
  group('Problem Model Tests', () {
    late Problem testProblem;
    late Map<String, dynamic> testJson;

    setUp(() {
      testJson = {
        'id': '1',
        'attributes': {
          'title': 'Test Problem',
          'description': 'This is a test problem description',
          'difficulty': 'intermediate',
          'category': 'geometry',
          'geometryData': {
            'points': [
              {'x': 0, 'y': 0},
              {'x': 1, 'y': 1}
            ]
          },
          'solution': 'Test solution',
          'createdAt': '2025-10-04T10:00:00.000Z',
          'updatedAt': '2025-10-04T11:00:00.000Z',
        },
      };

      testProblem = Problem(
        id: '1',
        title: 'Test Problem',
        description: 'This is a test problem description',
        difficulty: ProblemDifficulty.intermediate,
        category: ProblemCategory.geometry,
        geometryData: {
          'points': [
            {'x': 0, 'y': 0},
            {'x': 1, 'y': 1}
          ]
        },
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
      expect(problem.geometryData, isA<Map<String, dynamic>>());
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
      expect(json['geometryData'], isA<Map<String, dynamic>>());
      expect(json['solution'], 'Test solution');
    });

    test('should handle null optional fields correctly', () {
      final jsonWithNulls = {
        'id': '2',
        'attributes': {
          'title': 'Minimal Problem',
          'description': 'Minimal description',
          'difficulty': 'beginner',
          'category': 'algebra',
          'geometryData': null,
          'solution': null,
          'createdAt': '2025-10-04T10:00:00.000Z',
          'updatedAt': '2025-10-04T10:00:00.000Z',
        },
      };

      final problem = Problem.fromJson(jsonWithNulls);

      expect(problem.geometryData, isNull);
      expect(problem.solution, isNull);
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
      expect(ProblemDifficulty.fromString('beginner'), ProblemDifficulty.beginner);
      expect(ProblemDifficulty.fromString('INTERMEDIATE'), ProblemDifficulty.intermediate);
      expect(ProblemDifficulty.fromString('Advanced'), ProblemDifficulty.advanced);
      expect(ProblemDifficulty.fromString('invalid'), ProblemDifficulty.beginner);
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
      expect(ProblemCategory.fromString('Trigonometry'), ProblemCategory.trigonometry);
      expect(ProblemCategory.fromString('invalid'), ProblemCategory.geometry);
    });
  });

  group('ProblemList Tests', () {
    test('should create ProblemList from JSON correctly', () {
      final testData = {
        'data': [
          {
            'id': '1',
            'attributes': {
              'title': 'Problem 1',
              'description': 'Description 1',
              'difficulty': 'beginner',
              'category': 'geometry',
              'createdAt': '2025-10-04T10:00:00.000Z',
              'updatedAt': '2025-10-04T10:00:00.000Z',
            },
          },
          {
            'id': '2',
            'attributes': {
              'title': 'Problem 2',
              'description': 'Description 2',
              'difficulty': 'intermediate',
              'category': 'algebra',
              'createdAt': '2025-10-04T10:00:00.000Z',
              'updatedAt': '2025-10-04T10:00:00.000Z',
            },
          },
        ],
        'meta': {
          'pagination': {
            'start': 0,
            'limit': 20,
            'total': 25,
          },
        },
      };

      final problemList = ProblemList.fromJson(testData);

      expect(problemList.problems.length, 2);
      expect(problemList.total, 25);
      expect(problemList.start, 0);
      expect(problemList.limit, 20);
      expect(problemList.hasMore, isTrue);
    });

    test('should correctly determine if there are more problems', () {
      final problemListWithMore = ProblemList(
        problems: [],
        total: 100,
        start: 0,
        limit: 20,
      );

      final problemListWithoutMore = ProblemList(
        problems: [],
        total: 15,
        start: 0,
        limit: 20,
      );

      expect(problemListWithMore.hasMore, isTrue);
      expect(problemListWithoutMore.hasMore, isFalse);
    });

    test('should support equality comparison', () {
      final list1 = ProblemList(
        problems: [],
        total: 10,
        start: 0,
        limit: 20,
      );

      final list2 = ProblemList(
        problems: [],
        total: 10,
        start: 0,
        limit: 20,
      );

      expect(list1, equals(list2));
    });
  });
}