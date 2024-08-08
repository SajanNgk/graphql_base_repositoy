# GraphQL Repository

A flexible and easy-to-use GraphQL client repository for Flutter applications.

## Features

- Easy setup and configuration
- Support for queries, mutations, and subscriptions
- Built-in error handling and logging
- Customizable authentication

## Usage

```dart
import 'package:graphql_repository/graphql_repository.dart';

class MyRepository extends GraphQLBaseRepository {
  MyRepository() : super();

  Future<Map<String, dynamic>> getUser(String id) async {
    const query = '''
      query GetUser(\$id: ID!) {
        user(id: \$id) {
          id
          name
          email
        }
      }
    ''';

    final result = await query<Map<String, dynamic>>(
      query,
      variables: {'id': id},
    );

    return result['user'];
  }
}