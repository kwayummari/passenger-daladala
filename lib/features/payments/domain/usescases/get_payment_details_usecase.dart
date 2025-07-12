// lib/features/payments/domain/usecases/get_payment_details_usecase.dart
import 'package:daladala_smart_app/features/payments/presentation/providers/payment_provider.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetPaymentDetailsUseCase implements UseCase<Payment, GetPaymentDetailsParams> {
  final PaymentRepository repository;

  GetPaymentDetailsUseCase({required this.repository});

  @override
  Future<Either<Failure, Payment>> call(GetPaymentDetailsParams params) async {
    return await repository.getPaymentDetails(params.paymentId);
  }
}