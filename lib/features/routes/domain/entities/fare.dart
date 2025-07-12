import 'package:equatable/equatable.dart';

class Fare extends Equatable {
  final int id;
  final int routeId;
  final int startStopId;
  final int endStopId;
  final double amount;
  final String currency;
  final String fareType;
  final bool isActive;
  
  const Fare({
    required this.id,
    required this.routeId,
    required this.startStopId,
    required this.endStopId,
    required this.amount,
    required this.currency,
    required this.fareType,
    required this.isActive,
  });
  
  @override
  List<Object?> get props => [
    id,
    routeId,
    startStopId,
    endStopId,
    amount,
    currency,
    fareType,
    isActive,
  ];
}