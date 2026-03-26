import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../services/strapi_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/logout_helper.dart';
import '../../widgets/rider_button.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  static const Color _brandColor = AppColors.accent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProfile();
    });
  }

  void _loadProfile() {
    final auth = context.read<AuthProvider>();
    final rider = context.read<RiderProvider>();
    final riderId = auth.user?.riderId;
    if (auth.token != null && riderId != null) {
      rider.loadRiderProfile(auth.token!, riderId);
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'R';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _getDisplayName(String? name) {
    if (name == null || name.isEmpty) return 'Rider';
    return name
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<AuthProvider, RiderProvider>(
        builder: (context, authProvider, riderProvider, _) {
          final user = authProvider.user;
          final profile = riderProvider.riderProfile;
          final isOnline = riderProvider.isOnline;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                backgroundColor: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/rider/home');
                    }
                  },
                ),
                title: const Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Header Card
                    _buildProfileHeader(user, isOnline, authProvider),
                    const SizedBox(height: AppSizes.lg),

                    // Online/Offline Toggle
                    _buildOnlineToggle(riderProvider, authProvider, user, isOnline),
                    const SizedBox(height: AppSizes.lg),

                    // Stats Row
                    _buildStatsRow(riderProvider),
                    const SizedBox(height: AppSizes.lg),

                    // Personal Information
                    _buildSectionHeader('Personal Information', Iconsax.user),
                    const SizedBox(height: AppSizes.sm),
                    _buildInfoCard([
                      _buildInfoRow(Iconsax.user, 'Name',
                          _getDisplayName(user?.name)),
                      _buildInfoRow(Iconsax.call, 'Phone',
                          user?.phoneNumber ?? 'Not set'),
                      _buildInfoRow(Iconsax.sms, 'Email',
                          user?.email ?? 'Not set'),
                    ]),
                    const SizedBox(height: AppSizes.lg),

                    // Vehicle Details
                    _buildSectionHeader('Vehicle Details', Iconsax.truck),
                    const SizedBox(height: AppSizes.sm),
                    _buildVehicleCard(profile),
                    const SizedBox(height: AppSizes.lg),

                    // Payment Details
                    _buildSectionHeader('Payment Details', Iconsax.wallet_2),
                    const SizedBox(height: AppSizes.sm),
                    _buildPaymentCard(profile),
                    const SizedBox(height: AppSizes.lg),

                    // Emergency Contact
                    _buildSectionHeader('Emergency Contact', Iconsax.call),
                    const SizedBox(height: AppSizes.sm),
                    _buildInfoCard([
                      _buildInfoRow(Iconsax.user, 'Name',
                          profile?['emergency_contact_name'] ?? 'Not set'),
                      _buildInfoRow(Iconsax.call, 'Phone',
                          profile?['emergency_contact_phone'] ?? 'Not set'),
                    ]),
                    const SizedBox(height: AppSizes.lg),

                    // KYC Status
                    _buildSectionHeader('Verification', Iconsax.shield_tick),
                    const SizedBox(height: AppSizes.sm),
                    _buildKycCard(
                      user?.kycStatus ?? profile?['kyc_status'] ?? 'not_submitted',
                      isVerified: profile?['is_verified'] == true,
                      profile: profile,
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Actions
                    _buildSectionHeader('Actions', Iconsax.setting_2),
                    const SizedBox(height: AppSizes.sm),
                    _buildActionCard(context, authProvider, user),
                    const SizedBox(height: AppSizes.xl),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    dynamic user,
    bool isOnline,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: _brandColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(user?.name),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                  _getDisplayName(user?.name),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF4CAF50)
                            : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Delivery Rider',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Edit button
          GestureDetector(
            onTap: () => _showEditProfileSheet(context, user, authProvider),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: const Icon(Iconsax.edit_2, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle(
    RiderProvider riderProvider,
    AuthProvider authProvider,
    dynamic user,
    bool isOnline,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isOnline ? AppColors.accentMuted : AppColors.grey200,
        ),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.accentSoft : AppColors.grey100,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              isOnline ? Iconsax.wifi : Iconsax.wifi_square,
              color: isOnline ? _brandColor : AppColors.grey500,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'You are Online' : 'You are Offline',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'Customers can see you for deliveries'
                      : 'Go online to receive delivery requests',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOnline,
            onChanged: (value) {
              final rid = authProvider.user?.riderId;
              if (authProvider.token != null && rid != null) {
                riderProvider.toggleOnlineStatus(
                  authProvider.token!,
                  rid,
                  value,
                );
              }
            },
            activeTrackColor: _brandColor.withValues(alpha: 0.5),
            activeThumbColor: _brandColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(RiderProvider riderProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Iconsax.tick_circle,
            label: 'Completed',
            value: '${riderProvider.completedOrders}',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _buildStatItem(
            icon: Iconsax.star_1,
            label: 'Rating',
            value: riderProvider.averageRating > 0
                ? riderProvider.averageRating.toStringAsFixed(1)
                : '-',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _buildStatItem(
            icon: Iconsax.message,
            label: 'Reviews',
            value: '${riderProvider.totalReviews}',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSizes.md, horizontal: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _brandColor),
          const SizedBox(width: AppSizes.sm),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic>? profile) {
    final hasVehicle = profile?['vehicle_type'] != null;

    if (!hasVehicle) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.grey200),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          children: [
            Icon(Iconsax.truck, size: 32, color: AppColors.grey300),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'No vehicle details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vehicle information will appear after KYC submission',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return _buildInfoCard([
      _buildInfoRow(Iconsax.truck, 'Type',
          profile?['vehicle_type'] ?? 'Not set'),
      _buildInfoRow(Iconsax.truck_fast, 'Make',
          profile?['vehicle_make'] ?? 'Not set'),
      _buildInfoRow(Iconsax.hashtag, 'Plate',
          profile?['vehicle_plate'] ?? 'Not set'),
      _buildInfoRow(Iconsax.card, 'License',
          profile?['license_number'] ?? 'Not set'),
    ]);
  }

  Widget _buildPaymentCard(Map<String, dynamic>? profile) {
    final hasMomo = profile?['mobile_money_number'] != null &&
        (profile!['mobile_money_number'] as String).isNotEmpty;
    final hasBank = profile?['bank_account_number'] != null &&
        (profile!['bank_account_number'] as String).isNotEmpty;

    if (!hasMomo && !hasBank) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.grey200),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          children: [
            Icon(Iconsax.wallet_2, size: 32, color: AppColors.grey300),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'No payment method added',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add a payment method to receive your earnings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            RiderButton.secondary(
              text: 'Add Payment Method',
              icon: Iconsax.add,
              height: 44,
              onPressed: () => _showEditPaymentSheet(context, profile),
            ),
          ],
        ),
      );
    }

    return _buildInfoCard([
      if (hasMomo) ...[
        _buildInfoRow(Iconsax.mobile, 'Provider',
            profile['mobile_money_provider'] ?? 'MTN Mobile Money'),
        _buildInfoRow(Iconsax.call, 'Number',
            profile['mobile_money_number'] ?? ''),
      ],
      if (hasBank) ...[
        _buildInfoRow(Iconsax.bank, 'Bank',
            profile['bank_name'] ?? ''),
        _buildInfoRow(Iconsax.user, 'Account',
            profile['bank_account_name'] ?? ''),
        _buildInfoRow(Iconsax.card, 'Number',
            _maskAccountNumber(profile['bank_account_number'] ?? '')),
      ],
    ]);
  }

  String _maskAccountNumber(String number) {
    if (number.length <= 4) return number;
    return '${'*' * (number.length - 4)}${number.substring(number.length - 4)}';
  }

  Widget _buildKycCard(String kycStatus,
      {bool isVerified = false, Map<String, dynamic>? profile}) {
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;
    final String subtitle;

    if (isVerified || kycStatus == 'approved') {
      statusColor = AppColors.success;
      statusText = 'Verified';
      statusIcon = Iconsax.shield_tick;
      subtitle = 'Your identity has been verified';
    } else {
      switch (kycStatus) {
        case 'pending_review':
          statusColor = AppColors.warning;
          statusText = 'Pending Review';
          statusIcon = Iconsax.clock;
          subtitle = 'Your documents are being reviewed';
          break;
        case 'rejected':
          statusColor = AppColors.error;
          statusText = 'Rejected';
          statusIcon = Iconsax.close_circle;
          subtitle = profile?['kyc_rejection_reason'] ??
              'Please resubmit your documents';
          break;
        default:
          statusColor = AppColors.textSecondary;
          statusText = 'Not Submitted';
          statusIcon = Iconsax.shield_cross;
          subtitle = 'Submit your documents to get verified';
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identity Verification',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (profile?['id_number'] != null &&
              (profile!['id_number'] as String).isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.sm),
            _buildInfoRow(Iconsax.card, 'ID Number', profile['id_number']),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context, AuthProvider authProvider, dynamic user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          _buildActionItem(
            icon: Iconsax.edit_2,
            label: 'Edit Profile',
            onTap: () => _showEditProfileSheet(context, user, authProvider),
          ),
          const Divider(height: 1, indent: 56),
          _buildActionItem(
            icon: Iconsax.wallet_2,
            label: 'Update Payment Details',
            onTap: () {
              final profile = context.read<RiderProvider>().riderProfile;
              _showEditPaymentSheet(context, profile);
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildActionItem(
            icon: Iconsax.call,
            label: 'Update Emergency Contact',
            onTap: () {
              final profile = context.read<RiderProvider>().riderProfile;
              _showEditContactSheet(context, profile);
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildActionItem(
            icon: Iconsax.shield_tick,
            label: 'Verification',
            onTap: () {
              final kycStatus = user?.kycStatus ?? 'not_submitted';
              if (kycStatus == 'not_submitted' || kycStatus == 'rejected') {
                context.push('/rider/kyc');
              }
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildActionItem(
            icon: Iconsax.logout,
            label: 'Logout',
            color: AppColors.error,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? _brandColor),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: color ?? AppColors.grey400),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await LogoutHelper.logoutAndClear(context);
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              GoRouter.of(context).go('/login');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ──── Edit Sheets ────

  void _showEditProfileSheet(
      BuildContext context, dynamic user, AuthProvider authProvider) {
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSizes.lg,
            right: AppSizes.lg,
            top: AppSizes.md,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon:
                        Icon(Iconsax.user, color: AppColors.accent, size: 20),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon:
                        Icon(Iconsax.sms, color: AppColors.accent, size: 20),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                StatefulBuilder(
                  builder: (context, setSheetState) {
                    bool saving = false;
                    return RiderButton.primary(
                      text: 'Save Changes',
                      isLoading: saving,

                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() => saving = true);
                        await authProvider.updateProfile(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                        );
                        final success = authProvider.errorMessage == null;
                        if (success && ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          setSheetState(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update profile'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSizes.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditPaymentSheet(
      BuildContext context, Map<String, dynamic>? profile) {
    final momoController = TextEditingController(
        text: profile?['mobile_money_number'] ?? '');
    String provider =
        profile?['mobile_money_provider'] ?? 'MTN Mobile Money';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            bool saving = false;
            return Padding(
              padding: EdgeInsets.only(
                left: AppSizes.lg,
                right: AppSizes.lg,
                top: AppSizes.md,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Update Payment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    // Provider toggle
                    Row(
                      children: ['MTN Mobile Money', 'Airtel Money']
                          .map((p) {
                        final isSelected = provider == p;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: p == 'MTN Mobile Money' ? 8.0 : 0.0,
                            ),
                            child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => provider = p),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _brandColor
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? _brandColor
                                        : AppColors.grey300,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusSm),
                                ),
                                child: Text(
                                  p == 'MTN Mobile Money'
                                      ? 'MTN MoMo'
                                      : 'Airtel Money',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSizes.md),
                    TextFormField(
                      controller: momoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Money Number',
                        prefixIcon: const Icon(Iconsax.call,
                            color: AppColors.accent, size: 20),
                        prefixText: '+256 ',
                        prefixStyle: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please enter your number'
                          : null,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    RiderButton.primary(
                      text: 'Save Payment Details',
                      isLoading: saving,

                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() => saving = true);
                        final auth = context.read<AuthProvider>();
                        final rid = auth.user!.riderId ?? auth.user!.id;
                        final success =
                            await StrapiService.updateRiderProfile(
                          rid,
                          {
                            'mobile_money_provider': provider,
                            'mobile_money_number': momoController.text.trim(),
                          },
                          auth.token!,
                        );
                        if (success && ctx.mounted) {
                          Navigator.of(ctx).pop();
                          _loadProfile();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Payment details updated'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          setSheetState(() => saving = false);
                        }
                      },
                    ),
                    const SizedBox(height: AppSizes.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditContactSheet(
      BuildContext context, Map<String, dynamic>? profile) {
    final nameController = TextEditingController(
        text: profile?['emergency_contact_name'] ?? '');
    final phoneController = TextEditingController(
        text: profile?['emergency_contact_phone'] ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            bool saving = false;
            return Padding(
              padding: EdgeInsets.only(
                left: AppSizes.lg,
                right: AppSizes.lg,
                top: AppSizes.md,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Emergency Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name',
                        prefixIcon: Icon(Iconsax.user,
                            color: AppColors.accent, size: 20),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: AppSizes.md),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Contact Phone',
                        prefixIcon: const Icon(Iconsax.call,
                            color: AppColors.accent, size: 20),
                        prefixText: '+256 ',
                        prefixStyle: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) => v == null || v.isEmpty
                          ? 'Phone number is required'
                          : null,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    RiderButton.primary(
                      text: 'Save Emergency Contact',
                      isLoading: saving,

                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() => saving = true);
                        final auth = context.read<AuthProvider>();
                        final rid = auth.user!.riderId ?? auth.user!.id;
                        final success =
                            await StrapiService.updateRiderProfile(
                          rid,
                          {
                            'emergency_contact_name':
                                nameController.text.trim(),
                            'emergency_contact_phone':
                                phoneController.text.trim(),
                          },
                          auth.token!,
                        );
                        if (success && ctx.mounted) {
                          Navigator.of(ctx).pop();
                          _loadProfile();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Emergency contact updated'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          setSheetState(() => saving = false);
                        }
                      },
                    ),
                    const SizedBox(height: AppSizes.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
