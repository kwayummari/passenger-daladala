import 'dart:convert';
import 'dart:io';
import 'package:daladala_smart_app/core/utils/constants.dart';
import 'package:daladala_smart_app/services/CustomHttpClient.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final client = CustomHttpClient.createUnsafeClient();
  static final String baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';

  Future<String?> _getAuthToken() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    return await storage.read(key: 'auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'x-access-token': token,
    };
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await client.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final token = await _getAuthToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/upload-avatar'),
      );

      if (token != null) {
        request.headers['x-access-token'] = token; // Use correct header
      }

      String mimeType = 'image/jpeg'; // Default
      String extension = imageFile.path.split('.').last.toLowerCase();

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          imageFile.path,
          contentType: MediaType.parse(mimeType), // ADD THIS
        ),
      );

      final response = await client.send(request);

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        return data['data']['profile_picture'];
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  // Wallet Methods
  Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/wallet/balance'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load wallet balance');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getWalletTransactions({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      };

      final uri = Uri.parse(
        '$baseUrl/wallet/transactions',
      ).replace(queryParameters: queryParams);

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load wallet transactions');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> topUpWallet({
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final headers = await _getHeaders();
      final data = {
        'amount': amount,
        'payment_method': paymentMethod,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };

      final response = await client.post(
        Uri.parse('$baseUrl/wallet/topup'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to top up wallet');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> processWalletPayment({
    required int bookingId,
  }) async {
    try {
      final headers = await _getHeaders();
      final data = {'booking_id': bookingId};

      final response = await client.post(
        Uri.parse('$baseUrl/wallet/pay'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to process wallet payment');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Booking Methods
  Future<Map<String, dynamic>> getBookings({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final uri = Uri.parse(
        '$baseUrl/bookings',
      ).replace(queryParameters: queryParams);

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getBookingDetails(int bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load booking details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
  }) async {
    try {
      final headers = await _getHeaders();
      final data = {
        'trip_id': tripId,
        'pickup_stop_id': pickupStopId,
        'dropoff_stop_id': dropoffStopId,
        'passenger_count': passengerCount,
      };

      final response = await client.post(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create booking');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getAvailableTrips({
    String? from,
    String? to,
    DateTime? date,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (date != null) 'date': date.toIso8601String().split('T')[0],
      };

      final uri = Uri.parse(
        '$baseUrl/trips/upcoming',
      ).replace(queryParameters: queryParams);
      print('Fetching available trips from: $uri');

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load available trips');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get trip details by ID
  Future<Map<String, dynamic>> getTripDetails(int tripId) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/trips/$tripId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load trip details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get user bookings
  static Future<List<Map<String, dynamic>>> getUserBookings({
    required String authToken,
    String? status,
  }) async {
    try {
      String url =
          '$baseUrl${AppConstants.apiBaseUrl}${AppConstants.bookingsEndpoint}/';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching user bookings: $e');
      return [];
    }
  }

  // Get all routes
  static Future<List<Map<String, dynamic>>> getAllRoutes() async {
    try {
      final response = await client.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiBaseUrl}${AppConstants.routesEndpoint}/',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching routes: $e');
      return [];
    }
  }

  // Get route by ID
  static Future<Map<String, dynamic>?> getRouteById(int routeId) async {
    try {
      final response = await client.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiBaseUrl}${AppConstants.routesEndpoint}/$routeId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching route: $e');
      return null;
    }
  }

  // Search stops
  static Future<List<Map<String, dynamic>>> searchStops(String query) async {
    try {
      final response = await client.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiBaseUrl}${AppConstants.stopsEndpoint}/search?q=$query',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error searching stops: $e');
      return [];
    }
  }

  // Get all stops
  static Future<List<Map<String, dynamic>>> getAllStops() async {
    try {
      final response = await client.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiBaseUrl}${AppConstants.stopsEndpoint}/',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching stops: $e');
      return [];
    }
  }

  // Get route stops
  static Future<List<Map<String, dynamic>>> getRouteStops(int routeId) async {
    try {
      final response = await client.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiBaseUrl}${AppConstants.routesEndpoint}/$routeId/stops',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching route stops: $e');
      return [];
    }
  }

  // Get fare between stops
  static Future<Map<String, dynamic>?> getFareBetweenStops({
    required int routeId,
    required int startStopId,
    required int endStopId,
    String fareType = 'standard',
  }) async {
    try {
      final response = await client.get(
        Uri.parse(
          '$baseUrl${AppConstants.routesEndpoint}/fare?route_id=$routeId&start_stop_id=$startStopId&end_stop_id=$endStopId&fare_type=$fareType',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("==========$data============");
        if (data['status'] == 'success') {
          return data['data'];
        }
      }

      print("==========${response.statusCode}============");
      return null;
    } catch (e) {
      print('Error fetching fare: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await client.put(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to cancel booking');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Payment Methods
  Future<Map<String, dynamic>> processPayment({
    required int bookingId,
    required String paymentMethod,
    String? phoneNumber,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final headers = await _getHeaders();
      final data = {
        'booking_id': bookingId,
        'payment_method': paymentMethod,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (paymentDetails != null) 'payment_details': paymentDetails,
      };

      final response = await client.post(
        Uri.parse('$baseUrl/payments/process'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to process payment');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(int paymentId) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/payments/$paymentId/status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get payment status');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Trips Methods
  Future<Map<String, dynamic>> getTrips({
    String? from,
    String? to,
    DateTime? date,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (date != null) 'date': date.toIso8601String().split('T')[0],
      };

      final uri = Uri.parse(
        '$baseUrl/trips',
      ).replace(queryParameters: queryParams);

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load trips');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Notifications Methods
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (isRead != null) 'is_read': isRead.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/notifications',
      ).replace(queryParameters: queryParams);

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(
    int notificationId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await client.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await client.put(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Dashboard/Stats Methods
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ZenoPay Integration Methods
  Future<Map<String, dynamic>> checkZenoPayStatus(String orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/payments/zenopay/status/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check ZenoPay status');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> searchRoutes({
    required String startPoint,
    required String endPoint,
  }) async {
    try {
      final response = await client.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiBaseUrl}${AppConstants.routesEndpoint}/search?start_point=$startPoint&end_point=$endPoint',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching trips: $e');
      return [];
    }
  }

  // Auth related methods (if needed)
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await client.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update stored tokens
        await prefs.setString('auth_token', data['data']['access_token']);
        if (data['data']['refresh_token'] != null) {
          await prefs.setString('refresh_token', data['data']['refresh_token']);
        }

        return data;
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      throw Exception('Token refresh error: $e');
    }
  }

  // Utility method to logout (clear tokens)
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
