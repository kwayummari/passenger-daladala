import 'package:daladala_smart_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../entities/booking.dart';
import '../usecases/create_multiple_bookings_usecase.dart';

abstract class BookingRepository {
  // Existing methods
  Future<Either<Failure, List<Booking>>> getUserBookings({String? status});
  Future<Either<Failure, Booking>> getBookingDetails(int bookingId);
  Future<Either<Failure, Booking>> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
  });
  Future<Either<Failure, void>> cancelBooking(int bookingId);

  // NEW: Add these methods to your repository interface
  Future<Either<Failure, MultipleBookingsResponse>> createMultipleBookings(
    List<Map<String, dynamic>> bookingsData,
  );

  Future<Either<Failure, void>> reserveSeats(
    int bookingId,
    List<String> seatNumbers,
  );

  Future<Either<Failure, void>> autoAssignSeats(int bookingId);
}
