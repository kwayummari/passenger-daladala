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
    return BookingModel(
      id: json['booking_id'] as int,
      userId: json['user_id'] as int,
      tripId: json['trip_id'] as int,
      pickupStopId: json['pickup_stop_id'] as int,
      dropoffStopId: json['dropoff_stop_id'] as int,
      bookingTime: DateTime.parse(json['booking_time'] as String),
      fareAmount: (json['fare_amount'] as num).toDouble(),
      passengerCount: json['passenger_count'] as int,
      seatNumbers:
          json['seat_numbers'] != null
              ? (json['seat_numbers'] as String).split(',')
              : null,
      bookingType: json['booking_type'] as String? ?? 'regular',
      bookingDate:
          json['booking_date'] != null
              ? DateTime.parse(json['booking_date'] as String)
              : null,
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      // Enhanced fields
      bookingReference: json['booking_reference'] as String?,
      isMultiDay: json['is_multi_day'] as bool? ?? false,
      travelDate:
          json['travel_date'] != null
              ? DateTime.parse(json['travel_date'] as String)
              : null,
      qrCode: json['qr_code'] as String? ?? json['qr_code_data'] as String?,
      seatDetails:
          json['seat_details'] != null
              ? (json['seat_details'] as List)
                  .map((e) => SeatDetailModel.fromJson(e))
                  .toList()
              : null,
      routeInfo:
          json['route_info'] != null
              ? RouteInfoModel.fromJson(json['route_info'])
              : null,
      pickupStop:
          json['pickup_stop'] != null || json['pickupStop'] != null
              ? StopInfoModel.fromJson(
                json['pickup_stop'] ?? json['pickupStop'],
              )
              : null,
      dropoffStop:
          json['dropoff_stop'] != null || json['dropoffStop'] != null
              ? StopInfoModel.fromJson(
                json['dropoff_stop'] ?? json['dropoffStop'],
              )
              : null,
      relatedBookings:
          json['related_bookings'] != null
              ? (json['related_bookings'] as List)
                  .map((e) => RelatedBookingModel.fromJson(e))
                  .toList()
              : null,
      seatAssignments:
          json['seat_assignments'] != null
              ? (json['seat_assignments'] is String
                      ? jsonDecode(json['seat_assignments'] as String)
                      : json['seat_assignments'])
                  as List<dynamic>?
              : null,
    );
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
