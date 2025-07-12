import 'package:daladala_smart_app/features/routes/data/models/stop_model.dart';
import 'package:daladala_smart_app/features/routes/domain/entities/stop.dart';
import 'package:daladala_smart_app/features/routes/presentation/widgets/modern_stop_selection_sheet.dart';
import 'package:daladala_smart_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_input.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/utils/constants.dart';
import '../widgets/route_selection_result.dart';
import '../../../trips/presentation/pages/trip_selection_page.dart';

class SearchRoutePage extends StatefulWidget {
  // Add optional parameters for preselected values
  final String? preselectedFrom;
  final String? preselectedTo;
  final int? pickupStopId;
  final int? dropoffStopId;
  final int? routeId;

  const SearchRoutePage({
    Key? key,
    this.preselectedFrom,
    this.preselectedTo,
    this.pickupStopId,
    this.dropoffStopId,
    this.routeId,
  }) : super(key: key);

  @override
  State<SearchRoutePage> createState() => _SearchRoutePageState();
}

class _SearchRoutePageState extends State<SearchRoutePage> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  bool _isSearching = false;
  bool _showResults = false;
  List<Map<String, dynamic>> _searchResults = [];

   @override
  void initState() {
    super.initState();

    // Pre-fill the text fields if values are provided
    if (widget.preselectedFrom != null) {
      _fromController.text = widget.preselectedFrom!;
    }
    if (widget.preselectedTo != null) {
      _toController.text = widget.preselectedTo!;
    }

    // Automatically search if both fields are pre-filled
    if (widget.preselectedFrom != null && widget.preselectedTo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchRoutes();
      });
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _searchRoutes() async {
    FocusScope.of(context).unfocus();

    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both pickup and destination locations'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = false;
    });

    try {
      // Use the existing ApiService method
      final results = await ApiService.searchRoutes(
        startPoint: _fromController.text,
        endPoint: _toController.text,
      );

      setState(() {
        _searchResults = results;
        _showResults = true;
      });
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _navigateToTripSelection(Map<String, dynamic> route) {
    // Show stop selection dialog before navigation
    _showStopSelectionDialog(route);
  }

  Future<List<Map<String, dynamic>>> _fetchRouteStops(int routeId) async {
    try {
      // Debug: Print the full URL being called
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.routesEndpoint}/$routeId/stops';
      print('🔍 Fetching route stops from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      // Debug: Print response details
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response headers: ${response.headers}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Parsed data: $data');

        if (data['status'] == 'success') {
          final stops = List<Map<String, dynamic>>.from(data['data']);
          print('✅ Successfully parsed ${stops.length} stops');
          return stops;
        } else {
          print('❌ API returned error status: ${data['status']}');
          print('❌ Error message: ${data['message']}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
      }
      return [];
    } catch (e) {
      print('💥 Exception in _fetchRouteStops: $e');
      print('💥 Exception type: ${e.runtimeType}');
      return [];
    }
  }

  // Also update the _showStopSelectionDialog method to handle empty stops better
  void _showStopSelectionDialog(Map<String, dynamic> route) async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch stops for the route
    final routeStopsData = await _fetchRouteStops(route['route_id']);

    // Close loading dialog
    Navigator.pop(context);

    if (routeStopsData.isEmpty) {
      _showError('No stops found for this route. Please try another route.');
      return;
    }

    // Convert API response to Stop entities using your existing StopModel
    final stops =
        routeStopsData.map((stopData) {
          try {
            return StopModel.fromJson(stopData) as Stop;
          } catch (e) {
            // Fallback manual conversion if needed
            return StopModel(
                  id: stopData['stop_id'] ?? 0,
                  stopName: stopData['stop_name'] ?? 'Unknown Stop',
                  latitude: (stopData['latitude'] ?? 0.0).toDouble(),
                  longitude: (stopData['longitude'] ?? 0.0).toDouble(),
                  address: stopData['address'],
                  isMajor: stopData['is_major'] ?? false,
                  status: stopData['status'] ?? 'active',
                )
                as Stop;
          }
        }).toList();

    StopSelectionHelper.showModernStopSelection(
      context: context,
      stops: stops,
      routeName: route['route_name'] ?? 'Unknown Route',
      onStopsSelected: (pickupStopId, dropoffStopId) {
        // Navigate to trip selection
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => TripSelectionPage(
                  routeId: route['route_id'],
                  pickupStopId: pickupStopId,
                  dropoffStopId: dropoffStopId,
                  routeName: route['route_name'] ?? '',
                  from: stops.firstWhere((s) => s.id == pickupStopId).stopName,
                  to: stops.firstWhere((s) => s.id == dropoffStopId).stopName,
                ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Routes'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Form
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CustomInput(
                        controller: _fromController,
                        label: 'From',
                        hint: 'Enter pickup location',
                        prefix: Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        controller: _toController,
                        label: 'To',
                        hint: 'Enter destination',
                        prefix: Icon(Icons.location_on),
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: 'Search Routes',
                        onPressed: _isSearching ? null : _searchRoutes,
                        isLoading: _isSearching,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Results Section
              Container(
                child:
                    _isSearching
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Searching for routes...'),
                            ],
                          ),
                        )
                        : _showResults
                        ? _searchResults.isNotEmpty
                            ? ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final route = _searchResults[index];

                                return RouteSelectionResult(
                                  id: route['route_id'] ?? 0,
                                  routeName:
                                      route['route_name'] ?? 'Unknown Route',
                                  startPoint: route['start_point'] ?? 'Unknown',
                                  endPoint: route['end_point'] ?? 'Unknown',
                                  stops:
                                      0, // You might want to fetch this separately or include in search results
                                  distanceKm:
                                      (route['distance'] ?? 0.0).toDouble(),
                                  estimatedTime:
                                      route['estimated_duration'] ?? 0,
                                  fare: (route['base_fare'] ?? 0.0).toDouble(),
                                  availableTrips:
                                      0, // You might want to fetch this separately
                                  onViewTrips:
                                      () => _navigateToTripSelection(route),
                                );
                              },
                            )
                            : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No routes found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try different locations',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/animations/search.json',
                                width: 200,
                                height: 200,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Find Your Route',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter your pickup and destination to find available daladala routes',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
