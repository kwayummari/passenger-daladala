import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/utils/extensions.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import '../../../bookings/presentation/providers/booking_provider.dart';

class BookingConfirmationPage extends StatefulWidget {
  // Single trip booking
  final int? tripId;
  final String routeName;
  final String from;
  final String to;
  final DateTime? startTime;
  final double fare;
  final String? vehiclePlate;
  final int pickupStopId;
  final int dropoffStopId;

  // Multiple trip booking support
  final List<Map<String, dynamic>>?
  selectedTrips; // New field for multiple trips
  final String? dateRange; // 'single', 'week', 'month', '3months'
  final DateTime? endDate;
  final int? totalDays;

  const BookingConfirmationPage({
    Key? key,
    this.tripId,
    required this.routeName,
    required this.from,
    required this.to,
    this.startTime,
    required this.fare,
    this.vehiclePlate,
    required this.pickupStopId,
    required this.dropoffStopId,
    // Multiple trip parameters
    this.selectedTrips,
    this.dateRange,
    this.endDate,
    this.totalDays,
  }) : super(key: key);

  @override
  State<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Payment method selection
  String _selectedPaymentMethod = 'mobile_money';
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPaymentSection = false;
  double _walletBalance = 0.0;

  int _totalPassengers = 0;
  double _totalFare = 0.0;

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG: BookingConfirmationPage initState');
    print('🔍 DEBUG: tripId: ${widget.tripId}');
    print('🔍 DEBUG: selectedTrips: ${widget.selectedTrips}');
    print('🔍 DEBUG: dateRange: ${widget.dateRange}');
    print('🔍 DEBUG: totalDays: ${widget.totalDays}');
    print('🔍 DEBUG: pickupStopId: ${widget.pickupStopId}');
    print('🔍 DEBUG: dropoffStopId: ${widget.dropoffStopId}');

    if (widget.selectedTrips != null) {
      for (int i = 0; i < widget.selectedTrips!.length; i++) {
        print('🔍 DEBUG: selectedTrips[$i]: ${widget.selectedTrips![i]}');
      }
    }

    _initializeAnimations();
    _initializeBookingData();

    // Add delay to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletBalance();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  void _initializeBookingData() {
    if (widget.selectedTrips != null && widget.selectedTrips!.isNotEmpty) {
      // Multiple trips booking
      _calculateMultipleTripTotals();
    } else {
      // Single trip booking
      _totalPassengers = 1;
      _totalFare = widget.fare;
    }
  }

  void _calculateMultipleTripTotals() {
    int totalPassengers = 0;
    double baseTotalFare = 0.0;

    // Calculate base fare for all selected trips and passengers
    for (final tripData in widget.selectedTrips!) {
      final passengerCount = tripData['passengerCount'] ?? 0;
      final tripFare = tripData['fare'] ?? widget.fare;

      totalPassengers += passengerCount as int;
      baseTotalFare += (tripFare * passengerCount) as double;
    }

    // Apply multipliers for date range bookings
    double finalTotalFare = baseTotalFare;

    if (widget.dateRange != null && widget.dateRange != 'single') {
      // Calculate multiplier based on date range
      double multiplier = 1.0;
      int days = widget.totalDays ?? 1;

      switch (widget.dateRange) {
        case 'week':
          multiplier = days * 0.95; // 7 days with 5% discount
          break;
        case 'month':
          multiplier = days * 0.85; // 30 days with 15% discount
          break;
        case '3months':
          multiplier = days * 0.75; // 90 days with 25% discount
          break;
        default:
          multiplier = days.toDouble();
      }

      finalTotalFare = baseTotalFare * multiplier;

      print('🔍 DEBUG: Multi-day calculation:');
      print('   Base fare: $baseTotalFare');
      print('   Days: $days');
      print('   Date range: ${widget.dateRange}');
      print('   Multiplier: $multiplier');
      print('   Final fare: $finalTotalFare');
    }

    _totalPassengers = totalPassengers;
    _totalFare = finalTotalFare;
  }

  Future<void> _loadWalletBalance() async {
    try {
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );

      print('🔍 DEBUG: Loading wallet balance...');
      await walletProvider.getWalletBalance();

      if (mounted) {
        setState(() {
          _walletBalance = walletProvider.balance;
          // Auto-select wallet if sufficient balance
          if (_walletBalance >= _totalFare) {
            _selectedPaymentMethod = 'wallet';
          }
        });
        print('✅ DEBUG: Wallet balance loaded: $_walletBalance TZS');
      }
    } catch (e) {
      print('⚠️ DEBUG: Failed to load wallet balance: $e');
      // Don't fail the entire page if wallet fails
      if (mounted) {
        setState(() {
          _walletBalance = 0.0;
          _selectedPaymentMethod = 'mobile_money';
        });
      }
    }
  }

  Future<void> _confirmBooking() async {
    print('🔍 DEBUG: _confirmBooking called');
    print('🔍 DEBUG: _showPaymentSection: $_showPaymentSection');
    print('🔍 DEBUG: _selectedPaymentMethod: $_selectedPaymentMethod');

    if (!_showPaymentSection) {
      setState(() {
        _showPaymentSection = true;
      });
      return;
    }

    // Only validate form if payment section is shown AND we need validation
    if (_selectedPaymentMethod == 'mobile_money') {
      if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
        return;
      }
    }

    // Additional validation for payment method
    if (_selectedPaymentMethod == 'wallet' && _walletBalance < _totalFare) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient wallet balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.selectedTrips != null && widget.selectedTrips!.isNotEmpty) {
        await _createMultipleBookings();
      } else {
        await _createSingleBooking();
      }
    } catch (e) {
      print('❌ DEBUG: Error in _confirmBooking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createSingleBooking() async {
    try {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      print('🔍 DEBUG: Creating single booking...');

      // Convert single booking to the multiple booking format for consistency
      final bookingData = {
        'trip_id': widget.tripId!,
        'pickup_stop_id': widget.pickupStopId,
        'dropoff_stop_id': widget.dropoffStopId,
        'passenger_count': _totalPassengers,
        'seat_numbers': [], // Add seat selection if needed
        'passenger_names': [], // Add passenger names if needed
        'travel_date': DateTime.now().toIso8601String().split('T')[0],
      };

      // Use the multiple bookings method for consistency with all required parameters
      final success = await bookingProvider.createMultipleBookings(
        bookingsData: [bookingData],
        dateRange: 'single',
        totalDays: 1,
        isMultiDay: false,
      );

      if (success &&
          bookingProvider.multipleBookings != null &&
          bookingProvider.multipleBookings!.isNotEmpty) {
        final bookingId = bookingProvider.multipleBookings!.first.id;
        await _processPayment(bookingId);
      } else {
        throw Exception(bookingProvider.error ?? 'Failed to create booking');
      }
    } catch (e) {
      print('❌ DEBUG: Error in _createSingleBooking: $e');
      rethrow;
    }
  }

  Future<void> _createMultipleBookings() async {
    try {
      print('🔍 DEBUG: _createMultipleBookings started');
      print('🔍 DEBUG: widget.selectedTrips: ${widget.selectedTrips}');
      print(
        '🔍 DEBUG: widget.selectedTrips length: ${widget.selectedTrips?.length}',
      );
      print('🔍 DEBUG: widget.dateRange: ${widget.dateRange}');
      print('🔍 DEBUG: widget.totalDays: ${widget.totalDays}');

      // Add null checks for selectedTrips
      if (widget.selectedTrips == null) {
        throw Exception('Selected trips is null');
      }

      if (widget.selectedTrips!.isEmpty) {
        throw Exception('No trips selected');
      }

      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      if (bookingProvider == null) {
        throw Exception('Booking provider is null');
      }

      print('🔍 DEBUG: Processing ${widget.selectedTrips!.length} trips...');

      // Convert selectedTrips to the correct format with detailed null checks
      final bookingsData = <Map<String, dynamic>>[];

      for (int i = 0; i < widget.selectedTrips!.length; i++) {
        final tripData = widget.selectedTrips![i];
        print('🔍 DEBUG: Processing trip $i: $tripData');

        // Check for required fields
        final tripId = tripData['trip_id'];
        final passengerCount = tripData['passenger_count'];
        final travelDate = tripData['travel_date'];

        print(
          '🔍 DEBUG: Trip $i - tripId: $tripId, passengerCount: $passengerCount, travelDate: $travelDate',
        );

        if (tripId == null) {
          throw Exception('Trip ID is null for trip $i');
        }

        if (passengerCount == null) {
          throw Exception('Passenger count is null for trip $i');
        }

        if (travelDate == null) {
          throw Exception('Travel date is null for trip $i');
        }

        final bookingData = {
          'trip_id': tripId,
          'pickup_stop_id': widget.pickupStopId,
          'dropoff_stop_id': widget.dropoffStopId,
          'passenger_count': passengerCount,
          'seat_numbers': tripData['seat_numbers'] ?? [],
          'passenger_names': tripData['passenger_names'] ?? [],
          'travel_date': travelDate,
        };

        bookingsData.add(bookingData);
        print('🔍 DEBUG: Added booking data for trip $i: $bookingData');
      }

      print('🔍 DEBUG: Final bookingsData: $bookingsData');
      print('🔍 DEBUG: Calling createMultipleBookings with parameters:');
      print('   - bookingsData: ${bookingsData.length} items');
      print('   - dateRange: ${widget.dateRange}');
      print('   - totalDays: ${widget.totalDays}');
      print('   - isMultiDay: ${widget.dateRange != 'single'}');

      final success = await bookingProvider.createMultipleBookings(
        bookingsData: bookingsData,
        dateRange: widget.dateRange ?? 'single',
        totalDays: widget.totalDays ?? 1,
        isMultiDay: widget.dateRange != 'single',
      );

      print('🔍 DEBUG: createMultipleBookings result: $success');
      print(
        '🔍 DEBUG: bookingProvider.multipleBookings: ${bookingProvider.multipleBookings}',
      );
      print('🔍 DEBUG: bookingProvider.error: ${bookingProvider.error}');

      if (success && bookingProvider.multipleBookings != null) {
        // Process payment for the total amount
        final bookingIds =
            bookingProvider.multipleBookings!.map((b) => b.id).toList();
        print('🔍 DEBUG: Processing payment for booking IDs: $bookingIds');
        await _processMultiplePayments(bookingIds);
      } else {
        final errorMessage =
            bookingProvider.error ?? 'Failed to create multiple bookings';
        print('❌ DEBUG: Booking creation failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error in _createMultipleBookings: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _processPayment(int bookingId) async {
    try {
      print('🔍 DEBUG: Processing payment for booking $bookingId');
      print('🔍 DEBUG: Payment method: $_selectedPaymentMethod');
      print('🔍 DEBUG: Amount: $_totalFare');

      // Add null checks
      if (_selectedPaymentMethod.isEmpty) {
        throw Exception('Please select a payment method');
      }

      if (_totalFare <= 0) {
        throw Exception('Invalid fare amount');
      }

      if (_selectedPaymentMethod == 'wallet') {
        await _processWalletPayment(bookingId);
      } else if (_selectedPaymentMethod == 'mobile_money') {
        await _processMobileMoneyPayment(bookingId);
      } else {
        throw Exception('Please select a payment method');
      }
    } catch (e) {
      print('❌ DEBUG: Payment processing failed: $e');
      rethrow;
    }
  }

  Future<void> _processWalletPayment(int bookingId) async {
    try {
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );

      if (walletProvider == null) {
        throw Exception('Wallet service not available');
      }

      print('💳 DEBUG: Processing wallet payment...');
      final success = await walletProvider.processWalletPayment(
        bookingId: bookingId,
        amount: _totalFare,
      );

      if (success) {
        print('✅ DEBUG: Wallet payment successful');
        if (mounted) {
          _showSuccessDialog('Payment completed successfully!');
        }
      } else {
        throw Exception(walletProvider.error ?? 'Wallet payment failed');
      }
    } catch (e) {
      print('❌ DEBUG: Wallet payment error: $e');
      throw Exception('Wallet payment failed: ${e.toString()}');
    }
  }

  Future<void> _processMobileMoneyPayment(int bookingId) async {
    try {
      if (_phoneController.text.trim().isEmpty) {
        throw Exception('Please enter your phone number');
      }

      print('📱 DEBUG: Processing mobile money payment...');

      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );

      if (paymentProvider == null) {
        throw Exception('Payment service not available');
      }

      // FIX: Convert double to String and use correct method
      final success = await paymentProvider.processMobileMoneyPayment(
        bookingId: bookingId,
        phoneNumber: _phoneController.text.trim(),
        amount: _totalFare, // This method expects double
      );

      if (success) {
        print('✅ DEBUG: Mobile money payment initiated');
        if (mounted) {
          _showSuccessDialog(
            'Payment initiated! Please complete on your phone.',
          );
        }
      } else {
        throw Exception(paymentProvider.error ?? 'Mobile money payment failed');
      }
    } catch (e) {
      print('❌ DEBUG: Mobile money payment error: $e');
      throw Exception('Mobile money payment failed: ${e.toString()}');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: Text('Success!'),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to previous page
                  Navigator.of(context).pop(); // Go back to main page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  Future<void> _processMultiplePayments(List<int> bookingIds) async {
    try {
      print('🔍 DEBUG: Processing payment for ${bookingIds.length} bookings');

      if (bookingIds.isEmpty) {
        throw Exception('No booking IDs provided for payment processing');
      }

      print('🔍 DEBUG: Booking IDs: $bookingIds');
      print('🔍 DEBUG: Total amount: $_totalFare');

      // Using Option 1 - single payment for all bookings
      if (_selectedPaymentMethod == 'wallet') {
        await _processWalletPaymentForMultiple(bookingIds);
      } else if (_selectedPaymentMethod == 'mobile_money') {
        await _processMobileMoneyPaymentForMultiple(bookingIds);
      } else {
        throw Exception('Please select a payment method');
      }
    } catch (e) {
      print('❌ DEBUG: Multiple payments processing failed: $e');
      rethrow;
    }
  }

  Future<void> _processWalletPaymentForMultiple(List<int> bookingIds) async {
    try {
      if (bookingIds.isEmpty) {
        throw Exception('No bookings to process payment for');
      }

      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );

      print('💳 DEBUG: Processing wallet payment for multiple bookings...');

      // Process payment for the first booking with total amount
      final success = await walletProvider.processWalletPayment(
        bookingId: bookingIds.first,
        amount: _totalFare,
      );

      if (success) {
        print('✅ DEBUG: Multiple wallet payments successful');
        if (mounted) {
          _showSuccessDialog(
            'Payment completed successfully for all bookings!',
          );
        }
      } else {
        throw Exception(walletProvider.error ?? 'Wallet payment failed');
      }
    } catch (e) {
      print('❌ DEBUG: Multiple wallet payments error: $e');
      throw Exception('Wallet payment failed: ${e.toString()}');
    }
  }

  Future<void> _processMobileMoneyPaymentForMultiple(
    List<int> bookingIds,
  ) async {
    try {
      if (_phoneController.text.isEmpty) {
        throw Exception('Please enter your phone number');
      }

      print(
        '📱 DEBUG: Processing mobile money payment for multiple bookings...',
      );

      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );

      // Process payment for the first booking with total amount
      final success = await paymentProvider.processMobileMoneyPayment(
        bookingId: bookingIds.first,
        phoneNumber: _phoneController.text.trim(),
        amount: _totalFare,
      );

      if (success) {
        print('✅ DEBUG: Multiple mobile money payments initiated');
        if (mounted) {
          _showSuccessDialog(
            'Payment initiated for all bookings! Please complete on your phone.',
          );
        }
      } else {
        throw Exception(paymentProvider.error ?? 'Mobile money payment failed');
      }
    } catch (e) {
      print('❌ DEBUG: Multiple mobile money payments error: $e');
      throw Exception('Mobile money payment failed: ${e.toString()}');
    }
  }

  void _navigateToSuccess([int? bookingId]) {
    // Navigate back to home or bookings page
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.selectedTrips != null && widget.selectedTrips!.isNotEmpty
                    ? 'Successfully booked ${widget.selectedTrips!.length} trips!'
                    : 'Booking confirmed successfully!',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Booking Confirmation'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildGradientHeader(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBookingDetailsCard(),
                    const SizedBox(height: 16),
                    if (_showPaymentSection) _buildPaymentSection(),
                    if (_showPaymentSection) const SizedBox(height: 16),
                    _buildTotalCard(),
                    const SizedBox(height: 24),
                    _buildActionButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(_slideAnimation),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Icon(
                  widget.selectedTrips != null
                      ? Icons.event_repeat
                      : Icons.directions_bus_rounded,
                  size: 64,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.routeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.from} → ${widget.to}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.selectedTrips != null &&
                    widget.dateRange != 'single')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${widget.selectedTrips!.length} trips • ${widget.totalDays} days',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.selectedTrips != null) ...[
              // Multiple trips details
              ...widget.selectedTrips!
                  .map((trip) => _buildTripDetail(trip))
                  .toList(),
            ] else ...[
              // Single trip details
              _buildDetailRow(
                'Date',
                DateFormat('EEEE, d MMMM yyyy').format(widget.startTime!),
              ),
              _buildDetailRow(
                'Departure',
                DateFormat('HH:mm').format(widget.startTime!),
              ),
              _buildDetailRow('Vehicle', widget.vehiclePlate ?? 'TBD'),
              _buildDetailRow('Fare per person', widget.fare.toPrice),
            ],

            const Divider(height: 24),
            _buildDetailRow('Total Passengers', '$_totalPassengers'),
            if (widget.dateRange != 'single' && widget.totalDays != null)
              _buildDetailRow('Booking Period', '${widget.totalDays} days'),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetail(Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip #${trip['tripId']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Passengers: ${trip['passengerCount']}'),
          if (trip['selectedSeats'] != null && trip['selectedSeats'].isNotEmpty)
            Text('Seats: ${trip['selectedSeats'].join(', ')}'),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        // Wallet Option
        if (_walletBalance > 0) ...[
          _buildPaymentOption(
            'wallet',
            'Wallet Payment',
            'Balance: ${_walletBalance.toStringAsFixed(0)} TZS',
            Icons.wallet,
            _walletBalance >= _totalFare,
            _walletBalance < _totalFare ? 'Insufficient balance' : null,
          ),
          SizedBox(height: 12),
        ],

        // Mobile Money Option
        _buildPaymentOption(
          'mobile_money',
          'Mobile Money',
          'Pay via Tigo Pesa, M-Pesa, Airtel Money',
          Icons.phone_android,
          true,
          null,
        ),

        // Phone number input for mobile money
        if (_selectedPaymentMethod == 'mobile_money') ...[
          SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '0744123456',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (!RegExp(r'^0[67]\d{8}$').hasMatch(value)) {
                return 'Please enter a valid Tanzanian phone number';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTotalCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                Text(
                  widget.selectedTrips != null
                      ? '${widget.selectedTrips!.length} trips • $_totalPassengers passenger${_totalPassengers > 1 ? 's' : ''}'
                      : '$_totalPassengers passenger${_totalPassengers > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                if (widget.dateRange != 'single' && widget.totalDays != null)
                  Text(
                    'for ${widget.totalDays} days',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            Text(
              _totalFare.toPrice,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: double.infinity,
        child: CustomButton(
          text:
              _isLoading
                  ? 'Processing...'
                  : _showPaymentSection
                  ? 'Confirm & Pay'
                  : 'Continue to Payment',
          onPressed: _isLoading ? null : _confirmBooking,
          isLoading: _isLoading,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    bool enabled,
    String? disabledMessage,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap:
          enabled ? () => setState(() => _selectedPaymentMethod = value) : null,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color:
              enabled
                  ? (isSelected
                      ? AppTheme.primaryColor.withOpacity(0.05)
                      : Colors.white)
                  : Colors.grey[100],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  enabled
                      ? (isSelected ? AppTheme.primaryColor : Colors.grey[600])
                      : Colors.grey[400],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                  Text(
                    disabledMessage ?? subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          disabledMessage != null
                              ? Colors.red
                              : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
