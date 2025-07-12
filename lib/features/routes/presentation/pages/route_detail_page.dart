// ignore_for_file: empty_catches

import 'package:daladala_smart_app/features/routes/presentation/widgets/modern_stop_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../providers/route_provider.dart';
import '../../../trips/presentation/pages/trip_selection_page.dart';
import '../../domain/entities/transport_route.dart';
import '../../domain/entities/stop.dart';

class RouteDetailPage extends StatefulWidget {
  final int routeId;

  const RouteDetailPage({super.key, required this.routeId});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  TransportRoute? _currentRoute;
  List<Stop> _routeStops = [];

  // Stop selection state
  Stop? _selectedPickupStop;
  Stop? _selectedDropoffStop;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRouteDetails();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadRouteDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final routeProvider = Provider.of<RouteProvider>(context, listen: false);

      TransportRoute? foundRoute;
      if (routeProvider.routes != null) {
        try {
          foundRoute = routeProvider.routes!.firstWhere(
            (route) => route.id == widget.routeId,
          );
        } catch (e) {}
      }

      if (foundRoute == null) {
        await routeProvider.getAllRoutes();

        if (routeProvider.routes != null) {
          try {
            foundRoute = routeProvider.routes!.firstWhere(
              (route) => route.id == widget.routeId,
            );
          } catch (e) {}
        }
      }

      if (foundRoute != null) {
        setState(() {
          _currentRoute = foundRoute;
        });

        final stopsResult = await routeProvider.getRouteStops(widget.routeId);

        stopsResult.fold(
          (failure) {
            setState(() {
              _error = 'Failed to load route stops: ${failure.message}';
            });
          },
          (stops) {
            setState(() {
              _routeStops = stops;
            });
            _updateMapMarkers(stops);
          },
        );
      } else {
        setState(() {
          _error = 'Route not found (ID: ${widget.routeId})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load route details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMapMarkers(List<Stop> stops) {
    try {
      final markers = <Marker>{};

      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        if (stop.latitude != 0.0 && stop.longitude != 0.0) {
          markers.add(
            Marker(
              markerId: MarkerId('stop_${stop.id}'),
              position: LatLng(stop.latitude, stop.longitude),
              infoWindow: InfoWindow(
                title: stop.stopName,
                snippet: stop.isMajor ? 'Major Stop' : 'Regular Stop',
              ),
              icon: _getMarkerIcon(stop),
            ),
          );
        }
      }

      setState(() {
        _markers = markers;
      });

      // Move camera to show all markers
      if (markers.isNotEmpty && _mapController != null) {
        _fitMarkersOnMap();
      }
    } catch (e) {}
  }

  BitmapDescriptor _getMarkerIcon(Stop stop) {
    // Change marker color based on selection
    if (_selectedPickupStop?.id == stop.id) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (_selectedDropoffStop?.id == stop.id) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else if (stop.isMajor) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  void _fitMarkersOnMap() async {
    if (_markers.isEmpty || _mapController == null) return;

    try {
      final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } catch (e) {}
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      minLat = minLat < pos.latitude ? minLat : pos.latitude;
      maxLat = maxLat > pos.latitude ? maxLat : pos.latitude;
      minLng = minLng < pos.longitude ? minLng : pos.longitude;
      maxLng = maxLng > pos.longitude ? maxLng : pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _showStopSelectionDialog() {
    StopSelectionHelper.showModernStopSelection(
      context: context,
      stops: _routeStops,
      routeName: _currentRoute?.routeName ?? 'Unknown Route',
      onStopsSelected: (pickupStopId, dropoffStopId) {
        try {
          // Find the actual stop objects
          final pickupStop = _routeStops.firstWhere(
            (s) => s.id == pickupStopId,
          );
          final dropoffStop = _routeStops.firstWhere(
            (s) => s.id == dropoffStopId,
          );

          // Update local state
          setState(() {
            _selectedPickupStop = pickupStop;
            _selectedDropoffStop = dropoffStop;
          });

          // NAVIGATE TO SEARCH ROUTE PAGE with selected stops
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                print('🏗️ Building TripSelectionPage...');
                return TripSelectionPage(
                  routeId: widget.routeId,
                  pickupStopId: pickupStopId,
                  dropoffStopId: dropoffStopId,
                  routeName: _currentRoute?.routeName ?? 'Unknown Route',
                  from: pickupStop.stopName,
                  to: dropoffStop.stopName,
                );
              },
            ),
          );

          // OR if you prefer to use Navigator.push:
          /*
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchRoutePage(
              preselectedFrom: pickupStop.stopName,
              preselectedTo: dropoffStop.stopName,
              pickupStopId: pickupStopId,
              dropoffStopId: dropoffStopId,
              routeId: widget.routeId,
            ),
          ),
        );
        */
        } catch (e) {
          print('❌ Error in onStopsSelected: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: Could not find selected stops - $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      initialPickupStopId: _selectedPickupStop?.id,
      initialDropoffStopId: _selectedDropoffStop?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoute?.routeName ?? 'Route Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _currentRoute != null && _routeStops.isNotEmpty)
            IconButton(
              icon: Icon(Icons.list),
              onPressed: _showStopSelectionDialog,
              tooltip: 'Select Stops',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: LoadingIndicator())
              : _error != null
              ? ErrorView(message: _error!, onRetry: _loadRouteDetails)
              : _currentRoute == null
              ? const Center(child: Text('Route not found'))
              : Column(
                children: [
                  // Route Info Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _currentRoute!.routeNumber,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentRoute!.routeName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.my_location,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentRoute!.startPoint,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentRoute!.endPoint,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        if (_currentRoute!.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _currentRoute!.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (_currentRoute!.distanceKm != null) ...[
                              Icon(
                                Icons.straighten,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentRoute!.distanceKm!.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (_currentRoute!.estimatedTimeMinutes !=
                                null) ...[
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentRoute!.estimatedTimeMinutes} min',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              '${_routeStops.length} stops',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Selected Stops Display
                  if (_selectedPickupStop != null ||
                      _selectedDropoffStop != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Selected Stops',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '🟢 Pickup: ${_selectedPickupStop?.stopName ?? 'Not selected'}',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '🔴 Drop-off: ${_selectedDropoffStop?.stopName ?? 'Not selected'}',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Map
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            _routeStops.isNotEmpty
                                ? GoogleMap(
                                  onMapCreated: (controller) {
                                    _mapController = controller;
                                    _fitMarkersOnMap();
                                  },
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      _routeStops.first.latitude != 0.0
                                          ? _routeStops.first.latitude
                                          : -6.7924,
                                      _routeStops.first.longitude != 0.0
                                          ? _routeStops.first.longitude
                                          : 39.2083,
                                    ),
                                    zoom: 12,
                                  ),
                                  markers: _markers,
                                  polylines: _polylines,
                                )
                                : const Center(
                                  child: Text(
                                    'No location data available',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                      ),
                    ),
                  ),

                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'Select Pickup & Drop-off Stops',
                          onPressed:
                              _routeStops.isNotEmpty
                                  ? _showStopSelectionDialog
                                  : null,
                          icon: Icons.list,
                        ),
                        if (_selectedPickupStop != null &&
                            _selectedDropoffStop != null) ...[
                          const SizedBox(height: 8),
                          CustomButton(
                            text: 'Find Trips',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TripSelectionPage(
                                        routeId: widget.routeId,
                                        routeName:
                                            _currentRoute?.routeName ??
                                            'Unknown Route',
                                        from: _selectedPickupStop!.stopName,
                                        to: _selectedDropoffStop!.stopName,
                                        pickupStopId: _selectedPickupStop!.id,
                                        dropoffStopId: _selectedDropoffStop!.id,
                                      ),
                                ),
                              );
                            },
                            icon: Icons.search,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
