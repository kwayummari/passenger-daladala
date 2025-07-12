import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/transport_route.dart';
import '../entities/stop.dart';
import '../entities/fare.dart';

abstract class RouteRepository {
  /// Gets all available routes
  Future<Either<Failure, List<TransportRoute>>> getAllRoutes();
  
  /// Gets route by ID
  Future<Either<Failure, TransportRoute>> getRouteById(int routeId);
  
  /// Gets stops for a specific route
  Future<Either<Failure, List<Stop>>> getRouteStops(int routeId);
  
  /// Gets fares for a specific route
  Future<Either<Failure, List<Fare>>> getRouteFares({
    required int routeId,
    String? fareType,
  });
  
  /// Searches for routes based on start and end points
  Future<Either<Failure, List<TransportRoute>>> searchRoutes({
    String? startPoint,
    String? endPoint,
  });
  
  /// Gets fare between specific stops
  Future<Either<Failure, Fare>> getFareBetweenStops({
    required int routeId,
    required int startStopId,
    required int endStopId,
    String? fareType,
  });
}