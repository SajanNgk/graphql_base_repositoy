class CustomAPIException implements Exception {
  final String message;
  final dynamic originalException;
  final StackTrace? stackTrace;

  CustomAPIException({
    required this.message,
    this.originalException,
    this.stackTrace,
  });

  static CustomAPIException onCatch(dynamic e, StackTrace s) {
    if (e is CustomAPIException) {
      return e;
    }
    return CustomAPIException(
      message: e.toString(),
      originalException: e,
      stackTrace: s,
    );
  }

  @override
  String toString() => message;
}