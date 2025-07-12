import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class GetUpcomingTripsUseCase implements UseCase<List<Trip>, GetUpcomingTripsParams> {
  final TripRepository repository;

  GetUpcomingTripsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<Trip>>> call(GetUpcomingTripsParams params) async {
    return await repository.getUpcomingTrips(routeId: params.routeId);
  }
}

class GetUpcomingTripsParams {
  final int? routeId;
  
  const GetUpcomingTripsParams({this.routeId});
}