import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:geoapp/bloc/problem_bloc.dart';
import 'package:geoapp/bloc/problem_event.dart';
import 'package:geoapp/bloc/problem_state.dart';

import 'problem_bloc_pagination_test.mocks.dart';

@GenerateMocks([GraphQLClient])
void main() {
  group('ProblemBloc pagination', () {
    late MockGraphQLClient mockClient;
    late ProblemBloc bloc;

    setUp(() {
      mockClient = MockGraphQLClient();
      bloc = ProblemBloc(graphQLClient: mockClient);
    });

    tearDown(() async {
      await bloc.close();
    });

    blocTest<ProblemBloc, ProblemState>(
      'FetchProblems then LoadMoreProblems accumulates items',
      build: () {
        when(mockClient.query(any)).thenAnswer((invocation) async {
          final opts = invocation.positionalArguments.first as QueryOptions;
          final vars = opts.variables;
          final offset = vars['offset'] as int? ?? 0;
          if (offset == 0) {
            return QueryResult(
              options: opts,
              data: {
                'problems': [
                  {
                    'id': '1',
                    'title': 'A',
                    'description': 'd1',
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
                ],
                'problems_aggregated': [
                  {
                    'count': {'id': 2}
                  }
                ],
              },
              source: QueryResultSource.network,
            );
          } else {
            return QueryResult(
              options: opts,
              data: {
                'problems': [
                  {
                    'id': '2',
                    'title': 'B',
                    'description': 'd2',
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
              },
              source: QueryResultSource.network,
            );
          }
        });
        return bloc;
      },
      act: (b) async {
        b.add(const FetchProblems(start: 0, limit: 1));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        b.add(const LoadMoreProblems());
      },
      expect: () => [
        const ProblemLoading(),
        isA<ProblemLoaded>()
            .having((s) => s.problems.length, 'len', 1)
            .having((s) => s.hasMore, 'hasMore', true),
        isA<ProblemLoadingMore>(),
        isA<ProblemLoaded>()
            .having((s) => s.problems.length, 'len', 2)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
      verify: (_) {
        verify(mockClient.query(any)).called(greaterThanOrEqualTo(2));
      },
    );
  });
}
