import 'package:daladala_smart_app/features/bookings/presentation/pages/bookings_page.dart';
import 'package:daladala_smart_app/features/home/presentation/widgets/home_nearby_stops.dart';
import 'package:daladala_smart_app/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:daladala_smart_app/features/home/presentation/widgets/home_search_bar.dart';
import 'package:daladala_smart_app/features/home/presentation/widgets/home_upcoming_trips.dart';
import 'package:daladala_smart_app/features/profile/presentation/pages/profile_page.dart';
import 'package:daladala_smart_app/features/routes/presentation/pages/routes_page.dart';
import 'package:daladala_smart_app/features/trips/presentation/pages/trips_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../routes/presentation/providers/route_provider.dart';

class HomePage extends StatefulWidget {
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  GoogleMapController? _mapController;
  late AnimationController _refreshAnimationController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize data loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final tripProvider = context.read<TripProvider>();
    final routeProvider = context.read<RouteProvider>();

    // Load initial data
    await Future.wait([
      tripProvider.getUpcomingTrips(),
      routeProvider.getAllRoutes(),
    ]);
  }

  Future<void> _refreshData() async {
    _refreshAnimationController.repeat();

    try {
      await _initializeData();
    } finally {
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();
    }
  }

  void navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // ✅ ADD: Trigger trips refresh when trips tab is selected
    if (index == 2) {
      // Trips tab index
      print('🎯 HomePage: Trips tab selected, refreshing trips');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tripProvider = context.read<TripProvider>();
        tripProvider.getUpcomingTrips();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 2) {
            // Trips tab
            print('🎯 HomePage: PageView switched to trips tab');
            Future.delayed(Duration(milliseconds: 300), () {
              if (mounted) {
                final tripProvider = context.read<TripProvider>();
                tripProvider.getUpcomingTrips();
              }
            });
          }
        },
        children: [
          // Home Tab
          _buildHomeTab(),
          // Routes Tab
          const RoutesPage(),
          // Trips Tab
          const TripsPage(),
          // Bookings Tab
          const BookingsPage(),
          // Profile Tab
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: navigateToTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Routes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshData,
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Text(
                    user?.firstName != null
                        ? '${user!.firstName} ${user.lastName}'.trim()
                        : 'Traveler',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              Consumer<TripProvider>(
                builder: (context, tripProvider, child) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/notifications');
                        },
                        icon: const Icon(Icons.notifications_outlined),
                        color: Colors.black87,
                      ),
                      if (tripProvider.hasActiveTrips)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Search Bar
                const HomeSearchBar(),

                // Quick Actions
                const HomeQuickActions(),

                // Upcoming Trips
                const HomeUpcomingTrips(),

                // Nearby Stops
                const HomeNearbyStops(),

                // Bottom spacing
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
