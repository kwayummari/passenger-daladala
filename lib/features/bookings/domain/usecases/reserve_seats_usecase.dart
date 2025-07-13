
import 'package:daladala_smart_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';

class ReserveSeatsUseCase implements UseCase<void, ReserveSeatsParams> {
  final BookingRepository repository;

  ReserveSeatsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ReserveSeatsParams params) async {
    return await repository.reserveSeats(params.bookingId, params.seatNumbers);
  }
}

class ReserveSeatsParams {
  final int bookingId;
  final List<String> seatNumbers;

  ReserveSeatsParams({
    required this.bookingId,
    required this.seatNumbers,
  });
}