// lib/features/payments/domain/usecases/get_payment_history_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetPaymentHistoryUseCase implements UseCase<List<Payment>, NoParams> {
  final PaymentRepository repository;

  GetPaymentHistoryUseCase({required this.repository});

  @override
  Future<Either<Failure, List<Payment>>> call(NoParams params) async {
    return await repository.getPaymentHistory();
  }
}