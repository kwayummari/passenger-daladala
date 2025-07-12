import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/payment.dart';

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
