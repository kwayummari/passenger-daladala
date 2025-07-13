// lib/features/bookings/data/models/multiple_bookings_response.dart
import '../../../bookings/domain/entities/booking.dart';
import 'booking_model.dart';

class MultipleBookingsResponse {
  final List<Booking> bookings;
  final double totalFare;
  final int totalBookings;
  final String? bookingReference;
  final bool isMultiDay;
  final String? dateRange;
  final int? totalDays;
  final Map<String, dynamic>? fareBreakdown;

  MultipleBookingsResponse({
    required this.bookings,
    required this.totalFare,
    required this.totalBookings,
    this.bookingReference,
    this.isMultiDay = false,
    this.dateRange,
    this.totalDays,
    this.fareBreakdown,
  });

  factory MultipleBookingsResponse.fromJson(Map<String, dynamic> json) {
  try {
    print('🔍 Parsing MultipleBookingsResponse: $json');
    
    // Parse bookings array
    List<Booking> bookingsList = [];
    if (json['bookings'] != null) {
      print('🔍 Bookings data: ${json['bookings']}');
      
      final bookingsData = json['bookings'] as List;
      for (int i = 0; i < bookingsData.length; i++) {
        try {
          print('🔍 Parsing booking $i: ${bookingsData[i]}');
          final booking = BookingModel.fromJson(bookingsData[i]);
          bookingsList.add(booking);
          print('✅ Successfully parsed booking $i');
        } catch (e) {
          print('❌ Error parsing booking $i: $e');
          // Continue with other bookings instead of failing completely
        }
      }
    }
    
    print('🔍 Successfully parsed ${bookingsList.length} bookings');

    return MultipleBookingsResponse(
      bookings: bookingsList,
      totalFare: _parseDouble(json['total_fare']) ?? 0.0,
      totalBookings: json['total_bookings'] as int? ?? bookingsList.length,
      bookingReference: json['booking_reference'] as String?,
      isMultiDay: json['is_multi_day'] as bool? ?? false,
      dateRange: json['date_range'] as String?,
      totalDays: json['total_days'] as int?,
      fareBreakdown: json['fare_breakdown'] as Map<String, dynamic>?,
    );
  } catch (e) {
    print('❌ Error parsing MultipleBookingsResponse: $e');
    rethrow;
  }

  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'bookings': bookings.map((b) => (b as BookingModel).toJson()).toList(),
      'total_fare': totalFare,
      'total_bookings': totalBookings,
      'booking_reference': bookingReference,
      'is_multi_day': isMultiDay,
      'date_range': dateRange,
      'total_days': totalDays,
      'fare_breakdown': fareBreakdown,
    };
  }
}
