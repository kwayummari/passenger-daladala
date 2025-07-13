// lib/features/bookings/domain/usecases/create_multiple_bookings_usecase.dart - UPDATED VERSION
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class CreateMultipleBookingsUseCase
    implements UseCase<MultipleBookingsResponse, CreateMultipleBookingsParams> {
  final BookingRepository repository;

  CreateMultipleBookingsUseCase(this.repository);

  @override
  Future<Either<Failure, MultipleBookingsResponse>> call(
    CreateMultipleBookingsParams params,
  ) async {
    return await repository.createMultipleBookings(params.bookingsData);
  }
}

class CreateMultipleBookingsParams {
  final List<Map<String, dynamic>> bookingsData;

  CreateMultipleBookingsParams({required this.bookingsData});
}

class MultipleBookingsResponse {
  final List<Booking> bookings;
  final double totalFare;
  final int totalBookings;
  final String? bookingReference;
  final bool isMultiDay;
  final String? dateRange;

  MultipleBookingsResponse({
    required this.bookings,
    required this.totalFare,
    required this.totalBookings,
    this.bookingReference,
    this.isMultiDay = false,
    this.dateRange,
  });
}
