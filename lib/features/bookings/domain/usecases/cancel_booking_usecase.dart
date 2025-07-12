import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/booking_repository.dart';

class CancelBookingUseCase {
  final BookingRepository repository;
  
  CancelBookingUseCase({required this.repository});
  
  Future<Either<Failure, void>> call(CancelBookingParams params) async {
    return await repository.cancelBooking(params.bookingId);
  }
}

class CancelBookingParams {
  final int bookingId;
  
  CancelBookingParams({required this.bookingId});
}