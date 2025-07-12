import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import 'login_page.dart';
import 'dart:math' as math;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _mainController;
  late AnimationController _floatingController;
  late AnimationController _backgroundController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _backgroundAnimation;

  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      icon: Icons.explore,
      title: 'Discover Routes',
      subtitle: 'Find Your Way',
      description:
          'Explore all daladala routes with real-time updates and smart recommendations tailored for you',
      primaryColor: const Color(0xFF00967B),
      secondaryColor: const Color(0xFF4CAF50),
      accentColor: const Color(0xFF81C784),
      features: ['Real-time tracking', 'Smart routes', 'Nearby stops'],
    ),
    OnboardingStep(
      icon: Icons.airline_seat_recline_normal,
      title: 'Book Smart',
      subtitle: 'Reserve & Relax',
      description:
          'Skip the queues and guarantee your seat with our intelligent booking system',
      primaryColor: const Color(0xFF00967B),
      secondaryColor: const Color(0xFF4CAF50),
      accentColor: const Color(0xFF81C784),
      features: ['Instant booking', 'Seat selection', 'Group bookings'],
    ),
    OnboardingStep(
      icon: Icons.track_changes,
      title: 'Live Tracking',
      subtitle: 'Stay Updated',
      description:
          'Track your journey in real-time with precise GPS location and arrival predictions',
      primaryColor: const Color(0xFF00967B),
      secondaryColor: const Color(0xFF4CAF50),
      accentColor: const Color(0xFF81C784),
      features: ['GPS tracking', 'Live updates', 'ETA predictions'],
    ),
    OnboardingStep(
      icon: Icons.account_balance_wallet,
      title: 'Easy Payments',
      subtitle: 'Pay Your Way',
      description:
          'Multiple payment options including mobile money, cards, and digital wallets',
      primaryColor: const Color(0xFF00967B),
      secondaryColor: const Color(0xFF4CAF50),
      accentColor: const Color(0xFF81C784),
      features: ['Mobile money', 'Secure payments', 'Digital receipts'],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut),
    );

    _startAnimations();
    _floatingController.repeat(reverse: true);
  }

  void _startAnimations() {
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _mainController.forward();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatingController.dispose();
    _backgroundController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.mediumImpact();
    _mainController.reset();
    _backgroundController.reset();
    _startAnimations();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const LoginPage(),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentStep = _steps[_currentPage];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              currentStep.primaryColor.withOpacity(0.05),
              currentStep.secondaryColor.withOpacity(0.03),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _steps.length,
                  itemBuilder:
                      (context, index) => _buildPage(_steps[index], size),
                ),
              ),
              _buildFooter(currentStep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _backgroundAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      const Text(
                        'Daladala Smart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton(
              onPressed: _completeOnboarding,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingStep step, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Visual Section
          Expanded(
            flex: 3,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circles
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _floatingAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale:
                              0.8 +
                              (_floatingAnimation.value * 0.1) +
                              (index * 0.1),
                          child: Container(
                            width: 200 + (index * 40),
                            height: 200 + (index * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: step.primaryColor.withOpacity(
                                0.05 - (index * 0.015),
                              ),
                              border: Border.all(
                                color: step.primaryColor.withOpacity(0.1),
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // Main icon container
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value * 0.1,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  step.primaryColor,
                                  step.secondaryColor,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: step.primaryColor.withOpacity(0.4),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              step.icon,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Floating feature bubbles
                  ...List.generate(step.features.length, (index) {
                    final angles = [0.0, 2.1, 4.2]; // 120 degrees apart
                    final radius = 120.0;
                    final angle = angles[index % angles.length];

                    return AnimatedBuilder(
                      animation: _floatingAnimation,
                      builder: (context, child) {
                        final floatOffset = _floatingAnimation.value * 10;
                        return Transform.translate(
                          offset: Offset(
                            radius * math.cos(angle) +
                                (floatOffset * (index % 2 == 0 ? 1 : -1)),
                            radius * math.sin(angle) + floatOffset,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: step.primaryColor.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              step.features[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: step.primaryColor,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          // Text Section
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _mainController.value)),
                  child: Opacity(
                    opacity: _mainController.value,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Subtitle badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  step.primaryColor.withOpacity(0.1),
                                  step.accentColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: step.primaryColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              step.subtitle,
                              style: TextStyle(
                                color: step.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Main title
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Description
                          Text(
                            step.description,
                            style: TextStyle(
                              fontSize: 17,
                              color: AppTheme.textSecondaryColor,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(OnboardingStep currentStep) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Animated page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (index) {
              bool isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 40 : 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient:
                      isActive
                          ? LinearGradient(
                            colors: [
                              currentStep.primaryColor,
                              currentStep.secondaryColor,
                            ],
                          )
                          : null,
                  color: isActive ? null : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow:
                      isActive
                          ? [
                            BoxShadow(
                              color: currentStep.primaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
              );
            }),
          ),

          const SizedBox(height: 40),

          // Action button
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: currentStep.primaryColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == _steps.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _currentPage == _steps.length - 1
                          ? Icons.rocket_launch
                          : Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final List<String> features;

  OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.features,
  });
}
