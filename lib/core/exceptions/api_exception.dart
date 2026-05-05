class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.error,
    required this.message,
    required this.path,
  });

  final int status;
  final String error;
  final String message;
  final String path;

  factory ApiException.fromJson(Map<String, dynamic> json, int statusCode) {
    return ApiException(
      status: statusCode,
      error: json['error'] as String? ?? '',
      message: json['message'] as String? ?? '',
      path: json['path'] as String? ?? '',
    );
  }

  @override
  String toString() => 'ApiException($status): $message';
}
