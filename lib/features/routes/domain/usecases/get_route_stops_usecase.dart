import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/stop.dart';
import '../repositories/route_repository.dart';

class GetRouteStopsUseCase implements UseCase<List<Stop>, GetRouteStopsParams> {
  final RouteRepository repository;

  GetRouteStopsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<Stop>>> call(GetRouteStopsParams params) async {
    return await repository.getRouteStops(params.routeId);
  }
}

class GetRouteStopsParams {
  final int routeId;
  
  const GetRouteStopsParams({required this.routeId});
}