import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart'; // Import the GraphQL Flutter package
import 'package:flutter/foundation.dart'; // Import the Flutter foundation package

import 'custom_api_exceptions.dart'; // Import custom API exceptions
import 'graphql_client_configuration.dart'; // Import GraphQL client configuration

// Define an abstract base repository class for GraphQL operations
abstract class GraphQLBaseRepository {
  late GraphQLClient _client; // Declare a private GraphQL client variable

  // Constructor accepting client configuration and storage
  GraphQLBaseRepository(GraphQLClientConfiguration config) {
    // Initialize the GraphQL client with the provided configuration
    _initializeClient(config.createClient());
  }

  // Private method to initialize the GraphQL client
  void _initializeClient(GraphQLClient client) {
    _client =
        client; // Assign the provided client to the private client variable
  }

  // Generic query method
  Future<T> performQuery<T>(
    String queryString, {
    Map<String, dynamic>? variables,
    Map<String, String>? headers, // Query variables
    FetchPolicy? fetchPolicy, // Fetch policy
    ErrorPolicy? errorPolicy, // Error policy
    CacheRereadPolicy? cacheRereadPolicy, // Cache reread policy
    Object? optimisticResult, // Optimistic result
    Duration? pollInterval, // Poll interval
    Context? context, // Context
  }) async {
    try {
      // Create query options with the provided parameters
      final QueryOptions options = QueryOptions(
        document: gql(queryString),
        variables: variables ?? {},
        fetchPolicy: fetchPolicy ?? FetchPolicy.networkOnly,
        errorPolicy: errorPolicy ?? ErrorPolicy.none,
        cacheRereadPolicy: cacheRereadPolicy,
        optimisticResult: optimisticResult,
        pollInterval: pollInterval,
        context: (context ?? const Context()).withEntry(
          HttpLinkHeaders(headers: headers ?? {}),
        ),
      );

      // Execute the query and get the result
      final QueryResult result = await _client.query(options);

      // Handle exceptions if any
      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }

      // Return the data from the result
      return result.data as T;
    } catch (e, s) {
      // Log any errors that occur during the query
      _logError(e, s);
      throw CustomAPIException.onCatch(e, s);
    }
  }

  // Generic mutation method
  Future<T> performMutation<T>(
    String mutationString, {
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
    // Mutation variables
    FetchPolicy? fetchPolicy, // Fetch policy
    ErrorPolicy? errorPolicy, // Error policy
    CacheRereadPolicy? cacheRereadPolicy, // Cache reread policy
    Object? optimisticResult, // Optimistic result
    Context? context, // Context
    List<QueryOptions>? refetchQueries, // Refetch queries
    FutureOr<void> Function(GraphQLDataProxy, QueryResult<Object?>?)?
        update, // Update function
  }) async {
    try {
      // Create mutation options with the provided parameters
      final MutationOptions options = MutationOptions(
        document: gql(mutationString),
        variables: variables ?? {},
        fetchPolicy: fetchPolicy ?? FetchPolicy.networkOnly,
        errorPolicy: errorPolicy ?? ErrorPolicy.none,
        cacheRereadPolicy: cacheRereadPolicy,
        optimisticResult: optimisticResult,
        context: (context ?? const Context()).withEntry(
          HttpLinkHeaders(headers: headers ?? {}),
        ),
        update: update,
      );

      // Execute the mutation and get the result
      final QueryResult result = await _client.mutate(options);

      // Handle exceptions if any
      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }

      // Return the data from the result
      return result.data as T;
    } catch (e, s) {
      // Log any errors that occur during the mutation
      _logError(e, s);
      throw CustomAPIException.onCatch(e, s);
    }
  }

  // Generic subscription method
  Stream<T> performSubscribtion<T>(
    String subscriptionString, {
    Map<String, dynamic>? variables, // Subscription variables
    Map<String, String>? headers,
    FetchPolicy? fetchPolicy, // Fetch policy
    ErrorPolicy? errorPolicy, // Error policy
    CacheRereadPolicy? cacheRereadPolicy, // Cache reread policy
    Object? optimisticResult, // Optimistic result
    Context? context, // Context
  }) {
    // Create subscription options with the provided parameters
    final SubscriptionOptions options = SubscriptionOptions(
      document: gql(subscriptionString),
      variables: variables ?? {},
      fetchPolicy: fetchPolicy ?? FetchPolicy.networkOnly,
      errorPolicy: errorPolicy ?? ErrorPolicy.none,
      cacheRereadPolicy: cacheRereadPolicy,
      optimisticResult: optimisticResult,
      context: (context ?? const Context()).withEntry(
        HttpLinkHeaders(headers: headers ?? {}),
      ),
    );

    // Return the subscription stream
    return _client.subscribe(options).map((QueryResult result) {
      // Handle exceptions if any
      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }
      // Return the data from the result
      return result.data as T;
    });
  }

  // Handle GraphQL exceptions with more detailed messages
  Exception _handleGraphQLException(OperationException exception) {
    if (exception.linkException != null) {
      // Log network errors
      _log('Network error occurred: ${exception.linkException}');
      return CustomAPIException(message: 'Network error occurred');
    } else if (exception.graphqlErrors.isNotEmpty) {
      // Handle GraphQL errors
      final error = exception.graphqlErrors.first;
      _log('GraphQL error: ${error.message}');
      if (error.extensions?['code'] == 'UNAUTHENTICATED') {
        // Handle authentication errors
        return CustomAPIException(message: 'Authentication failed');
      } else {
        // Handle other GraphQL errors
        return CustomAPIException(message: error.message);
      }
    } else {
      // Handle unknown errors
      _log('Unknown GraphQL error occurred');
      return CustomAPIException(message: 'Unknown GraphQL error occurred');
    }
  }

  // Log messages if in debug mode
  void _log(String message) {
    if (kDebugMode) {
      print('[GraphQLBaseRepository] $message');
    }
  }

  // Log errors with stack traces if in debug mode
  void _logError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('[GraphQLBaseRepository] Error: $error');
      print('[GraphQLBaseRepository] StackTrace: $stackTrace');
    }
  }
}
