import 'package:daladala_smart_app/core/error/exceptions.dart';
import 'package:daladala_smart_app/core/error/failures.dart';
import 'package:daladala_smart_app/core/network/api_client.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/utils/constants.dart';
import '../models/user_model.dart';

abstract class AuthDataSource {
  Future<UserModel> login({
    required String identifier,
    required String password,
  });

  Future<UserModel> register({
    required String phone,
    required String email,
    required String password,
    required String national_id,
    required String role,
  });

  Future<void> logout();
  Future<UserModel?> getCurrentUser();

  Future<void> requestPasswordReset({required String phone});
  Future<void> resetPassword({required String token, required String password});

  Future<Either<Failure, void>> resendVerificationCode({
    required String identifier,
  });

  Future<UserModel> verifyAccount({
    required String identifier,
    required String code,
  });
}

class AuthDataSourceImpl implements AuthDataSource {
  final ApiClient apiClient;

  AuthDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.authEndpoint}/login',
        data: {'identifier': identifier, 'password': password},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final userData = response.data['data'];

        // Store the token
        await apiClient.setAuthToken(userData['accessToken']);

        return UserModel.fromJson(userData);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['message'] ?? 'Login failed',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: 'Invalid phone number or password',
        );
      } else if (e.response?.statusCode == 403) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: 'Account is not active',
        );
      }
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        message: e.response?.data['message'] ?? 'Login failed',
      );
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '${AppConstants.authEndpoint}/login',
        ),
        message: 'Network error. Please try again.',
      );
    }
  }

  @override
  Future<UserModel> register({
    required String phone,
    required String email,
    required String password,
    required String national_id,
    required String role,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.authEndpoint}/register',
        data: {
          'phone': phone,
          'email': email,
          'password': password,
          'national_id': national_id,
          'role': role,
        },
      );

      if (response.statusCode == 201 && response.data['status'] == 'success') {
        // Don't auto-login, just return user data from registration response
        final userData = response.data['data'];

        return UserModel(
          id: userData['user_id'].toString(),
          firstName: '', // Will be updated in profile later
          lastName: '', // Will be updated in profile later
          phone: userData['phone'],
          email: userData['email'],
          role: 'passenger',
          isVerified: false, // User needs to verify first
        );
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['message'] ?? 'Registration failed',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data['message'] ?? 'Registration failed';
        if (errorMessage.contains('Phone number is already registered')) {
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            message: 'This phone number is already registered',
          );
        }
        if (e.response?.data['errors'] != null) {
          final errors = e.response!.data['errors'] as List;
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            message: errors.first['msg'] ?? 'Validation error',
          );
        }
      }
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        message: e.response?.data['message'] ?? 'Registration failed',
      );
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '${AppConstants.authEndpoint}/register',
        ),
        message: 'Network error. Please try again.',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Clear the stored token
      await apiClient.clearAuthToken();

      // Call logout endpoint (optional - for server-side token invalidation)
      await apiClient.dio.post('${AppConstants.authEndpoint}/logout');
    } catch (e) {
      // Even if API call fails, clear local token
      await apiClient.clearAuthToken();
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.dio.get('/users/current');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final userData = response.data['data'];

        return UserModel(
          id: userData['id'].toString(),
          firstName: userData['first_name'] ?? '',
          lastName: userData['last_name'] ?? '',
          phone: userData['phone'],
          email: userData['email'],
          profilePicture: userData['profile_picture'],
          role: userData['role'] ?? 'passenger',
          isVerified: userData['is_verified'] ?? false,
          // Don't include accessToken in getCurrentUser response
        );
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['message'] ?? 'Failed to get current user',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: 'Authentication required',
        );
      }
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        message: e.response?.data['message'] ?? 'Failed to get current user',
      );
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '/users/current'),
        message: 'Network error. Please try again.',
      );
    }
  }

  Future<void> requestPasswordReset({required String phone}) async {
    try {
      await apiClient.dio.post(
        '${AppConstants.authEndpoint}/request-reset',
        data: {'phone': phone},
      );
    } catch (e) {
      throw ServerException(message: 'Failed to request password reset');
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await apiClient.dio.post(
        '${AppConstants.authEndpoint}/reset-password',
        data: {'token': token, 'new_password': password},
      );
    } catch (e) {
      throw ServerException(message: 'Failed to reset password');
    }
  }

  @override
  Future<UserModel> verifyAccount({
    required String identifier,
    required String code,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/verify',
        data: {'identifier': identifier, 'code': code},
      );

      if (response.data['status'] == 'success') {
        final userData = response.data['data'];
        return UserModel.fromJson(
          userData['user'],
        ).copyWith(accessToken: userData['accessToken']);
      } else {
        throw ServerException(message: response.data['message']);
      }
    } catch (e) {
      rethrow; // Let repository handle the Either wrapping
    }
  }

  @override
  Future<Either<Failure, void>> resendVerificationCode({
    required String identifier,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/resend-code',
        data: {'identifier': identifier},
      );

      if (response.data['status'] != 'success') {
        return Left(ServerFailure(message: response.data['message']));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to resend verification code'));
    }
  }
}
