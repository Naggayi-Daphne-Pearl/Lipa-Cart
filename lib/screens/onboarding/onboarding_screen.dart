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

  /// Total pages: 4 feature pages + 1 role selection page
  static const int _featurePageCount = 4;
  static const int _totalPageCount = 5;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Shop Fresh Groceries',
      description:
          'Browse through a wide selection of fresh produce, meat, dairy, and pantry essentials from local markets.',
      colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      sceneIcons: [
        SceneIcon(Iconsax.shop, 0.15, 0.20, 36, Colors.white70),
        SceneIcon(Iconsax.weight, 0.70, 0.15, 28, Color(0xFFFF6B6B)),
        SceneIcon(Iconsax.milk, 0.80, 0.55, 24, Colors.white70),
        SceneIcon(Iconsax.coffee, 0.20, 0.65, 22, Color(0xFFFFD93D)),
      ],
      mainIcon: Iconsax.shopping_bag,
    ),
    OnboardingItem(
      title: 'Personalised Grocery Lists',
      description:
          'Create custom shopping lists with detailed descriptions, budget amounts, and special instructions for each item.',
      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
      sceneIcons: [
        SceneIcon(Iconsax.tick_circle, 0.18, 0.22, 24, Color(0xFF81C784)),
        SceneIcon(Iconsax.tick_circle, 0.25, 0.38, 20, Color(0xFF81C784)),
        SceneIcon(Iconsax.edit_2, 0.75, 0.20, 26, Color(0xFFFFD54F)),
        SceneIcon(Iconsax.money_2, 0.72, 0.60, 22, Colors.white60),
      ],
      mainIcon: Iconsax.clipboard_text,
    ),
    OnboardingItem(
      title: 'Personal Shoppers',
      description:
          'Our trusted personal shoppers handpick the best quality items for your order with care and attention.',
      colors: [Color(0xFFE65100), Color(0xFFFF9800)],
      sceneIcons: [
        SceneIcon(Iconsax.bag_2, 0.18, 0.25, 28, Colors.white70),
        SceneIcon(Iconsax.star_1, 0.75, 0.18, 24, Color(0xFFFFD54F)),
        SceneIcon(Iconsax.verify, 0.22, 0.62, 22, Color(0xFF81C784)),
        SceneIcon(Iconsax.heart, 0.78, 0.58, 20, Color(0xFFFF8A80)),
      ],
      mainIcon: Iconsax.people,
    ),
    OnboardingItem(
      title: 'Fast Delivery',
      description:
          'Get your groceries delivered right to your doorstep by our reliable boda boda riders.',
      colors: [Color(0xFF4A148C), Color(0xFF7E57C2)],
      sceneIcons: [
        SceneIcon(Iconsax.location, 0.20, 0.22, 26, Color(0xFFFF5252)),
        SceneIcon(Iconsax.timer_1, 0.76, 0.18, 24, Color(0xFFFFD54F)),
        SceneIcon(Iconsax.box_1, 0.22, 0.62, 22, Colors.white60),
        SceneIcon(Iconsax.map, 0.75, 0.58, 20, Colors.white54),
      ],
      mainIcon: Iconsax.truck_fast,
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

    _iconAnimationController.forward();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _iconAnimationController.reset();
    _iconAnimationController.forward();
  }

  void _nextPage() {
    if (_currentPage < _totalPageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding({String? role}) {
    context.read<AuthProvider>().setFirstLaunchComplete();
    if (role != null && role != 'customer') {
      // Go to signup with role context
      context.replace('/signup');
    } else {
      context.replace('/customer/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRoleSelectionPage = _currentPage == _featurePageCount;

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
              // Header Bar with Logo and Skip
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
                    SvgPicture.asset(
                      'assets/images/logos/logo-on-white.svg',
                      height: 25,
                      fit: BoxFit.contain,
                    ),
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
                  itemCount: _totalPageCount,
                  itemBuilder: (context, index) {
                    if (index < _featurePageCount) {
                      return _buildFeaturePage(_items[index]);
                    } else {
                      return _buildRoleSelectionPage();
                    }
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
                    // Step indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isRoleSelectionPage
                              ? 'Almost there!'
                              : 'Step ${_currentPage + 1} of $_featurePageCount',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    // Progress dots
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: _totalPageCount,
                        effect: WormEffect(
                          dotWidth: 10,
                          dotHeight: 10,
                          spacing: 10,
                          activeDotColor: isRoleSelectionPage
                              ? AppColors.primaryOrange
                              : AppColors.primary,
                          dotColor: AppColors.grey300,
                          paintStyle: PaintingStyle.fill,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    // Next / Get Started button (hidden on role selection page)
                    if (!isRoleSelectionPage)
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
                                'Next',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              const Icon(
                                Iconsax.arrow_right_3,
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

  // ── Feature page with rich illustration ──────────────────────────
  Widget _buildFeaturePage(OnboardingItem item) {
    return AnimatedBuilder(
      animation: _iconAnimationController,
      builder: (context, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.lg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSizes.lg),
                // Rich scene illustration
                Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: _buildSceneIllustration(item),
                ),
                const SizedBox(height: 48),
                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    letterSpacing: -0.8,
                    height: 1.2,
                    color: Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.7,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a rich scene with gradient circle, central icon, and
  /// surrounding floating icons to create an illustration effect.
  Widget _buildSceneIllustration(OnboardingItem item) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  item.colors[0].withValues(alpha: 0.12),
                  item.colors[1].withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),
          // Middle ring with subtle pattern
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.colors[0].withValues(alpha: 0.15),
                  item.colors[1].withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
          // Central icon circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.colors[0].withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(item.mainIcon, size: 56, color: Colors.white),
          ),
          // Floating scene icons
          for (final si in item.sceneIcons)
            Positioned(
              left: si.relX * 260,
              top: si.relY * 260,
              child: _FloatingIcon(
                icon: si.icon,
                size: si.size,
                color: si.color,
                gradientColors: item.colors,
              ),
            ),
        ],
      ),
    );
  }

  // ── Role selection page ──────────────────────────────────────────
  Widget _buildRoleSelectionPage() {
    return AnimatedBuilder(
      animation: _iconAnimationController,
      builder: (context, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.lg,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSizes.lg),
                // Title
                Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B7F4E), Color(0xFF2ECC71)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Iconsax.user_octagon,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'What brings you here?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          letterSpacing: -0.5,
                          color: Color(0xFF2C2C2C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Choose how you\'d like to use LipaCart',
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Role cards
                _RoleCard(
                  icon: Iconsax.shopping_cart,
                  title: 'I want to shop',
                  subtitle: 'Browse groceries, place orders, and get them delivered to your door.',
                  gradientColors: const [Color(0xFF1B7F4E), Color(0xFF2ECC71)],
                  onTap: () => _completeOnboarding(role: 'customer'),
                ),
                const SizedBox(height: AppSizes.md),
                _RoleCard(
                  icon: Iconsax.bag_happy,
                  title: 'I want to be a Shopper',
                  subtitle: 'Earn money by picking and packing grocery orders for customers.',
                  gradientColors: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  onTap: () => _completeOnboarding(role: 'shopper'),
                ),
                const SizedBox(height: AppSizes.md),
                _RoleCard(
                  icon: Iconsax.truck_fast,
                  title: 'I want to be a Rider',
                  subtitle: 'Deliver orders on your boda boda and earn on your own schedule.',
                  gradientColors: const [Color(0xFFE65100), Color(0xFFFF9800)],
                  onTap: () => _completeOnboarding(role: 'rider'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Floating icon widget with glass-like container ─────────────────
class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final List<Color> gradientColors;

  const _FloatingIcon({
    required this.icon,
    required this.size,
    required this.color,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 20,
      height: size + 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: size, color: color),
    );
  }
}

// ── Role selection card ────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradientColors[0].withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Iconsax.arrow_right_3,
                size: 20,
                color: gradientColors[0],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data models ────────────────────────────────────────────────────
class OnboardingItem {
  final String title;
  final String description;
  final List<Color> colors;
  final List<SceneIcon> sceneIcons;
  final IconData mainIcon;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.colors,
    required this.sceneIcons,
    required this.mainIcon,
  });
}

class SceneIcon {
  final IconData icon;
  final double relX; // 0..1 relative position
  final double relY;
  final double size;
  final Color color;

  const SceneIcon(this.icon, this.relX, this.relY, this.size, this.color);
}
