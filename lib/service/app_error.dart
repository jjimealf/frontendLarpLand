class AppError implements Exception {
  final String code;
  final String message;
  final Object? cause;

  const AppError({
    required this.code,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'AppError($code): $message';
}
