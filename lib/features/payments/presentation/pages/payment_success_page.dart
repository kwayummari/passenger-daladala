// lib/features/payments/presentation/pages/payment_success_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/payment_provider.dart';
import '../../domain/entities/payment.dart';

class PaymentSuccessPage extends StatefulWidget {
  final int? paymentId;
  final int bookingId;
  final double amount;
  final String paymentMethod;

  const PaymentSuccessPage({
    super.key,
    this.paymentId,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Payment? _payment;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPaymentDetails();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  void _loadPaymentDetails() async {
    if (widget.paymentId != null) {
      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );
      await paymentProvider.getPaymentDetails(widget.paymentId!);
      setState(() {
        _payment = paymentProvider.paymentDetails;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _shareReceipt() {
    final receiptText = '''
🎉 Payment Successful - Daladala Smart

💰 Amount: ${widget.amount.toPrice}
🚌 Booking ID: #${widget.bookingId}
💳 Payment Method: ${_getPaymentMethodName(widget.paymentMethod)}
${_payment?.transactionId != null ? '🔗 Transaction ID: ${_payment!.transactionId}' : ''}
📅 Date: ${DateTime.now().toString().split('.')[0]}

Thank you for choosing Daladala Smart! 🚍
Your trip is confirmed and ready.

Download the app: [App Store Link]
''';

    Share.share(receiptText);
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'card':
        return 'Credit/Debit Card';
      case 'cash':
        return 'Cash';
      case 'wallet':
        return 'Daladala Wallet';
      default:
        return method.toUpperCase();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  void _navigateToBookings() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/bookings',
      (route) => route.settings.name == '/home',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox(), // Remove back button
        actions: [
          IconButton(
            onPressed: _shareReceipt,
            icon: const Icon(Icons.share),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 60,
                              color: Colors.green.shade600,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Success message
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Payment Successful!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your payment has been processed successfully.\nYour trip is now confirmed!',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondaryColor,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Payment details card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Amount Paid',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  widget.amount.toPrice,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              'Booking ID',
                              '#${widget.bookingId}',
                            ),
                            _buildDetailRow(
                              'Payment Method',
                              _getPaymentMethodName(widget.paymentMethod),
                            ),
                            if (_payment?.transactionId != null)
                              _buildDetailRow(
                                'Transaction ID',
                                _payment!.transactionId!,
                              ),
                            if (_payment?.mobileMoneyProvider != null)
                              _buildDetailRow(
                                'Provider',
                                _payment!.mobileMoneyProvider!,
                              ),
                            _buildDetailRow(
                              'Date',
                              DateTime.now().toString().split(' ')[0],
                            ),
                            _buildDetailRow('Status', 'Completed'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Confirmation message
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You will receive a confirmation SMS and email with your trip details.',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    CustomButton(
                      text: 'View My Bookings',
                      onPressed: _navigateToBookings,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Back to Home',
                      onPressed: _navigateToHome
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
