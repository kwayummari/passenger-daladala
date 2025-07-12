import 'dart:async';

import 'package:daladala_smart_app/core/ui/widgets/loading_indicator.dart';
import 'package:daladala_smart_app/core/utils/phone_number_formatter.dart';
import 'package:daladala_smart_app/features/payments/domain/entities/payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentMethodOption extends StatelessWidget {
  final String name;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;
  final String? disabledMessage;
  final String? badge;
  final Color? badgeColor;

  const PaymentMethodOption({
    super.key,
    required this.name,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
    this.disabledMessage,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              isSelected && enabled
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : enabled
                  ? Colors.white
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected && enabled
                    ? AppTheme.primaryColor
                    : enabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected && enabled
                        ? AppTheme.primaryColor
                        : enabled
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    isSelected && enabled
                        ? Colors.white
                        : enabled
                        ? AppTheme.primaryColor
                        : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color:
                              enabled
                                  ? (isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textPrimaryColor)
                                  : Colors.grey.shade600,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor ?? Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled ? description : disabledMessage ?? description,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          enabled
                              ? AppTheme.textSecondaryColor
                              : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Radio<bool>(
                value: true,
                groupValue: isSelected,
                onChanged: (_) => onTap(),
                activeColor: AppTheme.primaryColor,
              )
            else
              Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

// lib/features/payments/presentation/widgets/mobile_money_input.dart
class MobileMoneyInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const MobileMoneyInput({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mobile Money Number',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '07XXXXXXXX',
              prefixText: '+255 ',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
              PhoneNumberFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (!value.startsWith('07') || value.length != 10) {
                return 'Please enter a valid Tanzanian phone number (07XXXXXXXX)';
              }
              return null;
            },
            onChanged: onChanged,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your mobile money number (M-Pesa, Tigo Pesa, or Airtel Money)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// lib/features/payments/presentation/widgets/payment_processing_dialog.dart
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

// lib/features/payments/presentation/widgets/mobile_money_instructions_dialog.dart
class MobileMoneyInstructionsDialog extends StatefulWidget {
  final Payment payment;
  final VoidCallback onCheckStatus;

  const MobileMoneyInstructionsDialog({
    super.key,
    required this.payment,
    required this.onCheckStatus,
  });

  @override
  State<MobileMoneyInstructionsDialog> createState() =>
      _MobileMoneyInstructionsDialogState();
}

class _MobileMoneyInstructionsDialogState
    extends State<MobileMoneyInstructionsDialog> {
  late Timer _timer;
  int _countdown = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeRemaining {
    final minutes = _countdown ~/ 60;
    final seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android, size: 48, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Complete Payment on Your Phone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    widget.payment.zenoPayData?.instructions ??
                        'A USSD prompt has been sent to your phone. Please follow the instructions to complete the payment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                  if (widget.payment.zenoPayData?.reference != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Reference: ${widget.payment.zenoPayData!.reference}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Time remaining: $_timeRemaining',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onCheckStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text(
                      'Check Status',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/payments/presentation/widgets/payment_success_dialog.dart
class PaymentSuccessDialog extends StatelessWidget {
  final Payment payment;

  const PaymentSuccessDialog({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 48, color: Colors.green.shade600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment of ${payment.formattedAmount} has been completed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Transaction ID',
                    payment.transactionId ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Payment Method',
                    payment.displayPaymentMethod,
                  ),
                  _buildDetailRow('Status', payment.displayStatus),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}

// lib/features/payments/presentation/widgets/payment_failed_dialog.dart
class PaymentFailedDialog extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const PaymentFailedDialog({
    super.key,
    required this.error,
    required this.onRetry,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
