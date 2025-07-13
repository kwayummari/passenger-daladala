// lib/features/wallet/presentation/providers/wallet_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/datasource/wallet_datasource.dart';
import '../../data/models/wallet_model.dart';
import '../../data/models/wallet_transaction_model.dart';

class WalletProvider extends ChangeNotifier {
  final WalletDataSource walletDataSource;

  WalletProvider({required this.walletDataSource});

  // State variables
  bool _isLoading = false;
  bool _isTopingUp = false;
  bool _isProcessingPayment = false;
  String? _error;
  WalletModel? _wallet;
  List<WalletTransactionModel> _transactions = [];
  Map<String, dynamic>? _topupResult;

  // Getters
  bool get isLoading => _isLoading;
  bool get isTopingUp => _isTopingUp;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get error => _error;
  WalletModel? get wallet => _wallet;
  List<WalletTransactionModel> get transactions => _transactions;
  Map<String, dynamic>? get topupResult => _topupResult;

  double get balance => _wallet?.balance ?? 0.0;
  String get currency => _wallet?.currency ?? 'TZS';
  double get dailyLimit => _wallet?.dailyLimit ?? 1000000.0;
  double get monthlyLimit => _wallet?.monthlyLimit ?? 10000000.0;
  bool get isActive => _wallet?.isActive ?? true;

  String get formattedBalance {
    final balance = _wallet?.balance ?? 0.0;
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M TZS';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(0)}K TZS';
    } else {
      return '${balance.toStringAsFixed(0)} TZS';
    }
  }

  bool get hasWallet => _wallet != null;

  bool hasSufficientBalance(double amount) {
    return balance >= amount;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear topup result
  void clearTopupResult() {
    _topupResult = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Get wallet balance
  Future<void> getWalletBalance() async {
    try {
      _setLoading(true);
      clearError();

      final wallet = await walletDataSource.getWalletBalance();
      _wallet = wallet;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      print('Wallet balance error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Top up wallet (Mobile Money Only)
  Future<bool> topUpWallet({
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      _isTopingUp = true;
      clearError();
      _topupResult = null;
      notifyListeners();

      // Validate amount
      if (amount < 1000) {
        _setError('Minimum top-up amount is 1,000 TZS');
        return false;
      }

      if (amount > 5000000) {
        _setError('Maximum top-up amount is 5,000,000 TZS');
        return false;
      }

      // Validate phone number
      if (phoneNumber.isEmpty) {
        _setError('Phone number is required');
        return false;
      }

      final phoneRegex = RegExp(r'^(0|255)7\d{8}$');
      if (!phoneRegex.hasMatch(
        phoneNumber.replaceAll(RegExp(r'[\s\-\+]'), ''),
      )) {
        _setError('Invalid Tanzanian phone number. Use format: 0744963858');
        return false;
      }

      final result = await walletDataSource.topUpWallet(
        amount: amount,
        paymentMethod: 'mobile_money',
        phoneNumber: phoneNumber,
      );

      // The result should contain topup data including ZenoPay response
      _topupResult = {
        'transaction_id':
            result.balance, // This would be transaction ID from API
        'amount': amount,
        'status': 'pending',
        'zenopay': {
          'order_id': 'TOPUP_${DateTime.now().millisecondsSinceEpoch}',
          'reference': 'REF${DateTime.now().millisecondsSinceEpoch}',
          'message': 'USSD request sent to your phone',
          'instructions':
              'Please complete the payment on your mobile phone using the USSD prompt sent to your phone.',
        },
      };

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isTopingUp = false;
      notifyListeners();
    }
  }

  // Process wallet payment for booking
  Future<bool> processWalletPayment({
    required int bookingId,
    required double amount, // ✅ Added amount parameter
  }) async {
    try {
      _setProcessingPayment(true);
      _clearError();

      print('💳 Processing wallet payment:');
      print('   Booking ID: $bookingId');
      print('   Amount: $amount');
      print('   Current Balance: $balance');

      // Check sufficient balance
      if (!hasSufficientBalance(amount)) {
        _setError(
          'Insufficient wallet balance. Required: $amount, Available: $balance',
        );
        return false;
      }

      // Call the wallet payment API
      final result = await walletDataSource.processWalletPayment(
        bookingId: bookingId,
        amount: amount,
      );

      print("================= amount $amount");

      // Assuming processWalletPayment returns a WalletModel on success, null on failure
      // Update local wallet balance
      _wallet = result;

      // Refresh wallet data to get updated balance and transactions
      await getWalletBalance();

      return true;
    } catch (e) {
      print('💥 Wallet payment error: $e');
      _setError('Payment failed: ${e.toString()}');
      return false;
    } finally {
      _setProcessingPayment(false);
    }
  }

  // Helper method to set processing payment state
  void _setProcessingPayment(bool processing) {
    _isProcessingPayment = processing;
    notifyListeners();
  }

  // Helper method to clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Get wallet transactions
  Future<void> getWalletTransactions() async {
    try {
      _setLoading(true);
      clearError();

      final transactions = await walletDataSource.getWalletTransactions();
      _transactions = transactions;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      print('Wallet transactions error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh all wallet data
  Future<void> refresh() async {
    await Future.wait([getWalletBalance(), getWalletTransactions()]);
  }

  // Refresh wallet (alias for refresh method)
  Future<void> refreshWallet() async {
    await refresh();
  }

  // Clear all data (useful for logout)
  void clear() {
    _wallet = null;
    _transactions = [];
    _topupResult = null;
    _error = null;
    _isLoading = false;
    _isTopingUp = false;
    _isProcessingPayment = false;
    notifyListeners();
  }
}
