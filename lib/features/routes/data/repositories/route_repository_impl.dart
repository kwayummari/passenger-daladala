import 'package:daladala_smart_app/features/routes/data/datasources/route_datasource.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/transport_route.dart';
import '../../domain/entities/stop.dart';
import '../../domain/entities/fare.dart';
import '../../domain/repositories/route_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteDataSource dataSource;
  final NetworkInfo networkInfo;
  
  RouteRepositoryImpl({
    required this.dataSource,
    required this.networkInfo,
  });
  
  @override
  Future<Either<Failure, List<TransportRoute>>> getAllRoutes() async {
    if (await networkInfo.isConnected) {
      try {
        final routes = await dataSource.getAllRoutes();
        return Right(routes);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, TransportRoute>> getRouteById(int routeId) async {
    if (await networkInfo.isConnected) {
      try {
        final route = await dataSource.getRouteById(routeId);
        return Right(route);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Route not found'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, List<Stop>>> getRouteStops(int routeId) async {
    if (await networkInfo.isConnected) {
      try {
        final stops = await dataSource.getRouteStops(routeId);
        return Right(stops);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, List<Fare>>> getRouteFares({
    required int routeId,
    String? fareType,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final fares = await dataSource.getRouteFares(
          routeId: routeId,
          fareType: fareType,
        );
        return Right(fares);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, List<TransportRoute>>> searchRoutes({
    String? startPoint,
    String? endPoint,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final routes = await dataSource.searchRoutes(
          startPoint: startPoint,
          endPoint: endPoint,
        );
        return Right(routes);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, Fare>> getFareBetweenStops({
    required int routeId,
    required int startStopId,
    required int endStopId,
    String? fareType,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final fare = await dataSource.getFareBetweenStops(
          routeId: routeId,
          startStopId: startStopId,
          endStopId: endStopId,
          fareType: fareType,
        );
        return Right(fare);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server error'));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message ?? 'Fare not found'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}