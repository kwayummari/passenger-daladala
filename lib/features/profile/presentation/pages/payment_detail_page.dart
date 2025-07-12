import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/utils/extensions.dart';

class PaymentDetailPage extends StatefulWidget {
  final int paymentId;

  const PaymentDetailPage({super.key, required this.paymentId});

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  bool _isLoading = true;

  // Sample payment data (in real app, this would come from API)
  late Map<String, dynamic> _paymentData;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Sample data
    _paymentData = {
      'id': widget.paymentId,
      'bookingId': 123,
      'userId': 2,
      'amount': 1500.0,
      'currency': 'TZS',
      'paymentMethod': 'mobile_money',
      'transactionId': 'MM123456789',
      'paymentTime': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
      'paymentDetails': {
        'provider': 'M-Pesa',
        'phoneNumber': '+255712345678',
        'reference': 'DSM/123/456',
      },
      'trip': {
        'routeName': 'Mbezi - CBD',
        'from': 'Mbezi Mwisho',
        'to': 'Posta CBD',
      },
    };

    setState(() {
      _isLoading = false;
    });
  }

  void _shareReceipt() async {
    final receiptText = '''
Payment Receipt
-------------------
Transaction ID: ${_paymentData['transactionId']}
Amount: ${_paymentData['amount']} ${_paymentData['currency']}
Status: ${_paymentData['status']}
Method: ${_getFormattedPaymentMethod(_paymentData['paymentMethod'])}
Route: ${_paymentData['trip']['routeName']}
From: ${_paymentData['trip']['from']}
To: ${_paymentData['trip']['to']}
Date: ${DateFormat('dd MMM yyyy, HH:mm').format(_paymentData['paymentTime'])}
  ''';

    Share.share(receiptText);
  }

  Future<void> _downloadReceipt() async {
    setState(() => _isLoading = true);

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission denied'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final directory = await getExternalStorageDirectory();
      final path = directory?.path ?? '/storage/emulated/0/Download';
      final fileName = 'receipt_${_paymentData['transactionId']}.txt';
      final file = File('$path/$fileName');

      final receiptText = '''
Payment Receipt
-------------------
Transaction ID: ${_paymentData['transactionId']}
Amount: ${_paymentData['amount']} ${_paymentData['currency']}
Status: ${_paymentData['status']}
Method: ${_getFormattedPaymentMethod(_paymentData['paymentMethod'])}
Route: ${_paymentData['trip']['routeName']}
From: ${_paymentData['trip']['from']}
To: ${_paymentData['trip']['to']}
Date: ${DateFormat('dd MMM yyyy, HH:mm').format(_paymentData['paymentTime'])}
    ''';

      await file.writeAsString(receiptText);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt saved to $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download receipt'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyTransactionId() {
    final transactionId = _paymentData['transactionId'];
    if (transactionId != null) {
      Clipboard.setData(ClipboardData(text: transactionId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction ID copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Add the missing _getStatusColor method
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return AppTheme.textPrimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareReceipt),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: LoadingIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success header
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Payment Successful',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(_paymentData['paymentTime']),
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Payment amount
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Amount Paid',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_paymentData['amount'].toStringAsFixed(0)} ${_paymentData['currency']}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment details
                    const Text(
                      'Payment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      'Payment Method',
                      _getFormattedPaymentMethod(_paymentData['paymentMethod']),
                    ),
                    _buildDetailItem(
                      'Status',
                      _paymentData['status'].toUpperCase(),
                      valueColor: _getStatusColor(_paymentData['status']),
                    ),
                    _buildDetailItem(
                      'Transaction ID',
                      _paymentData['transactionId'] ?? 'N/A',
                      onTap:
                          _paymentData['transactionId'] != null
                              ? _copyTransactionId
                              : null,
                      trailingIcon:
                          _paymentData['transactionId'] != null
                              ? Icons.copy
                              : null,
                    ),

                    const SizedBox(height: 24),

                    // Trip details
                    const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      'Route',
                      _paymentData['trip']['routeName'],
                    ),
                    _buildDetailItem('From', _paymentData['trip']['from']),
                    _buildDetailItem('To', _paymentData['trip']['to']),
                    _buildDetailItem(
                      'Booking ID',
                      '#${_paymentData['bookingId']}',
                    ),

                    const SizedBox(height: 32),

                    // Download button
                    CustomButton(
                      text: 'Download Receipt',
                      onPressed: _downloadReceipt,
                      icon: Icons.download,
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    Color? valueColor,
    VoidCallback? onTap,
    IconData? trailingIcon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: AppTheme.textSecondaryColor)),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 4),
                  Icon(trailingIcon, size: 16, color: AppTheme.primaryColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedPaymentMethod(String method) {
    switch (method) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'Wallet';
      case 'cash':
        return 'Cash';
      default:
        return method.replaceAll('_', ' ').capitalize;
    }
  }
}
