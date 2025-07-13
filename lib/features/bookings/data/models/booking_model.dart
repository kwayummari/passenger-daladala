// lib/features/bookings/data/models/booking_model.dart - FIXED VERSION
import 'dart:convert';
import '../../domain/entities/booking.dart'; // Import the domain entity

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.tripId,
    required super.pickupStopId,
    required super.dropoffStopId,
    required super.bookingTime,
    required super.fareAmount,
    required super.passengerCount,
    super.seatNumbers,
    super.bookingType,
    super.bookingDate,
    super.status,
    super.paymentStatus,
    super.createdAt,
    super.updatedAt,
    // Enhanced fields
    super.bookingReference,
    super.isMultiDay,
    super.travelDate,
    super.qrCode,
    super.seatDetails,
    super.routeInfo,
    super.pickupStop,
    super.dropoffStop,
    super.relatedBookings,
    super.seatAssignments,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 DEBUG: Parsing booking from JSON: $json');

      return BookingModel(
        id: _parseInt(json['booking_id']),
        userId: _parseInt(json['user_id']),
        tripId: _parseInt(json['trip_id']),
        pickupStopId: _parseInt(json['pickup_stop_id']),
        dropoffStopId: _parseInt(json['dropoff_stop_id']),
        bookingTime: _parseDateTime(json['booking_time']) ?? DateTime.now(),
        fareAmount: _parseDouble(json['fare_amount']) ?? 0.0,
        passengerCount: _parseInt(json['passenger_count']) ?? 1,
        seatNumbers: _parseSeatNumbers(json['seat_numbers']),
        status: json['status']?.toString() ?? 'pending',
        paymentStatus: json['payment_status']?.toString() ?? 'pending',

        // Handle additional fields from the backend response
        travelDate: _parseDate(json['travel_date']),
        bookingReference: json['booking_reference']?.toString(),
        qrCode: json['qr_code']?.toString(),

        // Handle pickup/dropoff stops if present
        pickupStop:
            json['pickup_stop'] != null
                ? StopInfoModel.fromJson(json['pickup_stop'])
                : null,
        dropoffStop:
            json['dropoff_stop'] != null
                ? StopInfoModel.fromJson(json['dropoff_stop'])
                : null,

        // Handle route info if present
        routeInfo:
            json['route_info'] != null || json['route_name'] != null
                ? RouteInfoModel.fromJson({
                  'route_id': json['route_id'] ?? 0,
                  'route_name': json['route_name'] ?? 'Unknown Route',
                  'start_point': json['route_info']?['start_point'],
                  'end_point': json['route_info']?['end_point'],
                })
                : null,
      );
    } catch (e) {
      print('❌ Error parsing booking: $e');
      rethrow;
    }
  }

  // Add these helper methods to BookingModel
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static List<String> _parseSeatNumbers(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': id,
      'user_id': userId,
      'trip_id': tripId,
      'pickup_stop_id': pickupStopId,
      'dropoff_stop_id': dropoffStopId,
      'booking_time': bookingTime.toIso8601String(),
      'fare_amount': fareAmount,
      'passenger_count': passengerCount,
      'seat_numbers': seatNumbers?.join(','),
      'booking_type': bookingType,
      'booking_date': bookingDate?.toIso8601String(),
      'status': status,
      'payment_status': paymentStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Enhanced fields
      'booking_reference': bookingReference,
      'is_multi_day': isMultiDay,
      'travel_date': travelDate?.toIso8601String(),
      'qr_code': qrCode,
      'seat_details':
          seatDetails?.map((e) => (e as SeatDetailModel).toJson()).toList(),
      'route_info': (routeInfo as RouteInfoModel?)?.toJson(),
      'pickup_stop': (pickupStop as StopInfoModel?)?.toJson(),
      'dropoff_stop': (dropoffStop as StopInfoModel?)?.toJson(),
      'related_bookings':
          relatedBookings
              ?.map((e) => (e as RelatedBookingModel).toJson())
              .toList(),
      'seat_assignments': seatAssignments,
    };
  }
}

class SeatDetailModel extends SeatDetail {
  const SeatDetailModel({
    required super.bookingSeatId,
    required super.seatId,
    required super.seatNumber,
    super.seatType,
    super.passengerName,
    super.isOccupied,
    super.boardedAt,
    super.alightedAt,
  });

  factory SeatDetailModel.fromJson(Map<String, dynamic> json) {
    return SeatDetailModel(
      bookingSeatId: json['booking_seat_id'] as int,
      seatId: json['seat_id'] as int,
      seatNumber: json['seat_number'] as String,
      seatType: json['seat_type'] as String?,
      passengerName: json['passenger_name'] as String?,
      isOccupied: json['is_occupied'] as bool? ?? false,
      boardedAt:
          json['boarded_at'] != null
              ? DateTime.parse(json['boarded_at'] as String)
              : null,
      alightedAt:
          json['alighted_at'] != null
              ? DateTime.parse(json['alighted_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_seat_id': bookingSeatId,
      'seat_id': seatId,
      'seat_number': seatNumber,
      'seat_type': seatType,
      'passenger_name': passengerName,
      'is_occupied': isOccupied,
      'boarded_at': boardedAt?.toIso8601String(),
      'alighted_at': alightedAt?.toIso8601String(),
    };
  }
}

class RouteInfoModel extends RouteInfo {
  const RouteInfoModel({
    required super.routeId,
    required super.routeName,
    super.startPoint,
    super.endPoint,
  });

  factory RouteInfoModel.fromJson(Map<String, dynamic> json) {
    return RouteInfoModel(
      routeId: json['route_id'] as int,
      routeName: json['route_name'] as String,
      startPoint: json['start_point'] as String?,
      endPoint: json['end_point'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'route_name': routeName,
      'start_point': startPoint,
      'end_point': endPoint,
    };
  }
}

class StopInfoModel extends StopInfo {
  const StopInfoModel({
    required super.stopId,
    required super.stopName,
    super.latitude,
    super.longitude,
  });

  factory StopInfoModel.fromJson(Map<String, dynamic> json) {
    return StopInfoModel(
      stopId: json['stop_id'] as int,
      stopName: json['stop_name'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stop_id': stopId,
      'stop_name': stopName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class RelatedBookingModel extends RelatedBooking {
  const RelatedBookingModel({
    required super.bookingId,
    required super.travelDate,
    required super.fareAmount,
    required super.passengerCount,
    required super.status,
    super.qrCode,
    super.routeName,
    super.startTime,
  });

  factory RelatedBookingModel.fromJson(Map<String, dynamic> json) {
    return RelatedBookingModel(
      bookingId: json['booking_id'] as int,
      travelDate: DateTime.parse(json['travel_date'] as String),
      fareAmount: (json['fare_amount'] as num).toDouble(),
      passengerCount: json['passenger_count'] as int,
      status: json['status'] as String,
      qrCode: json['qr_code'] as String? ?? json['qr_code_data'] as String?,
      routeName: json['Trip']?['Route']?['route_name'] as String?,
      startTime:
          json['Trip']?['start_time'] != null
              ? DateTime.parse(json['Trip']['start_time'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'travel_date': travelDate.toIso8601String(),
      'fare_amount': fareAmount,
      'passenger_count': passengerCount,
      'status': status,
      'qr_code': qrCode,
      'route_name': routeName,
      'start_time': startTime?.toIso8601String(),
    };
  }
}
