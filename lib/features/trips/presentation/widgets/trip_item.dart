import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';

class TripItem extends StatelessWidget {
  final int id;
  final DateTime startTime;
  final String vehicleType;
  final String vehiclePlate;
  final String driverName;
  final double driverRating;
  final int availableSeats;
  final double fare;
  final List<String> features;
  final VoidCallback onSelectTrip;

  const TripItem({
    super.key,
    required this.id,
    required this.startTime,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.driverName,
    required this.driverRating,
    required this.availableSeats,
    required this.fare,
    required this.features,
    required this.onSelectTrip,
  });

  @override
  Widget build(BuildContext context) {
    // Format time
    final formattedTime = DateFormat('HH:mm').format(startTime);

    // Time until departure
    final now = DateTime.now();
    final difference = startTime.difference(now);
    final hoursRemaining = difference.inHours;
    final minutesRemaining = difference.inMinutes % 60;

    String timeUntilDeparture;
    if (hoursRemaining > 0) {
      timeUntilDeparture =
          '$hoursRemaining h ${minutesRemaining > 0 ? '$minutesRemaining min' : ''}';
    } else {
      timeUntilDeparture = '$minutesRemaining min';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Top part with time and fare
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Leaves in $timeUntilDeparture',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),

                // Fare
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fare.toPrice,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'per person',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Vehicle & driver info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Vehicle icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    vehicleType == 'daladala'
                        ? Icons.directions_bus
                        : Icons.directions_bus_filled,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Vehicle & driver details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehiclePlate,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: driverRating,
                                itemBuilder:
                                    (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                itemCount: 5,
                                itemSize: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                driverRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Seats available
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.event_seat,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$availableSeats seats',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'available',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Features and book button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Features
                if (features.isNotEmpty) ...[
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          features.map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // Book button
                ElevatedButton(
                  onPressed: onSelectTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Select'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
