// lib/features/payments/presentation/providers/payment_provider.dart
import 'dart:async';
import 'package:daladala_smart_app/core/usecases/usecase.dart';
import 'package:daladala_smart_app/features/payments/domain/usescases/check_payment_status_usecase.dart';
import 'package:daladala_smart_app/features/payments/domain/usescases/get_payment_details_usecase.dart';
import 'package:daladala_smart_app/features/payments/domain/usescases/get_payment_history_usecase.dart';
import 'package:daladala_smart_app/features/payments/domain/usescases/process_payment_usecase.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/payment.dart';

class PaymentProvider extends ChangeNotifier {
  final ProcessPaymentUseCase processPaymentUseCase;
  final GetPaymentHistoryUseCase getPaymentHistoryUseCase;
  final GetPaymentDetailsUseCase? getPaymentDetailsUseCase;
  final CheckPaymentStatusUseCase? checkPaymentStatusUseCase;

  PaymentProvider({
    required this.processPaymentUseCase,
    required this.getPaymentHistoryUseCase,
    this.getPaymentDetailsUseCase,
    this.checkPaymentStatusUseCase,
  });

  // State variables
  bool _isLoading = false;
  bool _isProcessingPayment = false;
  bool _isCheckingStatus = false;
  String? _error;
  List<Payment>? _paymentHistory;
  Payment? _currentPayment;
  Payment? _paymentDetails;
  Timer? _statusCheckTimer;

  // Getters
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  bool get isCheckingStatus => _isCheckingStatus;
  String? get error => _error;
  List<Payment>? get paymentHistory => _paymentHistory;
  Payment? get currentPayment => _currentPayment;
  Payment? get paymentDetails => _paymentDetails;

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setProcessingPayment(bool processing) {
    _isProcessingPayment = processing;
    notifyListeners();
  }

  void _setCheckingStatus(bool checking) {
    _isCheckingStatus = checking;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Clear current payment
  void clearCurrentPayment() {
    _currentPayment = null;
    _stopStatusChecking();
    notifyListeners();
  }

  // Process payment (existing method with proper params)
  Future<bool> processPayment({
    required int bookingId,
    required String paymentMethod,
    String? phoneNumber,
    String? transactionId,
    String? amount,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      _setProcessingPayment(true);
      _clearError();

      final result = await processPaymentUseCase.call(
        ProcessPaymentParams(
          bookingId: bookingId,
          paymentMethod: paymentMethod,
          phoneNumber: phoneNumber,
          transactionId: transactionId,
          paymentDetails: paymentDetails,
          amount: amount
        ),
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (payment) {
          _currentPayment = payment;

          // Start status checking for mobile money payments
          if (paymentMethod == 'mobile_money' && payment.isPending) {
            _startStatusChecking(payment.id);
          }

          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setProcessingPayment(false);
    }
  }

  // NEW: Process mobile money payment
  Future<bool> processMobileMoneyPayment({
    required int bookingId,
    required String phoneNumber,
    required double amount,
  }) async {
    return await processPayment(
      bookingId: bookingId,
      paymentMethod: 'mobile_money',
      phoneNumber: phoneNumber,
      paymentDetails: {
        'amount': amount,
        'phone_number': phoneNumber,
      },
    );
  }

  // NEW: Process wallet payment
  Future<bool> processWalletPayment(int bookingId, {
    required double amount, 
  }) async {
    return await processPayment(
      bookingId: bookingId,
      paymentMethod: 'wallet',
      paymentDetails: {
        'amount': amount,
      },
    );
  }

  // Get payment history
  Future<void> getPaymentHistory() async {
    try {
      _setLoading(true);
      _clearError();

      final result = await getPaymentHistoryUseCase.call(const NoParams());

      result.fold((failure) => _setError(failure.message), (payments) {
        _paymentHistory = payments;
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get payment details
  Future<void> getPaymentDetails(int paymentId) async {
    if (getPaymentDetailsUseCase == null) return;

    try {
      _setLoading(true);
      _clearError();

      final result = await getPaymentDetailsUseCase!.call(
        GetPaymentDetailsParams(paymentId: paymentId),
      );

      result.fold((failure) => _setError(failure.message), (payment) {
        _paymentDetails = payment;
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Check payment status
  Future<void> checkPaymentStatus(int paymentId) async {
    if (checkPaymentStatusUseCase == null) return;

    try {
      _setCheckingStatus(true);
      _clearError();

      final result = await checkPaymentStatusUseCase!.call(
        CheckPaymentStatusParams(paymentId: paymentId),
      );

      result.fold((failure) => _setError(failure.message), (payment) {
        _currentPayment = payment;

        // Stop status checking if payment is completed or failed
        if (payment.isCompleted || payment.isFailed) {
          _stopStatusChecking();
        }

        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setCheckingStatus(false);
    }
  }

  // Start automatic status checking for pending payments
  void _startStatusChecking(int paymentId) {
    _stopStatusChecking(); // Stop any existing timer

    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 10), // Check every 10 seconds
      (timer) async {
        await checkPaymentStatus(paymentId);

        // Stop checking if payment is no longer pending
        if (_currentPayment != null &&
            (!_currentPayment!.isPending || _currentPayment!.isFailed)) {
          _stopStatusChecking();
        }
      },
    );
  }

  // Stop automatic status checking
  void _stopStatusChecking() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  // Clear all data (useful for logout)
  void clear() {
    _currentPayment = null;
    _paymentHistory = null;
    _paymentDetails = null;
    _error = null;
    _isLoading = false;
    _isProcessingPayment = false;
    _isCheckingStatus = false;
    _stopStatusChecking();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopStatusChecking();
    super.dispose();
  }
}

// Parameters classes (only if they don't exist in the use case files)
// Remove these if they already exist in your use case files
class GetPaymentDetailsParams {
  final int paymentId;

  GetPaymentDetailsParams({required this.paymentId});
}

class CheckPaymentStatusParams {
  final int paymentId;

  CheckPaymentStatusParams({required this.paymentId});
}
