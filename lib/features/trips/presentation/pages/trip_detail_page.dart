import 'package:daladala_smart_app/features/reviews/presentation/pages/add_review_page.dart';
import 'package:daladala_smart_app/features/trips/domains/usecases/get_trip_details_usecase.dart';
import 'package:daladala_smart_app/features/trips/domains/entities/trip.dart';
import 'package:daladala_smart_app/core/di/service_locator.dart';
import 'package:daladala_smart_app/features/routes/presentation/providers/route_provider.dart';
import 'package:daladala_smart_app/features/routes/domain/entities/stop.dart';
import 'package:daladala_smart_app/features/trips/presentation/pages/live_trackin_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/error_view.dart';

class TripDetailPage extends StatefulWidget {
  final int tripId;

  const TripDetailPage({super.key, required this.tripId});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  bool _isLoading = true;
  String? _error;
  Trip? _tripData;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Stop> _routeStops = [];

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final getTripDetailsUseCase = getIt<GetTripDetailsUseCase>();
      final result = await getTripDetailsUseCase(
        GetTripDetailsParams(tripId: widget.tripId),
      );

      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (trip) {
          setState(() {
            _tripData = trip;
            _isLoading = false;
          });
          _loadRouteStops();
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to load trip details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRouteStops() async {
    if (_tripData?.routeId == null) {
      _initializeMap();
      return;
    }

    try {
      final routeProvider = Provider.of<RouteProvider>(context, listen: false);
      final result = await routeProvider.getRouteStops(_tripData!.routeId);

      result.fold(
        (failure) {
          _initializeMap();
        },
        (stops) {
          setState(() {
            _routeStops = stops;
          });
          _initializeMap();
        },
      );
    } catch (e) {
      _initializeMap();
    }
  }

  void _initializeMap() {
    _markers.clear();
    _polylines.clear();

    if (_tripData?.currentLocation != null) {
      // Add vehicle marker
      _markers.add(
        Marker(
          markerId: const MarkerId('vehicle'),
          position: _tripData!.currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Vehicle Location',
            snippet: _tripData!.vehiclePlate ?? 'Vehicle',
          ),
        ),
      );
    }

    // Add route stops if available
    if (_routeStops.isNotEmpty) {
      for (int i = 0; i < _routeStops.length; i++) {
        final stop = _routeStops[i];
        _markers.add(
          Marker(
            markerId: MarkerId('stop_${stop.id}'),
            position: LatLng(stop.latitude, stop.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0
                  ? BitmapDescriptor.hueGreen
                  : i == _routeStops.length - 1
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: stop.stopName,
              snippet:
                  i == 0
                      ? 'Start'
                      : i == _routeStops.length - 1
                      ? 'End'
                      : 'Stop',
            ),
          ),
        );
      }

      // Create polyline for route
      if (_routeStops.length > 1) {
        final polylinePoints =
            _routeStops
                .map((stop) => LatLng(stop.latitude, stop.longitude))
                .toList();

        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: AppTheme.primaryColor,
            width: 4,
            patterns: [PatternItem.dash(10), PatternItem.gap(5)],
          ),
        );
      }
    }

    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return Icons.directions_bus;
      case 'scheduled':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildErrorView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ErrorView(
        message: _error ?? 'Failed to load trip details',
        onRetry: _loadTripDetails,
      ),
    );
  }

  Widget _buildLoadingView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(child: LoadingIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_tripData == null) {
      return _buildErrorView();
    }

    final trip = _tripData!;
    final statusColor = _getStatusColor(trip.status);
    final statusIcon = _getStatusIcon(trip.status);
    final formattedDate = DateFormat('MMM dd, yyyy').format(trip.startTime);
    final formattedStartTime = DateFormat('HH:mm').format(trip.startTime);
    final formattedEndTime =
        trip.endTime != null
            ? DateFormat('HH:mm').format(trip.endTime!)
            : 'TBD';

    return Scaffold(
      body: Stack(
        children: [
          // Map
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child:
                trip.currentLocation != null
                    ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: trip.currentLocation!,
                        zoom: 13.0,
                      ),
                      onMapCreated: _onMapCreated,
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    )
                    : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Location not available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),

          // App bar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        final String googleMapsLink =
                            trip.currentLocation != null
                                ? "https://www.google.com/maps/search/?api=1&query=${trip.currentLocation!.latitude},${trip.currentLocation!.longitude}"
                                : "https://www.google.com/maps";

                        final String tripDetails = """
Trip Details - Daladala Smart

Route: ${trip.routeName ?? 'N/A'}
From: ${trip.route?.startPoint ?? 'N/A'}
To: ${trip.route?.endPoint ?? 'N/A'}
Date: $formattedDate
Time: $formattedStartTime - $formattedEndTime
Vehicle: ${trip.vehiclePlate ?? 'N/A'}
Driver: ${trip.driverName ?? 'N/A'}
Status: ${_capitalize(trip.status.replaceAll('_', ' '))}

Track this trip: $googleMapsLink

Download Daladala Smart App for real-time tracking!
                        """;

                        Share.share(tripDetails);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trip details (bottom sheet)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
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
                                trip.routeName ?? 'Unknown Route',
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
                                _capitalize(trip.status.replaceAll('_', ' ')),
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

                  // Route details
                  if (trip.route != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  trip.route!.startPoint,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
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
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 2,
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  trip.route!.endPoint,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Trip info
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle and driver info
                          Row(
                            children: [
                              Expanded(
                                child: _InfoCard(
                                  icon: Icons.directions_bus,
                                  title: 'Vehicle',
                                  subtitle: trip.vehiclePlate ?? 'N/A',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InfoCard(
                                  icon: Icons.person,
                                  title: 'Driver',
                                  subtitle: trip.driverName ?? 'N/A',
                                  trailing:
                                      trip.driverRating != null
                                          ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 14,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                trip.driverRating!
                                                    .toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          )
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Seats info
                          Row(
                            children: [
                              Expanded(
                                child: _InfoCard(
                                  icon: Icons.airline_seat_recline_normal,
                                  title: 'Available Seats',
                                  subtitle: '${trip.availableSeats ?? 0}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InfoCard(
                                  icon: Icons.people,
                                  title: 'Occupied Seats',
                                  subtitle: '${trip.occupiedSeats ?? 0}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Distance and time
                          if (trip.route != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoCard(
                                    icon: Icons.straighten,
                                    title: 'Distance',
                                    subtitle:
                                        trip.route!.distanceKm != null
                                            ? '${trip.route!.distanceKm!.toStringAsFixed(1)} km'
                                            : 'N/A',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _InfoCard(
                                    icon: Icons.access_time,
                                    title: 'Est. Duration',
                                    subtitle:
                                        trip.route!.estimatedTimeMinutes != null
                                            ? '${trip.route!.estimatedTimeMinutes} min'
                                            : 'N/A',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Action buttons
                          if (trip.status == 'completed') ...[
                            CustomButton(
                              text: 'Rate Trip',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AddReviewPage(
                                          tripId: trip.id,
                                          driverId: trip.driverId ?? 0,
                                          driverName:
                                              trip.driverName ??
                                              'Unknown Driver',
                                          vehicleId: trip.vehicleId,
                                          vehiclePlate:
                                              trip.vehiclePlate ??
                                              'Unknown Vehicle',
                                        ),
                                  ),
                                );
                              },
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          ] else if (trip.status == 'active' ||
                              trip.status == 'in_progress') ...[
                            CustomButton(
                              text: 'Track Live',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            LiveTrackingPage(tripId: trip.id),
                                  ),
                                );
                              },
                              backgroundColor: Colors.green,
                              icon: Icons.my_location,
                            ),
                          ] else if (trip.status == 'scheduled') ...[
                            CustomButton(
                              text: 'Get Ready',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Trip will start soon. Please be at the pickup point.',
                                    ),
                                  ),
                                );
                              },
                              backgroundColor: Colors.blue,
                              icon: Icons.notifications_active,
                            ),
                          ],
                        ],
                      ),
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
