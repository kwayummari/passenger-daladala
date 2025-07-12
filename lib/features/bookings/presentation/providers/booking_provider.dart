import 'package:flutter/foundation.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/get_user_bookings_usecase.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';

class BookingProvider extends ChangeNotifier {
  final GetBookingDetailsUseCase getBookingDetailsUseCase;
  final GetUserBookingsUseCase getUserBookingsUseCase;
  final CreateBookingUseCase createBookingUseCase;
  final CancelBookingUseCase cancelBookingUseCase;
  
  BookingProvider({
    required this.getBookingDetailsUseCase,
    required this.getUserBookingsUseCase,
    required this.createBookingUseCase,
    required this.cancelBookingUseCase,
  });
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  List<Booking>? _userBookings;
  List<Booking>? get userBookings => _userBookings;
  
  Booking? _currentBooking;
  Booking? get currentBooking => _currentBooking;
  
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
            updatedBookings[index] = updatedBookings[index].copyWith(status: 'cancelled');
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
}