import 'dart:async';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/foundation.dart';
import 'custom_api_exceptions.dart';
import 'logging_link.dart';

abstract class GraphQLBaseRepository {
  late GraphQLClient _client;
  
  GraphQLBaseRepository({
    required String endpoint,
    Link? link,
    GraphQLCache? cache,
    Future<String?> Function()? getToken,
  }) {
    _initializeClient(endpoint, link, cache, getToken);
  }

  void _initializeClient(
    String endpoint,
    Link? customLink,
    GraphQLCache? cache,
    Future<String?> Function()? getToken,
  ) {
    final HttpLink httpLink = HttpLink(endpoint);
    Link link = httpLink;

    if (getToken != null) {
      final AuthLink authLink = AuthLink(getToken: getToken);
      link = authLink.concat(link);
    }

    final ErrorLink errorLink = ErrorLink(
      onGraphQLError: (request, forward, response) {
        for (final error in response.errors ?? []) {
          _log('GraphQL Error: ${error.message}');
        }
        return null;
      },
      onException: (request, forward, exception) {
        _log('Network Exception: $exception');
        return null;
      },
    );

    link = LoggingLink().concat(link);
    link = errorLink.concat(link);

    if (customLink != null) {
      link = customLink.concat(link);
    }

    _client = GraphQLClient(
      cache: cache ?? GraphQLCache(),
      link: link,
    );
  }

  Future<T> query<T>(
    String queryString, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Duration? pollInterval,
    Context? context,
  }) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(queryString),
        variables: variables ?? {},
        fetchPolicy: fetchPolicy ?? FetchPolicy.networkOnly,
        errorPolicy: errorPolicy ?? ErrorPolicy.none,
        cacheRereadPolicy: cacheRereadPolicy,
        optimisticResult: optimisticResult,
        pollInterval: pollInterval,
        context: context,
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }

      return result.data as T;
    } catch (e, s) {
      throw CustomAPIException.onCatch(e, s);
    }
  }

  Future<T> mutate<T>(
    String mutationString, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Context? context,
    List<QueryOptions>? refetchQueries,
    FutureOr<void> Function(GraphQLDataProxy, QueryResult<Object?>?)? update,
  }) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(mutationString),
        variables: variables ?? {},
        fetchPolicy: fetchPolicy ?? FetchPolicy.networkOnly,
        errorPolicy: errorPolicy ?? ErrorPolicy.none,
        cacheRereadPolicy: cacheRereadPolicy,
        optimisticResult: optimisticResult,
        context: context,
        update: update,
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }

      return result.data as T;
    } catch (e, s) {
      throw CustomAPIException.onCatch(e, s);
    }
  }

  Stream<T> subscribe<T>(
    String subscriptionString, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Context? context,
  }) {
    final SubscriptionOptions options = SubscriptionOptions(
      document: gql(subscriptionString),
      variables: variables ?? {},
      fetchPolicy: fetchPolicy ?? FetchPolicy.networkOnly,
      errorPolicy: errorPolicy ?? ErrorPolicy.none,
      cacheRereadPolicy: cacheRereadPolicy,
      optimisticResult: optimisticResult,
      context: context,
    );

    return _client.subscribe(options).map((QueryResult result) {
      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }
      return result.data as T;
    });
  }

  Exception _handleGraphQLException(OperationException exception) {
    if (exception.linkException != null) {
      _log('Network error occurred: ${exception.linkException}');
      return CustomAPIException(message: 'Network error occurred');
    } else if (exception.graphqlErrors.isNotEmpty) {
      final error = exception.graphqlErrors.first;
      _log('GraphQL error: ${error.message}');
      if (error.extensions?['code'] == 'UNAUTHENTICATED') {
        return CustomAPIException(message: 'Authentication failed');
      } else {
        return CustomAPIException(message: error.message);
      }
    } else {
      _log('Unknown GraphQL error occurred');
      return CustomAPIException(message: 'Unknown GraphQL error occurred');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[GraphQLBaseRepository] $message');
    }
  }
}