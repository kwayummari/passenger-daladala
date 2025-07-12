import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class GetBookingDetailsUseCase {
  final BookingRepository repository;
  
  GetBookingDetailsUseCase({required this.repository});
  
  Future<Either<Failure, Booking>> call(GetBookingDetailsParams params) async {
    return await repository.getBookingDetails(params.bookingId);
  }
}

class GetBookingDetailsParams {
  final int bookingId;
  
  GetBookingDetailsParams({required this.bookingId});
}