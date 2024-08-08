import 'package:flutter_test/flutter_test.dart';
import 'package:graph_base_repo/graphql_repository.dart';

import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:graphql_flutter/graphql_flutter.dart';


// This will generate a MockGraphQLClient
@GenerateMocks([GraphQLClient])

import 'raphql_repository_test.mocks.dart';

class TestRepository extends GraphQLBaseRepository {
  TestRepository({required GraphQLClient client})
      : super(endpoint: 'https://graphql.anilist.co', link: client.link);
}

void main() {
  late MockGraphQLClient mockClient;
  late TestRepository repository;

  setUp(() {
    mockClient = MockGraphQLClient();
    repository = TestRepository(client: mockClient);
  });

  group('GraphQLBaseRepository', () {
    test('query should return data on success', () async {
      const testQuery = '''
        query TestQuery {
          test {
            id
            name
          }
        }
      ''';

      final expectedData = {
        'test': {'id': '1', 'name': 'Test Name'}
      };

      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            data: expectedData,
            options: QueryOptions(document: gql(testQuery)),
          ));

      final result = await repository.query(testQuery);

      expect(result, equals(expectedData));
    });

    test('query should throw CustomAPIException on GraphQL error', () async {
      const testQuery = '''
        query TestQuery {
          test {
            id
            name
          }
        }
      ''';

      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            exception: OperationException(
              graphqlErrors: [GraphQLError(message: 'Test GraphQL Error')],
            ),
            options: QueryOptions(document: gql(testQuery)),
          ));

      expect(
        () => repository.query(testQuery),
        throwsA(isA<CustomAPIException>().having(
          (e) => e.message,
          'message',
          'Test GraphQL Error',
        )),
      );
    });

    // Add more tests for mutation, subscription, error handling, etc.
  });
}