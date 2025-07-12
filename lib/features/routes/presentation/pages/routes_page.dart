import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../providers/route_provider.dart';
import '../widgets/route_card.dart';
import 'route_detail_page.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> with AutomaticKeepAliveClientMixin {
  bool _isInitialized = false;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadRoutes();
  });
      _isInitialized = true;
    }
  }
  
  Future<void> _loadRoutes() async {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    await routeProvider.getAllRoutes();
  }
  
  Future<void> _refreshRoutes() async {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    await routeProvider.getAllRoutes();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to route search
            },
          ),
        ],
      ),
      body: Consumer<RouteProvider>(
        builder: (context, routeProvider, child) {
          if (routeProvider.isLoading) {
            return const Center(
              child: LoadingIndicator(),
            );
          }
          
          if (routeProvider.error != null) {
            return GenericErrorView(
              message: routeProvider.error,
              onRetry: _refreshRoutes,
            );
          }
          
          final routes = routeProvider.routes;
          
          if (routes == null || routes.isEmpty) {
            return EmptyState(
              title: 'No Routes Found',
              message: 'There are no available routes at the moment.',
              lottieAsset: 'assets/animations/empty_routes.json',
              buttonText: 'Refresh',
              onButtonPressed: _refreshRoutes,
            );
          }
          
          return RefreshIndicator(
            onRefresh: _refreshRoutes,
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return RouteCard(
                  route: route,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RouteDetailPage(routeId: route.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}