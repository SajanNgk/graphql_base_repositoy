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

  // Configure GraphQLClient
    final graphQLClientConfig = GraphQLClientConfiguration(
      endpoint: 'https://your-graphql-endpoint.com/graphql',
      getToken: () async {
        // Fetch token logic, e.g., from secure storage
        return 'your-auth-token';
      },
    );

    final client = graphQLClientConfig.createClient();

    // Wrap the app with GraphQLProvider
    return GraphQLProvider(
      client: ValueNotifier<GraphQLClient>(client),
      child: MaterialApp(
        title: 'Your App Title',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(),
      ),
    );





class MyRepository extends GraphQLBaseRepository {
  MyRepository(GraphQLClientConfiguration config) : super(config);

  // Method to fetch a user by ID
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

    final result = await performQuery<Map<String, dynamic>>(
      query,
      variables: {'id': id},
    );

    return result['user'];
  }

  // Method to update user information
  Future<Map<String, dynamic>> updateUser(String id, String name, String email) async {
    const mutation = '''
      mutation UpdateUser(\$id: ID!, \$name: String!, \$email: String!) {
        updateUser(id: \$id, name: \$name, email: \$email) {
          id
          name
          email
        }
      }
    ''';

    final result = await performMutation<Map<String, dynamic>>(
      mutation,
      variables: {'id': id, 'name': name, 'email': email},
    );

    return result['updateUser'];
  }

  // Method to subscribe to user updates
  Stream<Map<String, dynamic>> userUpdates(String id) {
    const subscription = '''
      subscription OnUserUpdated(\$id: ID!) {
        userUpdated(id: \$id) {
          id
          name
          email
        }
      }
    ''';

    return performSubscription<Map<String, dynamic>>(
      subscription,
      variables: {'id': id},
    );
  }
}

```

// Extract headers from the response context
result = response.data!['something'];
final HttpLinkResponseContext? responseContext =
result.context.entry<HttpLinkResponseContext>();
final Map<String, String?> responseHeaders = responseContext?.headers ?? {};
