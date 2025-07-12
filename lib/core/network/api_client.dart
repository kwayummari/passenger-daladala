// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  late final Dio dio;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  ApiClient() {
    dio = Dio();
    _initializeDio();
  }

  void _initializeDio() {
    // Base URL from environment
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

    dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add request interceptor to include auth token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAuthToken();
          if (token != null) {
            options.headers['x-access-token'] = token;
            // Also support Authorization header format
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle token expiration
          if (error.response?.statusCode == 401) {
            await clearAuthToken();
            // You might want to redirect to login here
          }
          handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    if (dotenv.env['APP_ENV'] == 'development') {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
        ),
      );
    }
  }

  // Auth token management
  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> setAuthToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      // Handle storage error
    }
  }

  Future<void> clearAuthToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      // Handle storage error
    }
  }

  Future<bool> hasValidToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}

// Create a singleton instance
final apiClient = ApiClient();
