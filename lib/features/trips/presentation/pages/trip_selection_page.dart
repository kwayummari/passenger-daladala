import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
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

// Add this debug version to your TripSelectionPage

class _TripSelectionPageState extends State<TripSelectionPage> {
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _trips = [];
  Map<String, dynamic>? _fareInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('🏗️ TripSelectionPage initState called');
    print('🏗️ Route ID: ${widget.routeId}');
    print('🏗️ Pickup Stop ID: ${widget.pickupStopId}');
    print('🏗️ Dropoff Stop ID: ${widget.dropoffStopId}');
    print('🏗️ Route Name: ${widget.routeName}');
    print('🏗️ From: ${widget.from}');
    print('🏗️ To: ${widget.to}');
    _loadData();
  }

  Future<void> _loadData() async {
    print('📊 DEBUG: _loadData started');

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      print('📊 Set loading state to true');

      // Load fare information and trips concurrently
      print('📊 About to load fare info and trips...');
      await Future.wait([_loadFareInfo(), _loadTrips()]);
      print('📊 Finished loading fare info and trips');
    } catch (e, stackTrace) {
      print('❌ Error in _loadData: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
        });
      }
    } finally {
      print('📊 Setting loading to false');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('📊 _loadData completed');
    }
  }

  Future<void> _loadFareInfo() async {
    print('💰 DEBUG: _loadFareInfo started');

    try {
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.routesEndpoint}/fare?route_id=${widget.routeId}&start_stop_id=${widget.pickupStopId}&end_stop_id=${widget.dropoffStopId}';
      print('💰 Fare API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('💰 Fare API Response Status: ${response.statusCode}');
      print('💰 Fare API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              _fareInfo = data['data'];
            });
          }
          print('💰 Fare info loaded successfully: $_fareInfo');
        } else {
          print('💰 Fare API returned error status: ${data['status']}');
          print('💰 Fare API error message: ${data['message']}');
        }
      } else {
        print('💰 Fare API HTTP error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading fare info: $e');
      print('❌ Fare info stack trace: $stackTrace');
    }
  }

  Future<void> _loadTrips() async {
    print('🚌 DEBUG: _loadTrips started');

    try {
      final dateString = _selectedDate.toIso8601String().split('T')[0];
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.tripsEndpoint}/route/${widget.routeId}?date=$dateString';
      print('🚌 Trips API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('🚌 Trips API Response Status: ${response.statusCode}');
      print('🚌 Trips API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              _trips = List<Map<String, dynamic>>.from(data['data']);
            });
          }
          print('🚌 Trips loaded successfully: ${_trips.length} trips found');
        } else {
          print('🚌 Trips API returned error status: ${data['status']}');
          print('🚌 Trips API error message: ${data['message']}');
        }
      } else {
        print('🚌 Trips API HTTP error: ${response.statusCode}');
        print('🚌 Using sample data as fallback');
        if (mounted) {
          setState(() {
            _trips = _getSampleTrips();
          });
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error loading trips: $e');
      print('❌ Trips stack trace: $stackTrace');
      print('🚌 Using sample data as fallback');

      // Fallback to sample data for demo
      if (mounted) {
        setState(() {
          _trips = _getSampleTrips();
        });
      }
    }
  }

  List<Map<String, dynamic>> _getSampleTrips() {
    print('📝 Using sample trips data');
    return [
      {
        'trip_id': 1,
        'start_time':
            DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
        'Vehicle': {
          'vehicle_type': 'daladala',
          'plate_number': 'T123ABC',
          'capacity': 14,
          'is_air_conditioned': true,
        },
        'Driver': {
          'rating': 4.75,
          'total_ratings': 120,
          'User': {'first_name': 'David', 'last_name': 'Mwangi'},
        },
        'available_seats': 8,
        'status': 'scheduled',
      },
      {
        'trip_id': 2,
        'start_time':
            DateTime.now()
                .add(const Duration(hours: 1, minutes: 15))
                .toIso8601String(),
        'Vehicle': {
          'vehicle_type': 'daladala',
          'plate_number': 'T456DEF',
          'capacity': 14,
          'is_air_conditioned': false,
        },
        'Driver': {
          'rating': 4.60,
          'total_ratings': 95,
          'User': {'first_name': 'Daniel', 'last_name': 'Miller'},
        },
        'available_seats': 12,
        'status': 'scheduled',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 TripSelectionPage build called');
    print('🎨 Loading: $_isLoading, Error: $_error, Trips: ${_trips.length}');

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
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.from} → ${widget.to}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.routeName,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (_fareInfo != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fare: ${_fareInfo!['amount']?.toString() ?? 'N/A'} TZS',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Date selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                TextButton(onPressed: _selectDate, child: const Text('Change')),
              ],
            ),
          ),

          const Divider(),

          // Content area
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading available trips...'),
                        ],
                      ),
                    )
                    : _error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
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
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try selecting a different date',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _trips.length,
                      itemBuilder: (context, index) {
                        final trip = _trips[index];
                        print(
                          '🎨 Building trip item $index: ${trip['trip_id']}',
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text('Trip ${trip['trip_id']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vehicle: ${trip['Vehicle']?['plate_number'] ?? 'N/A'}',
                                ),
                                Text(
                                  'Departure: ${trip['start_time'] ?? 'N/A'}',
                                ),
                                Text(
                                  'Available Seats: ${trip['available_seats'] ?? 'N/A'}',
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _bookTrip(trip),
                              child: const Text('Book'),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      await _loadTrips();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _bookTrip(Map<String, dynamic> trip) {
    print('📖 Booking trip: ${trip['trip_id']}');

    final vehicle = trip['Vehicle'] ?? {};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingConfirmationPage(
              tripId: trip['trip_id'] ?? 0,
              routeName: widget.routeName,
              from: widget.from,
              to: widget.to,
              startTime:
                  DateTime.tryParse(trip['start_time'] ?? '') ?? DateTime.now(),
              fare: _fareInfo?['amount']?.toDouble() ?? 1500.0,
              vehiclePlate: vehicle['plate_number'] ?? 'Unknown',
              pickupStopId: widget.pickupStopId,
              dropoffStopId: widget.dropoffStopId,
            ),
      ),
    );
  }
}
