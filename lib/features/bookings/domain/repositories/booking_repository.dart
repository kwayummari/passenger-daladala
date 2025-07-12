import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking.dart';

abstract class BookingRepository {
  /// Get a list of bookings for the current user
  Future<Either<Failure, List<Booking>>> getUserBookings({String? status});
  
  /// Get details of a specific booking
  Future<Either<Failure, Booking>> getBookingDetails(int bookingId);
  
  /// Create a new booking
  Future<Either<Failure, Booking>> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
  });
  
  /// Cancel an existing booking
  Future<Either<Failure, void>> cancelBooking(int bookingId);
}