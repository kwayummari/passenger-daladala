import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/create_multiple_bookings_usecase.dart';
import '../datasources/booking_datasource.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingDataSource dataSource;
  final NetworkInfo networkInfo;

  BookingRepositoryImpl({required this.dataSource, required this.networkInfo});

  @override
  Future<Either<Failure, List<Booking>>> getUserBookings({
    String? status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final bookings = await dataSource.getUserBookings(status: status);
        return Right(bookings);
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
  Future<Either<Failure, Booking>> getBookingDetails(int bookingId) async {
    if (await networkInfo.isConnected) {
      try {
        final booking = await dataSource.getBookingDetails(bookingId);
        return Right(booking);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Booking not found'));
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
  Future<Either<Failure, Booking>> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final booking = await dataSource.createBooking(
          tripId: tripId,
          pickupStopId: pickupStopId,
          dropoffStopId: dropoffStopId,
          passengerCount: passengerCount,
        );
        return Right(booking);
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
  Future<Either<Failure, void>> cancelBooking(int bookingId) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.cancelBooking(bookingId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Booking not found'));
      } on BadRequestException catch (e) {
        return Left(
          InputFailure(
            message: e.message ?? 'Cannot cancel booking at this stage',
          ),
        );
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

  // NEW: Create multiple bookings implementation - FIXED
  @override
  Future<Either<Failure, MultipleBookingsResponse>> createMultipleBookings(
    List<Map<String, dynamic>> bookingsData,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await dataSource.createMultipleBookings(bookingsData);

        // FIXED: Convert response to MultipleBookingsResponse without toEntity()
        final bookings =
            (response['bookings'] as List)
                .map((booking) => BookingModel.fromJson(booking) as Booking)
                .toList();

        return Right(
          MultipleBookingsResponse(
            bookings: bookings,
            totalFare: (response['total_fare'] as num).toDouble(),
            totalBookings: response['total_bookings'] as int,
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on BadRequestException catch (e) {
        return Left(InputFailure(message: e.message ?? 'Invalid booking data'));
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

  // NEW: Reserve seats implementation
  @override
  Future<Either<Failure, void>> reserveSeats(
    int bookingId,
    List<String> seatNumbers,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.reserveSeats(bookingId, seatNumbers);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Booking not found'));
      } on BadRequestException catch (e) {
        return Left(
          InputFailure(message: e.message ?? 'Invalid seat selection'),
        );
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

  // NEW: Auto-assign seats implementation
  @override
  Future<Either<Failure, void>> autoAssignSeats(int bookingId) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.autoAssignSeats(bookingId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Booking not found'));
      } on BadRequestException catch (e) {
        return Left(
          InputFailure(message: e.message ?? 'Cannot auto-assign seats'),
        );
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
