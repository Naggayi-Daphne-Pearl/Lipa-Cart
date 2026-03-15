import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/logout_helper.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/address_service.dart';
import '../../services/order_service.dart';
import '../../widgets/app_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBottomNav;

  const ProfileScreen({super.key, this.showBottomNav = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _loadProfileData() async {
    if (_isLoadingProfile) return;

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    final user = authProvider.user;

    if (token == null || user == null) return;

    setState(() => _isLoadingProfile = true);

    try {
      await authProvider.refreshProfile();
      final refreshedUser = authProvider.user;
      if (refreshedUser == null) return;

      final addressService = context.read<AddressService>();
      final customerId = refreshedUser.customerId ?? refreshedUser.id;
      final addressSuccess = await addressService.fetchAddresses(
        token,
        customerId,
      );
      if (addressSuccess) {
        await authProvider.setAddresses(addressService.userAddresses);
      }

      final orderProvider = context.read<OrderProvider>();
      if (orderProvider.orders.isEmpty) {
        final orderService = context.read<OrderService>();
        final ordersSuccess = await orderService.fetchOrders(
          token,
          refreshedUser.id,
        );
        if (ordersSuccess) {
          orderProvider.syncOrdersFromService(orderService.orders);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(currentIndex: 4)
          : null,
      body: ResponsiveContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Greeting
                Padding(
                  padding: EdgeInsets.all(
                    context.responsive<double>(
                      mobile: AppSizes.lg,
                      tablet: AppSizes.xl,
                      desktop: 24.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar with initials
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: user?.profileImage != null && user!.profileImage!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  user.profileImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        _getInitials(user.name),
                                        style: AppTextStyles.h4.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Text(
                                  _getInitials(user?.name),
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome ${user?.name?.split(' ')[0] ?? 'User'}!',
                              style: AppTextStyles.h3.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: context.responsive<double>(
                                  mobile: 26.0,
                                  tablet: 30.0,
                                  desktop: 34.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? user?.phoneNumber ?? 'No email',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Wallet/Balance Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(
                      context.responsive<double>(
                        mobile: AppSizes.lg,
                        tablet: AppSizes.xl,
                        desktop: 20.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        context.responsive<double>(
                          mobile: AppSizes.radiusLg,
                          tablet: AppSizes.radiusXl,
                          desktop: 16.0,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          child: Icon(
                            Iconsax.wallet_2,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lipa Cart balance',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'UGX 0',
                                style: AppTextStyles.h5.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.lg,
                    tablet: AppSizes.xl,
                    desktop: AppSizes.xl,
                  ),
                ),

                // Quick Action Buttons
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: context.isDesktop ? 400 : double.infinity,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Open live chat
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive<double>(
                                  mobile: AppSizes.md,
                                  tablet: AppSizes.lg,
                                  desktop: AppSizes.lg,
                                ),
                                vertical: AppSizes.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLg,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.message,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSizes.sm),
                                  Text(
                                    'Live Chat',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Open WhatsApp
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive<double>(
                                  mobile: AppSizes.md,
                                  tablet: AppSizes.lg,
                                  desktop: AppSizes.lg,
                                ),
                                vertical: AppSizes.md,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF25D366),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLg,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.send_2,
                                    color: const Color(0xFF25D366),
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSizes.sm),
                                  Text(
                                    'WhatsApp',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: const Color(0xFF25D366),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.lg,
                    tablet: AppSizes.xl,
                    desktop: AppSizes.xl,
                  ),
                ),

                // Help & Support Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: _buildMenuSection(context, 'Need Assistance?', [
                    _MenuItem(
                      icon: Iconsax.info_circle,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                  ], showDividers: false),
                ),

                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.lg,
                    tablet: AppSizes.xl,
                    desktop: AppSizes.xl,
                  ),
                ),

                // My Lipa Cart & My Settings Sections
                if (context.isDesktop)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.horizontalPadding,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildMenuSection(context, 'My Lipa Cart', [
                            _MenuItem(
                              icon: Iconsax.receipt,
                              title: 'Orders',
                              onTap: () => context.go('/customer/orders'),
                            ),
                            _MenuItem(
                              icon: Iconsax.star,
                              title: 'Ratings & Reviews',
                              onTap: () => context.go('/customer/ratings-reviews'),
                            ),
                          ]),
                        ),
                        const SizedBox(width: AppSizes.lg),
                        Expanded(
                          child: _buildMenuSection(context, 'My Settings', [
                            _MenuItem(
                              icon: Iconsax.location,
                              title: 'Addresses',
                              onTap: () => context.go('/customer/addresses'),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Mobile: vertical layout
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.horizontalPadding,
                    ),
                    child: _buildMenuSection(context, 'My Lipa Cart', [
                      _MenuItem(
                        icon: Iconsax.receipt,
                        title: 'Orders',
                        onTap: () => context.go('/customer/orders'),
                      ),
                      _MenuItem(
                        icon: Iconsax.star,
                        title: 'Ratings & Reviews',
                        onTap: () => context.go('/customer/ratings-reviews'),
                      ),
                    ]),
                  ),

                  SizedBox(
                    height: context.responsive<double>(
                      mobile: AppSizes.lg,
                      tablet: AppSizes.xl,
                      desktop: AppSizes.xl,
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.horizontalPadding,
                    ),
                    child: _buildMenuSection(context, 'My Settings', [
                      _MenuItem(
                        icon: Iconsax.location,
                        title: 'Addresses',
                        onTap: () => context.go('/customer/addresses'),
                      ),
                    ]),
                  ),
                ],

                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.lg,
                    tablet: AppSizes.xl,
                    desktop: AppSizes.xl,
                  ),
                ),

                // Logout Button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: Center(
                    child: TextButton(
                      onPressed: () async {
                        await LogoutHelper.logoutAndClear(context);
                        if (context.mounted) {
                          GoRouter.of(context).go('/login');
                        }
                      },
                      child: Text(
                        'Logout',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    List<_MenuItem> items, {
    bool showDividers = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: context.responsive<double>(
              mobile: 14.0,
              tablet: 15.0,
              desktop: 16.0,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(
              context.responsive<double>(
                mobile: AppSizes.radiusLg,
                tablet: AppSizes.radiusXl,
                desktop: 16.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              return _buildMenuItem(
                context,
                item,
                showDivider: showDividers && !isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    _MenuItem item, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: item.onTap,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.responsive<double>(
              mobile: AppSizes.md,
              tablet: AppSizes.lg,
              desktop: 20.0,
            ),
            vertical: context.responsive<double>(
              mobile: AppSizes.xs,
              tablet: AppSizes.sm,
              desktop: AppSizes.sm,
            ),
          ),
          leading: Container(
            width: context.responsive<double>(
              mobile: 40.0,
              tablet: 44.0,
              desktop: 48.0,
            ),
            height: context.responsive<double>(
              mobile: 40.0,
              tablet: 44.0,
              desktop: 48.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(
              item.icon,
              color: AppColors.textSecondary,
              size: context.responsive<double>(
                mobile: 20.0,
                tablet: 22.0,
                desktop: 24.0,
              ),
            ),
          ),
          title: Text(
            item.title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: context.responsive<double>(
                mobile: 14.0,
                tablet: 15.0,
                desktop: 16.0,
              ),
            ),
          ),
          trailing: Icon(
            Iconsax.arrow_right_3,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(
              left: context.responsive<double>(
                mobile: 68.0,
                tablet: 76.0,
                desktop: 84.0,
              ),
            ),
            child: Divider(height: 1, color: AppColors.grey100),
          ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.title, required this.onTap});
}
