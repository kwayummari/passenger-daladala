import '../../domains/entities/trip.dart';

class TripModel extends Trip {
  const TripModel({
    required super.id,
    required super.scheduleId,
    required super.routeId,
    required super.vehicleId,
    super.driverId,
    required super.startTime,
    super.endTime,
    required super.status,
    super.currentStopId,
    super.nextStopId,
    super.currentLocation,
    super.routeName,
    super.vehiclePlate,
    super.driverName,
    super.driverRating,
    super.route,
    super.availableSeats,
    super.occupiedSeats,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    try {
      return TripModel(
        id: json['trip_id'] ?? 0,
        scheduleId: json['schedule_id'],
        routeId: json['route_id'] ?? 0,
        vehicleId: json['vehicle_id'] ?? 0,
        driverId: json['driver_id'],
        startTime: DateTime.parse(json['start_time'].toString()),
        endTime:
            json['end_time'] != null
                ? DateTime.parse(json['end_time'].toString())
                : null,
        status: (json['status'] ?? 'scheduled').toString(),
        currentStopId: json['current_stop_id'],
        nextStopId: json['next_stop_id'],

        // Simplified string handling
        routeName: json['Route']?['route_name']?.toString(),
        vehiclePlate: json['Vehicle']?['plate_number']?.toString(),
        driverName: json['Driver']?['User']?['first_name']?.toString(),
        driverRating: _parseDouble(json['Driver']?['rating']),

        // Skip route parsing for now to isolate the issue
        route: null,
        availableSeats: json['available_seats'] ?? 0,
        occupiedSeats: json['occupied_seats'] ?? 0,
      );
    } catch (e) {
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

  Map<String, dynamic> toJson() {
    return {
      'trip_id': id,
      'schedule_id': scheduleId,
      'route_id': routeId,
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
      'current_stop_id': currentStopId,
      'next_stop_id': nextStopId,
      if (currentLocation != null)
        'current_location': {
          'latitude': currentLocation!.latitude,
          'longitude': currentLocation!.longitude,
        },
      'route_name': routeName,
      'vehicle_plate': vehiclePlate,
      'driver_name': driverName,
      'driver_rating': driverRating,
      'available_seats': availableSeats,
      'occupied_seats': occupiedSeats,
    };
  }
}

// Supporting models for nested objects
class VehicleModel {
  final int vehicleId;
  final String plateNumber;
  final String vehicleType;
  final int capacity;
  final String? color;
  final bool isAirConditioned;

  const VehicleModel({
    required this.vehicleId,
    required this.plateNumber,
    required this.vehicleType,
    required this.capacity,
    this.color,
    required this.isAirConditioned,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleId: json['vehicle_id'],
      plateNumber: json['plate_number'],
      vehicleType: json['vehicle_type'],
      capacity: json['capacity'],
      color: json['color'],
      isAirConditioned: json['is_air_conditioned'] ?? false,
    );
  }
}

class DriverModel {
  final int driverId;
  final double? rating;
  final int? totalRatings;
  final UserModel? user;

  const DriverModel({
    required this.driverId,
    this.rating,
    this.totalRatings,
    this.user,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      driverId: json['driver_id'],
      rating: json['rating']?.toDouble(),
      totalRatings: json['total_ratings'],
      user: json['User'] != null ? UserModel.fromJson(json['User']) : null,
    );
  }
}

class UserModel {
  final String firstName;
  final String? lastName;
  final String? profilePicture;

  const UserModel({
    required this.firstName,
    this.lastName,
    this.profilePicture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePicture: json['profile_picture'],
    );
  }
}

class BookingModel {
  final int bookingId;
  final int passengerCount;
  final double fareAmount;
  final String status;
  final String paymentStatus;
  final DateTime bookingTime;
  final StopModel? pickupStop;
  final StopModel? dropoffStop;

  const BookingModel({
    required this.bookingId,
    required this.passengerCount,
    required this.fareAmount,
    required this.status,
    required this.paymentStatus,
    required this.bookingTime,
    this.pickupStop,
    this.dropoffStop,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['booking_id'],
      passengerCount: json['passenger_count'],
      fareAmount: json['fare_amount'].toDouble(),
      status: json['status'],
      paymentStatus: json['payment_status'],
      bookingTime: DateTime.parse(json['booking_time']),
      pickupStop:
          json['pickup_stop'] != null
              ? StopModel.fromJson(json['pickup_stop'])
              : null,
      dropoffStop:
          json['dropoff_stop'] != null
              ? StopModel.fromJson(json['dropoff_stop'])
              : null,
    );
  }
}

class StopModel {
  final int stopId;
  final String stopName;
  final double latitude;
  final double longitude;

  const StopModel({
    required this.stopId,
    required this.stopName,
    required this.latitude,
    required this.longitude,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      stopId: json['stop_id'],
      stopName: json['stop_name'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}
