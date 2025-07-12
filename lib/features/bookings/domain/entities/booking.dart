import 'package:equatable/equatable.dart';

class Booking extends Equatable {
  final int id;
  final int userId;
  final int tripId;
  final int pickupStopId;
  final int dropoffStopId;
  final DateTime bookingTime;
  final double fareAmount;
  final int passengerCount;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields that might be included from API but are not in the base model
  final Map<String, dynamic>? trip;
  final Map<String, dynamic>? pickupStop;
  final Map<String, dynamic>? dropoffStop;
  final Map<String, dynamic>? payment;
  final Map<String, dynamic>? user;
  
  const Booking({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.pickupStopId,
    required this.dropoffStopId,
    required this.bookingTime,
    required this.fareAmount,
    required this.passengerCount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    this.trip,
    this.pickupStop,
    this.dropoffStop,
    this.payment,
    this.user,
  });
  
  Booking copyWith({
    int? id,
    int? userId,
    int? tripId,
    int? pickupStopId,
    int? dropoffStopId,
    DateTime? bookingTime,
    double? fareAmount,
    int? passengerCount,
    String? status,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? trip,
    Map<String, dynamic>? pickupStop,
    Map<String, dynamic>? dropoffStop,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? user,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      pickupStopId: pickupStopId ?? this.pickupStopId,
      dropoffStopId: dropoffStopId ?? this.dropoffStopId,
      bookingTime: bookingTime ?? this.bookingTime,
      fareAmount: fareAmount ?? this.fareAmount,
      passengerCount: passengerCount ?? this.passengerCount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trip: trip ?? this.trip,
      pickupStop: pickupStop ?? this.pickupStop,
      dropoffStop: dropoffStop ?? this.dropoffStop,
      payment: payment ?? this.payment,
      user: user ?? this.user,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    userId,
    tripId,
    pickupStopId,
    dropoffStopId,
    bookingTime,
    fareAmount,
    passengerCount,
    status,
    paymentStatus,
    createdAt,
    updatedAt,
  ];
}