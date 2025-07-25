import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../providers/booking_provider.dart';
import '../../domain/entities/booking.dart';

class BookingDetailPage extends StatefulWidget {
  final int bookingId;

  const BookingDetailPage({super.key, required this.bookingId});

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
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    await bookingProvider.getBookingDetails(widget.bookingId);
  }

  Future<void> _cancelBooking() async {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Booking'),
            content: const Text(
              'Are you sure you want to cancel this booking? Cancellation may be subject to fees.',
            ),
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
          // Navigate back
          Navigator.pop(context);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookingDetails,
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (bookingProvider.error != null) {
            return GenericErrorView(
              message: bookingProvider.error,
              onRetry: _loadBookingDetails,
            );
          }

          final booking = bookingProvider.currentBooking;

          if (booking == null) {
            return const GenericErrorView(message: 'Booking not found');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking header card
                _buildBookingHeader(booking),
                const SizedBox(height: 16),

                // QR Code section (if available)
                if (booking.hasQrCode) ...[
                  _buildQrCodeSection(booking),
                  const SizedBox(height: 16),
                ],

                // Trip details
                _buildTripDetailsSection(booking),
                const SizedBox(height: 16),

                // Passenger details
                _buildPassengerDetailsSection(booking),
                const SizedBox(height: 16),

                // Payment details
                _buildPaymentDetailsSection(booking),
                const SizedBox(height: 16),

                // Seat information (if available)
                if (booking.hasSeats) ...[
                  _buildSeatDetailsSection(booking),
                  const SizedBox(height: 16),
                ],

                // Related bookings (for multi-day bookings)
                if (booking.relatedBookings != null &&
                    booking.relatedBookings!.isNotEmpty) ...[
                  _buildRelatedBookingsSection(booking),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                _buildActionButtons(booking),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingHeader(Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusIcon = _getStatusIcon(booking.status);

    return Card(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking #${booking.id}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            booking.status.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (booking.isPaid)
                    const Icon(Icons.verified, color: Colors.green, size: 24),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Fare',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        '${booking.totalFare.toStringAsFixed(0)} TZS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Passengers',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        '${booking.passengerCount}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCodeSection(Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Show QR Code to Driver',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:
                  booking.qrCode != null
                      ? QrImageView(
                        data: booking.qrCode!,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      )
                      : Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code, size: 60, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'QR Code not available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
            ),
            const SizedBox(height: 12),
            Text(
              'Booking ID: ${booking.id}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Present this QR code to the driver when boarding',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailsSection(Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Route information
            if (booking.routeInfo != null) ...[
              _buildDetailRow(
                'Route',
                booking.routeInfo!.routeName,
                Icons.route,
              ),
              const SizedBox(height: 12),
            ],

            // Pickup location
            _buildDetailRow(
              'Pickup Location',
              booking.pickupStop?.stopName ?? 'Unknown',
              Icons.my_location,
              color: Colors.green,
            ),
            const SizedBox(height: 12),

            // Dropoff location
            _buildDetailRow(
              'Dropoff Location',
              booking.dropoffStop?.stopName ?? 'Unknown',
              Icons.location_on,
              color: Colors.red,
            ),
            const SizedBox(height: 12),

            // Travel date
            if (booking.travelDate != null)
              _buildDetailRow(
                'Travel Date',
                DateFormat('EEEE, dd MMMM yyyy').format(booking.travelDate!),
                Icons.calendar_today,
              ),

            if (booking.travelDate != null) const SizedBox(height: 12),

            // Travel time
            if (booking.travelDate != null)
              _buildDetailRow(
                'Travel Time',
                DateFormat('HH:mm').format(booking.travelDate!),
                Icons.schedule,
              ),

            // Booking date
            const SizedBox(height: 12),
            _buildDetailRow(
              'Booking Date',
              DateFormat('dd MMM yyyy, HH:mm').format(booking.bookingTime),
              Icons.event,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerDetailsSection(Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Passenger Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              'Number of Passengers',
              '${booking.passengerCount}',
              Icons.people,
            ),
            const SizedBox(height: 12),

            _buildDetailRow(
              'Booking Type',
              booking.bookingType.replaceAll('_', ' ').toUpperCase(),
              Icons.bookmark,
            ),

            if (booking.isMultiDay) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Multi-Day Booking',
                'Yes',
                Icons.date_range,
                color: Colors.blue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsSection(Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              'Payment Status',
              booking.paymentStatus.replaceAll('_', ' ').toUpperCase(),
              booking.isPaid ? Icons.check_circle : Icons.pending,
              color: booking.isPaid ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),

            _buildDetailRow(
              'Individual Fare',
              '${booking.fareAmount.toStringAsFixed(0)} TZS',
              Icons.money,
            ),
            const SizedBox(height: 12),

            _buildDetailRow(
              'Total Amount',
              '${booking.totalFare.toStringAsFixed(0)} TZS',
              Icons.account_balance_wallet,
              color: AppTheme.primaryColor,
            ),

            if (booking.passengerCount > 1) ...[
              const SizedBox(height: 8),
              Text(
                '${booking.fareAmount.toStringAsFixed(0)} TZS × ${booking.passengerCount} passengers',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeatDetailsSection(Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seat Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            if (booking.seatNumbers != null &&
                booking.seatNumbers!.isNotEmpty) ...[
              _buildDetailRow(
                'Assigned Seats',
                booking.seatNumbers!.join(', '),
                Icons.airline_seat_recline_normal,
                color: Colors.blue,
              ),
            ] else ...[
              _buildDetailRow(
                'Seat Assignment',
                'No specific seats assigned',
                Icons.airline_seat_recline_normal,
                color: Colors.grey,
              ),
            ],

            // Show detailed seat information if available
            if (booking.seatDetails != null &&
                booking.seatDetails!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Seat Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...booking.seatDetails!.map((seat) => _buildSeatDetailCard(seat)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeatDetailCard(SeatDetail seat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            seat.isOccupied
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: seat.isOccupied ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.airline_seat_recline_normal,
            color: seat.isOccupied ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seat ${seat.seatNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (seat.passengerName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    seat.passengerName!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
                if (seat.seatType != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    seat.seatType!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (seat.hasBoarded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'BOARDED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRelatedBookingsSection(Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Related Bookings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${booking.relatedBookings!.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (booking.bookingReference != null) ...[
              _buildDetailRow(
                'Booking Reference',
                booking.bookingReference!,
                Icons.receipt_long,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
            ],

            ...booking.relatedBookings!
                .take(3)
                .map(
                  (relatedBooking) => _buildRelatedBookingCard(relatedBooking),
                ),

            if (booking.relatedBookings!.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '... and ${booking.relatedBookings!.length - 3} more bookings',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedBookingCard(RelatedBooking relatedBooking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.grey[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(relatedBooking.travelDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (relatedBooking.routeName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    relatedBooking.routeName!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${relatedBooking.fareAmount.toStringAsFixed(0)} TZS',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getStatusColor(relatedBooking.status),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  relatedBooking.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Booking booking) {
    return Column(
      children: [
        // Primary action button based on booking status
        if (booking.status == 'pending' || booking.status == 'confirmed') ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Cancel Booking',
              onPressed: _cancelBooking,
              backgroundColor: Colors.red,
            ),
          ),
        ] else if (booking.status == 'in_progress') ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Track Trip',
              onPressed: () {
                // Navigate to trip tracking
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trip tracking will be available soon'),
                  ),
                );
              },
              backgroundColor: Colors.blue,
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Share booking details
                  _shareBookingDetails(booking);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Contact support
                  _contactSupport(booking);
                },
                icon: const Icon(Icons.support_agent),
                label: const Text('Support'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _shareBookingDetails(Booking booking) async {
    final details = '''
Booking Details - Daladala Smart

Booking ID: #${booking.id}
Route: ${booking.routeInfo?.routeName ?? 'Unknown'}
From: ${booking.pickupStop?.stopName ?? 'Unknown'}
To: ${booking.dropoffStop?.stopName ?? 'Unknown'}
Passengers: ${booking.passengerCount}
Total Fare: ${booking.totalFare.toStringAsFixed(0)} TZS
Travel Date: ${booking.travelDate != null ? DateFormat('dd MMM yyyy, HH:mm').format(booking.travelDate!) : 'TBD'}
Status: ${booking.status.replaceAll('_', ' ').toUpperCase()}
Payment: ${booking.paymentStatus.replaceAll('_', ' ').toUpperCase()}

${booking.hasQrCode ? 'QR Code available for driver scanning' : ''}

Download Daladala Smart app for easy bus booking!
    ''';

    // final bytes = await rootBundle.load('assets/logo.png');
    // final tempDir = await getTemporaryDirectory();
    // final file = File('${tempDir.path}/logo.png');
    // await file.writeAsBytes(bytes.buffer.asUint8List());

    await SharePlus.instance.share(
      ShareParams(
        // files: [XFile(file.path)],
        title: 'Daladala Smart Booking Details',
        subject: 'Daladala Smart Booking #${booking.id}',
        text: details,
      ),
    );
  }

  void _contactSupport(Booking booking) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Contact Support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.phone, color: AppTheme.primaryColor),
                  title: const Text('Call Support'),
                  subtitle: const Text('+255 XXX XXX XXX'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement phone call
                  },
                ),
                ListTile(
                  leading: Icon(Icons.email, color: AppTheme.primaryColor),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@daladalasmart.com'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement email
                  },
                ),
                ListTile(
                  leading: Icon(Icons.chat, color: AppTheme.primaryColor),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Chat with our support team'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement live chat
                  },
                ),
              ],
            ),
          ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.directions_bus;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
