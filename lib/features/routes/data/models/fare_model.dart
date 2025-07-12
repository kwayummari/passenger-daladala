import '../../domain/entities/fare.dart';

class FareModel extends Fare {
  const FareModel({
    required int id,
    required int routeId,
    required int startStopId,
    required int endStopId,
    required double amount,
    required String currency,
    required String fareType,
    required bool isActive,
  }) : super(
    id: id,
    routeId: routeId,
    startStopId: startStopId,
    endStopId: endStopId,
    amount: amount,
    currency: currency,
    fareType: fareType,
    isActive: isActive,
  );
  
  factory FareModel.fromJson(Map<String, dynamic> json) {
    return FareModel(
      id: json['fare_id'],
      routeId: json['route_id'],
      startStopId: json['start_stop_id'],
      endStopId: json['end_stop_id'],
      amount: json['amount']?.toDouble(),
      currency: json['currency'],
      fareType: json['fare_type'],
      isActive: json['is_active'] == 1,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'fare_id': id,
      'route_id': routeId,
      'start_stop_id': startStopId,
      'end_stop_id': endStopId,
      'amount': amount,
      'currency': currency,
      'fare_type': fareType,
      'is_active': isActive ? 1 : 0,
    };
  }
}