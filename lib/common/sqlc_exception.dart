class SqlcException implements Exception {
  final String message;
  final Object? originalError;
  const SqlcException(this.message, [this.originalError]);

  @override
  String toString() => 'SqlcException: $message ${originalError != null ? "($originalError)" : ""}';
}
