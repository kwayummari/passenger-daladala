// lib/features/bookings/domain/usecases/create_multiple_bookings_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';
import '../../data/models/multiple_bookings_response.dart'; // Add this import

class CreateMultipleBookingsUseCase
    implements UseCase<MultipleBookingsResponse, CreateMultipleBookingsParams> {
  final BookingRepository repository;

  CreateMultipleBookingsUseCase(this.repository);

  @override
  Future<Either<Failure, MultipleBookingsResponse>> call(
    CreateMultipleBookingsParams params,
  ) async {
    return await repository.createMultipleBookings(
      params.bookingsData,
      dateRange: params.dateRange,
      totalDays: params.totalDays,
      isMultiDay: params.isMultiDay,
    );
  }
}

class CreateMultipleBookingsParams {
  final List<Map<String, dynamic>> bookingsData;
  final String? dateRange;
  final int? totalDays;
  final bool? isMultiDay;

  CreateMultipleBookingsParams({
    required this.bookingsData,
    this.dateRange,
    this.totalDays,
    this.isMultiDay,
  });
}
