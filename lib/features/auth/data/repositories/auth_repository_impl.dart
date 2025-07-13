import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;
  final NetworkInfo networkInfo;
  final SecureStorage secureStorage;
  final LocalStorage localStorage;

  AuthRepositoryImpl({
    required this.dataSource,
    required this.networkInfo,
    required this.secureStorage,
    required this.localStorage,
  });

  @override
  Future<Either<Failure, User>> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await dataSource.login(
          identifier: identifier,
          password: password,
        );

        // Save auth token
        if (userModel.accessToken != null) {
          await secureStorage.saveAuthToken(userModel.accessToken!);
        }

        // Save user data
        if (rememberMe) {
          await localStorage.saveObject(
            AppConstants.keyAuthUser,
            userModel.toJson(),
          );
        }

        return Right(userModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on UnauthorizedException catch (e) {
        return Left(
          AuthenticationFailure(message: e.message ?? 'Authentication error'),
        );
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String phone,
    required String email,
    required String password,
    required String national_id,
    required String role,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await dataSource.register(
          phone: phone,
          email: email,
          password: password,
          national_id: national_id,
          role: role,
        );

        // Save auth token
        if (userModel.accessToken != null) {
          await secureStorage.saveAuthToken(userModel.accessToken!);
        }

        // Save user data
        await localStorage.saveObject(
          AppConstants.keyAuthUser,
          userModel.toJson(),
        );

        return Right(userModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on BadRequestException catch (e) {
        return Left(InputFailure(message: e.message ?? 'Invalid input'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Clear auth token
      await secureStorage.deleteAuthToken();

      // Clear user data
      await localStorage.removeKey(AppConstants.keyAuthUser);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> checkAuthStatus() async {
    try {
      // Check if token exists
      final token = await secureStorage.getAuthToken();
      if (token == null || token.isEmpty) {
        return Left(AuthenticationFailure(message: 'No authenticated user'));
      }

      // Get user data from local storage
      final userData = await localStorage.getObject(AppConstants.keyAuthUser);
      if (userData == null) {
        return Left(AuthenticationFailure(message: 'User data not found'));
      }

      final userModel = UserModel.fromJson(userData);

      return Right(userModel);
    } catch (e) {
      return Left(AuthenticationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> requestPasswordReset({
    required String phone,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.requestPasswordReset(phone: phone);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'User not found'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.resetPassword(token: token, password: password);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on BadRequestException catch (e) {
        return Left(InputFailure(message: e.message ?? 'Invalid token'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> verifyAccount({
    required String identifier,
    required String code,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await dataSource.verifyAccount(
          identifier: identifier,
          code: code,
        );

        // Save auth token if available
        if (userModel.accessToken != null) {
          await secureStorage.saveAuthToken(userModel.accessToken!);
        }

        // Save user data
        await localStorage.saveObject(
          AppConstants.keyAuthUser,
          userModel.toJson(),
        );

        return Right(userModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Verification failed'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> resendVerificationCode({
    required String identifier,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.resendVerificationCode(identifier: identifier);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message ?? 'Failed to resend code'),
        );
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    if (await networkInfo.isConnected) {
      try {
        // Call the backend getCurrentUser endpoint
        final userModel = await dataSource.getCurrentUser();

        // Save updated user data locally
        await localStorage.saveObject(
          AppConstants.keyAuthUser,
          userModel!.toJson(),
        );

        return Right(userModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on UnauthorizedException catch (e) {
        return Left(
          AuthenticationFailure(message: e.message ?? 'Authentication error'),
        );
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      // If no network, try to get from local storage
      try {
        final userData = await localStorage.getObject(AppConstants.keyAuthUser);
        if (userData == null) {
          return Left(AuthenticationFailure(message: 'User data not found'));
        }

        final userModel = UserModel.fromJson(userData);
        return Right(userModel);
      } catch (e) {
        return Left(AuthenticationFailure(message: e.toString()));
      }
    }
  }
}
