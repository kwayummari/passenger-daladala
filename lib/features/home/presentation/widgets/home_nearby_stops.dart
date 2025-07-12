import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../routes/presentation/providers/route_provider.dart';
import '../../../routes/domain/entities/stop.dart';
import '../../../routes/presentation/pages/routes_page.dart';

class HomeNearbyStops extends StatefulWidget {
  const HomeNearbyStops({super.key});

  @override
  State<HomeNearbyStops> createState() => _HomeNearbyStopsState();
}

class _HomeNearbyStopsState extends State<HomeNearbyStops> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  List<Stop> _nearbyStops = [];
  bool _isLoadingStops = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
        _errorMessage = null;
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied.';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Load nearby stops
      await _loadNearbyStops();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: ${e.toString()}';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadNearbyStops() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoadingStops = true;
      _errorMessage = null;
    });

    try {
      // Get all routes to find nearby stops
      final routeProvider = context.read<RouteProvider>();
      await routeProvider.getAllRoutes();

      final routes = routeProvider.routes;
      if (routes != null && routes.isNotEmpty) {
        List<Stop> allStops = [];

        // Collect all stops from all routes
        for (var route in routes) {
          // Get stops for each route
          await routeProvider.getRouteStops(route.id);
          final stops = routeProvider.stops;
          if (stops != null && stops.isNotEmpty) {
            allStops.addAll(stops);
          }
        }

        // Filter stops by distance (within 2km)
        List<Stop> nearbyStops = [];
        for (var stop in allStops) {
          double distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            stop.latitude,
            stop.longitude,
          );

          if (distance <= 2000) {
            // 2km radius
            // Add distance to stop for sorting
            nearbyStops.add(stop);
          }
        }

        // Sort by distance and take first 5
        nearbyStops.sort((a, b) {
          double distanceA = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            a.latitude,
            a.longitude,
          );
          double distanceB = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            b.latitude,
            b.longitude,
          );
          return distanceA.compareTo(distanceB);
        });

        setState(() {
          _nearbyStops = nearbyStops.take(5).toList();
          _isLoadingStops = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No routes available';
          _isLoadingStops = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load nearby stops';
        _isLoadingStops = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Stops',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoutesPage()),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (_isLoadingLocation || _isLoadingStops)
            const SizedBox(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Finding nearby stops...'),
                  ],
                ),
              ),
            )
          else if (_errorMessage != null)
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, color: Colors.orange.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Location access needed',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_nearbyStops.isEmpty)
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_searching,
                      color: Colors.grey.shade400,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No nearby stops found',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try a different location',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _nearbyStops.length,
              itemBuilder: (context, index) {
                final stop = _nearbyStops[index];
                final distance = Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  stop.latitude,
                  stop.longitude,
                );

                return _StopCard(
                  stop: stop,
                  distance: distance,
                  onTap: () {
                    // Navigate to routes page with this stop pre-selected
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoutesPage()),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final Stop stop;
  final double distance;
  final VoidCallback onTap;

  const _StopCard({
    Key? key,
    required this.stop,
    required this.distance,
    required this.onTap,
  }) : super(key: key);

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      stop.isMajor
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stop.isMajor ? Icons.location_city : Icons.place,
                  color:
                      stop.isMajor
                          ? AppTheme.primaryColor
                          : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.stopName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (stop.address?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        stop.address!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDistance(distance),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (stop.isMajor) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'Major',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
