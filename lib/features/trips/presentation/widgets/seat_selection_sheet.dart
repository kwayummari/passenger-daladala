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
    _initializeNameControllers();
    _loadSeatData();
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _loadSeatData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookingDataSource = getIt<BookingDataSource>();
      final seatData = await bookingDataSource.getAvailableSeats(
        tripId: widget.trip.id,
        pickupStopId: widget.pickupStopId,
        dropoffStopId: widget.dropoffStopId,
        travelDate: widget.travelDate,
      );

      setState(() {
        _seatData = seatData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load seat information: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleSeat(String seatNumber) {
    setState(() {
      if (_selectedSeats.contains(seatNumber)) {
        _selectedSeats.remove(seatNumber);
      } else {
        if (_selectedSeats.length < widget.maxPassengers) {
          _selectedSeats.add(seatNumber);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum ${widget.maxPassengers} passengers allowed',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      _passengerCount = _selectedSeats.length;
      _updateNameControllers();
    });
  }

  void _updateNameControllers() {
    // Adjust name controllers based on selected seats
    while (_nameControllers.length < _passengerCount) {
      _nameControllers.add(TextEditingController());
    }
    while (_nameControllers.length > _passengerCount) {
      _nameControllers.removeLast().dispose();
    }
  }

  Future<void> _autoAssignSeats() async {
    if (_passengerCount == 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingDataSource = getIt<BookingDataSource>();
      // ✅ FIXED: Use the correct method name with proper parameters
      final assignedSeats = await bookingDataSource.autoAssignSeatsForTrip(
        tripId: widget.trip.id,
        pickupStopId: widget.pickupStopId,
        dropoffStopId: widget.dropoffStopId,
        passengerCount: _passengerCount,
        travelDate: widget.travelDate,
      );

      setState(() {
        _selectedSeats = assignedSeats;
        _updateNameControllers();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seats auto-assigned: ${assignedSeats.join(", ")}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to auto-assign seats: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmSelection() {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one seat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get passenger names
    final names =
        _nameControllers
            .map((controller) => controller.text.trim())
            .where((name) => name.isNotEmpty)
            .toList();

    widget.onSeatsSelected(_selectedSeats, _passengerCount, names);
    Navigator.pop(context);
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
          _buildHeader(),
          if (_isLoading)
            Expanded(child: LoadingIndicator())
          else if (_error != null)
            Expanded(child: _buildErrorView())
          else
            Expanded(child: _buildSeatSelection()),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.airline_seat_recline_normal,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Seats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.trip.vehiclePlate ?? 'Vehicle ${widget.trip.id}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
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
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSeatData,
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
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPassengerCountSelector(),
          _buildSeatMap(),
          _buildPassengerNamesForm(),
        ],
      ),
    );
  }

  Widget _buildPassengerCountSelector() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Number of Passengers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
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
                                  _updateNameControllers();
                                });
                              }
                              : null,
                      icon: Icon(Icons.remove_circle_outline),
                      color: AppTheme.primaryColor,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_passengerCount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _passengerCount < widget.maxPassengers
                              ? () {
                                setState(() {
                                  _passengerCount++;
                                  _updateNameControllers();
                                });
                              }
                              : null,
                      icon: Icon(Icons.add_circle_outline),
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _autoAssignSeats,
                icon: Icon(Icons.auto_fix_high, size: 18),
                label: Text('Auto Assign'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatMap() {
    if (_seatData == null) return SizedBox.shrink();

    final availableSeats =
        _seatData!['available_seats'] as List<dynamic>? ?? [];
    final occupiedSeats = _seatData!['occupied_seats'] as List<dynamic>? ?? [];
    final seatSummary =
        _seatData!['seat_summary'] as Map<String, dynamic>? ?? {};

    // Create a map of all seats
    Map<String, String> seatStatuses = {};

    for (final seat in availableSeats) {
      seatStatuses[seat['seat_number']] = 'available';
    }

    for (final seat in occupiedSeats) {
      seatStatuses[seat['seat_number']] = 'occupied';
    }

    // Generate seat layout (simplified - you may want to customize based on vehicle type)
    final totalSeats = seatSummary['total_seats'] ?? 0;
    final seatsPerRow = 4; // Typical daladala layout
    final rows =
        totalSeats > 0
            ? (totalSeats / seatsPerRow).ceil()
            : 7; // Default 7 rows

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seat Map',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '${_selectedSeats.length}/$_passengerCount selected',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Driver area
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.drive_eta, size: 20, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text('Driver', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Seat grid
          ...List.generate(rows, (rowIndex) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(seatsPerRow, (seatIndex) {
                  final seatNumber =
                      '${String.fromCharCode(65 + rowIndex)}${seatIndex + 1}';
                  final status = seatStatuses[seatNumber] ?? 'unavailable';
                  final isSelected = _selectedSeats.contains(seatNumber);

                  return _buildSeatWidget(seatNumber, status, isSelected);
                }),
              ),
            );
          }),
          SizedBox(height: 16),
          _buildSeatLegend(),
        ],
      ),
    );
  }

  Widget _buildSeatWidget(String seatNumber, String status, bool isSelected) {
    Color seatColor;
    Color textColor;
    bool isClickable = false;

    switch (status) {
      case 'available':
        seatColor = isSelected ? AppTheme.primaryColor : Colors.grey[200]!;
        textColor = isSelected ? Colors.white : Colors.grey[700]!;
        isClickable = true;
        break;
      case 'occupied':
        seatColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        break;
      default:
        seatColor = Colors.grey[100]!;
        textColor = Colors.grey[400]!;
    }

    return GestureDetector(
      onTap: isClickable ? () => _toggleSeat(seatNumber) : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            seatNumber,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Available', Colors.grey[200]!, Colors.grey[700]!),
        _buildLegendItem('Selected', AppTheme.primaryColor, Colors.white),
        _buildLegendItem('Occupied', Colors.red[100]!, Colors.red[700]!),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPassengerNamesForm() {
    if (_selectedSeats.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passenger Names (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          ...List.generate(_selectedSeats.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _nameControllers[index],
                decoration: InputDecoration(
                  labelText:
                      'Seat ${_selectedSeats[index]} - Passenger ${index + 1}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedSeats.length} seat${_selectedSeats.length != 1 ? 's' : ''} selected',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (_selectedSeats.isNotEmpty)
                    Text(
                      'Seats: ${_selectedSeats.join(", ")}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: _selectedSeats.isNotEmpty ? _confirmSelection : null,
              child: Text('Confirm Seats'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
