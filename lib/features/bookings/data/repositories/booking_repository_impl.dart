// lib/features/bookings/data/repositories/booking_repository_impl.dart - FIXED VERSION
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/booking.dart'
    as entities; // Use prefix for entity
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_datasource.dart';
import '../models/multiple_bookings_response.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingDataSource dataSource;
  final NetworkInfo networkInfo;

  BookingRepositoryImpl({required this.dataSource, required this.networkInfo});

  @override
  Future<Either<Failure, List<entities.Booking>>> getUserBookings({
    String? status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final bookingModels = await dataSource.getUserBookings(status: status);
        // Convert models to entities
        final bookings =
            bookingModels.map((model) => model as entities.Booking).toList();
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
  Future<Either<Failure, entities.Booking>> getBookingDetails(
    int bookingId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final bookingModel = await dataSource.getBookingDetails(bookingId);
        // Convert model to entity
        final booking = bookingModel as entities.Booking;
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
  Future<Either<Failure, entities.Booking>> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
    List<String>? seatNumbers,
    List<String>? passengerNames,
    String? travelDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final bookingModel = await dataSource.createBooking(
          tripId: tripId,
          pickupStopId: pickupStopId,
          dropoffStopId: dropoffStopId,
          passengerCount: passengerCount,
          seatNumbers: seatNumbers,
          passengerNames: passengerNames,
          travelDate: travelDate,
        );
        // Convert model to entity
        final booking = bookingModel as entities.Booking;
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
  Future<Either<Failure, void>> cancelBooking(
    int bookingId, {
    bool cancelEntireGroup = false,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.cancelBooking(
          bookingId,
          cancelEntireGroup: cancelEntireGroup,
        );
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

  // NEW: Create multiple bookings implementation
  @override
  Future<Either<Failure, MultipleBookingsResponse>> createMultipleBookings(
    List<Map<String, dynamic>> bookingsData, {
    String? dateRange,
    int? totalDays,
    bool? isMultiDay,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await dataSource.createMultipleBookings(
          bookingsData,
          dateRange: dateRange,
          totalDays: totalDays,
          isMultiDay: isMultiDay,
        );
        return Right(response);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on UnauthorizedException catch (e) {
        return Left(
          AuthenticationFailure(message: e.message ?? 'Unauthorized'),
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
        await dataSource.reserveSeats(
          bookingId: bookingId,
          seatNumbers: seatNumbers,
        );
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
        await dataSource.autoAssignSeats(bookingId); // ✅ Correct method call
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
  
  // NEW: Get available seats implementation
  @override
  Future<Either<Failure, Map<String, dynamic>>> getAvailableSeats({
    required int tripId,
    int? pickupStopId,
    int? dropoffStopId,
    String? travelDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final seatData = await dataSource.getAvailableSeats(
          tripId: tripId,
          pickupStopId: pickupStopId,
          dropoffStopId: dropoffStopId,
          travelDate: travelDate,
        );
        return Right(seatData);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Trip not found'));
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


  // NEW: Release seat implementation
  @override
  Future<Either<Failure, void>> releaseSeat(int bookingSeatId) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.releaseSeat(bookingSeatId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message ?? 'Booking seat not found'),
        );
      } on BadRequestException catch (e) {
        return Left(InputFailure(message: e.message ?? 'Cannot release seat'));
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

  // NEW: Board passenger implementation
  @override
  Future<Either<Failure, void>> boardPassenger(int bookingSeatId) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.boardPassenger(bookingSeatId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(
          NotFoundFailure(message: e.message ?? 'Booking seat not found'),
        );
      } on BadRequestException catch (e) {
        return Left(
          InputFailure(message: e.message ?? 'Cannot board passenger'),
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

  // NEW: Get vehicle seat map implementation
  @override
  Future<Either<Failure, Map<String, dynamic>>> getVehicleSeatMap({
    required int vehicleId,
    int? tripId,
    String? travelDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final seatMap = await dataSource.getVehicleSeatMap(
          vehicleId: vehicleId,
          tripId: tripId,
          travelDate: travelDate,
        );
        return Right(seatMap);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Vehicle not found'));
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
  Future<Either<Failure, List<String>>> autoAssignSeatsForTrip({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
    String? travelDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final assignedSeats = await dataSource.autoAssignSeatsForTrip(
          // ✅ Correct method call
          tripId: tripId,
          pickupStopId: pickupStopId,
          dropoffStopId: dropoffStopId,
          passengerCount: passengerCount,
          travelDate: travelDate,
        );
        return Right(assignedSeats);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Trip not found'));
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
