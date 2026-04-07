import 'package:clean_framework/clean_framework.dart';

/// Exception thrown when an API call fails
class ApiException implements Exception {
  final String message;
  final RestResponseType responseType;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? details;

  ApiException({
    required this.message,
    required this.responseType,
    this.statusCode,
    this.errorCode,
    this.details,
  });

  factory ApiException.fromResponse(RestResponseType type, String message) {
    return ApiException(
      message: message,
      responseType: type,
      statusCode: _typeToStatusCode(type),
    );
  }

  static int? _typeToStatusCode(RestResponseType type) {
    switch (type) {
      case RestResponseType.success:
        return 200;
      case RestResponseType.badRequest:
        return 400;
      case RestResponseType.unauthorized:
        return 401;
      case RestResponseType.notFound:
        return 404;
      case RestResponseType.conflict:
        return 409;
      case RestResponseType.internalServerError:
        return 500;
      case RestResponseType.timeOut:
        return 408;
      case RestResponseType.unknown:
        return null;
    }
  }

  bool get isUnauthorized => responseType == RestResponseType.unauthorized;
  bool get isNotFound => responseType == RestResponseType.notFound;
  bool get isServerError => responseType == RestResponseType.internalServerError;
  bool get isTimeout => responseType == RestResponseType.timeOut;
  bool get isNetworkError => responseType == RestResponseType.unknown;

  @override
  String toString() => 'ApiException: $message (${statusCode ?? responseType})';
}

/// Exception for network connectivity issues
class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = 'No network connection']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception for authentication failures
class AuthException implements Exception {
  final String message;
  final String? errorCode;

  AuthException({
    required this.message,
    this.errorCode,
  });

  factory AuthException.invalidCredentials() {
    return AuthException(
      message: 'Invalid username or password',
      errorCode: 'AUTH_INVALID_CREDENTIALS',
    );
  }

  factory AuthException.sessionExpired() {
    return AuthException(
      message: 'Your session has expired. Please login again.',
      errorCode: 'AUTH_SESSION_EXPIRED',
    );
  }

  @override
  String toString() => 'AuthException: $message';
}
