import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../providers/booking_provider.dart';
import '../../../trips/presentation/pages/trip_detail_page.dart';

class BookingDetailPage extends StatefulWidget {
  final int bookingId;

  const BookingDetailPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBookingDetails();
      });
  }
  
  Future<void> _loadBookingDetails() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    await bookingProvider.getBookingDetails(widget.bookingId);
  }
  
  Future<void> _cancelBooking() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? Cancellation may be subject to fees.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      // Call the cancelBooking method and let the provider handle the state updates
      await bookingProvider.cancelBooking(widget.bookingId);
      
      // Check for errors after the operation is complete
      if (mounted) {
        if (bookingProvider.error != null) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(bookingProvider.error!),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const Center(
              child: LoadingIndicator(),
            );
          }
          
          if (bookingProvider.error != null) {
            return GenericErrorView(
              message: bookingProvider.error,
              onRetry: _loadBookingDetails,
            );
          }
          
          final booking = bookingProvider.currentBooking;
          
          if (booking == null) {
            return const GenericErrorView(
              message: 'Booking not found',
            );
          }
          
          // Format dates
          final formattedBookingDate = DateFormat('dd MMM yyyy, HH:mm').format(booking.bookingTime);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking ID and status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(booking.status),
                        color: _getStatusColor(booking.status),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking #${booking.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedBookingDate,
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.status.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Trip details
                _buildSectionHeader('Trip Details'),
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
                      // Route info would come from trip details
                      _buildDetailRow(
                        'Trip ID',
                        '#${booking.tripId}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'From',
                        'Stop #${booking.pickupStopId}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'To',
                        'Stop #${booking.dropoffStopId}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Passengers',
                        booking.passengerCount.toString(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Payment details
                _buildSectionHeader('Payment Details'),
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
                      _buildDetailRow(
                        'Status',
                        booking.paymentStatus.toUpperCase(),
                        valueColor: booking.paymentStatus == 'paid'
                            ? Colors.green
                            : booking.paymentStatus == 'failed'
                                ? Colors.red
                                : Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Amount',
                        'TZS ${booking.fareAmount.toStringAsFixed(0)}',
                        valueColor: AppTheme.primaryColor,
                        valueFontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Payment Method',
                        booking.paymentStatus == 'paid' ? 'Mobile Money' : '-',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Action buttons
                Row(
                  children: [
                    if (['pending', 'confirmed'].contains(booking.status)) ...[
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel Booking',
                          onPressed: _cancelBooking,
                          type: ButtonType.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: CustomButton(
                        text: 'View Trip',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripDetailPage(tripId: booking.tripId),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: valueFontWeight ?? FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.pendingColor;
      case 'confirmed':
        return AppTheme.confirmedColor;
      case 'in_progress':
        return AppTheme.inProgressColor;
      case 'completed':
        return AppTheme.completedColor;
      case 'cancelled':
        return AppTheme.cancelledColor;
      default:
        return AppTheme.pendingColor;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.directions_bus;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }
}