import 'package:daladala_smart_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../../../../core/di/service_locator.dart';
import '../../domains/usecases/get_upcoming_trips_usecase.dart';
import '../../domains/entities/trip.dart';
import '../../../bookings/presentation/pages/booking_confirmation_page.dart';

class TripSelectionPage extends StatefulWidget {
  final int routeId;
  final String routeName;
  final String from;
  final String to;
  final int pickupStopId;
  final int dropoffStopId;

  const TripSelectionPage({
    super.key,
    required this.routeId,
    required this.routeName,
    required this.from,
    required this.to,
    required this.pickupStopId,
    required this.dropoffStopId,
  });

  @override
  State<TripSelectionPage> createState() => _TripSelectionPageState();
}

class _TripSelectionPageState extends State<TripSelectionPage> {
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<Trip> _trips = [];
  double? _fareAmount;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([_loadTrips(), _loadFareInfo()]);
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTrips() async {
    try {
      final getTripsUseCase = getIt<GetUpcomingTripsUseCase>();
      final result = await getTripsUseCase(
        GetUpcomingTripsParams(routeId: widget.routeId),
      );

      result.fold(
        (failure) {
          throw Exception(failure.message);
        },
        (trips) {
          // Filter trips by selected date and route
          final filteredTrips =
              trips.where((trip) {
                final tripDate = DateTime(
                  trip.startTime.year,
                  trip.startTime.month,
                  trip.startTime.day,
                );
                final selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                );

                return tripDate.isAtSameMomentAs(selectedDate) &&
                    trip.routeId == widget.routeId &&
                    (trip.status == 'scheduled' || trip.status == 'active') &&
                    (trip.availableSeats ?? 0) > 0;
              }).toList();

          // Sort by start time
          filteredTrips.sort((a, b) => a.startTime.compareTo(b.startTime));

          setState(() {
            _trips = filteredTrips;
          });
        },
      );
    } catch (e) {
      throw Exception('Failed to load trips: $e');
    }
  }

  Future<void> _loadFareInfo() async {
    try {
      final fareData = await ApiService.getFareBetweenStops(
        routeId: widget.routeId,
        startStopId: widget.pickupStopId,
        endStopId: widget.dropoffStopId,
      );

      setState(() {
        _fareAmount = fareData?['amount']?.toDouble() ?? 2000.0;
      });
    } catch (e) {
      print('Error loading fare info: $e');
      setState(() {
        _fareAmount = 2000.0; // Base fare fallback
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 30),
      ), // Allow 30 days booking
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadTrips();
    }
  }

  void _bookTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingConfirmationPage(
              tripId: trip.id,
              routeName: widget.routeName,
              from: widget.from,
              to: widget.to,
              startTime: trip.startTime,
              fare: _fareAmount ?? 1500.0,
              vehiclePlate: trip.vehiclePlate ?? 'Unknown',
              pickupStopId: widget.pickupStopId,
              dropoffStopId: widget.dropoffStopId,
            ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final startTime = DateFormat('HH:mm').format(trip.startTime);
    final endTime =
        trip.endTime != null
            ? DateFormat('HH:mm').format(trip.endTime!)
            : 'TBD';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip #${trip.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$startTime - $endTime',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                    color:
                        trip.status == 'active'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trip.status.toUpperCase(),
                    style: TextStyle(
                      color:
                          trip.status == 'active' ? Colors.green : Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Trip details
            Row(
              children: [
                // Vehicle info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_bus,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vehicle',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip.vehiclePlate ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // Available seats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.airline_seat_recline_normal,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Available Seats',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trip.availableSeats ?? 0}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color:
                              (trip.availableSeats ?? 0) > 5
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // Driver info
                if (trip.driverName != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Driver',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.driverName!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (trip.availableSeats ?? 0) > 0
                        ? () => _bookTrip(trip)
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  (trip.availableSeats ?? 0) > 0 ? 'Book Trip' : 'Fully Booked',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Route info header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Route details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.from,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            child: Column(
                              children: List.generate(3, (index) {
                                return Container(
                                  width: 2,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 1,
                                  ),
                                  color: Colors.grey[400],
                                );
                              }),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.to,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_fareAmount != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Fare',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_fareAmount!.toStringAsFixed(0)} TZS',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Date selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(onPressed: _selectDate, child: const Text('Change')),
              ],
            ),
          ),

          // Content area
          Expanded(
            child:
                _isLoading
                    ? const Center(child: LoadingIndicator())
                    : _error != null
                    ? ErrorView(message: _error!, onRetry: _loadData)
                    : _trips.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_bus_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No trips available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try selecting a different date',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _selectDate,
                            child: const Text('Select Different Date'),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _trips.length,
                        itemBuilder: (context, index) {
                          return _buildTripCard(_trips[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
