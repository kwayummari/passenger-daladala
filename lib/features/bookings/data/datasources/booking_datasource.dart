// lib/features/bookings/data/datasources/booking_datasource.dart - FIXED VERSION

import 'package:daladala_smart_app/features/bookings/domain/usecases/create_multiple_bookings_usecase.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/multiple_bookings_response.dart';
import '../models/booking_model.dart';

abstract class BookingDataSource {
  Future<List<BookingModel>> getUserBookings({String? status});
  Future<BookingModel> getBookingDetails(int bookingId);
  Future<BookingModel> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
    List<String>? seatNumbers,
    List<String>? passengerNames,
    String? travelDate,
  });
  Future<void> cancelBooking(int bookingId, {bool cancelEntireGroup = false});

  // NEW: Enhanced booking methods
  Future<MultipleBookingsResponse> createMultipleBookings(
    List<Map<String, dynamic>> bookingsData, {
    String? dateRange,
    int? totalDays,
    bool? isMultiDay,
  });

  Future<Map<String, dynamic>> getAvailableSeats({
    required int tripId,
    int? pickupStopId,
    int? dropoffStopId,
    String? travelDate,
  });

  Future<void> reserveSeats({
    required int bookingId,
    required List<String> seatNumbers,
    List<String>? passengerNames,
  });

  // Two different autoAssignSeats methods:
  // 1. For existing bookings (just bookingId)
  Future<void> autoAssignSeats(int bookingId);

  // 2. For new trip seat assignment (with trip details)
  Future<List<String>> autoAssignSeatsForTrip({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
    String? travelDate,
  });

  Future<void> releaseSeat(int bookingSeatId);
  Future<void> boardPassenger(int bookingSeatId);
  Future<Map<String, dynamic>> getVehicleSeatMap({
    required int vehicleId,
    int? tripId,
    String? travelDate,
  });
}

class BookingDataSourceImpl implements BookingDataSource {
  final DioClient dioClient;

  BookingDataSourceImpl({required this.dioClient});

  @override
  Future<List<BookingModel>> getUserBookings({String? status}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;

      final response = await dioClient.get(
        '/bookings',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Handle both single and multi-day bookings
        final List<BookingModel> allBookings = [];

        // Add single bookings
        if (data['single_bookings'] != null) {
          final singleBookings =
              (data['single_bookings'] as List)
                  .map((json) => BookingModel.fromJson(json))
                  .toList();
          allBookings.addAll(singleBookings);
        }

        // Add multi-day bookings (flattened)
        if (data['multi_day_bookings'] != null) {
          for (final group in data['multi_day_bookings']) {
            if (group['bookings'] != null) {
              final groupBookings =
                  (group['bookings'] as List)
                      .map((json) => BookingModel.fromJson(json))
                      .toList();
              allBookings.addAll(groupBookings);
            }
          }
        }

        return allBookings;
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to get bookings',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get user bookings: $e');
    }
  }

  @override
  Future<BookingModel> getBookingDetails(int bookingId) async {
    try {
      final response = await dioClient.get('/bookings/$bookingId');

      if (response.statusCode == 200) {
        return BookingModel.fromJson(response.data['data']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to get booking details',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get booking details: $e');
    }
  }

  @override
  Future<BookingModel> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
    List<String>? seatNumbers,
    List<String>? passengerNames,
    String? travelDate,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'trip_id': tripId,
        'pickup_stop_id': pickupStopId,
        'dropoff_stop_id': dropoffStopId,
        'passenger_count': passengerCount,
      };

      if (seatNumbers != null && seatNumbers.isNotEmpty) {
        data['seat_numbers'] = seatNumbers;
      }

      if (passengerNames != null && passengerNames.isNotEmpty) {
        data['passenger_names'] = passengerNames;
      }

      if (travelDate != null) {
        data['travel_date'] = travelDate;
      }

      final response = await dioClient.post('/bookings', data: data);

      if (response.statusCode == 201) {
        return BookingModel.fromJson(response.data['data']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to create booking',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to create booking: $e');
    }
  }

  @override
  Future<void> cancelBooking(
    int bookingId, {
    bool cancelEntireGroup = false,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'cancel_entire_group': cancelEntireGroup,
      };

      final response = await dioClient.put(
        '/bookings/$bookingId/cancel',
        data: data,
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to cancel booking',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to cancel booking: $e');
    }
  }

  @override
  Future<MultipleBookingsResponse> createMultipleBookings(
    List<Map<String, dynamic>> bookingsData, {
    String? dateRange,
    int? totalDays,
    bool? isMultiDay,
  }) async {
    try {
      final data = {
        'bookings_data': bookingsData,
        'is_multi_day': isMultiDay ?? false,
        'date_range': dateRange ?? 'single',
        'total_days': totalDays ?? 1,
      };

      print('📤 Sending multiple bookings request: $data');

      final response = await dioClient.post('/bookings/multiple', data: data);

      print('📥 Multiple bookings response: $response');

      if (response['status'] == 'success') {
        // Parse the response data
        return MultipleBookingsResponse.fromJson(response['data']);
      } else {
        throw ServerException(
          message: response['message'] ?? 'Failed to create multiple bookings',
        );
      }
    } catch (e) {
      print('❌ Multiple bookings error: $e');
      if (e is ServerException) {
        rethrow;
      } else {
        throw ServerException(
          message: 'Failed to create multiple bookings: ${e.toString()}',
        );
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getAvailableSeats({
    required int tripId,
    int? pickupStopId,
    int? dropoffStopId,
    String? travelDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (pickupStopId != null) {
        queryParams['pickup_stop_id'] = pickupStopId.toString();
      }
      if (dropoffStopId != null) {
        queryParams['dropoff_stop_id'] = dropoffStopId.toString();
      }
      if (travelDate != null) queryParams['travel_date'] = travelDate;

      final response = await dioClient.get(
        '/bookings/$tripId/seats',
        queryParameters: queryParams,
      );

      if (response['status'] == "success" && response['data'] != null) {
        final seatData = response['data'];

        return {
          'trip_id': seatData['trip_id'],
          'vehicle_info': seatData['vehicle_info'],
          'seat_summary': seatData['seat_summary'],
          'available_seats': seatData['available_seats'] ?? [],
          'occupied_seats': seatData['occupied_seats'] ?? [],
          'unavailable_seats': [],
        };
      } else {
        throw ServerException(
          message: response['message'] ?? 'Failed to get available seats',
        );
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }

      // Handle network/connection errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection') ||
          e.toString().contains('Failed host lookup')) {
        throw ServerException(
          message:
              'Network connection error. Please check your internet connection.',
        );
      }

      // Handle DioException
      if (e.toString().contains('DioException')) {
        throw ServerException(
          message: 'Network request failed. Please try again.',
        );
      }

      throw ServerException(
        message: 'Failed to load seat information: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> reserveSeats({
    required int bookingId,
    required List<String> seatNumbers,
    List<String>? passengerNames,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'booking_id': bookingId,
        'seat_numbers': seatNumbers,
      };

      if (passengerNames != null && passengerNames.isNotEmpty) {
        data['passenger_names'] = passengerNames;
      }

      final response = await dioClient.post('/seats/reserve', data: data);

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to reserve seats',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to reserve seats: $e');
    }
  }

  @override
  Future<void> autoAssignSeats(int bookingId) async {
    try {
      final Map<String, dynamic> data = {'booking_id': bookingId};

      final response = await dioClient.post('/seats/auto-assign', data: data);

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to auto-assign seats',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to auto-assign seats: $e');
    }
  }

  @override
  Future<List<String>> autoAssignSeatsForTrip({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
    String? travelDate,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'trip_id': tripId,
        'pickup_stop_id': pickupStopId,
        'dropoff_stop_id': dropoffStopId,
        'passenger_count': passengerCount,
      };

      if (travelDate != null) {
        data['travel_date'] = travelDate;
      }

      final response = await dioClient.post('/seats/auto-assign', data: data);

      if (response.statusCode == 200) {
        final assignedSeats = response.data['data']['assigned_seats'] as List;
        return assignedSeats.cast<String>();
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to auto-assign seats',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to auto-assign seats: $e');
    }
  }

  @override
  Future<void> releaseSeat(int bookingSeatId) async {
    try {
      final response = await dioClient.put('/seats/$bookingSeatId/release');

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to release seat',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to release seat: $e');
    }
  }

  @override
  Future<void> boardPassenger(int bookingSeatId) async {
    try {
      final response = await dioClient.put('/seats/$bookingSeatId/board');

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to board passenger',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to board passenger: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getVehicleSeatMap({
    required int vehicleId,
    int? tripId,
    String? travelDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (tripId != null) queryParams['trip_id'] = tripId.toString();
      if (travelDate != null) queryParams['travel_date'] = travelDate;

      final response = await dioClient.get(
        '/vehicles/$vehicleId/seat-map',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to get vehicle seat map',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get vehicle seat map: $e');
    }
  }
}
