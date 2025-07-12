// lib/features/payments/domain/entities/payment.dart
import 'package:equatable/equatable.dart';
import '../../../bookings/domain/entities/booking.dart';

class Payment extends Equatable {
  final int id;
  final int bookingId;
  final int userId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String? paymentProvider;
  final String? transactionId;
  final String? internalReference;
  final DateTime? paymentTime;
  final DateTime? initiatedTime;
  final String status;
  final String? failureReason;
  final Map<String, dynamic>? paymentDetails;
  final Map<String, dynamic>? webhookData;
  final ZenoPayData? zenoPayData;
  final double? refundAmount;
  final DateTime? refundTime;
  final double? commissionAmount;
  final Booking? booking;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.paymentProvider,
    this.transactionId,
    this.internalReference,
    this.paymentTime,
    this.initiatedTime,
    required this.status,
    this.failureReason,
    this.paymentDetails,
    this.webhookData,
    this.zenoPayData,
    this.refundAmount,
    this.refundTime,
    this.commissionAmount,
    this.booking,
  });

  @override
  List<Object?> get props => [
    id,
    bookingId,
    userId,
    amount,
    currency,
    paymentMethod,
    paymentProvider,
    transactionId,
    internalReference,
    paymentTime,
    initiatedTime,
    status,
    failureReason,
    paymentDetails,
    webhookData,
    zenoPayData,
    refundAmount,
    refundTime,
    commissionAmount,
    booking,
  ];

  // Helper methods
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => ['failed', 'cancelled', 'expired'].contains(status);
  bool get isMobileMoneyPayment => paymentMethod == 'mobile_money';
  bool get canRefund => isCompleted && (refundAmount ?? 0) < amount;

  String get formattedAmount => '${amount.toStringAsFixed(0)} $currency';

  String get displayStatus {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      case 'refunded':
        return 'Refunded';
      default:
        return status.toUpperCase();
    }
  }

  String get displayPaymentMethod {
    switch (paymentMethod) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'Wallet';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return paymentMethod.toUpperCase();
    }
  }

  String? get mobileMoneyProvider {
    if (!isMobileMoneyPayment || paymentDetails == null) return null;

    final phone = paymentDetails!['phone_number'] as String?;
    if (phone == null) return null;

    // Determine provider based on phone number or channel
    final channel = zenoPayData?.channel ?? paymentDetails!['channel'];
    if (channel != null) {
      if (channel.toString().toUpperCase().contains('MPESA')) return 'M-Pesa';
      if (channel.toString().toUpperCase().contains('TIGO')) return 'Tigo Pesa';
      if (channel.toString().toUpperCase().contains('AIRTEL'))
        return 'Airtel Money';
    }

    return 'Mobile Money';
  }

  Payment copyWith({
    int? id,
    int? bookingId,
    int? userId,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? paymentProvider,
    String? transactionId,
    String? internalReference,
    DateTime? paymentTime,
    DateTime? initiatedTime,
    String? status,
    String? failureReason,
    Map<String, dynamic>? paymentDetails,
    Map<String, dynamic>? webhookData,
    ZenoPayData? zenoPayData,
    double? refundAmount,
    DateTime? refundTime,
    double? commissionAmount,
    Booking? booking,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      transactionId: transactionId ?? this.transactionId,
      internalReference: internalReference ?? this.internalReference,
      paymentTime: paymentTime ?? this.paymentTime,
      initiatedTime: initiatedTime ?? this.initiatedTime,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      webhookData: webhookData ?? this.webhookData,
      zenoPayData: zenoPayData ?? this.zenoPayData,
      refundAmount: refundAmount ?? this.refundAmount,
      refundTime: refundTime ?? this.refundTime,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      booking: booking ?? this.booking,
    );
  }
}

class ZenoPayData extends Equatable {
  final String? orderId;
  final String? reference;
  final String? message;
  final String? instructions;
  final String? channel;
  final String? msisdn;

  const ZenoPayData({
    this.orderId,
    this.reference,
    this.message,
    this.instructions,
    this.channel,
    this.msisdn,
  });

  factory ZenoPayData.fromJson(Map<String, dynamic> json) {
    return ZenoPayData(
      orderId: json['order_id'] as String?,
      reference: json['reference'] as String?,
      message: json['message'] as String?,
      instructions: json['instructions'] as String?,
      channel: json['channel'] as String?,
      msisdn: json['msisdn'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    orderId,
    reference,
    message,
    instructions,
    channel,
    msisdn,
  ];

  ZenoPayData copyWith({
    String? orderId,
    String? reference,
    String? message,
    String? instructions,
    String? channel,
    String? msisdn,
  }) {
    return ZenoPayData(
      orderId: orderId ?? this.orderId,
      reference: reference ?? this.reference,
      message: message ?? this.message,
      instructions: instructions ?? this.instructions,
      channel: channel ?? this.channel,
      msisdn: msisdn ?? this.msisdn,
    );
  }
}
