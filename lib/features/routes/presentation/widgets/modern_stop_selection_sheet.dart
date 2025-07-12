// lib/features/routes/presentation/widgets/modern_stop_selection_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/stop.dart';

class ModernStopSelectionSheet extends StatefulWidget {
  final List<Stop> stops;
  final String routeName;
  final Function(int pickupStopId, int dropoffStopId) onStopsSelected;
  final int? initialPickupStopId;
  final int? initialDropoffStopId;

  const ModernStopSelectionSheet({
    Key? key,
    required this.stops,
    required this.routeName,
    required this.onStopsSelected,
    this.initialPickupStopId,
    this.initialDropoffStopId,
  }) : super(key: key);

  @override
  State<ModernStopSelectionSheet> createState() =>
      _ModernStopSelectionSheetState();
}

class _ModernStopSelectionSheetState extends State<ModernStopSelectionSheet>
    with TickerProviderStateMixin {
  int? selectedPickupId;
  int? selectedDropoffId;
  late PageController _pageController;
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    selectedPickupId = widget.initialPickupStopId;
    selectedDropoffId = widget.initialDropoffStopId;
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _onStopSelected(int stopId, bool isPickup) {
    setState(() {
      if (isPickup) {
        selectedPickupId = stopId;
        // Clear dropoff if it's before pickup
        if (selectedDropoffId != null) {
          final pickupIndex = widget.stops.indexWhere((s) => s.id == stopId);
          final dropoffIndex = widget.stops.indexWhere(
            (s) => s.id == selectedDropoffId,
          );
          if (dropoffIndex <= pickupIndex) {
            selectedDropoffId = null;
          }
        }
      } else {
        selectedDropoffId = stopId;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _confirmSelection() {

    if (selectedPickupId != null && selectedDropoffId != null) {
      widget.onStopsSelected(selectedPickupId!, selectedDropoffId!);
      Navigator.pop(context);
      HapticFeedback.mediumImpact();
    } else {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Select Your Stops',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.routeName,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Pickup', Icons.my_location),
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color:
                          _currentStep >= 1 ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                _buildStepIndicator(1, 'Drop-off', Icons.location_on),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildStopSelectionPage(
                  title: 'Where do you want to board?',
                  subtitle: 'Select your pickup stop',
                  stops: widget.stops,
                  selectedStopId: selectedPickupId,
                  isPickup: true,
                  primaryColor: Colors.green,
                ),
                _buildStopSelectionPage(
                  title: 'Where do you want to get off?',
                  subtitle: 'Select your drop-off stop',
                  stops: widget.stops,
                  selectedStopId: selectedDropoffId,
                  isPickup: false,
                  primaryColor: Colors.red,
                ),
              ],
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: _currentStep > 0 ? 2 : 1,
                  child: ElevatedButton(
                    onPressed:
                        _currentStep == 0
                            ? (selectedPickupId != null ? _nextStep : null)
                            : (selectedPickupId != null &&
                                    selectedDropoffId != null
                                ? _confirmSelection
                                : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _currentStep == 0 ? Colors.green : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _currentStep == 0 ? 'Next' : 'Confirm Selection',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? Colors.green
                    : isActive
                    ? Colors.blue
                    : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isActive || isCompleted ? Colors.white : Colors.grey[600],
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.blue : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStopSelectionPage({
    required String title,
    required String subtitle,
    required List<Stop> stops,
    required int? selectedStopId,
    required bool isPickup,
    required Color primaryColor,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Stops list
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: stops.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final stop = stops[index];
                    final isSelected = selectedStopId == stop.id;
                    final isDisabled =
                        !isPickup &&
                        selectedPickupId != null &&
                        index <=
                            stops.indexWhere((s) => s.id == selectedPickupId);

                    return _buildStopCard(
                      stop: stop,
                      index: index,
                      isSelected: isSelected,
                      isDisabled: isDisabled,
                      primaryColor: primaryColor,
                      onTap:
                          isDisabled
                              ? null
                              : () => _onStopSelected(stop.id, isPickup),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopCard({
    required Stop stop,
    required int index,
    required bool isSelected,
    required bool isDisabled,
    required Color primaryColor,
    required VoidCallback? onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? primaryColor.withOpacity(0.1)
                    : isDisabled
                    ? Colors.grey[100]
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? primaryColor
                      : isDisabled
                      ? Colors.grey[300]!
                      : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Row(
            children: [
              // Stop number/icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? primaryColor
                          : isDisabled
                          ? Colors.grey
                          : stop.isMajor
                          ? Colors.orange
                          : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                          : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                ),
              ),

              const SizedBox(width: 16),

              // Stop info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stop.stopName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDisabled ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                        if (stop.isMajor) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Major',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (stop.address != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        stop.address!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDisabled ? Colors.grey : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Selection indicator
              const SizedBox(width: 12),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    isSelected
                        ? primaryColor
                        : isDisabled
                        ? Colors.grey[400]
                        : Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Usage example - how to show the modern stop selection sheet
class StopSelectionHelper {
  static void showModernStopSelection({
    required BuildContext context,
    required List<Stop> stops,
    required String routeName,
    required Function(int pickupStopId, int dropoffStopId) onStopsSelected,
    int? initialPickupStopId,
    int? initialDropoffStopId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ModernStopSelectionSheet(
            stops: stops,
            routeName: routeName,
            onStopsSelected: onStopsSelected,
            initialPickupStopId: initialPickupStopId,
            initialDropoffStopId: initialDropoffStopId,
          ),
    );
  }
}
