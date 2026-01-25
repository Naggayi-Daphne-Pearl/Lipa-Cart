import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
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

                // User Card with Stats
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(context.responsive<double>(
                        mobile: AppSizes.radiusXl,
                        tablet: 20.0,
                        desktop: 24.0,
                      )),
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
                          padding: EdgeInsets.all(context.responsive<double>(
                            mobile: AppSizes.lg,
                            tablet: AppSizes.xl,
                            desktop: 24.0,
                          )),
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
                                          user?.phoneNumber ?? ''),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white.withValues(alpha: 0.85),
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
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusFull),
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
                              bottomLeft: Radius.circular(context.responsive<double>(
                                mobile: AppSizes.radiusXl,
                                tablet: 20.0,
                                desktop: 24.0,
                              )),
                              bottomRight: Radius.circular(context.responsive<double>(
                                mobile: AppSizes.radiusXl,
                                tablet: 20.0,
                                desktop: 24.0,
                              )),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(context, '12', 'Orders'),
                              _buildStatDivider(context),
                              _buildStatItem(context, '3', 'Addresses'),
                              _buildStatDivider(context),
                              _buildStatItem(context, '4.9', 'Rating'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: context.responsive<double>(
                mobile: AppSizes.md,
                tablet: AppSizes.lg,
                desktop: AppSizes.xl,
              )),

              // Default Address Card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                child: Container(
                  padding: EdgeInsets.all(context.responsive<double>(
                    mobile: AppSizes.md,
                    tablet: AppSizes.lg,
                    desktop: 20.0,
                  )),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(context.responsive<double>(
                      mobile: AppSizes.radiusLg,
                      tablet: AppSizes.radiusXl,
                      desktop: 20.0,
                    )),
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
                                  'Home',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusFull),
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
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Plot 45, Nakasero Road, Nakasero',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
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

              SizedBox(height: context.responsive<double>(
                mobile: AppSizes.lg,
                tablet: AppSizes.xl,
                desktop: 24.0,
              )),

              // Account Section
              _buildSectionTitle(context, 'ACCOUNT'),
              _buildMenuCard(context, [
                _MenuItem(
                  icon: Iconsax.location,
                  title: 'My Addresses',
                  onTap: () {},
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
                  onTap: () => Navigator.pushNamed(context, '/orders'),
                ),
              ]),

              SizedBox(height: context.responsive<double>(
                mobile: AppSizes.md,
                tablet: AppSizes.lg,
                desktop: AppSizes.lg,
              )),

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

              SizedBox(height: context.responsive<double>(
                mobile: AppSizes.md,
                tablet: AppSizes.lg,
                desktop: AppSizes.lg,
              )),

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

              SizedBox(height: context.responsive<double>(
                mobile: AppSizes.lg,
                tablet: AppSizes.xl,
                desktop: 24.0,
              )),

              // Logout button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                child: _buildLogoutButton(context, authProvider),
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
          borderRadius: BorderRadius.circular(context.responsive<double>(
            mobile: AppSizes.radiusLg,
            tablet: AppSizes.radiusXl,
            desktop: 20.0,
          )),
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

  Widget _buildMenuItem(BuildContext context, _MenuItem item, {bool showDivider = true}) {
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
            padding: EdgeInsets.only(left: context.responsive<double>(
              mobile: 68.0,
              tablet: 76.0,
              desktop: 84.0,
            )),
            child: Divider(
              height: 1,
              color: AppColors.grey100,
            ),
          ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context, authProvider),
      child: Container(
        padding: EdgeInsets.all(context.responsive<double>(
          mobile: AppSizes.md,
          tablet: AppSizes.lg,
          desktop: 20.0,
        )),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(context.responsive<double>(
            mobile: AppSizes.radiusLg,
            tablet: AppSizes.radiusXl,
            desktop: 20.0,
          )),
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

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text(
          'Logout',
          style: AppTextStyles.h5,
        ),
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
              authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
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

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
