import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';
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
    final isGuest = !authProvider.isAuthenticated;

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
                // Guest state — show Sign In prompt
                if (isGuest) ...[
                  _buildGuestHeader(context),
                ] else ...[
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
                              launchUrl(Uri.parse('mailto:daphnepearl101@gmail.com?subject=Help%20Request'));
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
                              launchUrl(Uri.parse('https://wa.me/256785796401?text=Hi%20LipaCart%2C%20I%20need%20help'));
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
                      onTap: () => context.push('/customer/help'),
                    ),
                    _MenuItem(
                      icon: Iconsax.setting_2,
                      title: 'App Settings',
                      onTap: () => context.push('/customer/settings'),
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
                      _MenuItem(
                        icon: Iconsax.card,
                        title: 'Payment Methods',
                        onTap: () => _showPaymentMethodsSheet(context),
                      ),
                      _MenuItem(
                        icon: Iconsax.call,
                        title: 'Change Phone Number',
                        onTap: () => _showChangePhoneDialog(context),
                      ),
                      _MenuItem(
                        icon: Iconsax.trash,
                        title: 'Delete Account',
                        onTap: () => _showDeleteAccountDialog(context),
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
                          GoRouter.of(context).go('/customer/home');
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
                ], // end else (authenticated)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(
        context.responsive<double>(
          mobile: AppSizes.lg,
          tablet: AppSizes.xl,
          desktop: 24.0,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Guest avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.user,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            'Welcome to LipaCart',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to track orders, save addresses,\nand get personalised recommendations.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          // Sign In button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                elevation: 0,
              ),
              child: Text(
                'Sign In',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          // Create Account button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => context.push('/signup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
              child: Text(
                'Create Account',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          // Earn with LipaCart — Glovo-style footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primaryOrange.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Iconsax.money_recive,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Earn with LipaCart',
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Become a Personal Shopper or Delivery Rider and start earning today.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/signup'),
                        icon: Icon(Iconsax.shopping_bag, size: 18),
                        label: const Text('Shopper'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/signup'),
                        icon: Icon(Iconsax.truck_fast, size: 18),
                        label: const Text('Rider'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryOrange,
                          side: BorderSide(color: AppColors.primaryOrange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          // Help & Support for guests too
          _buildMenuSection(context, 'Need Assistance?', [
            _MenuItem(
              icon: Iconsax.info_circle,
              title: 'Help & Support',
              onTap: () => context.push('/customer/help'),
            ),
            _MenuItem(
              icon: Iconsax.setting_2,
              title: 'App Settings',
              onTap: () => context.push('/customer/settings'),
            ),
          ]),
        ],
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

  // --- Saved Payment Methods ---
  void _showPaymentMethodsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text('Payment Methods', style: AppTextStyles.h5),
              const SizedBox(height: AppSizes.lg),
              _buildPaymentMethodTile(
                icon: Iconsax.mobile,
                title: 'Mobile Money',
                subtitle: 'MTN MoMo, Airtel Money',
                isDefault: true,
              ),
              const Divider(height: 1),
              _buildPaymentMethodTile(
                icon: Iconsax.card,
                title: 'Debit / Credit Card',
                subtitle: 'Visa, Mastercard',
                isDefault: false,
              ),
              const Divider(height: 1),
              _buildPaymentMethodTile(
                icon: Iconsax.money_recive,
                title: 'Cash on Delivery',
                subtitle: 'Pay when you receive your order',
                isDefault: false,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Your default payment method is used at checkout. Full payment integration with MTN MoMo and Airtel Money coming soon.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDefault,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: AppTextStyles.labelMedium),
      subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      trailing: isDefault
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text('Default', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  // --- Change Phone Number Dialog ---
  void _showChangePhoneDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    bool otpSent = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!otpSent) ...[
                const Text('Enter your new phone number. We\'ll send an OTP to verify it.'),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixText: '+256 ',
                    hintText: '7XXXXXXXX',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else ...[
                Text('Enter the OTP sent to +256 ${phoneController.text}'),
                const SizedBox(height: 12),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '6-digit OTP',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final authProvider = context.read<AuthProvider>();
                      final token = authProvider.token;
                      if (token == null) return;

                      setDialogState(() => isLoading = true);

                      if (!otpSent) {
                        // Request OTP for new phone
                        final phone = '+256${phoneController.text.trim()}';
                        try {
                          await http.post(
                            Uri.parse('${AppConstants.apiUrl}/otp/send'),
                            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                            body: jsonEncode({'phone': phone}),
                          );
                          setDialogState(() {
                            otpSent = true;
                            isLoading = false;
                          });
                        } catch (_) {
                          setDialogState(() => isLoading = false);
                        }
                      } else {
                        // Verify OTP and change phone
                        final phone = '+256${phoneController.text.trim()}';
                        try {
                          final response = await http.post(
                            Uri.parse('${AppConstants.apiUrl}/user/change-phone'),
                            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                            body: jsonEncode({'new_phone': phone, 'otp': otpController.text.trim()}),
                          );

                          Navigator.pop(ctx);

                          if (response.statusCode == 200 && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Phone number updated! Please log in again.'), backgroundColor: AppColors.success),
                            );
                            await LogoutHelper.logoutAndClear(context);
                            if (context.mounted) GoRouter.of(context).go('/customer/home');
                          } else if (context.mounted) {
                            final data = jsonDecode(response.body);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(data['error']?['message'] ?? 'Failed to change phone'), backgroundColor: AppColors.error),
                            );
                          }
                        } catch (_) {
                          Navigator.pop(ctx);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(otpSent ? 'Verify & Change' : 'Send OTP'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Delete Account Dialog ---
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.warning_2, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your data, order history, and saved addresses will be deleted.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Account'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final authProvider = context.read<AuthProvider>();
              final token = authProvider.token;
              if (token == null) return;

              // Show loading
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Deleting account...')],
                        ),
                      ),
                    ),
                  ),
                );
              }

              try {
                final response = await http.delete(
                  Uri.parse('${AppConstants.apiUrl}/user/delete-account'),
                  headers: {'Authorization': 'Bearer $token'},
                );

                if (context.mounted) Navigator.of(context).pop(); // dismiss loading

                if (response.statusCode == 200 && context.mounted) {
                  await LogoutHelper.logoutAndClear(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account deleted successfully'), backgroundColor: AppColors.success),
                    );
                    GoRouter.of(context).go('/customer/home');
                  }
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete account'), backgroundColor: AppColors.error),
                  );
                }
              } catch (_) {
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete Account'),
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
