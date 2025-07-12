import '../../domain/entities/transport_route.dart';

class RouteModel extends TransportRoute {
  const RouteModel({
    required int id,
    required String routeNumber,
    required String routeName,
    required String startPoint,
    required String endPoint,
    String? description,
    double? distanceKm,
    int? estimatedTimeMinutes,
    required String status,
  }) : super(
    id: id,
    routeNumber: routeNumber,
    routeName: routeName,
    startPoint: startPoint,
    endPoint: endPoint,
    description: description,
    distanceKm: distanceKm,
    estimatedTimeMinutes: estimatedTimeMinutes,
    status: status,
  );
  
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['route_id'],
      routeNumber: json['route_number'],
      routeName: json['route_name'],
      startPoint: json['start_point'],
      endPoint: json['end_point'],
      description: json['description'],
      distanceKm: double.parse(json['distance_km'].toString()),
      estimatedTimeMinutes: json['estimated_time_minutes'],
      status: json['status'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'route_id': id,
      'route_number': routeNumber,
      'route_name': routeName,
      'start_point': startPoint,
      'end_point': endPoint,
      'description': description,
      'distance_km': distanceKm,
      'estimated_time_minutes': estimatedTimeMinutes,
      'status': status,
    };
  }
}