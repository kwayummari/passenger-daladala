import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class GetTripDetailsUseCase implements UseCase<Trip, GetTripDetailsParams> {
  final TripRepository repository;

  GetTripDetailsUseCase({required this.repository});

  @override
  Future<Either<Failure, Trip>> call(GetTripDetailsParams params) async {
    return await repository.getTripDetails(params.tripId);
  }
}

class GetTripDetailsParams {
  final int tripId;
  
  const GetTripDetailsParams({required this.tripId});
}