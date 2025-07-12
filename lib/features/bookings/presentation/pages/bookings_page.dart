import 'package:daladala_smart_app/features/home/presentation/pages/home_page.dart';
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
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    await bookingProvider.getUserBookings(status: _currentFilter);
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

            final bookings = bookingProvider.userBookings;

            if (bookings == null || bookings.isEmpty) {
              return EmptyState(
                title: 'No Bookings Found',
                message:
                    'You don\'t have any bookings${_currentFilter != null ? ' in this category' : ''}.',
                lottieAsset: 'assets/animations/empty_list.json',
                buttonText: 'Book a Trip',
                onButtonPressed: () {
                  HomePage.navigateToRoutes();
                },
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _BookingItem(
                  booking: booking,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => BookingDetailPage(bookingId: booking.id),
                      ),
                    ).then((_) => _loadBookings());
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BookingItem extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _BookingItem({Key? key, required this.booking, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format date and time
    final formattedDate = DateFormat('dd MMM yyyy').format(booking.bookingTime);
    final formattedTime = DateFormat('HH:mm').format(booking.bookingTime);

    // Determine status color
    Color statusColor;
    IconData statusIcon;

    switch (booking.status) {
      case 'pending':
        statusColor = AppTheme.pendingColor;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'confirmed':
        statusColor = AppTheme.confirmedColor;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'in_progress':
        statusColor = AppTheme.inProgressColor;
        statusIcon = Icons.directions_bus;
        break;
      case 'completed':
        statusColor = AppTheme.completedColor;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = AppTheme.cancelledColor;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.pendingColor;
        statusIcon = Icons.hourglass_empty;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Top section with status and booking info
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
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Booking #${booking.id}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
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

            // Booking details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Trip info
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_bus,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Trip #${booking.tripId}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      Text(
                        '$formattedDate at $formattedTime',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // From -> To info
                  Row(
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.circle_outlined,
                            size: 12,
                            color: Colors.green,
                          ),
                          Container(
                            width: 1,
                            height: 16,
                            color: Colors.grey.shade300,
                          ),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stop #${booking.pickupStopId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Stop #${booking.dropoffStopId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TZS ${booking.fareAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${booking.passengerCount} passenger${booking.passengerCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom action button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Text(
                'View Details',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
