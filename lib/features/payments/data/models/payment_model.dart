// lib/features/payments/data/models/payment_model.dart
import '../../domain/entities/payment.dart';
import '../../../bookings/data/models/booking_model.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.bookingId,
    required super.userId,
    required super.amount,
    required super.currency,
    required super.paymentMethod,
    super.paymentProvider,
    super.transactionId,
    super.internalReference,
    super.paymentTime,
    super.initiatedTime,
    required super.status,
    super.failureReason,
    super.paymentDetails,
    super.webhookData,
    super.zenoPayData,
    super.refundAmount,
    super.refundTime,
    super.commissionAmount,
    super.booking,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    // Debug print to help diagnose issues
    print('🔍 PaymentModel.fromJson received: $json');

    // Safely extract ID fields with proper null checking and type conversion
    final paymentId = _safeParseInt(json['payment_id'] ?? json['id']);
    final bookingId = _safeParseInt(json['booking_id']);
    final userId = _safeParseInt(json['user_id']);

    if (paymentId == null) {
      throw FormatException(
        'payment_id is required but was null or invalid: ${json['payment_id'] ?? json['id']}',
      );
    }

    if (bookingId == null) {
      throw FormatException(
        'booking_id is required but was null or invalid: ${json['booking_id']}',
      );
    }

    if (userId == null) {
      throw FormatException(
        'user_id is required but was null or invalid: ${json['user_id']}',
      );
    }

    return PaymentModel(
      id: paymentId,
      bookingId: bookingId,
      userId: userId,
      amount: _safeParseDouble(json['amount']) ?? 0.0,
      currency: json['currency']?.toString() ?? 'TZS',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentProvider: json['payment_provider']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      internalReference: json['internal_reference']?.toString(),
      paymentTime:
          json['payment_time'] != null
              ? _safeParseDateTime(json['payment_time'])
              : null,
      initiatedTime:
          json['initiated_time'] != null
              ? _safeParseDateTime(json['initiated_time']) ?? DateTime.now()
              : DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      failureReason: json['failure_reason']?.toString(),
      paymentDetails:
          json['payment_details'] != null
              ? Map<String, dynamic>.from(json['payment_details'])
              : null,
      webhookData:
          json['webhook_data'] != null
              ? Map<String, dynamic>.from(json['webhook_data'])
              : null,
      zenoPayData:
          json['zenopay'] != null
              ? ZenoPayData.fromJson(json['zenopay'])
              : _createZenoPayDataFromResponse(json),
      refundAmount: _safeParseDouble(json['refund_amount']),
      refundTime:
          json['refund_time'] != null
              ? _safeParseDateTime(json['refund_time'])
              : null,
      commissionAmount: _safeParseDouble(json['commission_amount']),
      booking:
          json['booking'] != null
              ? BookingModel.fromJson(json['booking'])
              : null,
    );
  }

  factory PaymentModel.fromPaymentInitiationResponse(
    Map<String, dynamic> json, {
    required int bookingId,
    required int userId,
  }) {
    print('🔍 PaymentModel.fromPaymentInitiationResponse received: $json');
    print('🔍 Using context: bookingId=$bookingId, userId=$userId');

    final paymentId = _safeParseInt(json['payment_id'] ?? json['id']);

    if (paymentId == null) {
      throw FormatException(
        'payment_id is required but was null or invalid: ${json['payment_id'] ?? json['id']}',
      );
    }

    return PaymentModel(
      id: paymentId,
      bookingId: bookingId, // Use provided context
      userId: userId, // Use provided context
      amount: _safeParseDouble(json['amount']) ?? 0.0,
      currency: json['currency']?.toString() ?? 'TZS',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentProvider: json['payment_provider']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      internalReference: json['internal_reference']?.toString(),
      paymentTime:
          json['payment_time'] != null
              ? _safeParseDateTime(json['payment_time'])
              : null,
      initiatedTime:
          json['initiated_time'] != null
              ? _safeParseDateTime(json['initiated_time']) ?? DateTime.now()
              : DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      failureReason: json['failure_reason']?.toString(),
      paymentDetails:
          json['payment_details'] != null
              ? Map<String, dynamic>.from(json['payment_details'])
              : null,
      webhookData:
          json['webhook_data'] != null
              ? Map<String, dynamic>.from(json['webhook_data'])
              : null,
      zenoPayData:
          json['zenopay'] != null
              ? ZenoPayData.fromJson(json['zenopay'])
              : _createZenoPayDataFromResponse(json),
      refundAmount: _safeParseDouble(json['refund_amount']),
      refundTime:
          json['refund_time'] != null
              ? _safeParseDateTime(json['refund_time'])
              : null,
      commissionAmount: _safeParseDouble(json['commission_amount']),
      booking: null, // Payment initiation doesn't include booking details
    );
  }

  static ZenoPayData? _createZenoPayDataFromResponse(
    Map<String, dynamic> json,
  ) {
    // If this looks like a ZenoPay response, create ZenoPayData
    if (json['external_reference'] != null ||
        json['message'] != null ||
        json['instructions'] != null) {
      return ZenoPayData(
        orderId: json['external_reference']?.toString(),
        reference: json['external_reference']?.toString(),
        message: json['message']?.toString(),
        instructions: json['instructions']?.toString(),
        channel: json['channel']?.toString(),
        msisdn: json['msisdn']?.toString(),
      );
    }
    return null;
  }

  // Safe parsing helper methods
  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _safeParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }




  Map<String, dynamic> toJson() {
    return {
      'payment_id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'payment_provider': paymentProvider,
      'transaction_id': transactionId,
      'internal_reference': internalReference,
      'payment_time': paymentTime?.toIso8601String(),
      'initiated_time': initiatedTime!.toIso8601String(),
      'status': status,
      'failure_reason': failureReason,
      'payment_details': paymentDetails,
      'webhook_data': webhookData,
      'refund_amount': refundAmount,
      'refund_time': refundTime?.toIso8601String(),
      'commission_amount': commissionAmount,
    };
  }
}

// You'll also need to add the ZenoPayDataModel if it doesn't exist
class ZenoPayDataModel {
  final String? orderId;
  final String? reference;
  final String? message;
  final String? instructions;
  final String? channel;
  final String? msisdn;

  const ZenoPayDataModel({
    this.orderId,
    this.reference,
    this.message,
    this.instructions,
    this.channel,
    this.msisdn,
  });

  factory ZenoPayDataModel.fromJson(Map<String, dynamic> json) {
    return ZenoPayDataModel(
      orderId: json['order_id']?.toString(),
      reference: json['reference']?.toString(),
      message: json['message']?.toString(),
      instructions: json['instructions']?.toString(),
      channel: json['channel']?.toString(),
      msisdn: json['msisdn']?.toString(),
    );
  }

  ZenoPayData toEntity() {
    return ZenoPayData(
      orderId: orderId,
      reference: reference,
      message: message,
      instructions: instructions,
      channel: channel,
      msisdn: msisdn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'reference': reference,
      'message': message,
      'instructions': instructions,
      'channel': channel,
      'msisdn': msisdn,
    };
  }
}
