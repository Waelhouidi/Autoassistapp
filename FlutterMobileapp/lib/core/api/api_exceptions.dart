/// API Exceptions
/// Custom exceptions with user-friendly messages
class ApiException implements Exception {
  final String message;
  final String? userMessage;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.userMessage,
    this.statusCode,
    this.data,
  });

  /// Get user-friendly message for display
  String get displayMessage => userMessage ?? message;

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Network connection error
class NetworkException extends ApiException {
  NetworkException({String? message})
      : super(
          message: message ?? 'Network connection failed',
          userMessage:
              'Unable to connect to the server. Please check your internet connection and try again.',
          statusCode: null,
        );
}

/// Server error (5xx)
class ServerException extends ApiException {
  ServerException({String? message, int? statusCode})
      : super(
          message: message ?? 'Server error occurred',
          userMessage:
              'Something went wrong on our end. Please try again later.',
          statusCode: statusCode,
        );
}

/// Authentication error (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException({String? message})
      : super(
          message: message ?? 'Unauthorized',
          userMessage: 'Your session has expired. Please log in again.',
          statusCode: 401,
        );
}

/// Forbidden error (403)
class ForbiddenException extends ApiException {
  ForbiddenException({String? message})
      : super(
          message: message ?? 'Forbidden',
          userMessage: 'You don\'t have permission to access this resource.',
          statusCode: 403,
        );
}

/// Not found error (404)
class NotFoundException extends ApiException {
  NotFoundException({String? message})
      : super(
          message: message ?? 'Resource not found',
          userMessage: 'The requested item could not be found.',
          statusCode: 404,
        );
}

/// Validation error (400)
class ValidationException extends ApiException {
  final List<ValidationError>? errors;

  ValidationException({String? message, this.errors})
      : super(
          message: message ?? 'Validation failed',
          userMessage: message ?? 'Please check your input and try again.',
          statusCode: 400,
        );
}

/// Single validation error
class ValidationError {
  final String field;
  final String message;

  ValidationError({required this.field, required this.message});

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

/// Timeout error
class TimeoutException extends ApiException {
  TimeoutException()
      : super(
          message: 'Request timed out',
          userMessage: 'The request took too long. Please try again.',
          statusCode: null,
        );
}
