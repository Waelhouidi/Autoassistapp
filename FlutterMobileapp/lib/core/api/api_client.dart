import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exceptions.dart';

/// API Client
/// Centralized HTTP client with error handling
class ApiClient {
  static String? _authToken;

  /// Set authentication token
  static void setToken(String? token) {
    _authToken = token;
  }

  /// Get current token
  static String? get token => _authToken;

  /// Clear token (logout)
  static void clearToken() {
    _authToken = null;
  }

  /// GET request
  static Future<ApiResponse> get(String endpoint) async {
    return _request('GET', endpoint);
  }

  /// POST request
  static Future<ApiResponse> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    return _request('POST', endpoint, body: body);
  }

  /// PUT request
  static Future<ApiResponse> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    return _request('PUT', endpoint, body: body);
  }

  /// PATCH request
  static Future<ApiResponse> patch(String endpoint,
      {Map<String, dynamic>? body}) async {
    return _request('PATCH', endpoint, body: body);
  }

  /// DELETE request
  static Future<ApiResponse> delete(String endpoint) async {
    return _request('DELETE', endpoint);
  }

  /// Make HTTP request with error handling
  static Future<ApiResponse> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final headers = ApiConfig.getHeaders(token: _authToken);

    try {
      http.Response response;

      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(ApiConfig.connectionTimeout);
          break;
        case 'POST':
          response = await http
              .post(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(ApiConfig.connectionTimeout);
          break;
        case 'PUT':
          response = await http
              .put(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(ApiConfig.connectionTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(ApiConfig.connectionTimeout);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(ApiConfig.connectionTimeout);
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method');
      }

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutException();
    } on http.ClientException {
      throw NetworkException(message: 'Connection failed');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
        userMessage: 'Error: ${e.toString()}',
      );
    }
  }

  /// Handle HTTP response
  static ApiResponse _handleResponse(http.Response response) {
    dynamic data;

    try {
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }
    } catch (_) {
      data = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        success: true,
        data: data is Map ? data['data'] : data,
        message: data is Map ? data['message'] : null,
        statusCode: response.statusCode,
      );
    }

    // Handle error responses
    final message = data is Map ? data['message'] : 'Request failed';

    switch (response.statusCode) {
      case 400:
        List<ValidationError>? errors;
        if (data is Map && data['errors'] is List) {
          errors = (data['errors'] as List)
              .map((e) => ValidationError.fromJson(e))
              .toList();
        }
        throw ValidationException(message: message, errors: errors);
      case 401:
        throw UnauthorizedException(message: message);
      case 403:
        throw ForbiddenException(message: message);
      case 404:
        throw NotFoundException(message: message);
      case 500:
      case 502:
      case 503:
        throw ServerException(
            message: message, statusCode: response.statusCode);
      default:
        throw ApiException(
          message: message,
          userMessage: message,
          statusCode: response.statusCode,
          data: data,
        );
    }
  }
}

/// API Response wrapper
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });
}
