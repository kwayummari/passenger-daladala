import 'package:daladala_smart_app/features/home/presentation/pages/home_page.dart';
import 'package:daladala_smart_app/features/payments/domain/entities/payment.dart';
import 'package:daladala_smart_app/features/payments/presentation/providers/payment_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../core/ui/widgets/error_view.dart';
import 'payment_detail_page.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );
    await paymentProvider.getPaymentHistory();
  }

  Future<void> _refreshPaymentHistory() async {
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );
    await paymentProvider.getPaymentHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          if (paymentProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (paymentProvider.error != null) {
            return GenericErrorView(
              message: paymentProvider.error,
              onRetry: _refreshPaymentHistory,
            );
          }

          final payments = paymentProvider.paymentHistory;

          if (payments == null || payments.isEmpty) {
            return EmptyState(
              title: 'No Payments Found',
              message: 'You haven\'t made any payments yet.',
              lottieAsset: 'assets/animations/empty_payments.json',
              buttonText: 'Book a Trip',
              onButtonPressed: () {
                // Navigate to route search or home
                HomePage.navigateToRoutes();
              },
            );
          }

          // Group payments by month
          final Map<String, List<Payment>> groupedPayments = {};
          for (final payment in payments) {
            if (payment.paymentTime == null) {
              continue; // Skip payments with null paymentTime
            }
            final monthYear = DateFormat(
              'MMMM yyyy',
            ).format(payment.paymentTime!);
            if (!groupedPayments.containsKey(monthYear)) {
              groupedPayments[monthYear] = [];
            }
            groupedPayments[monthYear]!.add(payment);
          }

          // Sort months in descending order (most recent first)
          final sortedMonths =
              groupedPayments.keys.toList()..sort((a, b) {
                final aDate = DateFormat('MMMM yyyy').parse(a);
                final bDate = DateFormat('MMMM yyyy').parse(b);
                return bDate.compareTo(aDate);
              });

          return RefreshIndicator(
            onRefresh: _refreshPaymentHistory,
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: sortedMonths.length,
              itemBuilder: (context, index) {
                final month = sortedMonths[index];
                final monthPayments = groupedPayments[month]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        month,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Payment items
                    ...monthPayments.map(
                      (payment) => _PaymentItem(
                        payment: payment,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      PaymentDetailPage(paymentId: payment.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;

  const _PaymentItem({required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Format date
    final formattedDate = payment.paymentTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(payment.paymentTime!)
        : '';

    // Determine payment method icon
    IconData methodIcon;
    switch (payment.paymentMethod) {
      case 'mobile_money':
        methodIcon = Icons.phone_android;
        break;
      case 'card':
        methodIcon = Icons.credit_card;
        break;
      case 'wallet':
        methodIcon = Icons.account_balance_wallet;
        break;
      case 'cash':
        methodIcon = Icons.money;
        break;
      default:
        methodIcon = Icons.payment;
    }

    // Determine status color
    Color statusColor;
    switch (payment.status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'failed':
        statusColor = Colors.red;
        break;
      case 'refunded':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Payment method icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(methodIcon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),

            // Payment details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment description - would normally come from booking details
                  Text(
                    'Booking #${payment.bookingId}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Amount and status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        payment.status == 'refunded'
                            ? Colors.blue
                            : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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
