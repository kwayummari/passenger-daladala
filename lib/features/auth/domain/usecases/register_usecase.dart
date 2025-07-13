import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase({required this.repository});

  Future<Either<Failure, User>> call(RegisterParams params) async {
    return await repository.register(
      phone: params.phone,
      email: params.email,
      password: params.password,
      national_id: params.national_id,
      role: params.role,
    );
  }
}

class RegisterParams {
  final String phone;
  final String email;
  final String password;
  final String national_id;
  final String role;

  RegisterParams({
    required this.phone,
    required this.email,
    required this.password,
    required this.national_id,
    required this.role,
  });
}
