import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/trip.dart';

abstract class TripRepository {
  /// Get upcoming trips, optionally filtered by route ID
  Future<Either<Failure, List<Trip>>> getUpcomingTrips({int? routeId});
  
  /// Get details of a specific trip
  Future<Either<Failure, Trip>> getTripDetails(int tripId);
  
  /// Get trips by route
  Future<Either<Failure, List<Trip>>> getTripsByRoute(int routeId, {String? date});
  
  /// Update trip status (for driver)
  Future<Either<Failure, void>> updateTripStatus({
    required int tripId,
    required String status,
    int? currentStopId,
    int? nextStopId,
  });
  
  /// Update vehicle location (for driver)
  Future<Either<Failure, void>> updateVehicleLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  });
}