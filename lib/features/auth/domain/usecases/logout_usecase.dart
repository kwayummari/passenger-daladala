import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LogoutUseCase {
  final AuthRepository repository;
  
  LogoutUseCase({required this.repository});
  
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.logout();
  }
}