import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:geoapp/bloc/problem_bloc.dart';
import 'package:geoapp/bloc/problem_event.dart';
import 'package:geoapp/bloc/problem_state.dart';
import 'package:geoapp/models/problem.dart';

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
        'problems': [
          {
            'id': '1',
            'title': 'Test Problem 1',
            'description': 'Description 1',
            'difficulty': 'beginner',
            'category': 'geometry',
            'geometry_data': null,
            'solution': null,
            'scalar_constraints': null,
            'object_constraints': null,
            'scalar_proof': null,
            'object_proof': null,
            'thumbnail': null,
            'date_created': '2025-10-04T10:00:00.000Z',
            'date_updated': '2025-10-04T10:00:00.000Z',
          },
          {
            'id': '2',
            'title': 'Test Problem 2',
            'description': 'Description 2',
            'difficulty': 'intermediate',
            'category': 'algebra',
            'geometry_data': null,
            'solution': null,
            'scalar_constraints': null,
            'object_constraints': null,
            'scalar_proof': null,
            'object_proof': null,
            'thumbnail': null,
            'date_created': '2025-10-04T10:00:00.000Z',
            'date_updated': '2025-10-04T10:00:00.000Z',
          },
        ],
        'problems_aggregated': [
          {
            'count': {'id': 2}
          }
        ],
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
        'create_problems_item': {
          'id': '3',
          'title': 'New Problem',
          'description': 'New Description',
          'difficulty': 'advanced',
          'category': 'proofs',
          'geometry_data': null,
          'solution': null,
          'scalar_constraints': null,
          'object_constraints': null,
          'scalar_proof': null,
          'object_proof': null,
          'thumbnail': null,
          'date_created': '2025-10-04T12:00:00.000Z',
          'date_updated': '2025-10-04T12:00:00.000Z',
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
          status: ProblemStatus.draft,
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
          status: ProblemStatus.draft,
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

    // Skipping UpdateProblem test due to direct HTTP patch in Directus mode,
    // which isn't injectable/mocked here without refactoring the bloc.

    group('DeleteProblem', () {
      final mockDeleteResponse = {
        'delete_problems_item': {'id': '1'},
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
          return ProblemLoaded(problems: [
            Problem(
              id: '1',
              title: 'Problem to Delete',
              description: 'Description',
              difficulty: ProblemDifficulty.beginner,
              category: ProblemCategory.geometry,
              status: ProblemStatus.published,
              createdAt: DateTime.parse('2025-10-04T10:00:00.000Z'),
              updatedAt: DateTime.parse('2025-10-04T10:00:00.000Z'),
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
        'problems_by_id': {
          'id': '1',
          'title': 'Single Problem',
          'description': 'Single Description',
          'difficulty': 'intermediate',
          'category': 'trigonometry',
          'status': 'published',
          'geometry_data': null,
          'solution': null,
          'scalar_constraints': null,
          'object_constraints': null,
          'scalar_proof': null,
          'object_proof': null,
          'thumbnail': null,
          'date_created': '2025-10-04T10:00:00.000Z',
          'date_updated': '2025-10-04T10:00:00.000Z',
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