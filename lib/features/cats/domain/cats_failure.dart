class CatsFailure implements Exception {
  CatsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
