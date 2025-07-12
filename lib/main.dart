import 'package:daladala_smart_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:daladala_smart_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/bookings/presentation/providers/booking_provider.dart';
import 'features/trips/presentation/providers/trip_provider.dart';
import 'features/routes/presentation/providers/route_provider.dart';
import 'features/payments/presentation/providers/payment_provider.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize service locator (dependency injection)
  await setupServiceLocator();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => getIt<AuthProvider>(),
        ),
        ChangeNotifierProvider(create: (_) => getIt<BookingProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<TripProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<RouteProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<PaymentProvider>()),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => getIt<ProfileProvider>(),
        ),
        // ADD THIS LINE:
        ChangeNotifierProvider<WalletProvider>(
          create: (_) => getIt<WalletProvider>(),
        ),
      ],
      child: MaterialApp(
        title: 'Daladala Smart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // We could add darkTheme and themeMode support later if needed
        home: const SplashScreen(),
        // We'll add route configuration here later
      ),
    );
  }
}