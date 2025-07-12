import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class UpcomingDepartureItem extends StatelessWidget {
  final int tripId;
  final String routeName;
  final DateTime departureTime;
  final String destination;
  final String vehicleType;
  final int availableSeats;
  final VoidCallback onBookTrip;

  const UpcomingDepartureItem({
    Key? key,
    required this.tripId,
    required this.routeName,
    required this.departureTime,
    required this.destination,
    required this.vehicleType,
    required this.availableSeats,
    required this.onBookTrip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = departureTime.difference(now);
    
    String timeUntilDeparture;
    if (difference.inMinutes <= 0) {
      timeUntilDeparture = 'Departing now';
    } else if (difference.inMinutes < 60) {
      timeUntilDeparture = 'In ${difference.inMinutes} min';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      timeUntilDeparture = 'In $hours h${minutes > 0 ? ' $minutes min' : ''}';
    }
    
    final formattedTime = DateFormat('HH:mm').format(departureTime);
    
    Color timeColor;
    if (difference.inMinutes < 5) {
      timeColor = AppTheme.errorColor;
    } else if (difference.inMinutes < 15) {
      timeColor = AppTheme.warningColor;
    } else {
      timeColor = AppTheme.primaryColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Time and route info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: timeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: timeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: timeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        timeUntilDeparture,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: timeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Route info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'To $destination',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Vehicle info and book button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Vehicle and seats info
                Row(
                  children: [
                    Icon(
                      vehicleType == 'daladala'
                          ? Icons.directions_bus_outlined
                          : Icons.directions_bus_filled,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vehicleType.substring(0, 1).toUpperCase() + vehicleType.substring(1),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.event_seat,
                      size: 16,
                      color: availableSeats > 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$availableSeats ${availableSeats == 1 ? 'seat' : 'seats'} available',
                      style: TextStyle(
                        fontSize: 14,
                        color: availableSeats > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Book button
                ElevatedButton(
                  onPressed: availableSeats > 0 ? onBookTrip : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Book'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}