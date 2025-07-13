// // lib/core/services/seat_service.dart - NEW SERVICE
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class SeatService {
//   // Get available seats for a trip
//   static Future<Map<String, dynamic>?> getAvailableSeats({
//     required int tripId,
//     int? pickupStopId,
//     int? dropoffStopId,
//   }) async {
//     try {
//       final token = await TokenService.getToken();
//       if (token == null) return null;

//       String url = '${ApiConstants.baseUrl}/seats/trips/$tripId/available';

//       List<String> queryParams = [];
//       if (pickupStopId != null) {
//         queryParams.add('pickup_stop_id=$pickupStopId');
//       }
//       if (dropoffStopId != null) {
//         queryParams.add('dropoff_stop_id=$dropoffStopId');
//       }

//       if (queryParams.isNotEmpty) {
//         url += '?${queryParams.join('&')}';
//       }

//       final response = await http.get(
//         Uri.parse(url),
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['status'] == 'success') {
//         return data['data'];
//       } else {
//         throw Exception(data['message'] ?? 'Failed to get available seats');
//       }
//     } catch (e) {
//       print('Error getting available seats: $e');
//       return null;
//     }
//   }

//   // Reserve specific seats
//   static Future<bool> reserveSeats({
//     required int bookingId,
//     required List<String> seatNumbers,
//   }) async {
//     try {
//       final token = await TokenService.getToken();
//       if (token == null) return false;

//       final response = await http.post(
//         Uri.parse('${ApiConstants.baseUrl}/seats/reserve'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'booking_id': bookingId,
//           'seat_numbers': seatNumbers,
//         }),
//       );

//       final data = jsonDecode(response.body);
//       return response.statusCode == 200 && data['status'] == 'success';
//     } catch (e) {
//       print('Error reserving seats: $e');
//       return false;
//     }
//   }

//   // Auto-assign seats
//   static Future<bool> autoAssignSeats(int bookingId) async {
//     try {
//       final token = await TokenService.getToken();
//       if (token == null) return false;

//       final response = await http.post(
//         Uri.parse('${ApiConstants.baseUrl}/seats/auto-assign'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({'booking_id': bookingId}),
//       );

//       final data = jsonDecode(response.body);
//       return response.statusCode == 200 && data['status'] == 'success';
//     } catch (e) {
//       print('Error auto-assigning seats: $e');
//       return false;
//     }
//   }

//   // Get trip seat statistics
//   static Future<Map<String, dynamic>?> getTripSeatStats(int tripId) async {
//     try {
//       final token = await TokenService.getToken();
//       if (token == null) return null;

//       final response = await http.get(
//         Uri.parse('${ApiConstants.baseUrl}/seats/trips/$tripId/stats'),
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['status'] == 'success') {
//         return data['data'];
//       } else {
//         throw Exception(data['message'] ?? 'Failed to get seat statistics');
//       }
//     } catch (e) {
//       print('Error getting seat stats: $e');
//       return null;
//     }
//   }
// }
