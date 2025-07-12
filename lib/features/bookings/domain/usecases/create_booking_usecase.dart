import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase {
  final BookingRepository repository;
  
  CreateBookingUseCase({required this.repository});
  
  Future<Either<Failure, Booking>> call(CreateBookingParams params) async {
    return await repository.createBooking(
      tripId: params.tripId,
      pickupStopId: params.pickupStopId,
      dropoffStopId: params.dropoffStopId,
      passengerCount: params.passengerCount,
    );
  }
}

class CreateBookingParams {
  final int tripId;
  final int pickupStopId;
  final int dropoffStopId;
  final int passengerCount;
  
  CreateBookingParams({
    required this.tripId,
    required this.pickupStopId,
    required this.dropoffStopId,
    required this.passengerCount,
  });
}