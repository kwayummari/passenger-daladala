// lib/features/trips/domains/entities/trip.dart
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../routes/domain/entities/transport_route.dart';

class Trip extends Equatable {
  final int id;
  final int? scheduleId;
  final int routeId;
  final int vehicleId;
  final int? driverId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final int? currentStopId;
  final int? nextStopId;
  final LatLng? currentLocation;

  // Simple properties for basic display
  final String? routeName;
  final String? vehiclePlate;
  final String? driverName;
  final double? driverRating;

  // Only include route object (since RouteModel extends TransportRoute properly)
  final TransportRoute? route;

  // Additional trip info
  final int? availableSeats;
  final int? occupiedSeats;

  const Trip({
    required this.id,
    this.scheduleId,
    required this.routeId,
    required this.vehicleId,
    this.driverId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.currentStopId,
    this.nextStopId,
    this.currentLocation,
    this.routeName,
    this.vehiclePlate,
    this.driverName,
    this.driverRating,
    this.route,
    this.availableSeats,
    this.occupiedSeats,
  });

  // Getter to get trip ID (for consistency with backend)
  int get tripId => id;

  // Helper getters for route information
  String get displayRouteName =>
      routeName ?? route?.routeName ?? 'Unknown Route';
  String get displayStartPoint => route?.startPoint ?? 'Unknown';
  String get displayEndPoint => route?.endPoint ?? 'Unknown';
  String get displayVehiclePlate => vehiclePlate ?? 'N/A';
  String get displayDriverName => driverName ?? 'Unknown';
  double get displayDriverRating => driverRating ?? 0.0;

  Trip copyWith({
    int? id,
    int? scheduleId,
    int? routeId,
    int? vehicleId,
    int? driverId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    int? currentStopId,
    int? nextStopId,
    LatLng? currentLocation,
    String? routeName,
    String? vehiclePlate,
    String? driverName,
    double? driverRating,
    TransportRoute? route,
    int? availableSeats,
    int? occupiedSeats,
  }) {
    return Trip(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      routeId: routeId ?? this.routeId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      currentStopId: currentStopId ?? this.currentStopId,
      nextStopId: nextStopId ?? this.nextStopId,
      currentLocation: currentLocation ?? this.currentLocation,
      routeName: routeName ?? this.routeName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      route: route ?? this.route,
      availableSeats: availableSeats ?? this.availableSeats,
      occupiedSeats: occupiedSeats ?? this.occupiedSeats,
    );
  }

  @override
  List<Object?> get props => [
    id,
    scheduleId,
    routeId,
    vehicleId,
    driverId,
    startTime,
    endTime,
    status,
    currentStopId,
    nextStopId,
    currentLocation,
    routeName,
    vehiclePlate,
    driverName,
    driverRating,
    route,
    availableSeats,
    occupiedSeats,
  ];
}
