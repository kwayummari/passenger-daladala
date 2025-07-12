import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../widgets/upcoming_departure_item.dart';
import '../../../trips/presentation/pages/trip_selection_page.dart';

class StopDetailPage extends StatefulWidget {
  final int stopId;

  const StopDetailPage({
    Key? key,
    required this.stopId,
  }) : super(key: key);

  @override
  State<StopDetailPage> createState() => _StopDetailPageState();
}

class _StopDetailPageState extends State<StopDetailPage> {
  bool _isLoading = true;
  GoogleMapController? _mapController;
  Map<String, dynamic>? _stopData;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadStopDetails();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadStopDetails() async {
    // In a real app, this would load from the API
    // For now, we'll use sample data
    await Future.delayed(const Duration(seconds: 1));

    // Sample data
    _stopData = {
      'id': widget.stopId,
      'name': 'Mwenge Bus Terminal',
      'latitude': -6.7689,
      'longitude': 39.2192,
      'address': 'Mwenge Bus Terminal, Ali Hassan Mwinyi Road',
      'is_major': true,
      'status': 'active',
      'routes': [
        {
          'id': 1,
          'route_name': 'R001: Mbezi - CBD',
          'start_point': 'Mbezi Mwisho',
          'end_point': 'Posta CBD',
          'stops': [
            {'id': 1, 'name': 'Mbezi Mwisho Terminal'},
            {'id': 2, 'name': 'Mbezi Beach'},
            {'id': 3, 'name': 'Sinza Mori'},
            {'id': 4, 'name': 'Mwenge Bus Terminal'},
            {'id': 5, 'name': 'Msimbazi'},
            {'id': 6, 'name': 'Posta CBD'},
          ],
        },
        {
          'id': 2,
          'route_name': 'R002: Kimara - CBD',
          'start_point': 'Kimara Mwisho',
          'end_point': 'Posta CBD',
          'stops': [
            {'id': 7, 'name': 'Kimara Mwisho'},
            {'id': 8, 'name': 'Kimara Korogwe'},
            {'id': 4, 'name': 'Mwenge Bus Terminal'},
            {'id': 9, 'name': 'Ubungo'},
            {'id': 6, 'name': 'Posta CBD'},
          ],
        },
        {
          'id': 3,
          'route_name': 'R003: Tegeta - CBD',
          'start_point': 'Tegeta Mwisho',
          'end_point': 'Posta CBD',
          'stops': [
            {'id': 10, 'name': 'Tegeta Mwisho'},
            {'id': 11, 'name': 'Tegeta Wazo'},
            {'id': 4, 'name': 'Mwenge Bus Terminal'},
            {'id': 12, 'name': 'Mlimani City'},
            {'id': 6, 'name': 'Posta CBD'},
          ],
        },
      ],
      'upcoming_departures': [
        {
          'trip_id': 1,
          'route_id': 1,
          'route_name': 'R001: Mbezi - CBD',
          'departure_time': DateTime.now().add(const Duration(minutes: 5)),
          'destination': 'Posta CBD',
          'vehicle_type': 'daladala',
          'available_seats': 12,
        },
        {
          'trip_id': 2,
          'route_id': 2,
          'route_name': 'R002: Kimara - CBD',
          'departure_time': DateTime.now().add(const Duration(minutes: 15)),
          'destination': 'Posta CBD',
          'vehicle_type': 'daladala',
          'available_seats': 8,
        },
        {
          'trip_id': 3,
          'route_id': 3,
          'route_name': 'R003: Tegeta - CBD',
          'departure_time': DateTime.now().add(const Duration(minutes: 30)),
          'destination': 'Posta CBD',
          'vehicle_type': 'minibus',
          'available_seats': 5,
        },
      ],
    };

    // Set up map marker
    _setupMapMarker();

    setState(() {
      _isLoading = false;
    });
  }

  void _setupMapMarker() {
    if (_stopData == null) return;

    final position = LatLng(
      _stopData!['latitude'],
      _stopData!['longitude'],
    );

    _markers = {
      Marker(
        markerId: MarkerId('stop_${_stopData!['id']}'),
        position: position,
        infoWindow: InfoWindow(title: _stopData!['name']),
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Center the map on the stop
    if (_stopData != null) {
      final position = LatLng(
        _stopData!['latitude'],
        _stopData!['longitude'],
      );
      controller.moveCamera(
        CameraUpdate.newLatLngZoom(position, 15.0),
      );
    }
  }

  void _navigateToTripSelection(Map<String, dynamic> departure) {
    // Find the route to get its stops
    final route = (_stopData!['routes'] as List).firstWhere(
      (r) => r['id'] == departure['route_id'],
    );
    
    _showDestinationSelectionDialog(departure, route);
  }

  void _showDestinationSelectionDialog(Map<String, dynamic> departure, Map<String, dynamic> route) {
    final routeStops = route['stops'] as List<Map<String, dynamic>>;
    final currentStopId = _stopData!['id'] as int;
    
    // Filter stops that come after the current stop (for departure)
    final availableDestinations = routeStops
        .where((stop) => stop['id'] != currentStopId)
        .toList();

    int? selectedDestinationId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Select Destination',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 12),
                    const SizedBox(width: 8),
                    Text('From: ${_stopData!['name']}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Choose your destination along ${route['route_name']}:',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Destinations list
              Expanded(
                child: ListView.builder(
                  itemCount: availableDestinations.length,
                  itemBuilder: (context, index) {
                    final stop = availableDestinations[index];
                    final isSelected = selectedDestinationId == stop['id'];
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? Colors.red : Colors.grey.shade300,
                        child: Icon(
                          Icons.location_on,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        stop['name'] as String,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected 
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.red,
                            )
                          : null,
                      onTap: () {
                        setModalState(() {
                          selectedDestinationId = stop['id'] as int;
                        });
                      },
                    );
                  },
                ),
              ),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'View Trips',
                      onPressed: selectedDestinationId != null
                          ? () {
                              Navigator.pop(context);
                              
                              final destinationStop = availableDestinations.firstWhere(
                                (s) => s['id'] == selectedDestinationId
                              );
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TripSelectionPage(
                                    routeId: departure['route_id'],
                                    routeName: departure['route_name'],
                                    from: _stopData!['name'],
                                    to: destinationStop['name'] as String,
                                    pickupStopId: currentStopId,           // ✅ Current stop as pickup
                                    dropoffStopId: selectedDestinationId!, // ✅ Selected destination
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stop Details'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: ErrorView(
          title: 'Stop Not Found',
          message: 'The requested stop information could not be found.',
          buttonText: 'Go Back',
          onRetry: () => Navigator.pop(context),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Map view (upper half)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_stopData!['latitude'], _stopData!['longitude']),
                    zoom: 15.0,
                  ),
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),

                // App bar
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Back button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        // Share button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () {
                              // Share stop details
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stop details
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stop name and info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _stopData!['name'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_stopData!['is_major'])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Major Terminal',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _stopData!['address'],
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Get directions to the stop
                                },
                                icon: const Icon(Icons.directions),
                                label: const Text('Directions'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Save stop as favorite
                                },
                                icon: const Icon(Icons.favorite_border),
                                label: const Text('Save'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Upcoming departures
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming Departures',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_stopData!['upcoming_departures'].isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.departure_board,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No upcoming departures',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _stopData!['upcoming_departures'].length,
                            itemBuilder: (context, index) {
                              final departure = _stopData!['upcoming_departures'][index];
                              return UpcomingDepartureItem(
                                tripId: departure['trip_id'],
                                routeName: departure['route_name'],
                                departureTime: departure['departure_time'],
                                destination: departure['destination'],
                                vehicleType: departure['vehicle_type'],
                                availableSeats: departure['available_seats'],
                                onBookTrip: () => _navigateToTripSelection(departure), // ✅ Now shows destination selection
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  // Routes serving this stop
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Routes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _stopData!['routes'].length,
                          itemBuilder: (context, index) {
                            final route = _stopData!['routes'][index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // Navigate to route detail
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.directions_bus,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              route['route_name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${route['start_point']} - ${route['end_point']}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textSecondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppTheme.textTertiaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}