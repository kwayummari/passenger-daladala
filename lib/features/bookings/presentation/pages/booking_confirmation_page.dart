// lib/features/bookings/presentation/pages/booking_confirmation_page.dart
import 'package:daladala_smart_app/features/bookings/presentation/providers/booking_provider.dart';
import 'package:daladala_smart_app/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/utils/extensions.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../payments/presentation/providers/payment_provider.dart';

class BookingConfirmationPage extends StatefulWidget {
  final int tripId;
  final String routeName;
  final String from;
  final String to;
  final DateTime startTime;
  final double fare;
  final String vehiclePlate;
  final int pickupStopId;
  final int dropoffStopId;

  const BookingConfirmationPage({
    Key? key,
    required this.tripId,
    required this.routeName,
    required this.from,
    required this.to,
    required this.startTime,
    required this.fare,
    required this.vehiclePlate,
    required this.pickupStopId,
    required this.dropoffStopId,
  }) : super(key: key);

  @override
  State<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage>
    with TickerProviderStateMixin {
  int _passengerCount = 1;
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

  double get _totalFare => widget.fare * _passengerCount;

  @override
  void initState() {
    super.initState();
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
    _loadWalletBalance();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
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

  void _incrementPassengers() {
    setState(() {
      if (_passengerCount < 5) {
        _passengerCount++;
      }
    });
  }

  void _decrementPassengers() {
    setState(() {
      if (_passengerCount > 1) {
        _passengerCount--;
      }
    });
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
      final response = await _createBooking();

      if (response != null && response['status'] == 'success') {
        final bookingId = response['data']['booking_id'];

        await _processPayment(bookingId);
      } else {
        throw Exception('Failed to create booking');
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

  Future<Map<String, dynamic>?> _createBooking() async {
    try {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      final success = await bookingProvider.createBooking(
        tripId: widget.tripId, // Use widget.tripId
        pickupStopId: widget.pickupStopId, // Use widget.pickupStopId
        dropoffStopId: widget.dropoffStopId, // Use widget.dropoffStopId
        passengerCount: _passengerCount,
      );

      if (success && bookingProvider.currentBooking != null) {
        final booking = bookingProvider.currentBooking!;
        return {
          'status': 'success',
          'data': {
            'booking_id': booking.id,
            'fare_amount': booking.fareAmount,
            'passenger_count': booking.passengerCount,
            'trip_id': booking.tripId,
            'status': booking.status,
            'payment_status': booking.paymentStatus,
          },
        };
      } else {
        final errorMessage =
            bookingProvider.error ?? 'Failed to create booking';
        throw Exception(errorMessage);
      }
    } catch (e) {
      return null;
    }
  }

  // lib/features/bookings/presentation/pages/booking_confirmation_page.dart - CORRECTED VERSION

  Future<void> _processPayment(int bookingId) async {
    if (bookingId <= 0) {
      throw Exception('Invalid booking ID: $bookingId');
    }

    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );

    try {
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
        final payment = paymentProvider.currentPayment;

        if (payment != null) {
          _handlePaymentSuccess(bookingId, payment);
        } else {
          // Payment was successful but no payment object returned
          _navigateToSuccess(bookingId);
        }
      } else {
        throw Exception(paymentProvider.error ?? 'Payment processing failed');
      }
    } catch (e) {
      throw Exception('Payment failed: ${e.toString()}');
    }
  }

  void _handlePaymentSuccess(int bookingId, dynamic payment) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment successful! Booking #$bookingId confirmed.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    if (payment.isMobileMoneyPayment && payment.isPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment Ussd generated successful! Booking #$bookingId confirmed.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      _navigateToSuccess(bookingId);
    } else {
      _navigateToSuccess(bookingId);
    }
  }

  // Navigate to success page
  void _navigateToSuccess(int bookingId) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomePage.navigateToTab(3); // Bookings tab

      // Show success dialog
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
                'Your booking #$bookingId has been confirmed! '
                'You can view details in the Bookings tab.',
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
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(widget.startTime);
    final formattedTime = DateFormat('HH:mm').format(widget.startTime);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
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
              // Gradient header
              Container(
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
                            Icons.directions_bus_rounded,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Trip details card
                    FadeTransition(
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
                                  Icons.schedule,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Trip Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow('Date', formattedDate),
                            _buildDetailRow('Departure', formattedTime),
                            _buildDetailRow('Vehicle', widget.vehiclePlate),
                            _buildDetailRow(
                              'Fare per person',
                              widget.fare.toPrice,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    FadeTransition(
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
                                  Icons.people,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Passengers',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Number of passengers',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _decrementPassengers,
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        color:
                                            _passengerCount > 1
                                                ? AppTheme.primaryColor
                                                : Colors.grey,
                                      ),
                                      iconSize: 32,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$_passengerCount',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _incrementPassengers,
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        color:
                                            _passengerCount < 5
                                                ? AppTheme.primaryColor
                                                : Colors.grey,
                                      ),
                                      iconSize: 32,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment section
                    if (_showPaymentSection)
                      FadeTransition(
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
                                    Icons.payment,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
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

                              // Mobile Money Option
                              _buildPaymentOption(
                                'mobile_money',
                                'Mobile Money',
                                Icons.smartphone,
                                'Pay with M-Pesa, Tigo Pesa, Airtel Money',
                                true,
                              ),

                              // Wallet Option (only if user has balance)
                              if (_walletBalance > 0)
                                _buildPaymentOption(
                                  'wallet',
                                  'Wallet',
                                  Icons.account_balance_wallet,
                                  'Balance: ${_walletBalance.toPrice}',
                                  _walletBalance >= _totalFare,
                                ),

                              // Phone number input for mobile money
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
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppTheme.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Phone number is required';
                                      }
                                      if (!RegExp(
                                        r'^(0|255)7\d{8}$',
                                      ).hasMatch(value.trim())) {
                                        return 'Enter valid Tanzanian number (07xxxxxxxx)';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Total amount card
                    FadeTransition(
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
                                  '${_passengerCount} passenger${_passengerCount > 1 ? 's' : ''}',
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
                    ),

                    const SizedBox(height: 24),

                    // Action button
                    FadeTransition(
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
                    ),

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
}
