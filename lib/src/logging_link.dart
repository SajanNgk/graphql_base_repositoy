import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/foundation.dart';

class LoggingLink extends Link {
  final bool Function()? shouldLog;

  LoggingLink({this.shouldLog});

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    if (shouldLog == null || shouldLog!()) {
      final operation = request.operation;
      final variables = request.variables;

      _log('GraphQL Request:');
      _log('Operation: ${operation.operationName}');
      _log('Query: ${operation.document}');
      _log('Variables: $variables');

      final timestamp = DateTime.now();
      await Future.delayed(Duration.zero);
      final stream = forward!(request);

      await for (final response in stream) {
        final requestDuration = DateTime.now().difference(timestamp);
        _log('GraphQL Response (${requestDuration.inMilliseconds}ms):');
        if (response.data != null) _log('Data: ${response.data}');
        if (response.errors != null) _log('Errors: ${response.errors}');

        yield response;
      }
    } else {
      yield* forward!(request);
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[GraphQL] $message');
    }
  }
}