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

  // Date range selection
  String _selectedDateRange = 'single'; // 'single', 'week', 'month', '3months'
  DateTime? _endDate;

  // Seat selection
  Map<int, List<String>> _selectedSeats = {}; // tripId -> list of seat numbers
  Map<int, int> _passengerCounts = {}; // tripId -> passenger count

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
      print('🔍 DEBUG: Loading trips for route ${widget.routeId}');
      print('🔍 DEBUG: Date range: $_selectedDateRange');
      print('🔍 DEBUG: Start date: $_selectedDate');
      print('🔍 DEBUG: End date: $_endDate');

      final getTripsUseCase = getIt<GetUpcomingTripsUseCase>();
      final result = await getTripsUseCase(
        GetUpcomingTripsParams(routeId: widget.routeId),
      );

      result.fold(
        (failure) {
          print('❌ DEBUG: Failed to get trips: ${failure.message}');
          throw Exception(failure.message);
        },
        (trips) {
          print('✅ DEBUG: Successfully parsed ${trips.length} trips');

          // Filter trips by selected date range
          final filteredTrips = trips.where((trip) {
            final tripDate = DateTime(
              trip.startTime.year,
              trip.startTime.month,
              trip.startTime.day,
            );

            bool dateMatch = false;

            if (_selectedDateRange == 'single') {
              final selectedDate = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              );
              dateMatch = tripDate.isAtSameMomentAs(selectedDate);
            } else {
              // Date range filtering
              final startDate = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              );
              final endDate = DateTime(
                _endDate!.year,
                _endDate!.month,
                _endDate!.day,
              );
              dateMatch =
                  tripDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                      tripDate.isBefore(endDate.add(Duration(days: 1)));
            }

            return dateMatch &&
                trip.routeId == widget.routeId &&
                (trip.status == 'scheduled' || trip.status == 'active');
          }).toList();

          // Sort by start time
          filteredTrips.sort((a, b) => a.startTime.compareTo(b.startTime));

          setState(() {
            _trips = filteredTrips;
          });

          print(
            '🎯 DEBUG: Filtered trips: ${filteredTrips.length} out of ${trips.length}',
          );
        },
      );
    } catch (e, stackTrace) {
      print('💥 DEBUG: Error in _loadTrips: $e');
      print('💥 DEBUG: Stack trace: $stackTrace');
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

  // Calculate total fare based on selected trips and dates
  double _calculateTotalFare() {
    double totalFare = 0.0;
    final baseFare = _fareAmount ?? 2000.0;

    // Calculate fare for selected trips
    for (final trip in _trips) {
      final passengerCount = _passengerCounts[trip.id] ?? 0;
      if (passengerCount > 0) {
        totalFare += baseFare * passengerCount;
      }
    }

    // Multiply by number of days for date range bookings
    if (_selectedDateRange != 'single') {
      final totalDays = _calculateTotalDays();
      totalFare *= totalDays;
    }

    return totalFare;
  }

  int _calculateTotalDays() {
    switch (_selectedDateRange) {
      case 'single':
        return 1;
      case 'week':
        return 7;
      case 'month':
        return 30;
      case '3months':
        return 90;
      default:
        return 1;
    }
  }

  List<Map<String, dynamic>> _buildSelectedTripsData() {
    List<Map<String, dynamic>> selectedTripsData = [];

    for (final trip in _trips) {
      final passengerCount = _passengerCounts[trip.id] ?? 0;
      if (passengerCount > 0) {
        selectedTripsData.add({
          'tripId': trip.id,
          'passengerCount': passengerCount,
          'selectedSeats': _selectedSeats[trip.id] ?? [],
          'fare': _fareAmount ?? 2000.0,
          'startTime': trip.startTime,
          'vehiclePlate': trip.vehiclePlate ?? 'Unknown',
        });
      }
    }

    return selectedTripsData;
  }

  // Get total selected passengers across all trips
  int _getTotalPassengers() {
    return _passengerCounts.values.fold(0, (sum, count) => sum + count);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateEndDate();
      });
      await _loadTrips();
    }
  }

  void _selectDateRange(String range) {
    setState(() {
      _selectedDateRange = range;
      _updateEndDate();
      // Clear previous selections when changing date range
      _selectedSeats.clear();
      _passengerCounts.clear();
    });
    _loadTrips();
  }

  void _updateEndDate() {
    switch (_selectedDateRange) {
      case 'single':
        _endDate = null;
        break;
      case 'week':
        _endDate = _selectedDate.add(Duration(days: 7));
        break;
      case 'month':
        _endDate = _selectedDate.add(Duration(days: 30));
        break;
      case '3months':
        _endDate = _selectedDate.add(Duration(days: 90));
        break;
    }
  }

  void _showSeatSelection(Trip trip) {
    // Check if total passengers across all trips would exceed 10
    final currentTotalPassengers = _getTotalPassengers();
    final currentTripPassengers = _passengerCounts[trip.id] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SeatSelectionSheet(
        trip: trip,
        selectedSeats: _selectedSeats[trip.id] ?? [],
        maxPassengers: 10 - (currentTotalPassengers - currentTripPassengers),
        onSeatsSelected: (seats, passengerCount) {
          setState(() {
            _selectedSeats[trip.id] = seats;
            _passengerCounts[trip.id] = passengerCount;
          });
        },
      ),
    );
  }

  void _proceedToBooking() {
    if (_getTotalPassengers() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one trip and passengers'),
        ),
      );
      return;
    }

    // Validate maximum passengers (10+ rule)
    if (_getTotalPassengers() > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 10 passengers allowed across all trips'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedTripsData = _buildSelectedTripsData();

    // Navigate to enhanced BookingConfirmationPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationPage(
          // Single trip data (for backward compatibility)
          tripId: selectedTripsData.isNotEmpty
              ? selectedTripsData.first['tripId']
              : null,
          routeName: widget.routeName,
          from: widget.from,
          to: widget.to,
          startTime: selectedTripsData.isNotEmpty
              ? selectedTripsData.first['startTime']
              : DateTime.now(),
          fare: _fareAmount ?? 2000.0,
          vehiclePlate: selectedTripsData.isNotEmpty
              ? selectedTripsData.first['vehiclePlate']
              : 'Unknown',
          pickupStopId: widget.pickupStopId,
          dropoffStopId: widget.dropoffStopId,

          // Multiple trip data (enhanced features)
          selectedTrips: selectedTripsData.isNotEmpty ? selectedTripsData : null,
          dateRange: _selectedDateRange,
          endDate: _endDate,
          totalDays: _calculateTotalDays(),
        ),
      ),
    );
  }

  void _showBookingSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BookingSummarySheet(
        trips: _trips,
        passengerCounts: _passengerCounts,
        selectedSeats: _selectedSeats,
        farePerTrip: _fareAmount ?? 2000.0,
        totalFare: _calculateTotalFare(),
        routeName: widget.routeName,
        from: widget.from,
        to: widget.to,
        pickupStopId: widget.pickupStopId,
        dropoffStopId: widget.dropoffStopId,
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Period',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateRangeChip('Single Day', 'single'),
                SizedBox(width: 8),
                _buildDateRangeChip('This Week', 'week'),
                SizedBox(width: 8),
                _buildDateRangeChip('This Month', 'month'),
                SizedBox(width: 8),
                _buildDateRangeChip('3 Months', '3months'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip(String label, String value) {
    final isSelected = _selectedDateRange == value;
    return GestureDetector(
      onTap: () => _selectDateRange(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final startTime = DateFormat('HH:mm').format(trip.startTime);
    final endTime = trip.endTime != null
        ? DateFormat('HH:mm').format(trip.endTime!)
        : 'TBD';
    final tripDate = DateFormat('MMM dd').format(trip.startTime);
    final passengerCount = _passengerCounts[trip.id] ?? 0;
    final selectedSeats = _selectedSeats[trip.id] ?? [];

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
                        '$tripDate • $startTime - $endTime',
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
                    color: trip.status == 'active'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trip.status.toUpperCase(),
                    style: TextStyle(
                      color: trip.status == 'active' ? Colors.green : Colors.blue,
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
                            'Available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(trip.availableSeats ?? 30) - passengerCount} seats',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: (trip.availableSeats ?? 30) > 5
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
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

            // Show selected passengers and seats
            if (passengerCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$passengerCount passenger(s) selected' +
                            (selectedSeats.isNotEmpty
                                ? ' • Seats: ${selectedSeats.join(", ")}'
                                : ''),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Select seats button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSeatSelection(trip),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      passengerCount > 0 ? Colors.green : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  passengerCount > 0
                      ? 'Update Selection'
                      : 'Select Passengers & Seats',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date range info (if not single day)
            if (_selectedDateRange != 'single') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_repeat,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Booking for ${_calculateTotalDays()} days',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Main booking info
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${_getTotalPassengers()} passenger(s)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      if (_selectedDateRange != 'single')
                        Text(
                          '${_buildSelectedTripsData().length} trips × ${_calculateTotalDays()} days',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      Text(
                        '${_calculateTotalFare().toStringAsFixed(0)} TZS',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _proceedToBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
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
                            'Fare per trip',
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDateRange == 'single'
                            ? 'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'
                            : 'From: ${DateFormat('MMM dd').format(_selectedDate)} - To: ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_selectedDateRange != 'single' && _trips.isNotEmpty)
                        Text(
                          '${_trips.length} trips available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(onPressed: _selectDate, child: const Text('Change')),
              ],
            ),
          ),

          // Date range selector
          _buildDateRangeSelector(),

          // Content area
          Expanded(
            child: _isLoading
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
                                  'Try selecting a different date or period',
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

      // Bottom bar with enhanced features
      bottomNavigationBar:
          _getTotalPassengers() > 0 ? _buildEnhancedBottomBar() : null,
    );
  }
}

// Seat Selection Bottom Sheet
class SeatSelectionSheet extends StatefulWidget {
  final Trip trip;
  final List<String> selectedSeats;
  final int maxPassengers;
  final Function(List<String>, int) onSeatsSelected;

  const SeatSelectionSheet({
    super.key,
    required this.trip,
    required this.selectedSeats,
    this.maxPassengers = 10,
    required this.onSeatsSelected,
  });

  @override
  State<SeatSelectionSheet> createState() => _SeatSelectionSheetState();
}

class _SeatSelectionSheetState extends State<SeatSelectionSheet> {
  List<String> _selectedSeats = [];
  int _passengerCount = 1;

  @override
  void initState() {
    super.initState();
    _selectedSeats = List.from(widget.selectedSeats);
    _passengerCount = _selectedSeats.length > 0 ? _selectedSeats.length : 1;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final capacity = widget.trip.availableSeats ?? 30;
    final seatsPerRow = 4;
    final maxAllowedPassengers = widget.maxPassengers.clamp(1, 10);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with validation info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Seats - Trip #${widget.trip.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (maxAllowedPassengers < 10)
                      Text(
                        'Max ${maxAllowedPassengers} passengers available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Passenger count selector with validation
          Row(
            children: [
              Text(
                'Passengers: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              IconButton(
                onPressed:
                    _passengerCount > 1
                        ? () {
                          setState(() {
                            _passengerCount--;
                            if (_selectedSeats.length > _passengerCount) {
                              _selectedSeats.removeRange(
                                _passengerCount,
                                _selectedSeats.length,
                              );
                            }
                          });
                        }
                        : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_passengerCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed:
                    _passengerCount < maxAllowedPassengers
                        ? () {
                          setState(() {
                            _passengerCount++;
                          });
                        }
                        : null,
                icon: Icon(
                  Icons.add_circle_outline,
                  color:
                      _passengerCount < maxAllowedPassengers
                          ? null
                          : Colors.grey,
                ),
              ),
              if (maxAllowedPassengers < 10)
                Text(
                  '(${maxAllowedPassengers} max)',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Seat map
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Driver area
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.settings_input_svideo_rounded),
                        SizedBox(width: 8),
                        Text('Driver'),
                      ],
                    ),
                  ),

                  // Seat grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: seatsPerRow,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: capacity,
                    itemBuilder: (context, index) {
                      final seatNumber =
                          'S${(index + 1).toString().padLeft(2, '0')}';
                      final isSelected = _selectedSeats.contains(seatNumber);
                      final isOccupied = false;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedSeats.remove(seatNumber);
                            } else if (_selectedSeats.length <
                                _passengerCount) {
                              _selectedSeats.add(seatNumber);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Maximum $_passengerCount seats can be selected',
                                  ),
                                ),
                              );
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isOccupied
                                    ? Colors.red[300]
                                    : isSelected
                                    ? Colors.green[400]
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isSelected ? Colors.green : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.airline_seat_recline_normal,
                                  color:
                                      isOccupied
                                          ? Colors.white
                                          : isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                  size: 20,
                                ),
                                Text(
                                  seatNumber,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        isOccupied
                                            ? Colors.white
                                            : isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem(Colors.grey[200]!, 'Available'),
                      _buildLegendItem(Colors.green[400]!, 'Selected'),
                      _buildLegendItem(Colors.red[300]!, 'Occupied'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Enhanced confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _selectedSeats.length == _passengerCount
                      ? () {
                        widget.onSeatsSelected(_selectedSeats, _passengerCount);
                        Navigator.pop(context);
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _selectedSeats.length == _passengerCount
                    ? 'Confirm Selection (${_selectedSeats.length}/$_passengerCount)'
                    : 'Select ${_passengerCount - _selectedSeats.length} more seat(s)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Booking Summary Bottom Sheet
class BookingSummarySheet extends StatelessWidget {
  final List<Trip> trips;
  final Map<int, int> passengerCounts;
  final Map<int, List<String>> selectedSeats;
  final double farePerTrip;
  final double totalFare;
  final String routeName;
  final String from;
  final String to;
  final int pickupStopId;
  final int dropoffStopId;

  const BookingSummarySheet({
    super.key,
    required this.trips,
    required this.passengerCounts,
    required this.selectedSeats,
    required this.farePerTrip,
    required this.totalFare,
    required this.routeName,
    required this.from,
    required this.to,
    required this.pickupStopId,
    required this.dropoffStopId,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTrips =
        trips.where((trip) => (passengerCounts[trip.id] ?? 0) > 0).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Booking Summary',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Route info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(from),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Icon(Icons.location_on, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(to),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Selected trips
          Expanded(
            child: ListView.builder(
              itemCount: selectedTrips.length,
              itemBuilder: (context, index) {
                final trip = selectedTrips[index];
                final passengerCount = passengerCounts[trip.id] ?? 0;
                final seats = selectedSeats[trip.id] ?? [];
                final tripFare = farePerTrip * passengerCount;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Trip #${trip.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${tripFare.toStringAsFixed(0)} TZS',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy • HH:mm',
                          ).format(trip.startTime),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vehicle: ${trip.vehiclePlate ?? "N/A"}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '$passengerCount passenger(s)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (seats.isNotEmpty) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.airline_seat_recline_normal,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Seats: ${seats.join(", ")}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Total summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Trips:', style: const TextStyle(fontSize: 16)),
                    Text(
                      '${selectedTrips.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Passengers:',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${passengerCounts.values.fold(0, (sum, count) => sum + count)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${totalFare.toStringAsFixed(0)} TZS',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Confirm booking button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Booking confirmed! Total: ${totalFare.toStringAsFixed(0)} TZS',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm Booking - ${totalFare.toStringAsFixed(0)} TZS',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
