import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logout_helper.dart';
import '../../core/utils/responsive.dart';
import '../../models/order.dart';
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
    final orderProvider = context.watch<OrderProvider>();
    final addressService = context.watch<AddressService>();
    final user = authProvider.user;
    final defaultAddress = authProvider.defaultAddress;
    final ordersCount = orderProvider.orders.length;
    final addressesCount =
        authProvider.user?.addresses.length ?? addressService.addresses.length;
    final ratingSummary = _ratingSummary(orderProvider.orders);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar:
          widget.showBottomNav ? const AppBottomNav(currentIndex: 5) : null,
      body: ResponsiveContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    context.responsive<double>(
                      mobile: AppSizes.md,
                      tablet: AppSizes.lg,
                      desktop: AppSizes.xl,
                    ),
                    context.horizontalPadding,
                    AppSizes.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'My Profile',
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: context.responsive<double>(
                              mobile: 26.0,
                              tablet: 30.0,
                              desktop: 34.0,
                            ),
                          ),
                        ),
                      ),
                      if (_isLoadingProfile)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),

                // User Card with Stats
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(
                        context.responsive<double>(
                          mobile: AppSizes.radiusXl,
                          tablet: 20.0,
                          desktop: 24.0,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          blurRadius: context.responsive<double>(
                            mobile: 8.0,
                            tablet: 12.0,
                            desktop: 16.0,
                          ),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // User Info Row
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
                              // Avatar
                              Container(
                                width: context.responsive<double>(
                                  mobile: 56.0,
                                  tablet: 64.0,
                                  desktop: 72.0,
                                ),
                                height: context.responsive<double>(
                                  mobile: 56.0,
                                  tablet: 64.0,
                                  desktop: 72.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: user?.profileImage != null
                                    ? ClipOval(
                                        child: Image.network(
                                          user!.profileImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        Iconsax.user,
                                        color: Colors.white,
                                        size: context.responsive<double>(
                                          mobile: 28.0,
                                          tablet: 32.0,
                                          desktop: 36.0,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              // Name and Phone
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.name ?? 'Guest User',
                                      style: AppTextStyles.h5.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: context.responsive<double>(
                                          mobile: 18.0,
                                          tablet: 20.0,
                                          desktop: 22.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Formatters.formatPhoneNumber(
                                        user?.phoneNumber ?? '',
                                      ),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Edit Button
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.responsive<double>(
                                    mobile: AppSizes.md,
                                    tablet: AppSizes.lg,
                                    desktop: AppSizes.lg,
                                  ),
                                  vertical: AppSizes.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  'Edit',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Stats Row
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive<double>(
                              mobile: AppSizes.lg,
                              tablet: AppSizes.xl,
                              desktop: 24.0,
                            ),
                            vertical: context.responsive<double>(
                              mobile: AppSizes.md,
                              tablet: AppSizes.lg,
                              desktop: AppSizes.lg,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(
                                context.responsive<double>(
                                  mobile: AppSizes.radiusXl,
                                  tablet: 20.0,
                                  desktop: 24.0,
                                ),
                              ),
                              bottomRight: Radius.circular(
                                context.responsive<double>(
                                  mobile: AppSizes.radiusXl,
                                  tablet: 20.0,
                                  desktop: 24.0,
                                ),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                ordersCount.toString(),
                                'Orders',
                              ),
                              _buildStatDivider(context),
                              _buildStatItem(
                                context,
                                addressesCount.toString(),
                                'Addresses',
                              ),
                              _buildStatDivider(context),
                              _buildStatItem(context, ratingSummary, 'Rating'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.md,
                    tablet: AppSizes.lg,
                    desktop: AppSizes.xl,
                  ),
                ),

                // Default Address Card
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: GestureDetector(
                    onTap: () => context.go('/customer/addresses'),
                    child: Container(
                      padding: EdgeInsets.all(
                        context.responsive<double>(
                          mobile: AppSizes.md,
                          tablet: AppSizes.lg,
                          desktop: 20.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(
                          context.responsive<double>(
                            mobile: AppSizes.radiusLg,
                            tablet: AppSizes.radiusXl,
                            desktop: 20.0,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.location,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      defaultAddress?.label ??
                                          'No address saved',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (defaultAddress != null) ...[
                                      const SizedBox(width: AppSizes.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusFull,
                                          ),
                                        ),
                                        child: Text(
                                          'Default',
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  defaultAddress?.fullAddress.isNotEmpty == true
                                      ? defaultAddress!.fullAddress
                                      : 'Add a delivery address to speed up checkout',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Iconsax.arrow_right_3,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.lg,
                    tablet: AppSizes.xl,
                    desktop: 24.0,
                  ),
                ),

                // Account Section
                _buildSectionTitle(context, 'ACCOUNT'),
                _buildMenuCard(context, [
                  _MenuItem(
                    icon: Iconsax.location,
                    title: 'My Addresses',
                    onTap: () => context.go('/customer/addresses'),
                  ),
                  _MenuItem(
                    icon: Iconsax.card,
                    title: 'Payment Methods',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Iconsax.heart,
                    title: 'Saved Items',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Iconsax.clock,
                    title: 'Order History',
                    onTap: () => context.go('/customer/orders'),
                  ),
                ]),

                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.md,
                    tablet: AppSizes.lg,
                    desktop: AppSizes.lg,
                  ),
                ),

                // Preferences Section
                _buildSectionTitle(context, 'PREFERENCES'),
                _buildMenuCard(context, [
                  _MenuItem(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Iconsax.setting_2,
                    title: 'App Settings',
                    onTap: () {},
                  ),
                ]),

                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.md,
                    tablet: AppSizes.lg,
                    desktop: AppSizes.lg,
                  ),
                ),

                // Support Section
                _buildSectionTitle(context, 'SUPPORT'),
                _buildMenuCard(context, [
                  _MenuItem(
                    icon: Iconsax.message_question,
                    title: 'Help Center',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Iconsax.document_text,
                    title: 'Terms & Privacy',
                    onTap: () {},
                  ),
                ]),

                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.lg,
                    tablet: AppSizes.xl,
                    desktop: 24.0,
                  ),
                ),

                // Logout button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: _buildLogoutButton(context),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: context.responsive<double>(
              mobile: 22.0,
              tablet: 26.0,
              desktop: 28.0,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: context.responsive<double>(
              mobile: 12.0,
              tablet: 13.0,
              desktop: 14.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: context.responsive<double>(
        mobile: 32.0,
        tablet: 36.0,
        desktop: 40.0,
      ),
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.horizontalPadding,
        AppSizes.sm,
        context.horizontalPadding,
        AppSizes.sm,
      ),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<_MenuItem> items) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(
            context.responsive<double>(
              mobile: AppSizes.radiusLg,
              tablet: AppSizes.radiusXl,
              desktop: 20.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: context.responsive<double>(
                mobile: 8.0,
                tablet: 12.0,
                desktop: 16.0,
              ),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            return _buildMenuItem(context, item, showDivider: !isLast);
          }).toList(),
        ),
      ),
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
            color: AppColors.grey400,
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

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: EdgeInsets.all(
          context.responsive<double>(
            mobile: AppSizes.md,
            tablet: AppSizes.lg,
            desktop: 20.0,
          ),
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(
            context.responsive<double>(
              mobile: AppSizes.radiusLg,
              tablet: AppSizes.radiusXl,
              desktop: 20.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.logout,
              color: AppColors.error,
              size: context.responsive<double>(
                mobile: 20.0,
                tablet: 22.0,
                desktop: 24.0,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              'Logout',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
                fontSize: context.responsive<double>(
                  mobile: 14.0,
                  tablet: 15.0,
                  desktop: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingSummary(List<Order> orders) {
    final ratings = orders
        .map((order) => order.rating?.stars)
        .whereType<double>()
        .where((value) => value > 0)
        .toList();

    if (ratings.isEmpty) return 'N/A';

    final total = ratings.fold<double>(0, (sum, value) => sum + value);
    final average = total / ratings.length;
    return average.toStringAsFixed(1);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text('Logout', style: AppTextStyles.h5),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              LogoutHelper.logoutAndClear(context).then((_) {
                if (!context.mounted) return;
                Navigator.of(dialogContext).pop();
                context.go('/login');
              });
            },
            child: Text(
              'Logout',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.title, required this.onTap});
}
