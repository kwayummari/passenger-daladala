import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../providers/booking_provider.dart';
import '../../domain/entities/booking.dart';
import 'booking_detail_page.dart';
import '../../../auth/presentation/pages/home_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }

    String? filter;
    switch (_tabController.index) {
      case 0:
        filter = null; // All bookings
        break;
      case 1:
        filter = 'pending,confirmed'; // Upcoming
        break;
      case 2:
        filter = 'in_progress'; // Active
        break;
      case 3:
        filter = 'completed,cancelled'; // Past
        break;
    }

    if (filter != _currentFilter) {
      setState(() {
        _currentFilter = filter;
      });
      _loadBookings();
    }
  }

  Future<void> _loadBookings() async {
    print('🔍 Loading bookings with filter: $_currentFilter');

    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    await bookingProvider.getUserBookings(status: _currentFilter);

    print('🔍 BookingProvider error: ${bookingProvider.error}');
    print(
      '🔍 BookingProvider bookings count: ${bookingProvider.userBookings?.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            if (bookingProvider.isLoading) {
              return const Center(child: LoadingIndicator());
            }

            if (bookingProvider.error != null) {
              return GenericErrorView(
                message: bookingProvider.error,
                onRetry: _loadBookings,
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_getAllBookings(bookingProvider)), // All
                _buildBookingsList(
                  _getUpcomingBookings(bookingProvider),
                ), // Upcoming
                _buildBookingsList(
                  _getActiveBookings(bookingProvider),
                ), // Active
                _buildBookingsList(_getPastBookings(bookingProvider)), // Past
              ],
            );
          },
        ),
      ),
    );
  }

  List<Booking> _getAllBookings(BookingProvider provider) {
    return provider.userBookings ?? [];
  }

  List<Booking> _getUpcomingBookings(BookingProvider provider) {
    final bookings = provider.userBookings ?? [];
    return bookings.where((booking) {
      return ['pending', 'confirmed'].contains(booking.status) &&
          !_isPastBooking(booking);
    }).toList();
  }

  List<Booking> _getActiveBookings(BookingProvider provider) {
    final bookings = provider.userBookings ?? [];
    return bookings.where((booking) {
      return booking.status == 'in_progress';
    }).toList();
  }

  List<Booking> _getPastBookings(BookingProvider provider) {
    final bookings = provider.userBookings ?? [];
    return bookings.where((booking) {
      return ['completed', 'cancelled'].contains(booking.status) ||
          _isPastBooking(booking);
    }).toList();
  }

  bool _isPastBooking(Booking booking) {
    // Check if travel date or booking date has passed
    final now = DateTime.now();
    final checkDate =
        booking.travelDate ?? booking.bookingDate ?? booking.bookingTime;

    // If the date is more than 1 day ago, consider it past
    return checkDate.isBefore(now.subtract(const Duration(days: 1)));
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return EmptyState(
        title: 'No Bookings Found',
        message:
            'You don\'t have any bookings${_currentFilter != null ? ' in this category' : ''}.',
        buttonText: 'Book a Trip',
        onButtonPressed: () {
          // Navigate to routes page
          if (HomePage.homeKey.currentState != null) {
            HomePage.navigateToTab(1);
          }
        },
      );
    }

    return ListView.builder(
      itemCount: bookings.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusIcon = _getStatusIcon(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailPage(bookingId: booking.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Status header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Booking #${booking.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // QR Code indicator
                  if (booking.hasQrCode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code, color: Colors.white, size: 14),
                          SizedBox(width: 2),
                          Text(
                            'QR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Status chip
                  _buildStatusChip(booking.status),
                ],
              ),
            ),

            // Booking details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route info
                  if (booking.routeInfo != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.route, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.routeInfo!.routeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // From and To stops
                  Row(
                    children: [
                      Expanded(
                        child: _buildStopInfo(
                          'From',
                          booking.pickupStop?.stopName ?? 'Unknown',
                          Icons.my_location,
                          Colors.green,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: _buildStopInfo(
                          'To',
                          booking.dropoffStop?.stopName ?? 'Unknown',
                          Icons.location_on,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bottom info row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Passenger count
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${booking.passengerCount} passenger${booking.passengerCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      // Fare amount
                      Text(
                        '${booking.totalFare.toStringAsFixed(0)} TZS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  // Travel date
                  if (booking.travelDate != null ||
                      booking.bookingDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(
                            booking.travelDate ??
                                booking.bookingDate ??
                                booking.bookingTime,
                          ),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        if (booking.travelDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(booking.travelDate!),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  // Payment status
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        booking.isPaid ? Icons.check_circle : Icons.pending,
                        size: 16,
                        color: booking.isPaid ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payment: ${booking.paymentStatus.replaceAll('_', ' ').toUpperCase()}',
                        style: TextStyle(
                          color: booking.isPaid ? Colors.green : Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopInfo(
    String label,
    String stopName,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          stopName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
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
