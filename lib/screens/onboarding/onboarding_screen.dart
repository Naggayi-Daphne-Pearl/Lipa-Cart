import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnimationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      icon: Iconsax.shopping_bag,
      title: 'Shop Fresh Groceries',
      description:
          'Browse through a wide selection of fresh produce, meat, dairy, and pantry essentials from local markets.',
      color: AppColors.primaryGreen,
    ),
    OnboardingItem(
      icon: Iconsax.clipboard_text,
      title: 'Personalised Grocery Lists',
      description:
          'Create custom shopping lists with detailed descriptions, budget amounts, and special instructions for each item.',
      color: AppColors.beverages,
    ),
    OnboardingItem(
      icon: Iconsax.people,
      title: 'Personal Shoppers',
      description:
          'Our trusted personal shoppers handpick the best quality items for your order with care and attention.',
      color: AppColors.primaryOrange,
    ),
    OnboardingItem(
      icon: Iconsax.truck_fast,
      title: 'Fast Delivery',
      description:
          'Get your groceries delivered right to your doorstep by our reliable boda boda riders.',
      color: AppColors.info,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _iconRotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeOut),
    );

    _iconAnimationController.forward();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Restart icon animation on page change
    _iconAnimationController.reset();
    _iconAnimationController.forward();
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    context.read<AuthProvider>().setFirstLaunchComplete();
    context.replace('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFAFBFC), Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Premium Header Bar with Logo and Skip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey200, width: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    SvgPicture.asset(
                      'assets/images/logos/logo-on-white.svg',
                      height: 25,
                      fit: BoxFit.contain,
                    ),
                    // Skip button with icon
                    TextButton.icon(
                      onPressed: _completeOnboarding,
                      icon: const Icon(Iconsax.arrow_right_3, size: 14),
                      label: Text(
                        'Skip',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: AppSizes.xs,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_items[index]);
                  },
                ),
              ),
              // Indicators and button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.xl,
                  AppSizes.lg,
                  AppSizes.xl,
                  AppSizes.xl,
                ),
                child: Column(
                  children: [
                    // Step indicator with text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Step ${_currentPage + 1} of ${_items.length}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    // Enhanced progress dots with glow
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: _items.length,
                        effect: WormEffect(
                          dotWidth: 12,
                          dotHeight: 12,
                          spacing: 12,
                          activeDotColor: AppColors.primary,
                          dotColor: AppColors.grey300,
                          strokeWidth: 2,
                          paintStyle: PaintingStyle.fill,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    // Enhanced button with press effect
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B7F4E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                              ),
                              elevation: 6,
                              shadowColor: const Color(
                                0xFF1B7F4E,
                              ).withValues(alpha: 0.5),
                            ).copyWith(
                              overlayColor: WidgetStateProperty.all(
                                Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _items.length - 1
                                  ? 'Start Shopping'
                                  : 'Next',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Icon(
                              _currentPage == _items.length - 1
                                  ? Iconsax.tick_circle5
                                  : Iconsax.arrow_right_3,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return AnimatedBuilder(
      animation: _iconAnimationController,
      builder: (context, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.xxl,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSizes.xl),
                // Animated icon with enhanced visuals and glow
                Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: Transform.rotate(
                    angle: _iconRotationAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            item.color.withValues(alpha: 0.2),
                            item.color.withValues(alpha: 0.08),
                            item.color.withValues(alpha: 0.0),
                          ],
                          stops: const [0.3, 0.7, 1.0],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.25),
                            blurRadius: 40,
                            spreadRadius: 8,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.15),
                            blurRadius: 70,
                            spreadRadius: 15,
                            offset: const Offset(0, 25),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              item.color,
                              item.color.withValues(alpha: 0.85),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(item.icon, size: 80, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                // Enhanced title with premium typography
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -0.8,
                    height: 1.2,
                    color: Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Enhanced description with optimal readability
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.75,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
