// lib/features/profile/domain/repositories/profile_repository.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, User>> updateProfile(
    Map<String, dynamic> profileData, {
    File? profileImage,
  });
}
