// lib/features/trips/presentation/widgets/booking_summary_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domains/entities/trip.dart';
import '../../../bookings/presentation/pages/booking_confirmation_page.dart';

class BookingSummarySheet extends StatelessWidget {
  final List<Trip> trips;
  final Map<String, int> passengerCounts;
  final Map<String, List<String>> selectedSeats;
  final Map<String, List<String>> passengerNames;
  final double farePerTrip;
  final double totalFare;
  final String routeName;
  final String from;
  final String to;
  final int pickupStopId;
  final int dropoffStopId;
  final String dateRange;
  final DateTime startDate;
  final DateTime? endDate;

  const BookingSummarySheet({
    Key? key,
    required this.trips,
    required this.passengerCounts,
    required this.selectedSeats,
    required this.passengerNames,
    required this.farePerTrip,
    required this.totalFare,
    required this.routeName,
    required this.from,
    required this.to,
    required this.pickupStopId,
    required this.dropoffStopId,
    required this.dateRange,
    required this.startDate,
    this.endDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildSummaryContent(context)),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.receipt_long, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$routeName ($from → $to)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(),
          SizedBox(height: 16),
          _buildTripsList(),
          SizedBox(height: 16),
          _buildTotalCard(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final totalTrips = passengerCounts.length;
    final totalPassengers = passengerCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final totalSeats = selectedSeats.values.fold(
      0,
      (sum, seats) => sum + seats.length,
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.calendar_today,
                  label: 'Period',
                  value: _getDateRangeText(),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.directions_bus,
                  label: 'Trips',
                  value: '$totalTrips',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.people,
                  label: 'Passengers',
                  value: '$totalPassengers',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildOverviewItem(
                  icon: Icons.airline_seat_recline_normal,
                  label: 'Seats',
                  value: totalSeats > 0 ? '$totalSeats' : 'Auto-assign',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTripsList() {
    // Group trips by date for better organization
    final groupedTrips = <String, List<MapEntry<String, int>>>{};

    passengerCounts.forEach((tripKey, passengerCount) {
      final parts = tripKey.split('_');
      if (parts.length >= 2) {
        final dateStr = parts[1];
        if (!groupedTrips.containsKey(dateStr)) {
          groupedTrips[dateStr] = [];
        }
        groupedTrips[dateStr]!.add(MapEntry(tripKey, passengerCount));
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12),
        ...groupedTrips.entries.map((dateGroup) {
          final date = DateTime.parse(dateGroup.key);
          final dayTrips = dateGroup.value;

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(date),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${dayTrips.length} trip${dayTrips.length != 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ...dayTrips.map(
                  (tripEntry) => _buildTripItem(tripEntry.key, tripEntry.value),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTripItem(String tripKey, int passengerCount) {
    final parts = tripKey.split('_');
    final tripId = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final trip = trips.firstWhere(
      (t) => t.id == tripId,
      orElse: () => trips.first,
    );

    final seats = selectedSeats[tripKey] ?? [];
    final names = passengerNames[tripKey] ?? [];
    final tripFare = farePerTrip * passengerCount;

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  DateFormat('HH:mm').format(trip.startTime),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  trip.vehiclePlate ?? 'Vehicle ${trip.id}',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                'TZS ${tripFare.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                '$passengerCount passenger${passengerCount != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              if (seats.isNotEmpty) ...[
                SizedBox(width: 16),
                Icon(
                  Icons.airline_seat_recline_normal,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  seats.join(', '),
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
          if (names.isNotEmpty) ...[
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children:
                  names
                      .map(
                        (name) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    final totalTrips = passengerCounts.length;
    final totalPassengers = passengerCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.receipt, color: Colors.white),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalTrips trips × $totalPassengers passengers',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                'TZS ${totalFare.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Edit Selection'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _proceedToBooking(context),
                child: Text('Proceed to Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToBooking(BuildContext context) {
    // Build selected trips data
    final selectedTripsData = <Map<String, dynamic>>[];

    passengerCounts.forEach((tripKey, passengerCount) {
      final parts = tripKey.split('_');
      if (parts.length >= 2) {
        final tripId = int.tryParse(parts[0]);
        final dateStr = parts[1];

        if (tripId != null) {
          final trip = trips.firstWhere(
            (t) => t.id == tripId,
            orElse: () => trips.first,
          );

          final seatNumbers = selectedSeats[tripKey] ?? [];
          final names = passengerNames[tripKey] ?? [];

          selectedTripsData.add({
            'trip_id': tripId,
            'pickup_stop_id': pickupStopId,
            'dropoff_stop_id': dropoffStopId,
            'passenger_count': passengerCount,
            'seat_numbers': seatNumbers,
            'passenger_names': names,
            'travel_date': dateStr,
            // Additional data for UI
            'tripId': tripId,
            'passengerCount': passengerCount,
            'selectedSeats': seatNumbers,
            'fare': farePerTrip,
            'startTime': trip.startTime,
            'vehiclePlate': trip.vehiclePlate ?? 'Unknown',
          });
        }
      }
    });

    // Navigate to BookingConfirmationPage
    Navigator.pop(context); // Close summary sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingConfirmationPage(
              // Single trip data (for backward compatibility)
              tripId:
                  selectedTripsData.isNotEmpty
                      ? selectedTripsData.first['tripId']
                      : null,
              routeName: routeName,
              from: from,
              to: to,
              startTime:
                  selectedTripsData.isNotEmpty
                      ? selectedTripsData.first['startTime']
                      : DateTime.now(),
              fare: farePerTrip,
              vehiclePlate:
                  selectedTripsData.isNotEmpty
                      ? selectedTripsData.first['vehiclePlate']
                      : 'Unknown',
              pickupStopId: pickupStopId,
              dropoffStopId: dropoffStopId,

              // Multiple trip data (enhanced features)
              selectedTrips:
                  selectedTripsData.isNotEmpty ? selectedTripsData : null,
              dateRange: dateRange,
              endDate: endDate,
              totalDays: _calculateTotalDays(),
            ),
      ),
    );
  }

  String _getDateRangeText() {
    switch (dateRange) {
      case 'single':
        return DateFormat('MMM d').format(startDate);
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case '3months':
        return '3 Months';
      default:
        if (endDate != null) {
          return '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate!)}';
        }
        return DateFormat('MMM d').format(startDate);
    }
  }

  int _calculateTotalDays() {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }
}
