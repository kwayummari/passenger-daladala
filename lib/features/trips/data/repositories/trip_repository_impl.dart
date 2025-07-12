import 'package:daladala_smart_app/features/trips/domains/entities/trip.dart';
import 'package:daladala_smart_app/features/trips/domains/repositories/trip_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/trip_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  final TripDataSource dataSource;
  final NetworkInfo networkInfo;

  TripRepositoryImpl({
    required this.dataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Trip>>> getUpcomingTrips({int? routeId}) async {
    if (await networkInfo.isConnected) {
      try {
        final trips = await dataSource.getUpcomingTrips(routeId: routeId);
        return Right(trips);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NoInternetConnectionException catch (e) {
        return Left(NetworkFailure(message: e.message ?? 'No internet connection'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Trip>> getTripDetails(int tripId) async {
    if (await networkInfo.isConnected) {
      try {
        final trip = await dataSource.getTripDetails(tripId);
        return Right(trip);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Trip not found'));
      } on NoInternetConnectionException catch (e) {
        return Left(NetworkFailure(message: e.message ?? 'No internet connection'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Trip>>> getTripsByRoute(int routeId, {String? date}) async {
    if (await networkInfo.isConnected) {
      try {
        final trips = await dataSource.getTripsByRoute(routeId, date: date);
        return Right(trips);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NoInternetConnectionException catch (e) {
        return Left(NetworkFailure(message: e.message ?? 'No internet connection'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTripStatus({
    required int tripId,
    required String status,
    int? currentStopId,
    int? nextStopId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.updateTripStatus(
          tripId: tripId,
          status: status,
          currentStopId: currentStopId,
          nextStopId: nextStopId,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on UnauthorizedException catch (e) {
        return Left(AuthenticationFailure(message: e.message ?? 'Unauthorized'));
      } on NoInternetConnectionException catch (e) {
        return Left(NetworkFailure(message: e.message ?? 'No internet connection'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> updateVehicleLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await dataSource.updateVehicleLocation(
          tripId: tripId,
          latitude: latitude,
          longitude: longitude,
          heading: heading,
          speed: speed,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on UnauthorizedException catch (e) {
        return Left(AuthenticationFailure(message: e.message ?? 'Unauthorized'));
      } on NoInternetConnectionException catch (e) {
        return Left(NetworkFailure(message: e.message ?? 'No internet connection'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}