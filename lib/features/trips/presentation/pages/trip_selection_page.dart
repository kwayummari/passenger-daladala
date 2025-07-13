// lib/features/trips/presentation/pages/trip_selection_page.dart - ENHANCED VERSION
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../../../../core/di/service_locator.dart';
import '../../domains/usecases/get_upcoming_trips_usecase.dart';
import '../../domains/entities/trip.dart';
import '../../../bookings/presentation/pages/booking_confirmation_page.dart';
import '../widgets/seat_selection_sheet.dart';
import '../widgets/booking_summary_sheet.dart';

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

  // Enhanced booking features
  String _selectedDateRange = 'single'; // 'single', 'week', 'month', '3months'
  DateTime? _endDate;

  // Seat selection for multiple trips
  Map<String, List<String>> _selectedSeats =
      {}; // 'tripId_date' -> seat numbers
  Map<String, int> _passengerCounts = {}; // 'tripId_date' -> passenger count
  Map<String, List<String>> _passengerNames =
      {}; // 'tripId_date' -> passenger names

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
          setState(() {
            _error = failure.message;
            _trips = [];
          });
        },
        (trips) {
          print('✅ DEBUG: Got ${trips.length} trips');
          setState(() {
            _trips = _filterTripsByDateRange(trips);
            _error = null;
          });
        },
      );
    } catch (e) {
      print('❌ DEBUG: Exception loading trips: $e');
      setState(() {
        _error = 'Failed to load trips: $e';
        _trips = [];
      });
    }
  }

  Future<void> _loadFareInfo() async {
    try {
      // Mock fare calculation - replace with actual API call
      setState(() {
        _fareAmount = 2000.0; // Default fare
      });
    } catch (e) {
      print('⚠️ DEBUG: Failed to load fare info: $e');
      // Don't set error for fare - use default
    }
  }

  List<Trip> _filterTripsByDateRange(List<Trip> allTrips) {
    final now = DateTime.now();
    final startDate = _selectedDate;
    final endDate = _endDate ?? startDate;

    return allTrips.where((trip) {
      final tripDate = trip.startTime;
      return tripDate.isAfter(startDate.subtract(Duration(days: 1))) &&
          tripDate.isBefore(endDate.add(Duration(days: 1)));
    }).toList();
  }

  // Calculate total selected passengers across all trips
  int _getTotalPassengers() {
    return _passengerCounts.values.fold(0, (sum, count) => sum + count);
  }

  // Calculate total fare for all selected trips
  double _calculateTotalFare() {
    double total = 0.0;
    _passengerCounts.forEach((tripKey, passengerCount) {
      total += (_fareAmount ?? 2000.0) * passengerCount;
    });
    return total;
  }

  // Build selected trips data for booking
  List<Map<String, dynamic>> _buildSelectedTripsData() {
    List<Map<String, dynamic>> selectedTripsData = [];

    for (final tripKey in _passengerCounts.keys) {
      final parts = tripKey.split('_');
      if (parts.length < 2) continue;

      final tripId = int.tryParse(parts[0]);
      final dateStr = parts[1];

      if (tripId == null) continue;

      final trip = _trips.firstWhere(
        (t) => t.id == tripId,
        orElse: () => _trips.first,
      );

      final passengerCount = _passengerCounts[tripKey] ?? 1;
      final seatNumbers = _selectedSeats[tripKey] ?? [];
      final passengerNames = _passengerNames[tripKey] ?? [];

      selectedTripsData.add({
        'trip_id': tripId,
        'pickup_stop_id': widget.pickupStopId,
        'dropoff_stop_id': widget.dropoffStopId,
        'passenger_count': passengerCount,
        'seat_numbers': seatNumbers,
        'passenger_names': passengerNames,
        'travel_date': dateStr,
        // Additional data for UI
        'tripId': tripId,
        'passengerCount': passengerCount,
        'selectedSeats': seatNumbers,
        'fare': _fareAmount ?? 2000.0,
        'startTime': trip.startTime,
        'vehiclePlate': trip.vehiclePlate ?? 'Unknown',
      });
    }

    return selectedTripsData;
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
        // Clear previous selections when changing date
        _selectedSeats.clear();
        _passengerCounts.clear();
        _passengerNames.clear();
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
      _passengerNames.clear();
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

  int _calculateTotalDays() {
    if (_endDate == null) return 1;
    return _endDate!.difference(_selectedDate).inDays + 1;
  }

  void _showSeatSelection(Trip trip) {
    // Check if total passengers across all trips would exceed 10
    final currentTotalPassengers = _getTotalPassengers();
    final tripKey =
        '${trip.id}_${_selectedDate.toIso8601String().split('T')[0]}';
    final currentTripPassengers = _passengerCounts[tripKey] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SeatSelectionSheet(
            trip: trip,
            selectedSeats: _selectedSeats[tripKey] ?? [],
            passengerNames: _passengerNames[tripKey] ?? [],
            maxPassengers:
                10 - (currentTotalPassengers - currentTripPassengers),
            pickupStopId: widget.pickupStopId,
            dropoffStopId: widget.dropoffStopId,
            travelDate: _selectedDate.toIso8601String().split('T')[0],
            onSeatsSelected: (seats, passengerCount, names) {
              setState(() {
                _selectedSeats[tripKey] = seats;
                _passengerCounts[tripKey] = passengerCount;
                _passengerNames[tripKey] = names;
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
          backgroundColor: Colors.orange,
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
        builder:
            (context) => BookingConfirmationPage(
              // Single trip data (for backward compatibility)
              tripId:
                  selectedTripsData.isNotEmpty
                      ? selectedTripsData.first['tripId']
                      : null,
              routeName: widget.routeName,
              from: widget.from,
              to: widget.to,
              startTime:
                  selectedTripsData.isNotEmpty
                      ? selectedTripsData.first['startTime']
                      : DateTime.now(),
              fare: _fareAmount ?? 2000.0,
              vehiclePlate:
                  selectedTripsData.isNotEmpty
                      ? selectedTripsData.first['vehiclePlate']
                      : 'Unknown',
              pickupStopId: widget.pickupStopId,
              dropoffStopId: widget.dropoffStopId,

              // Multiple trip data (enhanced features)
              selectedTrips:
                  selectedTripsData.isNotEmpty ? selectedTripsData : null,
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
      builder:
          (context) => BookingSummarySheet(
            trips: _trips,
            passengerCounts: _passengerCounts,
            selectedSeats: _selectedSeats,
            passengerNames: _passengerNames,
            farePerTrip: _fareAmount ?? 2000.0,
            totalFare: _calculateTotalFare(),
            routeName: widget.routeName,
            from: widget.from,
            to: widget.to,
            pickupStopId: widget.pickupStopId,
            dropoffStopId: widget.dropoffStopId,
            dateRange: _selectedDateRange,
            startDate: _selectedDate,
            endDate: _endDate,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.routeName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.from} → ${widget.to}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_getTotalPassengers() > 0)
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.list, color: AppTheme.primaryColor),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '${_getTotalPassengers()}',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: _showBookingSummary,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(),
          _buildDateSelector(),
          Expanded(
            child:
                _isLoading
                    ? LoadingIndicator()
                    : _error != null
                    ? ErrorView(message: _error!, onRetry: _loadData)
                    : _buildTripsList(),
          ),
        ],
      ),
      bottomNavigationBar:
          _getTotalPassengers() > 0 ? _buildBottomBookingBar() : null,
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
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

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDateRange == 'single' ? 'Travel Date' : 'Date Range',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  _selectedDateRange == 'single'
                      ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate)
                      : '${DateFormat('MMM d').format(_selectedDate)} - ${_endDate != null ? DateFormat('MMM d, yyyy').format(_endDate!) : 'Open'}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          TextButton(onPressed: _selectDate, child: Text('Change')),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No trips available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _selectedDateRange == 'single'
                  ? 'No trips scheduled for the selected date'
                  : 'No trips scheduled for the selected date range',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group trips by date for better organization
    Map<String, List<Trip>> tripsByDate = {};
    for (final trip in _trips) {
      final dateKey = trip.startTime.toIso8601String().split('T')[0];
      if (!tripsByDate.containsKey(dateKey)) {
        tripsByDate[dateKey] = [];
      }
      tripsByDate[dateKey]!.add(trip);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: tripsByDate.keys.length,
      itemBuilder: (context, index) {
        final dateKey = tripsByDate.keys.elementAt(index);
        final dateTrips = tripsByDate[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedDateRange != 'single') ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('EEE, MMM d, yyyy').format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
            ...dateTrips.map((trip) => _buildTripCard(trip, dateKey)),
            SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTripCard(Trip trip, String dateKey) {
    final tripKey = '${trip.id}_$dateKey';
    final isSelected = _passengerCounts.containsKey(tripKey);
    final passengerCount = _passengerCounts[tripKey] ?? 0;
    final selectedSeats = _selectedSeats[tripKey] ?? [];

    final startTime = DateFormat('HH:mm').format(trip.startTime);
    final endTime =
        trip.endTime != null
            ? DateFormat('HH:mm').format(trip.endTime!)
            : 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            trip.availableSeats! > 5
                                ? Colors.green.withOpacity(0.1)
                                : trip.availableSeats! > 0
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${trip.availableSeats} seats',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              trip.availableSeats! > 5
                                  ? Colors.green[700]
                                  : trip.availableSeats! > 0
                                  ? Colors.orange[700]
                                  : Colors.red[700],
                        ),
                      ),
                    ),
                    Spacer(),
                    Text(
                      'TZS ${(_fareAmount ?? 2000).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      '$startTime - $endTime',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    if (trip.vehiclePlate != null) ...[
                      Icon(
                        Icons.directions_bus,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        trip.vehiclePlate!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
                if (isSelected) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '$passengerCount passenger${passengerCount != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            if (selectedSeats.isNotEmpty) ...[
                              Spacer(),
                              Icon(
                                Icons.airline_seat_recline_normal,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                selectedSeats.join(', '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Subtotal: TZS ${((_fareAmount ?? 2000) * passengerCount).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed:
                        trip.availableSeats! > 0
                            ? () => _showSeatSelection(trip)
                            : null,
                    icon: Icon(
                      Icons.airline_seat_recline_normal,
                      size: 18,
                      color:
                          trip.availableSeats! > 0
                              ? AppTheme.primaryColor
                              : Colors.grey,
                    ),
                    label: Text(
                      isSelected ? 'Change Seats' : 'Select Seats',
                      style: TextStyle(
                        color:
                            trip.availableSeats! > 0
                                ? AppTheme.primaryColor
                                : Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(height: 48, width: 1, color: Colors.grey[200]),
                if (isSelected)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedSeats.remove(tripKey);
                          _passengerCounts.remove(tripKey);
                          _passengerNames.remove(tripKey);
                        });
                      },
                      icon: Icon(
                        Icons.remove_circle_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: Text(
                        'Remove',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBookingBar() {
    final totalPassengers = _getTotalPassengers();
    final totalFare = _calculateTotalFare();
    final selectedTripsCount = _passengerCounts.length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selectedTripsCount trip${selectedTripsCount != 1 ? 's' : ''} • $totalPassengers passenger${totalPassengers != 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      'TZS ${totalFare.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (selectedTripsCount > 1)
                      OutlinedButton(
                        onPressed: _showBookingSummary,
                        child: Text('Summary'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    if (selectedTripsCount > 1) SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _proceedToBooking,
                      child: Text('Book Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
