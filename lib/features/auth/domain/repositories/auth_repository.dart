import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Logs in a user with the given credentials
  Future<Either<Failure, User>> login({
    required String phone,
    required String password,
    required bool rememberMe,
  });
  
  /// Registers a new user with the given information
  Future<Either<Failure, User>> register({
    required String phone,
    required String email,
    required String password,
  });
  
  /// Logs out the current user
  Future<Either<Failure, void>> logout();
  
  /// Checks if a user is currently logged in
  Future<Either<Failure, User>> checkAuthStatus();
  
  /// Requests a password reset for the given phone number
  Future<Either<Failure, void>> requestPasswordReset({
    required String phone,
  });
  
  /// Resets the password with the given token and new password
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String password,
  });

  Future<Either<Failure, User>> verifyAccount({
    required String identifier,
    required String code,
  });
  Future<Either<Failure, void>> resendVerificationCode({
    required String identifier,
  });
  Future<Either<Failure, User>> getCurrentUser();
}