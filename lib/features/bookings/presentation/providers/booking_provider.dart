import 'package:flutter/foundation.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/get_user_bookings_usecase.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';
import '../../domain/usecases/create_multiple_bookings_usecase.dart';
import '../../domain/usecases/reserve_seats_usecase.dart';
import '../../domain/usecases/auto_assign_seats_usecase.dart';

class BookingProvider extends ChangeNotifier {
  final GetBookingDetailsUseCase getBookingDetailsUseCase;
  final GetUserBookingsUseCase getUserBookingsUseCase;
  final CreateBookingUseCase createBookingUseCase;
  final CancelBookingUseCase cancelBookingUseCase;

  // Add new use cases for enhanced functionality
  final CreateMultipleBookingsUseCase? createMultipleBookingsUseCase;
  final ReserveSeatsUseCase? reserveSeatsUseCase;
  final AutoAssignSeatsUseCase? autoAssignSeatsUseCase;

  BookingProvider({
    required this.getBookingDetailsUseCase,
    required this.getUserBookingsUseCase,
    required this.createBookingUseCase,
    required this.cancelBookingUseCase,
    // Optional new use cases (for backward compatibility)
    this.createMultipleBookingsUseCase,
    this.reserveSeatsUseCase,
    this.autoAssignSeatsUseCase,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<Booking>? _userBookings;
  List<Booking>? get userBookings => _userBookings;

  Booking? _currentBooking;
  Booking? get currentBooking => _currentBooking;

  // Enhanced state for multiple bookings
  List<Booking>? _multipleBookings;
  List<Booking>? get multipleBookings => _multipleBookings;

  double? _totalFare;
  double? get totalFare => _totalFare;

  Future<void> getUserBookings({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final params = GetUserBookingsParams(status: status);
    final result = await getUserBookingsUseCase(params);

    result.fold(
      (failure) {
        _error = failure.message;
        _userBookings = null;
      },
      (bookings) {
        _userBookings = bookings;
        _error = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> getBookingDetails(int bookingId) async {
    _isLoading = true;
    _error = null;
    _currentBooking = null;
    notifyListeners();

    final params = GetBookingDetailsParams(bookingId: bookingId);
    final result = await getBookingDetailsUseCase(params);

    result.fold(
      (failure) {
        _error = failure.message;
      },
      (booking) {
        _currentBooking = booking;
        _error = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBooking({
    required int tripId,
    required int pickupStopId,
    required int dropoffStopId,
    required int passengerCount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final params = CreateBookingParams(
      tripId: tripId,
      pickupStopId: pickupStopId,
      dropoffStopId: dropoffStopId,
      passengerCount: passengerCount,
    );

    final result = await createBookingUseCase(params);

    bool success = false;

    result.fold(
      (failure) {
        _error = failure.message;
      },
      (booking) {
        _currentBooking = booking;
        _error = null;
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();

    return success;
  }

  // NEW: Create multiple bookings method
  Future<bool> createMultipleBookings({
    required List<Map<String, dynamic>> bookingsData,
    String? dateRange,
    int? totalDays,
    bool? isMultiDay,
  }) async {
    try {
      // Check if the use case is available
      if (createMultipleBookingsUseCase == null) {
        print('❌ CreateMultipleBookingsUseCase is null');
        _error =
            'Multiple booking feature not available. Please update the app.';
        notifyListeners();
        return false;
      }

      if (bookingsData.isEmpty) {
        _error = 'No booking data provided';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      _multipleBookings = null;
      _totalFare = null;
      notifyListeners();

      final params = CreateMultipleBookingsParams(
        bookingsData: bookingsData,
        dateRange: dateRange,
        totalDays: totalDays,
        isMultiDay: isMultiDay,
      );

      print('🔍 Calling createMultipleBookingsUseCase with params');
      final result = await createMultipleBookingsUseCase!(params);

      bool success = false;

      result.fold(
        (failure) {
          print('❌ Booking creation failed: ${failure.message}');
          _error = failure.message;
        },
        (response) {
          print('✅ Booking creation successful');
          _multipleBookings = response.bookings;
          _totalFare = response.totalFare;
          _error = null;
          success = true;
        },
      );

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      print('❌ Exception in createMultipleBookings: $e');
      _error = 'Failed to create bookings: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // NEW: Reserve seats method
  Future<bool> reserveSeats({
    required int bookingId,
    required List<String> seatNumbers,
  }) async {
    if (reserveSeatsUseCase == null) {
      _error = 'Seat reservation feature not available';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final params = ReserveSeatsParams(
      bookingId: bookingId,
      seatNumbers: seatNumbers,
    );

    final result = await reserveSeatsUseCase!(params);

    bool success = false;

    result.fold(
      (failure) {
        _error = failure.message;
      },
      (_) {
        _error = null;
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();

    return success;
  }

  // NEW: Auto-assign seats method
  Future<bool> autoAssignSeats(int bookingId) async {
    if (autoAssignSeatsUseCase == null) {
      _error = 'Auto seat assignment feature not available';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final params = AutoAssignSeatsParams(bookingId: bookingId);
    final result = await autoAssignSeatsUseCase!(params);

    bool success = false;

    result.fold(
      (failure) {
        _error = failure.message;
      },
      (_) {
        _error = null;
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();

    return success;
  }

  Future<bool> cancelBooking(int bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final params = CancelBookingParams(bookingId: bookingId);
    final result = await cancelBookingUseCase(params);

    bool success = false;

    result.fold(
      (failure) {
        _error = failure.message;
      },
      (_) {
        // Update the current booking status if it's the one being cancelled
        if (_currentBooking != null && _currentBooking!.id == bookingId) {
          _currentBooking = _currentBooking!.copyWith(status: 'cancelled');
        }

        // Also update in the list if available
        if (_userBookings != null) {
          final index = _userBookings!.indexWhere((b) => b.id == bookingId);
          if (index != -1) {
            final updatedBookings = List<Booking>.from(_userBookings!);
            updatedBookings[index] = updatedBookings[index].copyWith(
              status: 'cancelled',
            );
            _userBookings = updatedBookings;
          }
        }

        _error = null;
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();

    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // NEW: Clear multiple booking state
  void clearMultipleBookingState() {
    _multipleBookings = null;
    _totalFare = null;
    notifyListeners();
  }

  // NEW: Helper method to check if multiple booking is supported
  bool get isMultipleBookingSupported => createMultipleBookingsUseCase != null;
  bool get isSeatReservationSupported => reserveSeatsUseCase != null;
  bool get isAutoSeatAssignSupported => autoAssignSeatsUseCase != null;
}
