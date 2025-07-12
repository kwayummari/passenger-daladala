// lib/features/routes/data/datasources/route_datasource.dart
import 'package:daladala_smart_app/features/routes/data/models/fare_model.dart';
import 'package:daladala_smart_app/features/routes/data/models/route_model.dart';
import 'package:daladala_smart_app/features/routes/data/models/stop_model.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/constants.dart';

abstract class RouteDataSource {
  /// Get all active routes
  Future<List<RouteModel>> getAllRoutes();

  /// Get route by ID
  Future<RouteModel> getRouteById(int routeId);

  /// Get stops for a route
  Future<List<StopModel>> getRouteStops(int routeId);

  /// Get fares for a route
  Future<List<FareModel>> getRouteFares({
    required int routeId,
    String? fareType,
  });

  /// Search routes by start and end points
  Future<List<RouteModel>> searchRoutes({String? startPoint, String? endPoint});

  /// Get fare between stops
  Future<FareModel> getFareBetweenStops({
    required int routeId,
    required int startStopId,
    required int endStopId,
    String? fareType,
  });
}

class RouteDataSourceImpl implements RouteDataSource {
  final DioClient dioClient;

  RouteDataSourceImpl({required this.dioClient});

  @override
  Future<List<RouteModel>> getAllRoutes() async {
    try {
      print('🌐 Fetching all routes from API...');
      final response = await dioClient.get(AppConstants.routesEndpoint);

      print('📡 Routes API Response: $response');

      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data != null && data is List) {
          return data
              .where((route) => route != null) // Filter out null entries
              .map(
                (route) => RouteModel.fromJson(route as Map<String, dynamic>),
              )
              .toList();
        } else {
          print('⚠️ Routes data is null or not a list: $data');
          return [];
        }
      } else {
        throw ServerException(
          message: response?['message'] ?? 'Failed to fetch routes',
        );
      }
    } catch (e) {
      print('💥 Error in getAllRoutes: $e');
      rethrow;
    }
  }

  @override
  Future<RouteModel> getRouteById(int routeId) async {
    try {
      print('🌐 Fetching route $routeId from API...');
      final response = await dioClient.get(
        '${AppConstants.routesEndpoint}/$routeId',
      );

      print('📡 Route API Response: $response');

      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data != null) {
          return RouteModel.fromJson(data as Map<String, dynamic>);
        } else {
          throw ServerException(message: 'Route data is null');
        }
      } else {
        throw ServerException(
          message: response?['message'] ?? 'Route not found',
        );
      }
    } catch (e) {
      print('💥 Error in getRouteById: $e');
      rethrow;
    }
  }

  @override
  Future<List<StopModel>> getRouteStops(int routeId) async {
    try {
      print('🌐 Fetching stops for route $routeId from API...');
      final response = await dioClient.get(
        '${AppConstants.routesEndpoint}/$routeId/stops',
      );

      print('📡 Route Stops API Response: $response');
      print('📡 Response type: ${response.runtimeType}');
      print('📡 Response status: ${response?['status']}');
      print('📡 Response data: ${response?['data']}');

      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        print('📦 Processing stops data: $data (type: ${data.runtimeType})');

        if (data != null && data is List) {
          final stops = <StopModel>[];
          for (int i = 0; i < data.length; i++) {
            final stopData = data[i];
            print(
              '🏪 Processing stop $i: $stopData (type: ${stopData.runtimeType})',
            );

            if (stopData != null && stopData is Map<String, dynamic>) {
              try {
                // Check if the stop data has the expected structure
                if (stopData.containsKey('stop_id') &&
                    stopData.containsKey('stop_name')) {
                  final stop = StopModel.fromJson(stopData);
                  stops.add(stop);
                } else {
                  print('⚠️ Stop data missing required fields: $stopData');
                }
              } catch (e) {
                print('⚠️ Error parsing stop $i: $e');
                print('⚠️ Stop data was: $stopData');
              }
            } else {
              print('⚠️ Stop $i is null or not a Map: $stopData');
            }
          }

          print('✅ Successfully parsed ${stops.length} stops');
          return stops;
        } else {
          print('⚠️ Stops data is null or not a list: $data');
          return [];
        }
      } else {
        final message = response?['message'] ?? 'Failed to fetch route stops';
        print('❌ API returned error: $message');
        throw ServerException(message: message);
      }
    } catch (e) {
      print('💥 Error in getRouteStops: $e');
      rethrow;
    }
  }

  @override
  Future<List<FareModel>> getRouteFares({
    required int routeId,
    String? fareType,
  }) async {
    try {
      print('🌐 Fetching fares for route $routeId from API...');
      final Map<String, dynamic>? queryParameters =
          fareType != null ? {'fare_type': fareType} : null;

      final response = await dioClient.get(
        '${AppConstants.routesEndpoint}/$routeId/fares',
        queryParameters: queryParameters,
      );

      print('📡 Route Fares API Response: $response');

      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data != null && data is List) {
          return data
              .where((fare) => fare != null)
              .map((fare) => FareModel.fromJson(fare as Map<String, dynamic>))
              .toList();
        } else {
          return [];
        }
      } else {
        throw ServerException(
          message: response?['message'] ?? 'Failed to fetch fares',
        );
      }
    } catch (e) {
      print('💥 Error in getRouteFares: $e');
      rethrow;
    }
  }

  @override
  Future<List<RouteModel>> searchRoutes({
    String? startPoint,
    String? endPoint,
  }) async {
    try {
      print(
        '🔍 Searching routes with startPoint: $startPoint, endPoint: $endPoint',
      );

      final queryParams = <String, String>{};
      if (startPoint != null) queryParams['start_point'] = startPoint;
      if (endPoint != null) queryParams['end_point'] = endPoint;

      final response = await dioClient.get(
        '${AppConstants.routesEndpoint}/search',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📡 Search Routes API Response: $response');

      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data != null && data is List) {
          return data
              .where((route) => route != null)
              .map(
                (route) => RouteModel.fromJson(route as Map<String, dynamic>),
              )
              .toList();
        } else {
          return [];
        }
      } else {
        throw ServerException(message: response?['message'] ?? 'Search failed');
      }
    } catch (e) {
      print('💥 Error in searchRoutes: $e');
      rethrow;
    }
  }

  @override
  Future<FareModel> getFareBetweenStops({
    required int routeId,
    required int startStopId,
    required int endStopId,
    String? fareType,
  }) async {
    try {
      print('💰 Fetching fare between stops for route $routeId');

      final queryParams = {
        'route_id': routeId.toString(),
        'start_stop_id': startStopId.toString(),
        'end_stop_id': endStopId.toString(),
        if (fareType != null) 'fare_type': fareType,
      };

      final response = await dioClient.get(
        '${AppConstants.routesEndpoint}/fare',
        queryParameters: queryParams,
      );

      print('📡 Fare API Response: $response');

      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data != null) {
          return FareModel.fromJson(data as Map<String, dynamic>);
        } else {
          throw ServerException(message: 'Fare data is null');
        }
      } else {
        throw ServerException(
          message: response?['message'] ?? 'Fare not found',
        );
      }
    } catch (e) {
      print('💥 Error in getFareBetweenStops: $e');
      rethrow;
    }
  }
}
