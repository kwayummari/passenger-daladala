// lib/features/bookings/domain/repositories/booking_repository.dart - UPDATED VERSION
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking.dart';
import '../usecases/create_multiple_bookings_usecase.dart';

abstract class BookingRepository {
  // Existing methods with enhanced parameters
  Future<Either<Failure, List<Booking>>> getUserBookings({String? status});

  Future<Either<Failure, Booking>> getBookingDetails(int bookingId);

  Future<Either<Failure, Booking>> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
    List<String>? seatNumbers,
    List<String>? passengerNames,
    String? travelDate,
  });

  Future<Either<Failure, void>> cancelBooking(
    int bookingId, {
    bool cancelEntireGroup = false,
  });

  // NEW: Enhanced booking methods
  Future<Either<Failure, MultipleBookingsResponse>> createMultipleBookings(
    List<Map<String, dynamic>> bookingsData,
  );

  Future<Either<Failure, void>> reserveSeats(
    int bookingId,
    List<String> seatNumbers,
  );

  Future<Either<Failure, void>> autoAssignSeats(int bookingId);

  // NEW: Seat management methods
  Future<Either<Failure, Map<String, dynamic>>> getAvailableSeats({
    required int tripId,
    int? pickupStopId,
    int? dropoffStopId,
    String? travelDate,
  });

  Future<Either<Failure, List<String>>> autoAssignSeatsForTrip({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
    String? travelDate,
  });

  Future<Either<Failure, void>> releaseSeat(int bookingSeatId);

  Future<Either<Failure, void>> boardPassenger(int bookingSeatId);

  Future<Either<Failure, Map<String, dynamic>>> getVehicleSeatMap({
    required int vehicleId,
    int? tripId,
    String? travelDate,
  });
}
