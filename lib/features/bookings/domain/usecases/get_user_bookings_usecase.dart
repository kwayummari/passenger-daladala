import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class GetUserBookingsUseCase {
  final BookingRepository repository;
  
  GetUserBookingsUseCase({required this.repository});
  
  Future<Either<Failure, List<Booking>>> call(GetUserBookingsParams params) async {
    return await repository.getUserBookings(status: params.status);
  }
}

class GetUserBookingsParams {
  final String? status;
  
  GetUserBookingsParams({this.status});
}