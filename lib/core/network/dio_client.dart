import 'dart:io';

import 'package:dio/dio.dart';
import '../error/exceptions.dart';

class DioClient {
  final Dio dio;
  final String baseUrl;
  final List<Interceptor> interceptors;

  DioClient({
    required this.dio,
    required this.baseUrl,
    required this.interceptors,
  }) {
    dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 30)
      ..options.receiveTimeout = const Duration(seconds: 30)
      ..options.responseType = ResponseType.json
      ..httpClientAdapter;

    if (interceptors.isNotEmpty) {
      dio.interceptors.addAll(interceptors);
    }
  }

  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await dio.get(
        uri,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<dynamic> post(
    String uri, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await dio.post(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<dynamic> put(
    String uri, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await dio.put(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<dynamic> delete(
    String uri, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.delete(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  void _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const FetchDataException(
          message: 'Connection timeout. Please try again later.',
        );
      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case 400:
            throw BadRequestException(
              message:
                  _extractErrorMessage(error.response?.data) ?? 'Bad request',
            );
          case 401:
            throw UnauthorizedException(
              message:
                  _extractErrorMessage(error.response?.data) ?? 'Unauthorized',
            );
          case 403:
            throw UnauthorizedException(
              message:
                  _extractErrorMessage(error.response?.data) ?? 'Forbidden',
            );
          case 404:
            throw NotFoundException(
              message:
                  _extractErrorMessage(error.response?.data) ??
                  'Resource not found',
            );
          case 500:
          case 502:
          case 503:
            throw ServerException(
              message:
                  _extractErrorMessage(error.response?.data) ?? 'Server error',
            );
          default:
            throw FetchDataException(
              message:
                  _extractErrorMessage(error.response?.data) ??
                  'Error occurred with status code: ${error.response?.statusCode}',
            );
        }
      case DioExceptionType.cancel:
        throw const RequestCancelledException(message: 'Request cancelled');
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          throw const NoInternetConnectionException(
            message:
                'No internet connection. Please check your network settings.',
          );
        }
        throw FetchDataException(
          message: error.error?.toString() ?? 'Unknown error occurred',
        );
      case DioExceptionType.badCertificate:
        throw const BadRequestException(message: 'Bad certificate');
      case DioExceptionType.connectionError:
        throw const NoInternetConnectionException(
          message: 'Connection error. Please check your network settings.',
        );
      }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    try {
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      } else if (data is Map && data.containsKey('error')) {
        if (data['error'] is String) {
          return data['error'].toString();
        } else if (data['error'] is Map &&
            data['error'].containsKey('message')) {
          return data['error']['message'].toString();
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
