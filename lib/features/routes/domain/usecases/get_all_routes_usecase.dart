import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transport_route.dart';
import '../repositories/route_repository.dart';

class GetAllRoutesUseCase implements UseCase<List<TransportRoute>, NoParams> {
  final RouteRepository repository;

  GetAllRoutesUseCase({required this.repository});

  @override
  Future<Either<Failure, List<TransportRoute>>> call(NoParams params) async {
    return await repository.getAllRoutes();
  }
}