import 'package:daladala_smart_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';

class AutoAssignSeatsUseCase implements UseCase<void, AutoAssignSeatsParams> {
  final BookingRepository repository;

  AutoAssignSeatsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AutoAssignSeatsParams params) async {
    return await repository.autoAssignSeats(params.bookingId);
  }
}

class AutoAssignSeatsParams {
  final int bookingId;

  AutoAssignSeatsParams({required this.bookingId});
}
