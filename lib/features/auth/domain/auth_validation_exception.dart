class AuthValidationException implements Exception {
  AuthValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
