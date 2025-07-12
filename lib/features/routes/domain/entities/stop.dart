import 'package:equatable/equatable.dart';

class Stop extends Equatable {
  final int id;
  final String stopName;
  final double latitude;
  final double longitude;
  final String? address;
  final bool isMajor;
  final String status;
  
  const Stop({
    required this.id,
    required this.stopName,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.isMajor,
    required this.status,
  });
  
  @override
  List<Object?> get props => [
    id,
    stopName,
    latitude,
    longitude,
    address,
    isMajor,
    status,
  ];
}