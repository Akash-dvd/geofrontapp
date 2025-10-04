import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:geofrontapp/bloc/problem_bloc.dart';
import 'package:geofrontapp/bloc/problem_event.dart';
import 'package:geofrontapp/bloc/problem_state.dart';
import 'package:geofrontapp/models/problem.dart';

import 'problem_bloc_test.mocks.dart';

@GenerateMocks([GraphQLClient])
void main() {
  group('ProblemBloc Tests', () {
    late MockGraphQLClient mockGraphQLClient;
    late ProblemBloc problemBloc;

    setUp(() {
      mockGraphQLClient = MockGraphQLClient();
      problemBloc = ProblemBloc(graphQLClient: mockGraphQLClient);
    });

    tearDown(() {
      problemBloc.close();
    });

    test('initial state is ProblemInitial', () {
      expect(problemBloc.state, const ProblemInitial());
    });

    group('FetchProblems', () {
      final mockProblemsResponse = {
        'problems': {
          'data': [
            {
              'id': '1',
              'attributes': {
                'title': 'Test Problem 1',
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
                'title': 'Test Problem 2',
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
              'total': 2,
            },
          },
        },
      };

      blocTest<ProblemBloc, ProblemState>(
        'emits [ProblemLoading, ProblemLoaded] when FetchProblems succeeds',
        build: () {
          when(mockGraphQLClient.query(any)).thenAnswer(
            (_) async => QueryResult(
              source: QueryResultSource.network,
              data: mockProblemsResponse,
              options: QueryOptions(document: gql('')),
            ),
          );
          return problemBloc;
        },
        act: (bloc) => bloc.add(const FetchProblems()),
        expect: () => [
          const ProblemLoading(),
          isA<ProblemLoaded>()
              .having((state) => state.problems.length, 'problems length', 2)
              .having((state) => state.total, 'total', 2)
              .having((state) => state.hasMore, 'hasMore', false),
        ],
        verify: (_) {
          verify(mockGraphQLClient.query(any)).called(1);
        },
      );

      blocTest<ProblemBloc, ProblemState>(
        'emits [ProblemLoading, ProblemError] when FetchProblems fails',
        build: () {
          when(mockGraphQLClient.query(any)).thenAnswer(
            (_) async => QueryResult(
              source: QueryResultSource.network,
              data: null,
              options: QueryOptions(document: gql('')),
              exception: OperationException(
                graphqlErrors: [GraphQLError(message: 'Network error')],
              ),
            ),
          );
          return problemBloc;
        },
        act: (bloc) => bloc.add(const FetchProblems()),
        expect: () => [
          const ProblemLoading(),
          isA<ProblemError>().having(
            (state) => state.message,
            'error message',
            contains('Network error'),
          ),
        ],
      );
    });

    group('CreateProblem', () {
      final mockCreateResponse = {
        'createProblem': {
          'data': {
            'id': '3',
            'attributes': {
              'title': 'New Problem',
              'description': 'New Description',
              'difficulty': 'advanced',
              'category': 'proofs',
              'createdAt': '2025-10-04T12:00:00.000Z',
              'updatedAt': '2025-10-04T12:00:00.000Z',
            },
          },
        },
      };

      blocTest<ProblemBloc, ProblemState>(
        'emits [ProblemOperationInProgress, ProblemOperationSuccess] when CreateProblem succeeds',
        build: () {
          when(mockGraphQLClient.mutate(any)).thenAnswer(
            (_) async => QueryResult(
              source: QueryResultSource.network,
              data: mockCreateResponse,
              options: QueryOptions(document: gql('')),
            ),
          );
          return problemBloc;
        },
        act: (bloc) => bloc.add(const CreateProblem(
          title: 'New Problem',
          description: 'New Description',
          difficulty: ProblemDifficulty.advanced,
          category: ProblemCategory.proofs,
        )),
        expect: () => [
          isA<ProblemOperationInProgress>(),
          isA<ProblemOperationSuccess>()
              .having((state) => state.message, 'message', 'Problem created successfully')
              .having((state) => state.problems.length, 'problems length', 1),
        ],
      );

      blocTest<ProblemBloc, ProblemState>(
        'emits [ProblemOperationInProgress, ProblemError] when CreateProblem fails',
        build: () {
          when(mockGraphQLClient.mutate(any)).thenAnswer(
            (_) async => QueryResult(
              source: QueryResultSource.network,
              data: null,
              options: QueryOptions(document: gql('')),
              exception: OperationException(
                graphqlErrors: [GraphQLError(message: 'Validation error')],
              ),
            ),
          );
          return problemBloc;
        },
        act: (bloc) => bloc.add(const CreateProblem(
          title: 'New Problem',
          description: 'New Description',
          difficulty: ProblemDifficulty.advanced,
          category: ProblemCategory.proofs,
        )),
        expect: () => [
          isA<ProblemOperationInProgress>(),
          isA<ProblemError>().having(
            (state) => state.message,
            'error message',
            contains('Validation error'),
          ),
        ],
      );
    });

    group('UpdateProblem', () {
      final mockUpdateResponse = {
        'updateProblem': {
          'data': {
            'id': '1',
            'attributes': {
              'title': 'Updated Problem',
              'description': 'Updated Description',
              'difficulty': 'expert',
              'category': 'calculus',
              'createdAt': '2025-10-04T10:00:00.000Z',
              'updatedAt': '2025-10-04T13:00:00.000Z',
            },
          },
        },
      };

      blocTest<ProblemBloc, ProblemState>(
        'emits [ProblemOperationInProgress, ProblemOperationSuccess] when UpdateProblem succeeds',
        build: () {
          when(mockGraphQLClient.mutate(any)).thenAnswer(
            (_) async => QueryResult(
              source: QueryResultSource.network,
              data: mockUpdateResponse,
              options: QueryOptions(document: gql('')),
            ),
          );
          return problemBloc;
        },
        seed: () {
          // Add a problem to the bloc's internal list first
          problemBloc.add(const FetchProblems());
          return const ProblemLoaded(problems: [
            Problem(
              id: '1',
              title: 'Original Problem',
              description: 'Original Description',
              difficulty: ProblemDifficulty.beginner,
              category: ProblemCategory.geometry,
              createdAt: '2025-10-04T10:00:00.000Z',
              updatedAt: '2025-10-04T10:00:00.000Z',
            ),
          ], hasMore: false, total: 1);
        },
        act: (bloc) => bloc.add(const UpdateProblem(
          id: '1',
          title: 'Updated Problem',
          description: 'Updated Description',
          difficulty: ProblemDifficulty.expert,
          category: ProblemCategory.calculus,
        )),
        expect: () => [
          isA<ProblemOperationInProgress>(),
          isA<ProblemOperationSuccess>()
              .having((state) => state.message, 'message', 'Problem updated successfully'),
        ],
      );
    });

    group('DeleteProblem', () {
      final mockDeleteResponse = {
        'deleteProblem': {
          'data': {
            'id': '1',
          },
        },
      };

      blocTest<ProblemBloc, ProblemState>(
        'emits [ProblemOperationInProgress, ProblemOperationSuccess] when DeleteProblem succeeds',
        build: () {
          when(mockGraphQLClient.mutate(any)).thenAnswer(
            (_) async => QueryResult(
              source: QueryResultSource.network,
              data: mockDeleteResponse,
              options: QueryOptions(document: gql('')),
            ),
          );
          return problemBloc;
        },
        seed: () {
          return const ProblemLoaded(problems: [
            Problem(
              id: '1',
              title: 'Problem to Delete',
              description: 'Description',
              difficulty: ProblemDifficulty.beginner,
              category: ProblemCategory.geometry,
              createdAt: '2025-10-04T10:00:00.000Z',
              updatedAt: '2025-10-04T10:00:00.000Z',
            ),
          ], hasMore: false, total: 1);
        },
        act: (bloc) => bloc.add(const DeleteProblem(id: '1')),
        expect: () => [
          isA<ProblemOperationInProgress>(),
          isA<ProblemOperationSuccess>()
              .having((state) => state.message, 'message', 'Problem deleted successfully')
              .having((state) => state.problems.length, 'problems length', 0),
        ],
      );
    });

    group('FetchProblemById', () {
      final mockProblemResponse = {
        'problem': {
          'data': {
            'id': '1',
            'attributes': {
              'title': 'Single Problem',
              'description': 'Single Description',
              'difficulty': 'intermediate',
              'category': 'trigonometry',
              'createdAt': '2025-10-04T10:00:00.000Z',
              'updatedAt': '2025-10-04T10:00:00.000Z',
            },
          },
        },
      };

      blocTest<ProblemBloc, ProblemState>(
        'emits [ProblemLoading, ProblemDetailsLoaded] when FetchProblemById succeeds',
        build: () {
          when(mockGraphQLClient.query(any)).thenAnswer(
            (_) async => QueryResult(
              source: QueryResultSource.network,
              data: mockProblemResponse,
              options: QueryOptions(document: gql('')),
            ),
          );
          return problemBloc;
        },
        act: (bloc) => bloc.add(const FetchProblemById(id: '1')),
        expect: () => [
          const ProblemLoading(),
          isA<ProblemDetailsLoaded>()
              .having((state) => state.problem.id, 'problem id', '1')
              .having((state) => state.problem.title, 'problem title', 'Single Problem'),
        ],
      );
    });
  });
}

// Helper method to create a QueryResult
extension on DateTime {
  String toIso8601String() {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}T${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}.000Z';
  }
}