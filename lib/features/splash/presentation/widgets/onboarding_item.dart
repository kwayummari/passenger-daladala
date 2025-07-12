import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingItem extends StatefulWidget {
  final String image;
  final String title;
  final String subtitle;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final bool isActive;

  const OnboardingItem({
    Key? key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    this.isActive = false,
  }) : super(key: key);

  @override
  State<OnboardingItem> createState() => _OnboardingItemState();
}

class _OnboardingItemState extends State<OnboardingItem>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    if (widget.isActive) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(OnboardingItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Image Section with Enhanced Animation
          Expanded(
            flex: 3,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        widget.primaryColor.withOpacity(0.02),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        // Background Pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: PatternPainter(
                              color: widget.primaryColor.withOpacity(0.03),
                            ),
                          ),
                        ),

                        // Main Content
                        Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Animated Icon
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      widget.primaryColor,
                                      widget.secondaryColor,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.primaryColor.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Feature Highlights
                              if (widget.image.isNotEmpty)
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      image: DecorationImage(
                                        image: AssetImage(widget.image),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                _buildFeatureCards(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 50),

          // Text Content with Fade Animation
          Expanded(
            flex: 2,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Animated Subtitle Badge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.primaryColor.withOpacity(0.1),
                            widget.secondaryColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: widget.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Main Title with Gradient
                    ShaderMask(
                      shaderCallback:
                          (bounds) => LinearGradient(
                            colors: [
                              widget.primaryColor,
                              widget.secondaryColor,
                            ],
                          ).createShader(bounds),
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Enhanced Description
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 17,
                          color: AppTheme.textSecondaryColor,
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    final features = _getFeatures();

    return Column(
      children: [
        Row(
          children:
              features
                  .take(2)
                  .map((feature) => Expanded(child: _buildFeatureCard(feature)))
                  .toList(),
        ),
        const SizedBox(height: 16),
        if (features.length > 2)
          Row(
            children:
                features
                    .skip(2)
                    .take(2)
                    .map(
                      (feature) => Expanded(child: _buildFeatureCard(feature)),
                    )
                    .toList(),
          ),
      ],
    );
  }

  Widget _buildFeatureCard(FeatureData feature) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(feature.icon, color: widget.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            feature.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<FeatureData> _getFeatures() {
    switch (widget.title) {
      case 'Find Your Route':
        return [
          FeatureData(Icons.map, 'Live Map'),
          FeatureData(Icons.schedule, 'Real-time'),
          FeatureData(Icons.near_me, 'Nearby'),
          FeatureData(Icons.route, 'Routes'),
        ];
      case 'Book Your Seats':
        return [
          FeatureData(Icons.event_seat, 'Reserve'),
          FeatureData(Icons.confirmation_number, 'Tickets'),
          FeatureData(Icons.groups, 'Group'),
          FeatureData(Icons.schedule, 'Schedule'),
        ];
      case 'Track Your Journey':
        return [
          FeatureData(Icons.gps_fixed, 'GPS'),
          FeatureData(Icons.notifications, 'Alerts'),
          FeatureData(Icons.speed, 'Live'),
          FeatureData(Icons.timer, 'ETA'),
        ];
      case 'Pay With Ease':
        return [
          FeatureData(Icons.phone_android, 'Mobile'),
          FeatureData(Icons.credit_card, 'Cards'),
          FeatureData(Icons.account_balance_wallet, 'Wallet'),
          FeatureData(Icons.money, 'Cash'),
        ];
      default:
        return [];
    }
  }
}

class FeatureData {
  final IconData icon;
  final String title;

  FeatureData(this.icon, this.title);
}

class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    // Draw diagonal lines pattern
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
