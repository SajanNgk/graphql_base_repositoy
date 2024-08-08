import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_repository/graphql_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// This will generate a MockGraphQLClient and MockLink
@GenerateMocks([GraphQLClient, Link])
import 'raphql_repository_test.mocks.dart';

class TestRepository extends GraphQLBaseRepository {
  TestRepository({required GraphQLClient client})
      : super(
            endpoint: 'https://restronaut.hyperce.io/shop-api/',
            link: client.link);
}

void main() {
  late MockGraphQLClient mockClient;
  late MockLink mockLink;
  late TestRepository repository;

  setUp(() {
    mockClient = MockGraphQLClient();
    mockLink = MockLink();
    when(mockClient.link).thenReturn(mockLink);

    // Stubbing the concat method to return a mockLink when called
    when(mockLink.concat(any)).thenReturn(mockLink);

    // Stubbing the request method to return a specific response
    when(mockLink.request(any, any)).thenAnswer((_) {
      const response = Response(data: {
        'channels': {
          'items': [
            {'id': '2', 'code': 'Restro One', 'token': 'restro-one'},
            {'id': '3', 'code': 'Restro two', 'token': 'restro-two'}
          ]
        }
      }, response: {
        'headers': <String, String>{'content-type': 'application/json'}
      });
      return Stream.value(response);
    });

    repository = TestRepository(client: mockClient);
  });

  group('GraphQLBaseRepository', () {
    test('query should return data on success', () async {
      const testQuery = '''
        query Channels {
          channels {
            items {
              id
              code
              token
            }
          }
        }
      ''';

      final expectedData = {
        'data': {
          'channels': {
            'items': [
              {'id': '2', 'code': 'Restro One', 'token': 'restro-one'},
              {'id': '3', 'code': 'Restro two', 'token': 'restro-two'}
            ]
          }
        }
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
              graphqlErrors: [
                const GraphQLError(message: 'Test GraphQL Error')
              ],
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
