import 'package:daladala_smart_app/features/trips/domains/entities/trip.dart';

import '../../../../core/network/dio_client.dart';
import '../models/trip_model.dart';

abstract class TripDataSource {
  Future<List<Trip>> getUpcomingTrips({int? routeId});
  Future<Trip> getTripDetails(int tripId);
  Future<List<Trip>> getTripsByRoute(int routeId, {String? date});
  Future<void> updateTripStatus({
    required int tripId,
    required String status,
    int? currentStopId,
    int? nextStopId,
  });
  Future<void> updateVehicleLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  });
}

class TripDataSourceImpl implements TripDataSource {
  final DioClient dioClient;

  TripDataSourceImpl({required this.dioClient});

  @override
  Future<List<Trip>> getUpcomingTrips({int? routeId}) async {
    try {
      final queryParams = routeId != null ? {'route_id': routeId} : null;
      final response = await dioClient.get('/trips/upcoming', queryParameters: queryParams);
      
      if (response['status'] == 'success') {
        final List<dynamic> tripsList = response['data'];
        return tripsList.map((tripData) => TripModel.fromJson(tripData)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get upcoming trips');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Trip> getTripDetails(int tripId) async {
    try {
      final response = await dioClient.get('/trips/$tripId');
      
      if (response['status'] == 'success') {
        return TripModel.fromJson(response['data']['trip']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get trip details');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Trip>> getTripsByRoute(int routeId, {String? date}) async {
    try {
      final queryParams = date != null ? {'date': date} : null;
      final response = await dioClient.get('/trips/route/$routeId', queryParameters: queryParams);
      
      if (response['status'] == 'success') {
        final List<dynamic> tripsList = response['data'];
        return tripsList.map((tripData) => TripModel.fromJson(tripData)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get trips by route');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateTripStatus({
    required int tripId,
    required String status,
    int? currentStopId,
    int? nextStopId,
  }) async {
    try {
      final data = {
        'status': status,
        if (currentStopId != null) 'current_stop_id': currentStopId,
        if (nextStopId != null) 'next_stop_id': nextStopId,
      };
      
      final response = await dioClient.put('/trips/driver/$tripId/status', data: data);
      
      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update trip status');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateVehicleLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    try {
      final data = {
        'latitude': latitude,
        'longitude': longitude,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
      };
      
      final response = await dioClient.post('/trips/driver/$tripId/location', data: data);
      
      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update vehicle location');
      }
    } catch (e) {
      rethrow;
    }
  }
}