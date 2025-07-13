// lib/features/trips/presentation/widgets/seat_selection_sheet.dart - UPDATED VERSION
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/di/service_locator.dart';
import '../../domains/entities/trip.dart';
import '../../../bookings/data/datasources/booking_datasource.dart';

class SeatSelectionSheet extends StatefulWidget {
  final Trip trip;
  final List<String> selectedSeats;
  final List<String> passengerNames;
  final int maxPassengers;
  final int pickupStopId;
  final int dropoffStopId;
  final String travelDate;
  final Function(List<String> seats, int passengerCount, List<String> names)
  onSeatsSelected;

  const SeatSelectionSheet({
    Key? key,
    required this.trip,
    required this.selectedSeats,
    required this.passengerNames,
    required this.maxPassengers,
    required this.pickupStopId,
    required this.dropoffStopId,
    required this.travelDate,
    required this.onSeatsSelected,
  }) : super(key: key);

  @override
  State<SeatSelectionSheet> createState() => _SeatSelectionSheetState();
}

class _SeatSelectionSheetState extends State<SeatSelectionSheet> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _seatData;
  List<String> _selectedSeats = [];
  List<TextEditingController> _nameControllers = [];
  bool _autoAssignMode = false;
  int _passengerCount = 1;

  @override
  void initState() {
    super.initState();
    _selectedSeats = List.from(widget.selectedSeats);
    _passengerCount = _selectedSeats.isNotEmpty ? _selectedSeats.length : 1;
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔍 DEBUG: Loading seats for trip ${widget.trip.id}');

      final bookingDataSource = getIt<BookingDataSource>();

      final seatData = await bookingDataSource.getAvailableSeats(
        tripId: widget.trip.id,
        pickupStopId: widget.pickupStopId,
        dropoffStopId: widget.dropoffStopId,
        travelDate: widget.travelDate,
      );

      print('✅ DEBUG: Seat data loaded successfully');
      print(
        '🔍 DEBUG: Available seats: ${seatData['available_seats']?.length ?? 0}',
      );

      setState(() {
        _seatData = seatData;
        _isLoading = false;
        _error = null;
      });

      // Initialize passenger name controllers
      _initializeNameControllers();
    } catch (e) {
      print('❌ DEBUG: Error loading seats: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load seats information: ${e.toString()}';
      });
    }
  }

  void _initializeNameControllers() {
    _nameControllers.clear();
    for (int i = 0; i < _passengerCount; i++) {
      final controller = TextEditingController();
      if (i < widget.passengerNames.length) {
        controller.text = widget.passengerNames[i];
      }
      _nameControllers.add(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Seats',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child:
                _isLoading
                    ? Center(child: LoadingIndicator())
                    : _error != null
                    ? _buildErrorView()
                    : _buildSeatSelection(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error Loading Seats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadSeats,
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatSelection() {
    if (_seatData == null) {
      return Center(child: Text('No seat data available'));
    }

    final availableSeats =
        (_seatData!['available_seats'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final occupiedSeats =
        (_seatData!['occupied_seats'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
    final unavailableSeats =
        (_seatData!['unavailable_seats'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    return Column(
      children: [
        // Seat selection mode toggle
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Passengers: $_passengerCount (Max: ${widget.maxPassengers})',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Switch(
                value: _autoAssignMode,
                onChanged: (value) {
                  setState(() {
                    _autoAssignMode = value;
                    if (value) {
                      _selectedSeats.clear();
                    }
                  });
                },
              ),
              Text('Auto-assign'),
            ],
          ),
        ),

        // Passenger count selector
        if (!_autoAssignMode) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Passengers: '),
                IconButton(
                  onPressed:
                      _passengerCount > 1
                          ? () {
                            setState(() {
                              _passengerCount--;
                              if (_selectedSeats.length > _passengerCount) {
                                _selectedSeats =
                                    _selectedSeats
                                        .take(_passengerCount)
                                        .toList();
                              }
                              _initializeNameControllers();
                            });
                          }
                          : null,
                  icon: Icon(Icons.remove),
                ),
                Text('$_passengerCount'),
                IconButton(
                  onPressed:
                      _passengerCount < widget.maxPassengers
                          ? () {
                            setState(() {
                              _passengerCount++;
                              _initializeNameControllers();
                            });
                          }
                          : null,
                  icon: Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],

        // Seat grid
        if (!_autoAssignMode) ...[
          Expanded(
            child: _buildSeatGrid(
              availableSeats,
              occupiedSeats,
              unavailableSeats,
            ),
          ),
        ],

        // Passenger names input
        if (_selectedSeats.isNotEmpty || _autoAssignMode) ...[
          _buildPassengerNamesInput(),
        ],

        // Confirm button
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _canConfirm() ? _confirmSelection : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text(
              _autoAssignMode
                  ? 'Confirm Auto-Assignment ($_passengerCount passengers)'
                  : 'Confirm Selection (${_selectedSeats.length} seats)',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatGrid(
    List<Map<String, dynamic>> available,
    List<Map<String, dynamic>> occupied,
    List<Map<String, dynamic>> unavailable,
  ) {
    // Create a combined list and sort by seat number
    final allSeats = <Map<String, dynamic>>[];

    for (final seat in available) {
      allSeats.add({...seat, 'status': 'available'});
    }
    for (final seat in occupied) {
      allSeats.add({...seat, 'status': 'occupied'});
    }
    for (final seat in unavailable) {
      allSeats.add({...seat, 'status': 'unavailable'});
    }

    allSeats.sort((a, b) {
      final aNum = int.tryParse(a['seat_number'].toString()) ?? 0;
      final bNum = int.tryParse(b['seat_number'].toString()) ?? 0;
      return aNum.compareTo(bNum);
    });

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allSeats.length,
      itemBuilder: (context, index) {
        final seat = allSeats[index];
        final seatNumber = seat['seat_number'].toString();
        final status = seat['status'];
        final isSelected = _selectedSeats.contains(seatNumber);

        Color backgroundColor;
        Color textColor = Colors.white;
        bool isSelectable = status == 'available';

        switch (status) {
          case 'available':
            backgroundColor = isSelected ? AppTheme.primaryColor : Colors.green;
            break;
          case 'occupied':
            backgroundColor = Colors.red;
            isSelectable = false;
            break;
          case 'unavailable':
            backgroundColor = Colors.grey;
            isSelectable = false;
            break;
          default:
            backgroundColor = Colors.grey;
            isSelectable = false;
        }

        return GestureDetector(
          onTap: isSelectable ? () => _toggleSeat(seatNumber) : null,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border:
                  isSelected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Center(
              child: Text(
                seatNumber,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPassengerNamesInput() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passenger Names:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ...List.generate(_passengerCount, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: TextField(
                controller:
                    index < _nameControllers.length
                        ? _nameControllers[index]
                        : null,
                decoration: InputDecoration(
                  labelText: 'Passenger ${index + 1}',
                  border: OutlineInputBorder(),
                  // dense: true,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _toggleSeat(String seatNumber) {
    setState(() {
      if (_selectedSeats.contains(seatNumber)) {
        _selectedSeats.remove(seatNumber);
      } else if (_selectedSeats.length < _passengerCount) {
        _selectedSeats.add(seatNumber);
      }
    });
  }

  bool _canConfirm() {
    if (_autoAssignMode) {
      return _passengerCount > 0;
    }
    return _selectedSeats.length == _passengerCount;
  }

  void _confirmSelection() {
    final names =
        _nameControllers
            .map((c) => c.text.trim())
            .where((n) => n.isNotEmpty)
            .toList();

    widget.onSeatsSelected(
      _autoAssignMode ? [] : _selectedSeats,
      _passengerCount,
      names,
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
