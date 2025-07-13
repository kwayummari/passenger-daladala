// Enhanced BookingConfirmationPage to support multiple trips
import 'package:daladala_smart_app/features/home/presentation/pages/home_page.dart';
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

  // Enhanced passenger and seat management
  Map<String, int> _passengerCounts =
      {}; // For multiple trips: 'tripId_date' -> count
  Map<String, List<String>> _selectedSeats =
      {}; // For multiple trips: 'tripId_date' -> seats
  int _totalPassengers = 0;
  double _totalFare = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeBookingData();
    _loadWalletBalance();
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
    double totalFare = 0.0;

    for (final tripData in widget.selectedTrips!) {
      final passengerCount = tripData['passengerCount'] ?? 0;
      final tripFare = tripData['fare'] ?? widget.fare;

      totalPassengers += passengerCount as int;
      totalFare += (tripFare * passengerCount) as double;
    }

    // If date range booking, multiply by number of days
    if (widget.dateRange != 'single' && widget.totalDays != null) {
      totalFare *= widget.totalDays!;
      // Note: passenger count stays the same as it's per trip
    }

    _totalPassengers = totalPassengers;
    _totalFare = totalFare;
  }

  Future<void> _loadWalletBalance() async {
    try {
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );
      await walletProvider.getWalletBalance();
      if (mounted) {
        setState(() {
          _walletBalance = walletProvider.balance;
        });
      }
    } catch (e) {
      // Handle wallet loading error
    }
  }

  Future<void> _confirmBooking() async {
    if (!_showPaymentSection) {
      setState(() {
        _showPaymentSection = true;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
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
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    final success = await bookingProvider.createBooking(
      tripId: widget.tripId!,
      pickupStopId: widget.pickupStopId,
      dropoffStopId: widget.dropoffStopId,
      passengerCount: _totalPassengers, // Remove selectedSeats parameter
    );

    if (success && bookingProvider.currentBooking != null) {
      final bookingId = bookingProvider.currentBooking!.id;
      await _processPayment(bookingId);
    } else {
      throw Exception(bookingProvider.error ?? 'Failed to create booking');
    }
  }

  Future<void> _createMultipleBookings() async {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    List<int> bookingIds = [];

    // Create bookings for each trip
    for (final tripData in widget.selectedTrips!) {
      final success = await bookingProvider.createBooking(
        tripId: tripData['tripId'],
        pickupStopId: widget.pickupStopId,
        dropoffStopId: widget.dropoffStopId,
        passengerCount:
            tripData['passengerCount'], // Remove selectedSeats parameter
      );

      if (success && bookingProvider.currentBooking != null) {
        bookingIds.add(bookingProvider.currentBooking!.id);
      } else {
        throw Exception(
          'Failed to create booking for trip ${tripData['tripId']}',
        );
      }
    }

    // Process payment for all bookings
    if (bookingIds.isNotEmpty) {
      await _processMultiplePayments(bookingIds);
    }
  }

  Future<void> _processPayment(int bookingId) async {
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );

    bool success = false;
    if (_selectedPaymentMethod == 'wallet') {
      success = await paymentProvider.processWalletPayment(
        bookingId,
        amount: _totalFare,
      );
    } else if (_selectedPaymentMethod == 'mobile_money') {
      success = await paymentProvider.processMobileMoneyPayment(
        bookingId: bookingId,
        phoneNumber: _phoneController.text.trim(),
        amount: _totalFare,
      );
    }

    if (success) {
      _navigateToSuccess(bookingId);
    } else {
      throw Exception(paymentProvider.error ?? 'Payment processing failed');
    }
  }

  Future<void> _processMultiplePayments(List<int> bookingIds) async {
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );

    // Process payment for the first booking (since your payment system might not support bulk payments)
    // You can enhance this later to support bulk payments in your backend

    bool success = false;
    if (_selectedPaymentMethod == 'wallet') {
      success = await paymentProvider.processWalletPayment(
        bookingIds.first, // Use first booking ID as reference
        amount: _totalFare,
        // Remove relatedBookingIds parameter since it doesn't exist
      );
    } else if (_selectedPaymentMethod == 'mobile_money') {
      success = await paymentProvider.processMobileMoneyPayment(
        bookingId: bookingIds.first,
        phoneNumber: _phoneController.text.trim(),
        amount: _totalFare,
        // Remove relatedBookingIds parameter since it doesn't exist
      );
    }

    if (success) {
      // If you need to handle multiple bookings, you could loop through them
      // or implement a bulk payment system in your backend
      for (int i = 1; i < bookingIds.length; i++) {
        // For now, mark other bookings as paid or handle them separately
        // You might want to implement a different approach here
      }

      _navigateToSuccess(bookingIds.first);
    } else {
      throw Exception(paymentProvider.error ?? 'Payment processing failed');
    }
  }

  void _navigateToSuccess(int bookingId) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomePage.navigateToTab(3); // Bookings tab

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 30),
                  SizedBox(width: 10),
                  Text('Booking Confirmed!'),
                ],
              ),
              content: Text(
                widget.selectedTrips != null
                    ? 'Your ${widget.selectedTrips!.length} bookings have been confirmed!'
                    : 'Your booking #$bookingId has been confirmed!',
                style: TextStyle(fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    });
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
                Icon(Icons.payment, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment options
            _buildPaymentOption(
              'mobile_money',
              'Mobile Money',
              Icons.smartphone,
              'Pay with M-Pesa, Tigo Pesa, Airtel Money',
              true,
            ),

            if (_walletBalance > 0)
              _buildPaymentOption(
                'wallet',
                'Wallet',
                Icons.account_balance_wallet,
                'Balance: ${_walletBalance.toPrice}',
                _walletBalance >= _totalFare,
              ),

            // Phone number input
            if (_selectedPaymentMethod == 'mobile_money')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '0744963858',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!RegExp(r'^(0|255)7\d{8}$').hasMatch(value.trim())) {
                      return 'Enter valid Tanzanian number (07xxxxxxxx)';
                    }
                    return null;
                  },
                ),
              ),
          ],
        ),
      ),
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
    IconData icon,
    String subtitle,
    bool enabled,
  ) {
    return GestureDetector(
      onTap:
          enabled
              ? () {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              }
              : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          border: Border.all(
            color:
                _selectedPaymentMethod == value && enabled
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
            width: _selectedPaymentMethod == value && enabled ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  enabled
                      ? (_selectedPaymentMethod == value
                          ? AppTheme.primaryColor
                          : Colors.grey.shade600)
                      : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color:
                          enabled
                              ? AppTheme.textPrimaryColor
                              : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          enabled
                              ? AppTheme.textSecondaryColor
                              : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged:
                  enabled
                      ? (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      }
                      : null,
              activeColor: AppTheme.primaryColor,
            ),
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
