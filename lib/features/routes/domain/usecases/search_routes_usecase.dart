import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transport_route.dart';
import '../repositories/route_repository.dart';

class SearchRoutesUseCase implements UseCase<List<TransportRoute>, SearchRoutesParams> {
  final RouteRepository repository;

  SearchRoutesUseCase({required this.repository});

  @override
  Future<Either<Failure, List<TransportRoute>>> call(SearchRoutesParams params) async {
    return await repository.searchRoutes(
      startPoint: params.startPoint,
      endPoint: params.endPoint,
    );
  }
}

class SearchRoutesParams {
  final String? startPoint;
  final String? endPoint;
  
  const SearchRoutesParams({this.startPoint, this.endPoint});
}