import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/payment_repository.dart';

class GetWalletBalanceUseCase implements UseCase<double, NoParams> {
  final PaymentRepository repository;

  GetWalletBalanceUseCase({required this.repository});

  @override
  Future<Either<Failure, double>> call(NoParams params) async {
    return await repository.getWalletBalance();
  }
}