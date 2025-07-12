
// lib/features/wallet/data/datasources/wallet_datasource.dart
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';

abstract class WalletDataSource {
  Future<WalletModel> getWalletBalance();
  Future<WalletModel> topUpWallet({
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  });
  Future<List<WalletTransactionModel>> getWalletTransactions();
  Future<WalletModel> processWalletPayment({required int bookingId, required double amount,
  });
}

class WalletDataSourceImpl implements WalletDataSource {
  final DioClient dioClient;
  
  WalletDataSourceImpl({required this.dioClient});
  
  @override
  Future<WalletModel> getWalletBalance() async {
    try {
      final response = await dioClient.get('/wallet/balance');
      
      if (response['status'] == 'success') {
        return WalletModel.fromJson(response['data']);
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<WalletModel> topUpWallet({
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final data = {
        'amount': amount,
        'payment_method': paymentMethod,
      };
      
      if (phoneNumber != null) {
        data['phone_number'] = phoneNumber;
      }
      
      final response = await dioClient.post('/wallet/topup', data: data);
      
      if (response['status'] == 'success') {
        // For mobile money, return wallet with pending status
        if (paymentMethod == 'mobile_money') {
          return WalletModel.fromJson({
            'wallet_id': 0,
            'user_id': 0,
            'balance': 0,
            'currency': 'TZS',
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'zenopay_data': response['data'],
          });
        }
        return WalletModel.fromJson(response['data']);
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<List<WalletTransactionModel>> getWalletTransactions() async {
    try {
      final response = await dioClient.get('/wallet/transactions');
      
      if (response['status'] == 'success') {
        final List<dynamic> transactionsData = response['data']['transactions'];
        return transactionsData
            .map((transaction) => WalletTransactionModel.fromJson(transaction))
            .toList();
      } else {
        throw ServerException(message: response['message']);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<WalletModel> processWalletPayment({
    required int bookingId,
    required double amount,
  }) async {
    try {
      print('🌐 WalletDataSource: Processing wallet payment');
      print('   Booking ID: $bookingId');
      print('   Amount: $amount');

      final response = await dioClient.post(
        '/payments', // This calls POST /api/payments
        data: {
          'booking_id': bookingId,
          'payment_method': 'wallet',
          'amount': amount, // ✅ Include amount in request
          'currency': 'TZS',
        },
      );

      print('📡 Wallet payment response: $response');

      if (response != null && response['status'] == 'success') {
        return WalletModel.fromJson(response['data']);
      } else {
        throw ServerException(message: response?['message'] ?? 'Wallet payment failed');
      }
    } catch (e) {
      print('💥 WalletDataSource error: $e');
      rethrow;
    }
  }
}