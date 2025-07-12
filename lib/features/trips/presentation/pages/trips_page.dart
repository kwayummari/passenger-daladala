import 'package:daladala_smart_app/features/home/presentation/pages/home_page.dart';
import 'package:daladala_smart_app/features/trips/domains/entities/trip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../providers/trip_provider.dart';
import 'trip_detail_page.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage>
    with AutomaticKeepAliveClientMixin {
  bool _isInitialized = false;
  String _selectedFilter = 'upcoming';

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTrips();
      });
      _isInitialized = true;
    }
  }

  Future<void> _loadTrips() async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    await tripProvider.getUpcomingTrips();
  }

  Future<void> _refreshTrips() async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    await tripProvider.refreshTrips();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildFilterTab('upcoming', 'Upcoming'),
                _buildFilterTab('past', 'Past'),
                _buildFilterTab('cancelled', 'Cancelled'),
              ],
            ),
          ),

          // Trip list
          Expanded(
            child: Consumer<TripProvider>(
              builder: (context, tripProvider, child) {
                if (tripProvider.isLoading) {
                  return const Center(child: LoadingIndicator());
                }

                if (tripProvider.error != null) {
                  return GenericErrorView(
                    message: tripProvider.error,
                    onRetry: _refreshTrips,
                  );
                }

                // Get trips based on selected filter
                final trips = tripProvider.getTripsByFilter(_selectedFilter);

                if (trips.isEmpty) {
                  return EmptyState(
                    title: 'No Trips Found',
                    message: 'You don\'t have any $_selectedFilter trips.',
                    lottieAsset: 'assets/animations/empty_trips.json',
                    buttonText: 'Book a Trip',
                    onButtonPressed: () {
                      HomePage.navigateToRoutes();
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshTrips,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return _TripCard(
                        trip: trip,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripDetailPage(tripId: trip.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const _TripCard({Key? key, required this.trip, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format time
    final formattedDate = DateFormat('EEE, d MMM').format(trip.startTime);
    final formattedTime = DateFormat('HH:mm').format(trip.startTime);

    // Define status color
    Color statusColor;
    switch (trip.status) {
      case 'scheduled':
        statusColor = Colors.blue;
        break;
      case 'in_progress':
        statusColor = AppTheme.primaryColor;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.displayRouteName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trip.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Trip details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and time
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vehicle and driver
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.displayVehiclePlate,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip.displayDriverName,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // View button
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'View',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
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
