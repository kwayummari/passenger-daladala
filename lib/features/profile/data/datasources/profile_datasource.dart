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

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['message'] ?? 'Invalid data provided');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized access');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile',
      );
    } catch (e) {
      throw Exception('Network error. Please try again.');
    }
  }
}
