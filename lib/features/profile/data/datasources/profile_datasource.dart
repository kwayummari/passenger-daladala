// lib/features/profile/data/datasources/profile_datasource.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/data/models/user_model.dart';

abstract class ProfileDataSource {
  Future<UserModel> updateProfile(
    Map<String, dynamic> profileData, {
    File? profileImage,
  });
}

class ProfileDataSourceImpl implements ProfileDataSource {
  final ApiClient apiClient;

  ProfileDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> updateProfile(
    Map<String, dynamic> profileData, {
    File? profileImage,
  }) async {
    try {
      String? imageUrl;

      // Upload profile image first if provided
      if (profileImage != null) {
        final formData = FormData.fromMap({
          'avatar': await MultipartFile.fromFile(profileImage.path),
        });

        final imageResponse = await apiClient.dio.post(
          '${AppConstants.userEndpoint}/upload-avatar',
          data: formData,
        );

        if (imageResponse.statusCode == 200 &&
            imageResponse.data['status'] == 'success') {
          imageUrl = imageResponse.data['data']['profile_picture'];
        }
      }

      // Update profile data
      if (imageUrl != null) {
        profileData['profile_picture'] = imageUrl;
      }

      final response = await apiClient.dio.put(
        '${AppConstants.userEndpoint}/profile',
        data: profileData,
      );

      print('Update Profile Response: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(_extractErrorMessage(e.response?.data['message']));
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized access');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile',
      );
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Network error. Please try again.');
    }
  }

  String _extractErrorMessage(dynamic message) {
    if (message is String) return message;

    if (message is Map) {
      try {
        final firstKey = message.keys.first;
        final firstValue = message[firstKey];
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        return firstValue.toString();
      } catch (_) {
        return message.toString();
      }
    }

    return 'Unknown error occurred';
  }
}
