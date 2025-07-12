// lib/features/payments/domain/usecases/process_payment_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class ProcessPaymentUseCase implements UseCase<Payment, ProcessPaymentParams> {
  final PaymentRepository repository;

  ProcessPaymentUseCase({required this.repository});

  @override
  Future<Either<Failure, Payment>> call(ProcessPaymentParams params) async {
    return await repository.processPayment(
      bookingId: params.bookingId,
      paymentMethod: params.paymentMethod,
      phoneNumber: params.phoneNumber,
      transactionId: params.transactionId,
      paymentDetails: params.paymentDetails,
    );
  }
}

class ProcessPaymentParams {
  final int bookingId;
  final String paymentMethod;
  final String? phoneNumber;
  final String? transactionId;
  final Map<String, dynamic>? paymentDetails;
  final String? amount;

  ProcessPaymentParams({
    required this.bookingId,
    required this.paymentMethod,
    this.phoneNumber,
    this.transactionId,
    this.paymentDetails,
    this.amount,
  });
}
