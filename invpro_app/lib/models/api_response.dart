class ApiError {
  final String code;
  final String message;
  const ApiError({required this.code, required this.message});
  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
    code: json['code'] ?? 'UNKNOWN_ERROR',
    message: json['message'] ?? 'Error desconocido',
  );
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final ApiError? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : null,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'])
          : null,
    );
  }

  bool get hasError => !success || error != null;
  String get errorMessage => error?.message ?? 'Error desconocido';
}
