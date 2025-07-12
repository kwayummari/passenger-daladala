import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/constants.dart';
import '../models/booking_model.dart';

abstract class BookingDataSource {
  Future<List<BookingModel>> getUserBookings({String? status});
  Future<BookingModel> getBookingDetails(int bookingId);
  Future<BookingModel> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
  });
  Future<void> cancelBooking(int bookingId);
}

class BookingDataSourceImpl implements BookingDataSource {
  final DioClient dioClient;

  BookingDataSourceImpl({required this.dioClient});

  @override
  Future<List<BookingModel>> getUserBookings({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await dioClient.get(
        AppConstants.bookingsEndpoint,
        queryParameters: queryParams,
      );

      if (response['status'] == 'success') {
        return (response['data'] as List)
            .map((booking) => BookingModel.fromJson(booking))
            .toList();
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BookingModel> getBookingDetails(int bookingId) async {
    try {
      final response = await dioClient.get(
        '${AppConstants.bookingsEndpoint}/$bookingId',
      );

      if (response['status'] == 'success') {
        return BookingModel.fromJson(response['data']['booking']);
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BookingModel> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
  }) async {
    try {
      final response = await dioClient.post(
        AppConstants.bookingsEndpoint,
        data: {
          'trip_id': tripId,
          'pickup_stop_id': pickupStopId,
          'dropoff_stop_id': dropoffStopId,
          'passenger_count': passengerCount,
        },
      );

      if (response['status'] == 'success') {
        return BookingModel.fromJson(response['data']);
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    try {
      final response = await dioClient.put(
        '${AppConstants.bookingsEndpoint}/$bookingId/cancel',
      );

      if (response['status'] != 'success') {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Mock implementation for debugging
class MockBookingDataSource implements BookingDataSource {
  @override
  Future<List<BookingModel>> getUserBookings({String? status}) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
    
    // Return mock data
    return [
      BookingModel(
        id: 1,
        userId: 2,
        tripId: 1,
        pickupStopId: 1,
        dropoffStopId: 4,
        bookingTime: DateTime.now(),
        fareAmount: 1500.0,
        passengerCount: 1,
        status: 'in_progress',
        paymentStatus: 'paid',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      BookingModel(
        id: 2,
        userId: 2,
        tripId: 2,
        pickupStopId: 5,
        dropoffStopId: 4,
        bookingTime: DateTime.now().add(const Duration(hours: 1)),
        fareAmount: 1500.0,
        passengerCount: 2,
        status: 'confirmed',
        paymentStatus: 'paid',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  @override
  Future<BookingModel> getBookingDetails(int bookingId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
    
    return BookingModel(
      id: bookingId,
      userId: 2,
      tripId: 1,
      pickupStopId: 1,
      dropoffStopId: 4,
      bookingTime: DateTime.now(),
      fareAmount: 1500.0,
      passengerCount: 1,
      status: 'confirmed',
      paymentStatus: 'paid',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

  @override
  Future<BookingModel> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
    
    return BookingModel(
      id: 3, // New booking ID
      userId: 2,
      tripId: tripId,
      pickupStopId: pickupStopId,
      dropoffStopId: dropoffStopId,
      bookingTime: DateTime.now(),
      fareAmount: 1500.0 * passengerCount,
      passengerCount: passengerCount,
      status: 'pending',
      paymentStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancelBooking(int bookingId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
    
    // In a real implementation, we would make an API call to cancel the booking
    // For this mock, we simply return without error
    return;
  }
}