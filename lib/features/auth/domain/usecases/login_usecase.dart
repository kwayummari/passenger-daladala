import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<Either<Failure, User>> call(LoginParams params) async {
    return await repository.login(
      identifier: params.identifier,
      password: params.password,
      rememberMe: params.rememberMe,
    );
  }

  Future<Either<Failure, User>> checkAuthStatus(
    CheckAuthStatusParams params,
  ) async {
    return await repository.checkAuthStatus();
  }
}

class LoginParams {
  final String identifier;
  final String password;
  final bool rememberMe;

  LoginParams({
    required this.identifier,
    required this.password,
    required this.rememberMe,
  });
}

class CheckAuthStatusParams {}
