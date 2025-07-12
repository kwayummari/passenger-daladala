// lib/features/payments/data/repositories/payment_repository_impl.dart
import 'package:daladala_smart_app/features/payments/data/datasources/payment_datasource.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentDataSource dataSource;
  final NetworkInfo networkInfo;

  PaymentRepositoryImpl({required this.dataSource, required this.networkInfo});

  @override
  Future<Either<Failure, Payment>> processPayment({
    required int bookingId,
    required String paymentMethod,
    String? phoneNumber,
    String? transactionId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final payment = await dataSource.processPayment(
          bookingId: bookingId,
          paymentMethod: paymentMethod,
          phoneNumber: phoneNumber,
          transactionId: transactionId,
          paymentDetails: paymentDetails,
        );
        return Right(payment);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on BadRequestException catch (e) {
        return Left(InputFailure(message: e.message ?? 'Invalid input'));
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
  Future<Either<Failure, List<Payment>>> getPaymentHistory() async {
    if (await networkInfo.isConnected) {
      try {
        final payments = await dataSource.getPaymentHistory();
        return Right(payments);
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
  Future<Either<Failure, Payment>> getPaymentDetails(int paymentId) async {
    if (await networkInfo.isConnected) {
      try {
        final payment = await dataSource.getPaymentDetails(paymentId);
        return Right(payment);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Payment not found'));
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
  Future<Either<Failure, Payment>> checkPaymentStatus(int paymentId) async {
    if (await networkInfo.isConnected) {
      try {
        final payment = await dataSource.checkPaymentStatus(paymentId);
        return Right(payment);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Payment not found'));
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
  Future<Either<Failure, double>> getWalletBalance() async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await dataSource.getWalletBalance();
        return Right(balance);
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
  Future<Either<Failure, double>> topUpWallet({
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
    String? transactionId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await dataSource.topUpWallet(
          amount: amount,
          paymentMethod: paymentMethod,
          transactionId: transactionId,
          paymentDetails: paymentDetails,
        );
        return Right(balance);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on BadRequestException catch (e) {
        return Left(InputFailure(message: e.message ?? 'Invalid input'));
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
}
