import 'package:flutter/material.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';

class PaymentProcessingDialog extends StatelessWidget {
  final String paymentMethod;
  final double amount;
  final String currency;

  const PaymentProcessingDialog({
    super.key,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Processing Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing your ${_getPaymentMethodName(paymentMethod)} payment of $amount $currency...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'mobile_money':
        return 'mobile money';
      case 'card':
        return 'card';
      case 'cash':
        return 'cash';
      case 'wallet':
        return 'wallet';
      default:
        return method;
    }
  }
}
