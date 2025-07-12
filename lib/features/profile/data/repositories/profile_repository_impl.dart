// lib/features/profile/data/repositories/profile_repository_impl.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;
  final NetworkInfo networkInfo;

  ProfileRepositoryImpl({required this.dataSource, required this.networkInfo});

  @override
  Future<Either<Failure, User>> updateProfile(
    Map<String, dynamic> profileData, {
    File? profileImage,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await dataSource.updateProfile(
          profileData,
          profileImage: profileImage,
        );
        return Right(user);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
