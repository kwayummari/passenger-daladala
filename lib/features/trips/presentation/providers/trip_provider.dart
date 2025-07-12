// lib/features/trips/presentation/providers/trip_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../services/api_service.dart';
import '../../../routes/domain/entities/transport_route.dart';
import '../../domains/entities/trip.dart';

class TripProvider extends ChangeNotifier {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  List<Trip> _upcomingTrips = [];
  List<Trip> _pastTrips = [];
  List<Trip> _cancelledTrips = [];
  bool _isLoading = false;
  String? _error;

  List<Trip> get upcomingTrips => _upcomingTrips;
  List<Trip> get pastTrips => _pastTrips;
  List<Trip> get cancelledTrips => _cancelledTrips;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage =>
      _error; // Add this getter for backward compatibility

  /// Get upcoming trips (actually gets user bookings)
  Future<void> getUpcomingTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🚀 TripProvider: Starting to fetch upcoming trips...');

      // Get auth token
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      print('🔑 TripProvider: Auth token found, fetching bookings...');

      // Use the correct API endpoint for user bookings with required parameters
      final response = await ApiService.getUserBookings(
        authToken: authToken,
        status: null, // Get all bookings
      );

      print(
        '📡 TripProvider: API response received with ${response.length} bookings',
      );

      if (response.isNotEmpty) {
        print('📋 TripProvider: Processing ${response.length} bookings...');

        // Convert bookings to trips for display
        final allTrips =
            response.map((bookingData) {
              print(
                '🔄 TripProvider: Converting booking ${bookingData['booking_id']} to trip',
              );
              return _convertBookingToTrip(bookingData);
            }).toList();

        print('✅ TripProvider: Converted ${allTrips.length} bookings to trips');

        // Filter trips by status and time
        final now = DateTime.now();

        _upcomingTrips =
            allTrips.where((trip) {
              final isUpcoming =
                  trip.startTime.isAfter(now) &&
                  (trip.status == 'scheduled' ||
                      trip.status == 'confirmed' ||
                      trip.status == 'in_progress');
              print(
                '📅 TripProvider: Trip ${trip.id} - ${trip.displayRouteName} - ${trip.startTime} - Upcoming: $isUpcoming',
              );
              return isUpcoming;
            }).toList();

        _pastTrips =
            allTrips.where((trip) {
              return trip.startTime.isBefore(now) || trip.status == 'completed';
            }).toList();

        _cancelledTrips =
            allTrips.where((trip) {
              return trip.status == 'cancelled';
            }).toList();

        // Sort by date
        _upcomingTrips.sort((a, b) => a.startTime.compareTo(b.startTime));
        _pastTrips.sort((a, b) => b.startTime.compareTo(a.startTime));

        print(
          '📊 TripProvider: Final counts - Upcoming: ${_upcomingTrips.length}, Past: ${_pastTrips.length}, Cancelled: ${_cancelledTrips.length}',
        );
      } else {
        print('📭 TripProvider: No bookings found');
        _upcomingTrips = [];
        _pastTrips = [];
        _cancelledTrips = [];
      }
    } catch (e) {
      _error = 'Failed to load trips: ${e.toString()}';
      print('❌ TripProvider Error: $e'); // For debugging

      // Clear trips on error
      _upcomingTrips = [];
      _pastTrips = [];
      _cancelledTrips = [];
    } finally {
      _isLoading = false;
      notifyListeners();
      print(
        '🏁 TripProvider: Finished fetching trips. Loading: $_isLoading, Error: $_error',
      );
    }
  }

  /// Convert booking data to Trip entity for display
  Trip _convertBookingToTrip(Map<String, dynamic> bookingData) {
    print('🔄 Converting booking data: $bookingData');

    final tripData = bookingData['Trip'] ?? {};
    final routeData = tripData['Route'] ?? {};

    print('📍 Trip data: $tripData');
    print('🛣️ Route data: $routeData');

    // Parse start time with fallback
    DateTime startTime;
    try {
      startTime = DateTime.parse(tripData['start_time']);
    } catch (e) {
      print(
        '⚠️ Failed to parse start_time: ${tripData['start_time']}, using current time',
      );
      startTime = DateTime.now().add(
        const Duration(hours: 1),
      ); // Default to 1 hour from now
    }

    // Parse end time with fallback
    DateTime? endTime;
    try {
      if (tripData['end_time'] != null) {
        endTime = DateTime.parse(tripData['end_time']);
      }
    } catch (e) {
      print('⚠️ Failed to parse end_time: ${tripData['end_time']}');
    }

    final trip = Trip(
      id: bookingData['booking_id'] ?? 0,
      scheduleId: tripData['schedule_id'] ?? 0,
      routeId: routeData['route_id'] ?? 0,
      vehicleId: tripData['vehicle_id'] ?? 0,
      driverId: tripData['driver_id'],
      startTime: startTime,
      endTime: endTime,
      status: _mapBookingStatusToTripStatus(bookingData['status']),
      currentStopId: tripData['current_stop_id'],
      nextStopId: tripData['next_stop_id'],
      routeName: routeData['route_name'] ?? 'Unknown Route',
      vehiclePlate: tripData['Vehicle']?['plate_number'],
      driverName: _getDriverName(tripData['Driver']),
      driverRating: tripData['Driver']?['rating']?.toDouble(),
      route:
          routeData.isNotEmpty
              ? TransportRoute(
                id: routeData['route_id'] ?? 0,
                routeNumber: routeData['route_number'] ?? 'Unknown',
                routeName: routeData['route_name'] ?? 'Unknown Route',
                startPoint: routeData['start_point'] ?? '',
                endPoint: routeData['end_point'] ?? '',
                description: routeData['description'],
                distanceKm: routeData['distance_km']?.toDouble(),
                estimatedTimeMinutes: routeData['estimated_time_minutes'],
                status: routeData['status'] ?? 'active',
              )
              : null,
      availableSeats: tripData['available_seats'],
      occupiedSeats: tripData['occupied_seats'],
    );

    print(
      '✅ Created trip: ${trip.id} - ${trip.displayRouteName} - ${trip.startTime}',
    );
    return trip;
  }

  String _mapBookingStatusToTripStatus(String? bookingStatus) {
    switch (bookingStatus) {
      case 'pending':
        return 'scheduled';
      case 'confirmed':
        return 'scheduled';
      case 'in_progress':
        return 'in_progress';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'scheduled';
    }
  }

  String? _getDriverName(Map<String, dynamic>? driverData) {
    if (driverData == null) return null;

    final user = driverData['User'];
    if (user != null) {
      final firstName = user['first_name'] ?? '';
      final lastName = user['last_name'] ?? '';
      return '$firstName $lastName'.trim();
    }

    return null;
  }

  /// Refresh trips
  Future<void> refreshTrips() async {
    await getUpcomingTrips();
  }

  /// Clear all trips
  void clearTrips() {
    _upcomingTrips = [];
    _pastTrips = [];
    _cancelledTrips = [];
    _error = null;
    notifyListeners();
  }

  /// Get trips by filter
  List<Trip> getTripsByFilter(String filter) {
    switch (filter) {
      case 'upcoming':
        return _upcomingTrips;
      case 'past':
        return _pastTrips;
      case 'cancelled':
        return _cancelledTrips;
      default:
        return _upcomingTrips;
    }
  }

  /// Check if user has any active trips
  bool get hasActiveTrips {
    return _upcomingTrips.any(
      (trip) => trip.status == 'active' || trip.status == 'in_progress',
    );
  }

  /// Get upcoming trips count
  int get upcomingTripsCount => _upcomingTrips.length;

  /// Get trips by status
  List<Trip> getTripsByStatus(String status) {
    return _upcomingTrips.where((trip) => trip.status == status).toList();
  }

  /// Get next upcoming trip
  Trip? get nextUpcomingTrip {
    if (_upcomingTrips.isEmpty) return null;

    final now = DateTime.now();
    final futureTrips =
        _upcomingTrips.where((trip) => trip.startTime.isAfter(now)).toList();

    if (futureTrips.isEmpty) return null;

    futureTrips.sort((a, b) => a.startTime.compareTo(b.startTime));
    return futureTrips.first;
  }

  /// Check if there are any trips for a specific route
  bool hasTripsForRoute(int routeId) {
    return _upcomingTrips.any((trip) => trip.route?.id == routeId);
  }
}
