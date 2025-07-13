import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  BookingModel({
    required int id,
    required int userId,
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required DateTime bookingTime,
    required double fareAmount,
    required int passengerCount,
    required String status,
    required String paymentStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    Map<String, dynamic>? trip,
    Map<String, dynamic>? pickupStop,
    Map<String, dynamic>? dropoffStop,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? user,
  }) : super(
         id: id,
         userId: userId,
         tripId: tripId,
         pickupStopId: pickupStopId,
         dropoffStopId: dropoffStopId,
         bookingTime: bookingTime,
         fareAmount: fareAmount,
         passengerCount: passengerCount,
         status: status,
         paymentStatus: paymentStatus,
         createdAt: createdAt,
         updatedAt: updatedAt,
         trip: trip,
         pickupStop: pickupStop,
         dropoffStop: dropoffStop,
         payment: payment,
         user: user,
       );
       

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🎫 Parsing booking JSON: $json');

      // Safe integer parsing with null checks
      final bookingId = _parseIntField(json, 'booking_id');
      final userId = _parseIntField(json, 'user_id');
      final tripId = _parseIntField(json, 'trip_id');
      final pickupStopId = _parseIntField(json, 'pickup_stop_id');
      final dropoffStopId = _parseIntField(json, 'dropoff_stop_id');
      final passengerCount = _parseIntField(json, 'passenger_count');

      // Safe double parsing
      final fareAmount = _parseDoubleField(json, 'fare_amount');

      // Safe string parsing
      final status = json['status']?.toString() ?? 'pending';
      final paymentStatus = json['payment_status']?.toString() ?? 'pending';

      // Safe date parsing
      final bookingTime =
          _parseDateField(json, 'booking_time') ?? DateTime.now();
      final createdAt = _parseDateField(json, 'created_at') ?? DateTime.now();
      final updatedAt = _parseDateField(json, 'updated_at') ?? DateTime.now();

      print(
        '✅ Parsed booking: ID=$bookingId, TripID=$tripId, Amount=$fareAmount',
      );

      return BookingModel(
        id: bookingId,
        userId: userId,
        tripId: tripId,
        pickupStopId: pickupStopId,
        dropoffStopId: dropoffStopId,
        bookingTime: bookingTime,
        fareAmount: fareAmount,
        passengerCount: passengerCount,
        status: status,
        paymentStatus: paymentStatus,
        createdAt: createdAt,
        updatedAt: updatedAt,
        trip: json['Trip'],
        pickupStop: json['pickupStop'],
        dropoffStop: json['dropoffStop'],
        payment: json['payment'],
        user: json['User'],
      );
    } catch (e) {
      print('❌ Error parsing booking from JSON: $e');
      print('❌ JSON was: $json');
      rethrow;
    }
  }

  // Helper methods for safe parsing
  static int _parseIntField(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      throw FormatException(
        'Required field "$key" is null in booking JSON: $json',
      );
    }

    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is double) return value.toInt();

    throw FormatException(
      'Cannot parse "$key" as int: $value (type: ${value.runtimeType})',
    );
  }

  static double _parseDoubleField(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      throw FormatException(
        'Required field "$key" is null in booking JSON: $json',
      );
    }

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }

    throw FormatException(
      'Cannot parse "$key" as double: $value (type: ${value.runtimeType})',
    );
  }

  static DateTime? _parseDateField(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Warning: Cannot parse date field "$key": $value');
        return null;
      }
    }

    return null;
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
      'status': status,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
