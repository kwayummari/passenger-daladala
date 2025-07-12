import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/utils/extensions.dart';
import '../../../trips/presentation/pages/trip_detail_page.dart';
import '../../../home/presentation/pages/home_page.dart';

class BookingSuccessPage extends StatelessWidget {
  final int bookingId;
  final int tripId;
  final String routeName;
  final String from;
  final String to;
  final DateTime startTime;
  final double amount;
  final int passengerCount;
  final String paymentMethod;

  const BookingSuccessPage({
    super.key,
    required this.bookingId,
    required this.tripId,
    required this.routeName,
    required this.from,
    required this.to,
    required this.startTime,
    required this.amount,
    required this.passengerCount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    // Format date and time
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(startTime);
    final formattedTime = DateFormat('HH:mm').format(startTime);
    
    // Format payment method display
    String displayPaymentMethod;
    switch (paymentMethod) {
      case 'mobile_money':
        displayPaymentMethod = 'M-Pesa';
        break;
      case 'tigo_pesa':
        displayPaymentMethod = 'Tigo Pesa';
        break;
      case 'airtel_money':
        displayPaymentMethod = 'Airtel Money';
        break;
      case 'card':
        displayPaymentMethod = 'Credit/Debit Card';
        break;
      case 'wallet':
        displayPaymentMethod = 'Wallet';
        break;
      case 'cash':
        displayPaymentMethod = 'Cash';
        break;
      default:
        displayPaymentMethod = 'Unknown';
    }
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Animation and success message
                    Lottie.asset(
                      'assets/animations/success.json',
                      width: 200,
                      height: 200,
                      repeat: false,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Booking Successful!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your trip has been booked successfully. Thank you for using Daladala Smart!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),
                    
                    // Booking details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Booking ID
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking ID',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              Text(
                                '#$bookingId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          
                          // Route info
                          _BookingDetailItem(
                            icon: Icons.directions_bus,
                            title: 'Route',
                            value: routeName,
                          ),
                          const SizedBox(height: 16),
                          
                          // Origin and destination
                          _BookingDetailItem(
                            icon: Icons.location_on_outlined,
                            title: 'From',
                            value: from,
                          ),
                          const SizedBox(height: 16),
                          _BookingDetailItem(
                            icon: Icons.flag_outlined,
                            title: 'To',
                            value: to,
                          ),
                          const SizedBox(height: 16),
                          
                          // Date and time
                          _BookingDetailItem(
                            icon: Icons.calendar_today,
                            title: 'Date',
                            value: formattedDate,
                          ),
                          const SizedBox(height: 16),
                          _BookingDetailItem(
                            icon: Icons.access_time,
                            title: 'Time',
                            value: formattedTime,
                          ),
                          const SizedBox(height: 16),
                          
                          // Passengers and payment
                          _BookingDetailItem(
                            icon: Icons.people,
                            title: 'Passengers',
                            value: passengerCount.toString(),
                          ),
                          const SizedBox(height: 16),
                          _BookingDetailItem(
                            icon: Icons.payment,
                            title: 'Payment Method',
                            value: displayPaymentMethod,
                          ),
                          const SizedBox(height: 16),
                          _BookingDetailItem(
                            icon: Icons.receipt_long,
                            title: 'Amount Paid',
                            value: amount.toPrice,
                            valueColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Important notes
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Important Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Please arrive at the pickup location 10 minutes before departure time.',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Keep this booking confirmation for reference.',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• You can track your trip in real-time from the app.',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'View Trip',
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailPage(tripId: tripId),
                          ),
                          (route) => route.isFirst,
                        );
                      },
                      type: ButtonType.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Go to Home',
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>  HomePage(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingDetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _BookingDetailItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}