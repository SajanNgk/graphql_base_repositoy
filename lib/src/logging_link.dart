import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/foundation.dart';

/// A class that extends the Link class from the graphql_flutter package.
///
/// This class is used to log GraphQL requests and responses.
class LoggingLink extends Link {
  // Function that determines whether the logging link should log requests and responses.
  final bool Function()? shouldLog;

  /// Constructs a new instance of the LoggingLink class.
  ///
  /// The [shouldLog] parameter is an optional function that determines whether the logging link should log requests and responses.
  LoggingLink({this.shouldLog});

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    // If the logging link should log requests and responses, or if no function is provided to determine whether to log,
    // log the GraphQL request information.
    if (shouldLog == null || shouldLog!()) {
      final operation =
          request.operation; // Get the GraphQL operation from the request.
      final variables =
          request.variables; // Get the variables from the request.

      _log('GraphQL Request:'); // Log that a GraphQL request is being made.
      _log(
          'Operation: ${operation.operationName}'); // Log the name of the GraphQL operation.
      _log('Query: ${operation.document}'); // Log the GraphQL query.
      _log('Variables: $variables'); // Log the variables.

      final timestamp = DateTime.now(); // Get the current timestamp.
      await Future.delayed(Duration.zero); // Delay for a short period of time.
      final stream = forward!(
          request); // Get the response stream from the next link in the link chain.

      await for (final response in stream) {
        // Iterate over the response stream.
        final requestDuration = DateTime.now()
            .difference(timestamp); // Get the duration of the request.
        _log(
            'GraphQL Response (${requestDuration.inMilliseconds}ms):'); // Log that a GraphQL response has been received.
        if (response.data != null) {
          _log('Data: ${response.data}'); // Log the data from the response.
        }
        if (response.errors != null) {
          _log(
              'Errors: ${response.errors}'); // Log any errors from the response.
        }

        yield response; // Yield the response to the next link in the link chain.
      }
    } else {
      // If the logging link should not log requests and responses, or if no function is provided to determine whether to log,
      // pass the request to the next link in the link chain.
      yield* forward!(request);
    }
  }

  /// Logs the provided message if the app is in debug mode.
  ///
  /// The message is logged to the console with a prefix of "[GraphQL]".
  void _log(String message) {
    if (kDebugMode) {
      print('[GraphQL] $message');
    }
  }
}
