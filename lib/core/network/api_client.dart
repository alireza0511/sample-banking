import 'dart:convert';
import 'dart:developer' as developer;

import 'package:clean_framework/clean_framework.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

void _log(String message) {
  developer.log(message, name: 'ApiClient');
  // ignore: avoid_print
  print('[ApiClient] $message');
}

/// Custom REST API client for Kind Banking
/// Extends clean_framework's RestApi with JSON support and auth headers
class ApiClient extends RestApi<RestResponse<String>> {
  final String baseUrl;
  final http.Client _httpClient;

  String? _authToken;

  /// Headers to include in every request
  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _httpClient = httpClient ?? http.Client();

  /// Set the auth token for authenticated requests
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Clear the auth token (logout)
  void clearAuthToken() {
    _authToken = null;
  }

  /// Check if client has an auth token set
  bool get isAuthenticated => _authToken != null;

  @override
  Future<RestResponse<String>> request({
    required RestMethod method,
    required String path,
    Map<String, dynamic> requestBody = const {},
  }) async {
    final uri = _buildUri(path);
    _log('>>> ${method.name.toUpperCase()} $uri');
    _log('>>> Base URL: $baseUrl');

    try {
      http.Response response;
      final encodedBody = requestBody.isNotEmpty ? json.encode(requestBody) : null;

      switch (method) {
        case RestMethod.get:
          response = await _httpClient.get(uri, headers: _baseHeaders);
          break;
        case RestMethod.post:
          response = await _httpClient.post(
            uri,
            headers: _baseHeaders,
            body: encodedBody,
          );
          break;
        case RestMethod.put:
          response = await _httpClient.put(
            uri,
            headers: _baseHeaders,
            body: encodedBody,
          );
          break;
        case RestMethod.delete:
          response = await _httpClient.delete(uri, headers: _baseHeaders);
          break;
        case RestMethod.patch:
          response = await _httpClient.patch(
            uri,
            headers: _baseHeaders,
            body: encodedBody,
          );
          break;
      }

      _log('<<< Response ${response.statusCode}');
      _log('<<< Body: ${response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body}');

      return RestResponse<String>(
        type: getResponseTypeFromCode(response.statusCode),
        uri: uri,
        content: response.body,
      );
    } on http.ClientException catch (e) {
      _log('!!! ClientException: ${e.message}');
      return RestResponse<String>(
        type: RestResponseType.unknown,
        uri: uri,
        content: '{"error": "${e.message}"}',
      );
    } catch (e, stackTrace) {
      _log('!!! Exception: $e');
      _log('!!! Stack: $stackTrace');
      return RestResponse<String>(
        type: RestResponseType.unknown,
        uri: uri,
        content: '{"error": "Unknown error occurred: $e"}',
      );
    }
  }

  @override
  Future<RestResponse<String>> requestBinary({
    required RestMethod method,
    required String path,
    Map<String, dynamic> requestBody = const {},
  }) {
    return request(method: method, path: path, requestBody: requestBody);
  }

  Uri _buildUri(String path) {
    // If path already starts with http, use as-is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }

    // Remove leading slash if present to avoid double slashes
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Ensure base URL ends with slash
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

    return Uri.parse('$cleanBaseUrl$cleanPath');
  }
}

/// Convenience methods for common HTTP operations
extension ApiClientExtensions on ApiClient {
  /// GET request with automatic JSON decoding
  Future<ApiResponse<T>> get<T>(
    String path, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await request(method: RestMethod.get, path: path);
    return _parseResponse(response, fromJson);
  }

  /// POST request with automatic JSON encoding/decoding
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await request(
      method: RestMethod.post,
      path: path,
      requestBody: body ?? {},
    );
    return _parseResponse(response, fromJson);
  }

  /// PUT request with automatic JSON encoding/decoding
  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await request(
      method: RestMethod.put,
      path: path,
      requestBody: body ?? {},
    );
    return _parseResponse(response, fromJson);
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await request(method: RestMethod.delete, path: path);
    return _parseResponse(response, fromJson);
  }

  /// PATCH request with automatic JSON encoding/decoding
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await request(
      method: RestMethod.patch,
      path: path,
      requestBody: body ?? {},
    );
    return _parseResponse(response, fromJson);
  }

  ApiResponse<T> _parseResponse<T>(
    RestResponse<String> response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    if (response.type != RestResponseType.success) {
      return ApiResponse<T>.error(
        type: response.type,
        message: _extractErrorMessage(response.content),
        statusCode: _responseTypeToCode(response.type),
      );
    }

    try {
      final jsonData = json.decode(response.content) as Map<String, dynamic>;

      if (fromJson != null) {
        return ApiResponse<T>.success(fromJson(jsonData));
      }

      // Return raw JSON if no parser provided
      return ApiResponse<T>.success(jsonData as T);
    } catch (e) {
      return ApiResponse<T>.error(
        type: RestResponseType.unknown,
        message: 'Failed to parse response: $e',
      );
    }
  }

  String _extractErrorMessage(String content) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json['error']?['message'] ??
             json['message'] ??
             json['error'] ??
             'Unknown error';
    } catch (_) {
      return content.isNotEmpty ? content : 'Unknown error';
    }
  }

  int? _responseTypeToCode(RestResponseType type) {
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
}

/// Wrapper for API responses with success/error handling
class ApiResponse<T> {
  final T? data;
  final bool isSuccess;
  final RestResponseType? errorType;
  final String? errorMessage;
  final int? statusCode;

  ApiResponse._({
    this.data,
    required this.isSuccess,
    this.errorType,
    this.errorMessage,
    this.statusCode,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(data: data, isSuccess: true, statusCode: 200);
  }

  factory ApiResponse.error({
    required RestResponseType type,
    required String message,
    int? statusCode,
  }) {
    return ApiResponse._(
      isSuccess: false,
      errorType: type,
      errorMessage: message,
      statusCode: statusCode,
    );
  }

  /// Execute callback if success, return error otherwise
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String error, RestResponseType? type) onError,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    }
    return onError(errorMessage ?? 'Unknown error', errorType);
  }
}
