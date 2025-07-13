// lib/features/bookings/domain/entities/booking.dart - ENTITY FILE
class Booking {
  final int id;
  final int userId;
  final int tripId;
  final int pickupStopId;
  final int dropoffStopId;
  final DateTime bookingTime;
  final double fareAmount;
  final int passengerCount;
  final List<String>? seatNumbers;
  final String bookingType;
  final DateTime? bookingDate;
  final String status;
  final String paymentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Enhanced fields
  final String? bookingReference;
  final bool isMultiDay;
  final DateTime? travelDate;
  final String? qrCode;
  final List<SeatDetail>? seatDetails;
  final RouteInfo? routeInfo;
  final StopInfo? pickupStop;
  final StopInfo? dropoffStop;
  final List<RelatedBooking>? relatedBookings;
  final List<dynamic>? seatAssignments;

  const Booking({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.pickupStopId,
    required this.dropoffStopId,
    required this.bookingTime,
    required this.fareAmount,
    required this.passengerCount,
    this.seatNumbers,
    this.bookingType = 'regular',
    this.bookingDate,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    this.createdAt,
    this.updatedAt,
    // Enhanced fields
    this.bookingReference,
    this.isMultiDay = false,
    this.travelDate,
    this.qrCode,
    this.seatDetails,
    this.routeInfo,
    this.pickupStop,
    this.dropoffStop,
    this.relatedBookings,
    this.seatAssignments,
  });

  Booking copyWith({
    int? id,
    int? userId,
    int? tripId,
    int? pickupStopId,
    int? dropoffStopId,
    DateTime? bookingTime,
    double? fareAmount,
    int? passengerCount,
    List<String>? seatNumbers,
    String? bookingType,
    DateTime? bookingDate,
    String? status,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bookingReference,
    bool? isMultiDay,
    DateTime? travelDate,
    String? qrCode,
    dynamic seatDetails,
    dynamic routeInfo,
    dynamic pickupStop,
    dynamic dropoffStop,
    dynamic relatedBookings,
    dynamic seatAssignments,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      pickupStopId: pickupStopId ?? this.pickupStopId,
      dropoffStopId: dropoffStopId ?? this.dropoffStopId,
      bookingTime: bookingTime ?? this.bookingTime,
      fareAmount: fareAmount ?? this.fareAmount,
      passengerCount: passengerCount ?? this.passengerCount,
      seatNumbers: seatNumbers ?? this.seatNumbers,
      bookingType: bookingType ?? this.bookingType,
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookingReference: bookingReference ?? this.bookingReference,
      isMultiDay: isMultiDay ?? this.isMultiDay,
      travelDate: travelDate ?? this.travelDate,
      qrCode: qrCode ?? this.qrCode,
      seatDetails: seatDetails ?? this.seatDetails,
      routeInfo: routeInfo ?? this.routeInfo,
      pickupStop: pickupStop ?? this.pickupStop,
      dropoffStop: dropoffStop ?? this.dropoffStop,
      relatedBookings: relatedBookings ?? this.relatedBookings,
      seatAssignments: seatAssignments ?? this.seatAssignments,
    );
  }

  // Helper methods
  bool get hasSeats => seatNumbers != null && seatNumbers!.isNotEmpty;
  bool get hasQrCode => qrCode != null && qrCode!.isNotEmpty;
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isPaid => paymentStatus == 'paid';

  String get displayDate =>
      travelDate?.toIso8601String().split('T')[0] ??
      bookingDate?.toIso8601String().split('T')[0] ??
      bookingTime.toIso8601String().split('T')[0];

  double get totalFare => fareAmount * passengerCount;
}

// Supporting classes
class SeatDetail {
  final int bookingSeatId;
  final int seatId;
  final String seatNumber;
  final String? seatType;
  final String? passengerName;
  final bool isOccupied;
  final DateTime? boardedAt;
  final DateTime? alightedAt;

  const SeatDetail({
    required this.bookingSeatId,
    required this.seatId,
    required this.seatNumber,
    this.seatType,
    this.passengerName,
    this.isOccupied = false,
    this.boardedAt,
    this.alightedAt,
  });

  bool get hasBoarded => boardedAt != null;
  bool get hasAlighted => alightedAt != null;
}

class RouteInfo {
  final int routeId;
  final String routeName;
  final String? startPoint;
  final String? endPoint;

  const RouteInfo({
    required this.routeId,
    required this.routeName,
    this.startPoint,
    this.endPoint,
  });
}

class StopInfo {
  final int stopId;
  final String stopName;
  final double? latitude;
  final double? longitude;

  const StopInfo({
    required this.stopId,
    required this.stopName,
    this.latitude,
    this.longitude,
  });
}

class RelatedBooking {
  final int bookingId;
  final DateTime travelDate;
  final double fareAmount;
  final int passengerCount;
  final String status;
  final String? qrCode;
  final String? routeName;
  final DateTime? startTime;

  const RelatedBooking({
    required this.bookingId,
    required this.travelDate,
    required this.fareAmount,
    required this.passengerCount,
    required this.status,
    this.qrCode,
    this.routeName,
    this.startTime,
  });
}
