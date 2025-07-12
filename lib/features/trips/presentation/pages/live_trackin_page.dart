import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../../../../core/di/service_locator.dart';
import '../../domains/usecases/get_trip_details_usecase.dart';
import '../../domains/entities/trip.dart';
import '../../../routes/presentation/providers/route_provider.dart';
import '../../../routes/domain/entities/stop.dart';

class LiveTrackingPage extends StatefulWidget {
  final int tripId;

  const LiveTrackingPage({super.key, required this.tripId});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  GoogleMapController? _mapController;
  Timer? _trackingTimer;
  Trip? _tripData;
  List<Stop> _routeStops = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isLoading = true;
  String? _error;
  bool _isTracking = false;

  // Tracking state
  LatLng? _previousLocation;
  List<LatLng> _vehicleTrail = [];

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadTripData() async {
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
        _error = 'Failed to load trip data: $e';
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
      // Add current vehicle position
      _markers.add(
        Marker(
          markerId: const MarkerId('vehicle'),
          position: _tripData!.currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Vehicle ${_tripData!.vehiclePlate ?? ''}',
            snippet: 'Current Position',
          ),
        ),
      );

      // Initialize vehicle trail
      if (_vehicleTrail.isEmpty) {
        _vehicleTrail.add(_tripData!.currentLocation!);
      }
    }

    // Add route stops
    if (_routeStops.isNotEmpty) {
      for (int i = 0; i < _routeStops.length; i++) {
        final stop = _routeStops[i];
        final isCurrentStop = _tripData?.currentStopId == stop.id;
        final isNextStop = _tripData?.nextStopId == stop.id;

        _markers.add(
          Marker(
            markerId: MarkerId('stop_${stop.id}'),
            position: LatLng(stop.latitude, stop.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isCurrentStop
                  ? BitmapDescriptor.hueGreen
                  : isNextStop
                  ? BitmapDescriptor.hueOrange
                  : i == 0
                  ? BitmapDescriptor.hueGreen
                  : i == _routeStops.length - 1
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueYellow,
            ),
            infoWindow: InfoWindow(
              title: stop.stopName,
              snippet:
                  isCurrentStop
                      ? 'Current Stop'
                      : isNextStop
                      ? 'Next Stop'
                      : i == 0
                      ? 'Start'
                      : i == _routeStops.length - 1
                      ? 'End'
                      : 'Stop',
            ),
          ),
        );
      }

      // Create route polyline
      if (_routeStops.length > 1) {
        final routePoints =
            _routeStops
                .map((stop) => LatLng(stop.latitude, stop.longitude))
                .toList();

        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: AppTheme.primaryColor.withOpacity(0.6),
            width: 4,
            patterns: [PatternItem.dash(10), PatternItem.gap(5)],
          ),
        );
      }
    }

    // Add vehicle trail polyline
    if (_vehicleTrail.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('vehicle_trail'),
          points: _vehicleTrail,
          color: Colors.blue,
          width: 3,
        ),
      );
    }

    setState(() {});
  }

  void _startTracking() {
    if (_isTracking) return;

    setState(() {
      _isTracking = true;
    });

    // Update every 10 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateTripLocation();
    });
  }

  void _stopTracking() {
    _trackingTimer?.cancel();
    setState(() {
      _isTracking = false;
    });
  }

  Future<void> _updateTripLocation() async {
    if (_tripData == null) return;

    try {
      final getTripDetailsUseCase = getIt<GetTripDetailsUseCase>();
      final result = await getTripDetailsUseCase(
        GetTripDetailsParams(tripId: widget.tripId),
      );

      result.fold(
        (failure) {
        },
        (updatedTrip) {
          if (updatedTrip.currentLocation != null) {
            final newLocation = updatedTrip.currentLocation!;

            // Update trip data
            setState(() {
              _tripData = updatedTrip;
            });

            // Add to trail if location changed significantly
            if (_previousLocation == null ||
                _calculateDistance(_previousLocation!, newLocation) > 50) {
              _vehicleTrail.add(newLocation);
              _previousLocation = newLocation;
            }

            _updateVehicleMarker(newLocation);
            _mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
          }
        },
      );
    } catch (e) {
    }
  }

  void _updateVehicleMarker(LatLng newLocation) {
    _markers.removeWhere((marker) => marker.markerId.value == 'vehicle');

    _markers.add(
      Marker(
        markerId: const MarkerId('vehicle'),
        position: newLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Vehicle ${_tripData!.vehiclePlate ?? ''}',
          snippet: 'Updated ${DateFormat('HH:mm:ss').format(DateTime.now())}',
        ),
      ),
    );

    // Update vehicle trail polyline
    _polylines.removeWhere(
      (polyline) => polyline.polylineId.value == 'vehicle_trail',
    );

    if (_vehicleTrail.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('vehicle_trail'),
          points: _vehicleTrail,
          color: Colors.blue,
          width: 3,
        ),
      );
    }

    setState(() {});
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // meters
    final double dLat = (end.latitude - start.latitude) * (math.pi / 180);
    final double dLng = (end.longitude - start.longitude) * (math.pi / 180);

    final double a =
        (dLat / 2) * (dLat / 2) +
        (dLng / 2) *
            (dLng / 2) *
            math.cos(start.latitude * math.pi / 180) *
            math.cos(end.latitude * math.pi / 180);

    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Start tracking automatically when map is ready
    if (_tripData != null &&
        (_tripData!.status == 'active' || _tripData!.status == 'in_progress')) {
      _startTracking();
    }
  }

  Widget _buildErrorView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ErrorView(
        message: _error ?? 'Failed to load trip data',
        onRetry: _loadTripData,
      ),
    );
  }

  Widget _buildLoadingView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(child: LoadingIndicator()),
    );
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

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
                  trip.currentLocation ??
                  const LatLng(-6.8, 39.3), // Default to Dar es Salaam
              zoom: 14.0,
            ),
            onMapCreated: _onMapCreated,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            mapType: MapType.normal,
          ),

          // App Bar
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
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isTracking ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Live Tracking',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tracking toggle
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
                      icon: Icon(
                        _isTracking ? Icons.pause : Icons.play_arrow,
                        color: _isTracking ? Colors.red : Colors.green,
                      ),
                      onPressed: _isTracking ? _stopTracking : _startTracking,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Trip info
                  Row(
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
                              'Vehicle: ${trip.vehiclePlate ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
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
                            Icon(
                              trip.status == 'active' ||
                                      trip.status == 'in_progress'
                                  ? Icons.directions_bus
                                  : Icons.schedule,
                              size: 16,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trip.status.replaceAll('_', ' ').toUpperCase(),
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
                  const SizedBox(height: 16),

                  // Current and next stop info
                  if (_routeStops.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildStopInfo(
                            'Current Stop',
                            _routeStops
                                .firstWhere(
                                  (stop) => stop.id == trip.currentStopId,
                                  orElse: () => _routeStops.first,
                                )
                                .stopName,
                            Icons.location_on,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStopInfo(
                            'Next Stop',
                            _routeStops
                                .firstWhere(
                                  (stop) => stop.id == trip.nextStopId,
                                  orElse:
                                      () =>
                                          _routeStops.length > 1
                                              ? _routeStops[1]
                                              : _routeStops.first,
                                )
                                .stopName,
                            Icons.flag,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Tracking status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _isTracking
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isTracking ? Icons.wifi : Icons.wifi_off,
                          color: _isTracking ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isTracking
                              ? 'Live tracking active • Updates every 10s'
                              : 'Tracking paused • Tap play to resume',
                          style: TextStyle(
                            color: _isTracking ? Colors.green : Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildStopInfo(
    String title,
    String stopName,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stopName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
