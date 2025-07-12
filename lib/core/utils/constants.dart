import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();
  
  // App info
  static const String appName = 'Daladala Smart';
  static const String appVersion = '1.0.0';
  
  // API endpoints
  static const String apiBaseUrl = '/api';
  static const String authEndpoint = '/auth';
  static const String userEndpoint = '/users';
  static const String routesEndpoint = '/routes';
  static const String stopsEndpoint = '/stops';
  static const String tripsEndpoint = '/trips';
  static const String bookingsEndpoint = '/bookings';
  static const String paymentsEndpoint = '/payments';
  static const String reviewsEndpoint = '/reviews';
  
  // SharedPreferences keys
  static const String keyAuthUser = 'auth_user';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyIsFirstRun = 'is_first_run';
  static const String keyLastSyncTime = 'last_sync_time';

  // MediaQuery Data
  static double getWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double getHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
  
  // Default values
  static const int itemsPerPage = 10;
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const double defaultMapZoom = 14.0;
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
}

class RouteConstants {
  RouteConstants._();
  
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String routes = '/routes';
  static const String routeDetail = '/route-detail';
  static const String trips = '/trips';
  static const String tripDetail = '/trip-detail';
  static const String booking = '/booking';
  static const String bookingDetail = '/booking-detail';
  static const String payment = '/payment';
  static const String paymentHistory = '/payment-history';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String about = '/about';
}

class BookingStatusConstants {
  BookingStatusConstants._();
  
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class PaymentStatusConstants {
  PaymentStatusConstants._();
  
  static const String pending = 'pending';
  static const String paid = 'paid';
  static const String failed = 'failed';
  static const String refunded = 'refunded';
}

class PaymentMethodConstants {
  PaymentMethodConstants._();
  
  static const String cash = 'cash';
  static const String mobileMoney = 'mobile_money';
  static const String card = 'card';
  static const String wallet = 'wallet';
}

class TripStatusConstants {
  TripStatusConstants._();
  
  static const String scheduled = 'scheduled';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}