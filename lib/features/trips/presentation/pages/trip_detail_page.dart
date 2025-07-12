import 'package:daladala_smart_app/features/reviews/presentation/pages/add_review_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_button.dart';

class TripDetailPage extends StatefulWidget {
  final int tripId;

  const TripDetailPage({super.key, required this.tripId});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  bool _isLoading = true;
  GoogleMapController? _mapController;

  // Trip data (would come from API)
  Map<String, dynamic>? _tripData;

  // Map markers
  Set<Marker> _markers = {};

  // Polyline for route
  Set<Polyline> _polylines = {};

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadTripDetails() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Set sample data
    _tripData = {
      'id': widget.tripId,
      'route_name': 'R001: Mbezi - CBD',
      'route_number': 'R001',
      'start_point': 'Mbezi Mwisho',
      'end_point': 'Posta CBD',
      'start_time': DateTime.now().add(const Duration(minutes: 30)),
      'estimated_end_time': DateTime.now().add(const Duration(minutes: 75)),
      'status': 'scheduled',
      'vehicle_plate': 'T123ABC',
      'vehicle_type': 'daladala',
      'driver_name': 'David Driver',
      'driver_rating': 4.75,
      'total_distance': 18.5,
      'current_location': const LatLng(-6.7789, 39.2083), // Mwenge
      'pickup_location': const LatLng(-6.7402, 39.1589), // Mbezi
      'dropoff_location': const LatLng(-6.8123, 39.2875), // Posta
      'stops': [
        {
          'id': 1,
          'name': 'Mbezi Mwisho',
          'position': const LatLng(-6.7402, 39.1589),
          'status': 'departed',
          'arrival_time': DateTime.now().subtract(const Duration(minutes: 15)),
          'departure_time': DateTime.now().subtract(
            const Duration(minutes: 10),
          ),
        },
        {
          'id': 2,
          'name': 'Mwenge',
          'position': const LatLng(-6.7689, 39.2192),
          'status': 'arrived',
          'arrival_time': DateTime.now().subtract(const Duration(minutes: 2)),
          'departure_time': null,
        },
        {
          'id': 3,
          'name': 'Morocco',
          'position': const LatLng(-6.7765, 39.2380),
          'status': 'pending',
          'arrival_time': null,
          'departure_time': null,
        },
        {
          'id': 4,
          'name': 'Posta CBD',
          'position': const LatLng(-6.8123, 39.2875),
          'status': 'pending',
          'arrival_time': null,
          'departure_time': null,
        },
      ],
    };

    // Setup map markers
    _setupMapMarkersAndPolylines();

    setState(() {
      _isLoading = false;
    });
  }

  void _setupMapMarkersAndPolylines() {
    if (_tripData == null) return;

    final stops = _tripData!['stops'] as List;
    final currentLocation = _tripData!['current_location'] as LatLng;

    // Create markers for each stop
    final markerSet = <Marker>{};
    for (final stop in stops) {
      final position = stop['position'] as LatLng;
      final name = stop['name'] as String;
      final status = stop['status'] as String;

      // Determine marker color based on status
      BitmapDescriptor markerIcon;
      switch (status) {
        case 'departed':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
          break;
        case 'arrived':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
          break;
        default:
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          );
      }

      markerSet.add(
        Marker(
          markerId: MarkerId('stop_${stop['id']}'),
          position: position,
          infoWindow: InfoWindow(title: name),
          icon: markerIcon,
        ),
      );
    }

    // Add vehicle marker
    markerSet.add(
      Marker(
        markerId: const MarkerId('vehicle'),
        position: currentLocation,
        infoWindow: InfoWindow(title: _tripData!['vehicle_plate']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ),
    );

    // Create polyline for the route
    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        points: stops.map((stop) => stop['position'] as LatLng).toList(),
        color: AppTheme.primaryColor,
        width: 5,
      ),
    };

    setState(() {
      _markers = markerSet;
      _polylines = polylines;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Center the map to show all markers
    if (_tripData != null) {
      controller.moveCamera(
        CameraUpdate.newLatLngZoom(_tripData!['current_location'], 13.0),
      );
    }
  }

  Future<void> _viewDriverInfo() async {
    if (_tripData == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Driver Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(
                      'assets/images/driver_placeholder.png',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tripData!['driver_name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${_tripData!['driver_rating']} Rating',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tripData!['vehicle_plate'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          capitalize(_tripData!['vehicle_type'].toString()),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: CustomButton(
                  text: 'Call Driver',
                  icon: Icons.phone,
                  onPressed: () {
                    // Make a call
                    Navigator.pop(context);
                  },
                  isFullWidth: false,
                  width: 200,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Trip'),
            content: const Text(
              'Are you sure you want to cancel this trip? Cancellation fees may apply based on our policy.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No, Keep Trip'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Handle trip cancellation
                },
                child: Text(
                  'Yes, Cancel',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trip Details'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Trip details not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Go Back',
                onPressed: () => Navigator.pop(context),
                isFullWidth: false,
                width: 120,
              ),
            ],
          ),
        ),
      );
    }

    // Format time
    final formattedStartTime = DateFormat(
      'HH:mm',
    ).format(_tripData!['start_time']);
    final formattedEndTime = DateFormat(
      'HH:mm',
    ).format(_tripData!['estimated_end_time']);
    final formattedDate = DateFormat(
      'EEE, d MMM',
    ).format(_tripData!['start_time']);

    // Determine trip status style
    Color statusColor;
    IconData statusIcon;

    switch (_tripData!['status']) {
      case 'scheduled':
        statusColor = AppTheme.confirmedColor;
        statusIcon = Icons.schedule;
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

    return Scaffold(
      body: Column(
        children: [
          // Map view (upper half)
          Expanded(
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _tripData!['current_location'],
                    zoom: 13.0,
                  ),
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                  polylines: _polylines,
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
                              // Format the trip details for sharing
                              final String googleMapsLink = "https://www.google.com/maps/search/?api=1&query=${_tripData!['current_location'].latitude},${_tripData!['current_location'].longitude}";

                              final String tripDetails = """
                              Trip Details - Daladala Smart

                              Route: ${_tripData!['route_name']}
                              From: ${_tripData!['start_point']}
                              To: ${_tripData!['end_point']}
                              Date: ${DateFormat('EEE, d MMM yyyy').format(_tripData!['start_time'])}
                              Time: ${DateFormat('HH:mm').format(_tripData!['start_time'])}
                              Vehicle: ${_tripData!['vehicle_plate']}

                              Track my location: $googleMapsLink

                              Track this trip live with Daladala Smart app!
                              """;

                              // Share the trip details
                              Share.share(
                                tripDetails,
                                subject:
                                    'My Daladala Trip - ${_tripData!['route_name']}',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recenter button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
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
                      icon: const Icon(Icons.my_location),
                      onPressed: () {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            _tripData!['current_location'],
                            15.0,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Trip details (bottom sheet)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                // Route and status
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tripData!['route_name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$formattedDate • $formattedStartTime - $formattedEndTime',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              capitalize(
                                _tripData!['status'].replaceAll('_', ' '),
                              ),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stops timeline
                Container(
                  height: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tripData!['stops'].length,
                    itemBuilder: (context, index) {
                      final stop = _tripData!['stops'][index];
                      final status = stop['status'];

                      // Determine status icon and color
                      IconData statusIcon;
                      Color statusColor;

                      switch (status) {
                        case 'departed':
                          statusIcon = Icons.check_circle;
                          statusColor = Colors.green;
                          break;
                        case 'arrived':
                          statusIcon = Icons.location_on;
                          statusColor = Colors.blue;
                          break;
                        default:
                          statusIcon = Icons.circle_outlined;
                          statusColor = Colors.grey;
                      }

                      // Format times
                      String arrivalTime = 'Pending';
                      if (stop['arrival_time'] != null) {
                        arrivalTime = DateFormat(
                          'HH:mm',
                        ).format(stop['arrival_time']);
                      }

                      return Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color:
                              status == 'arrived'
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                status == 'arrived'
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              stop['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              arrivalTime,
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              capitalize(status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Driver Info',
                          icon: Icons.person,
                          onPressed: _viewDriverInfo,
                          type: ButtonType.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text:
                              _tripData!['status'] == 'completed'
                                  ? 'Rate Trip'
                                  : 'Cancel Trip',
                          icon:
                              _tripData!['status'] == 'completed'
                                  ? Icons.star
                                  : Icons.cancel,
                          onPressed:
                              _tripData!['status'] == 'completed'
                                  ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AddReviewPage(
                                              tripId: widget.tripId,
                                              driverId:
                                                  1, // This would come from actual data
                                              driverName:
                                                  _tripData!['driver_name'],
                                              vehicleId:
                                                  1, // This would come from actual data
                                              vehiclePlate:
                                                  _tripData!['vehicle_plate'],
                                            ),
                                      ),
                                    );
                                  }
                                  : _showCancelDialog,
                          type:
                              _tripData!['status'] == 'completed'
                                  ? ButtonType.primary
                                  : ButtonType.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
