// This file contains the GraphQLClientConfiguration class, which is used to configure
// a GraphQL client for a specific API endpoint.

// Import necessary packages
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:graphql_repository/graphql_repository.dart';

// Define the GraphQLClientConfiguration class
// This class is responsible for configuring a GraphQL client.
class GraphQLClientConfiguration {
  // The GraphQL API endpoint URL
  final String endpoint;

  // A function that returns a future that resolves to an optional string representing
  // an authentication token. This function is used to obtain an authentication token
  // for authenticated requests.
  final Future<String?> Function()? getToken;

  // Constructor for the GraphQLClientConfiguration class
  // Takes in an endpoint URL and an optional getToken function.
  GraphQLClientConfiguration({
    required this.endpoint,
    this.getToken,
  });

  // Creates a GraphQL client based on the configuration.
  // This function creates a chain of links that represent the different parts of the
  // GraphQL client stack, such as the HTTP link, authentication link, logging link,
  // and error link.
  GraphQLClient createClient() {
    // Create an HTTP link using the endpoint URL
    final HttpLink httpLink = HttpLink(endpoint);

    // Create a link variable that starts with the HTTP link
    Link link = httpLink;

    // If a getToken function is provided, create an authentication link and add it to the link chain
    if (getToken != null) {
      final AuthLink authLink = AuthLink(
        // The getToken function is used to obtain an authentication token for the request
        getToken: () async {
          final token = await getToken!();
          // Ensure the token is prefixed with "Bearer "
          return token != null && token.isNotEmpty ? 'Bearer $token' : null;
        },
      );
      link = authLink.concat(link);
    }

    // Create a logging link and add it to the link chain. The logging link logs GraphQL requests and responses.
    final LoggingLink loggingLink = LoggingLink(
      // The shouldLog function determines whether the logging link should log requests and responses.
      // In debug mode or in release mode, the logging link logs requests and responses.
      shouldLog: () => kDebugMode || !kReleaseMode,
    );
    link = loggingLink.concat(link);

    // Create an error link and add it to the link chain. The error link handles GraphQL and network errors.
    final ErrorLink errorLink = ErrorLink(
      // The onGraphQLError function handles GraphQL errors. It logs the error and returns null.
      onGraphQLError: (request, forward, response) {
        _logError('GraphQL Error: ${response.errors}');
        return null;
      },
      // The onException function handles network errors. It logs the error and returns null.
      onException: (request, forward, exception) {
        _logError('Network Exception: ${exception.toString()}');
        return null;
      },
    );
    link = errorLink.concat(link);

    // Create a GraphQL client using the link chain and a cache.
    return GraphQLClient(
      cache: GraphQLCache(),
      link: link,
    );
  }

  // Logs an error message.
  // This function logs an error message using the print function.
  // It is only called in debug mode or in release mode.
  void _logError(String message) {
    if (kDebugMode) {
      print('[GraphQLClientConfiguration] $message');
    }
  }
}
