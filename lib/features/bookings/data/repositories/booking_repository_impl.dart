import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingDataSource dataSource;
  final NetworkInfo networkInfo;
  
  BookingRepositoryImpl({
    required this.dataSource,
    required this.networkInfo,
  });
  
  @override
  Future<Either<Failure, List<Booking>>> getUserBookings({String? status}) async {
    if (await networkInfo.isConnected) {
      try {
        final bookings = await dataSource.getUserBookings(status: status);
        return Right(bookings);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on UnauthorizedException catch (e) {
        return Left(AuthenticationFailure(message: e.message ?? 'Authentication error'));
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
        return Left(AuthenticationFailure(message: e.message ?? 'Authentication error'));
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
        return Left(AuthenticationFailure(message: e.message ?? 'Authentication error'));
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
        return Left(InputFailure(message: e.message ?? 'Cannot cancel booking at this stage'));
      } on UnauthorizedException catch (e) {
        return Left(AuthenticationFailure(message: e.message ?? 'Authentication error'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}