import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/constants.dart';
import '../models/payment_model.dart';

abstract class PaymentDataSource {
  /// Process a payment for a booking
  Future<PaymentModel> processPayment({
    required int bookingId,
    required String paymentMethod,
    String? phoneNumber,
    String? transactionId,
    Map<String, dynamic>? paymentDetails,
  });

  /// Get payment history for the current user
  Future<List<PaymentModel>> getPaymentHistory();

  /// Get payment details by ID
  Future<PaymentModel> getPaymentDetails(int paymentId);

  /// Check payment status
  Future<PaymentModel> checkPaymentStatus(int paymentId);

  /// Get wallet balance for the current user
  Future<double> getWalletBalance();

  /// Top up wallet
  Future<double> topUpWallet({
    required double amount,
    required String paymentMethod,
    String? transactionId,
    Map<String, dynamic>? paymentDetails,
  });
}

class PaymentDataSourceImpl implements PaymentDataSource {
  final DioClient dioClient;

  PaymentDataSourceImpl({required this.dioClient});

  @override
  Future<PaymentModel> processPayment({
    required int bookingId,
    required String paymentMethod,
    String? phoneNumber,
    String? transactionId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final data = {
        'booking_id': bookingId,
        'payment_method': paymentMethod,
      };

      // Add phone number for mobile money payments
      if (paymentMethod == 'mobile_money' && phoneNumber != null) {
        data['phone_number'] = phoneNumber;
      }

      if (transactionId != null) {
        data['transaction_id'] = transactionId;
      }

      if (paymentDetails != null && paymentDetails.containsKey('amount')) {
        data['amount'] =
            paymentDetails['amount']; // Send calculated amount to backend
        print('📤 Sending calculated amount: ${paymentDetails['amount']}');
      }

      print('📤 Sending payment request: $data');

      final response = await dioClient.post(
        AppConstants.paymentsEndpoint,
        data: data,
      );

      print('📥 Payment response: $response');

      if (response['status'] == 'success') {
        // Get user ID from authentication context (you might need to get this from storage)
        // For now, we'll use a placeholder - you should get this from your auth service
        final userId = await _getCurrentUserId();

        // Use the special factory method for payment initiation responses
        return PaymentModel.fromPaymentInitiationResponse(
          response['data'],
          bookingId: bookingId,
          userId: userId,
        );
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      print('❌ Payment processing error: $e');
      rethrow;
    }
  }

  Future<int> _getCurrentUserId() async {
    try {
      // Method 2: From SharedPreferences (Alternative)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        return userId;
      }

      // Fallback
      return 0;
    } catch (e) {
      print('Error getting current user ID: $e');
      return 0;
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentHistory() async {
    try {
      final response = await dioClient.get(
        '${AppConstants.paymentsEndpoint}/history',
      );

      if (response['status'] == 'success') {
        final List<dynamic> paymentsData =
            response['data']['payments'] ?? response['data'];
        return paymentsData
            .map(
              (payment) => PaymentModel.fromJson(payment),
            ) // ✅ Original method
            .toList();
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaymentModel> getPaymentDetails(int paymentId) async {
    try {
      final response = await dioClient.get(
        '${AppConstants.paymentsEndpoint}/$paymentId',
      );

      if (response['status'] == 'success') {
        return PaymentModel.fromJson(response['data']); // ✅ Original method
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaymentModel> checkPaymentStatus(int paymentId) async {
    try {
      final response = await dioClient.get(
        '${AppConstants.paymentsEndpoint}/$paymentId/status',
      );

      if (response['status'] == 'success') {
        return PaymentModel.fromJson(response['data']); // ✅ Original method
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<double> getWalletBalance() async {
    try {
      final response = await dioClient.get(
        '${AppConstants.paymentsEndpoint}/wallet/balance',
      );

      if (response['status'] == 'success') {
        return response['data']['balance']?.toDouble() ?? 0.0;
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<double> topUpWallet({
    required double amount,
    required String paymentMethod,
    String? transactionId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final data = {'amount': amount, 'payment_method': paymentMethod};

      if (transactionId != null) {
        data['transaction_id'] = transactionId;
      }

      if (paymentDetails != null) {
        data['payment_details'] = paymentDetails;
      }

      final response = await dioClient.post(
        '${AppConstants.paymentsEndpoint}/wallet/topup',
        data: data,
      );

      if (response['status'] == 'success') {
        return response['data']['balance']?.toDouble() ?? 0.0;
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }
}
