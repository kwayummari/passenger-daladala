import 'package:daladala_smart_app/features/bookings/presentation/pages/bookings_page.dart';
import 'package:daladala_smart_app/features/profile/presentation/pages/profile_page.dart';
import 'package:daladala_smart_app/features/routes/presentation/pages/routes_page.dart';
import 'package:daladala_smart_app/features/trips/presentation/pages/trips_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_nearby_stops.dart';
import '../widgets/home_upcoming_trips.dart';
import '../widgets/home_quick_actions.dart';

class HomePage extends StatefulWidget {
  // Add a global key to access the state from other widgets
  static final GlobalKey<_HomePageState> homeKey = GlobalKey<_HomePageState>();

  // Updated constructor to use the global key
  HomePage({Key? key}) : super(key: homeKey);

  // Static method to navigate to routes page
  static void navigateToRoutes() {
    homeKey.currentState?.navigateToTab(1);
  }

  // Static method to navigate to any tab
  static void navigateToTab(int index) {
    homeKey.currentState?.navigateToTab(index);
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  GoogleMapController? _mapController;

  final List<Widget> _pages = [
    const _HomeContent(),
    const RoutesPage(),
    const TripsPage(),
    const BookingsPage(),
    const ProfilePage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Make this method public to allow access from static methods
  void navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _onItemTapped(int index) {
    navigateToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_outlined),
            activeIcon: Icon(Icons.directions_bus),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  GoogleMapController? _mapController;
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(-6.8025, 39.2599), // Dar es Salaam city center
    zoom: 14.0,
  );

  Set<Marker> _markers = {};

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Add some sample markers for bus stops
    setState(() {
      _markers = {
        const Marker(
          markerId: MarkerId('stop1'),
          position: LatLng(-6.7889, 39.2083),
          infoWindow: InfoWindow(title: 'Mwenge Bus Terminal'),
        ),
        const Marker(
          markerId: MarkerId('stop2'),
          position: LatLng(-6.8123, 39.2875),
          infoWindow: InfoWindow(title: 'Posta CBD'),
        ),
        const Marker(
          markerId: MarkerId('stop3'),
          position: LatLng(-6.7801, 39.2082),
          infoWindow: InfoWindow(title: 'Ubungo Bus Terminal'),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Map view
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                markers: _markers,
              ),
            ),

            // Bottom sheet with content
            DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
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
                  child: SingleChildScrollView(
                    controller: scrollController,
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

                        // Greeting
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Good morning,',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Jongea kwa Malengo',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Navigate to notifications
                                },
                                icon: const Icon(Icons.notifications_outlined),
                              ),
                            ],
                          ),
                        ),

                        // Search bar
                        const HomeSearchBar(),

                        // Quick actions
                        const HomeQuickActions(),

                        // Nearby stops
                        const HomeNearbyStops(),

                        // Upcoming trips
                        const HomeUpcomingTrips(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
