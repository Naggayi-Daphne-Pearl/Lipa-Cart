import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../services/admin_user_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_loading_indicator.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int> _stats = {
    'totalUsers': 0,
    'totalOrders': 0,
    'totalProducts': 0,
    'shopperCount': 0,
    'riderCount': 0,
  };
  bool _statsLoading = true;
  bool _statsError = false;

  @override
  void initState() {
    super.initState();
    _validateRole();
    _loadStats();
  }

  void _validateRole() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.role != UserRole.admin) {
      Future.microtask(() {
        GoRouter.of(context).go(
          authProvider.user?.role == UserRole.shopper
              ? '/shopper/home'
              : authProvider.user?.role == UserRole.rider
                  ? '/rider/home'
                  : '/customer/home',
        );
      });
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _statsLoading = true;
      _statsError = false;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      if (token == null) return;

      final stats = await AdminUserService.getStats(token);
      if (mounted) {
        setState(() {
          _stats = {
            'totalUsers': stats['totalUsers'] ?? 0,
            'totalOrders': stats['totalOrders'] ?? 0,
            'totalProducts': stats['totalProducts'] ?? 0,
            'shopperCount': stats['shopperCount'] ?? 0,
            'riderCount': stats['riderCount'] ?? 0,
          };
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsLoading = false;
          _statsError = true;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getDisplayName() {
    final user = context.read<AuthProvider>().user;
    final name = user?.name;
    if (name == null || name.isEmpty) return 'Admin';
    // Return first name only
    return name.split(' ').first;
  }

  void _showAddStaffDialog(String userType) {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    bool obscurePassword = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add ${userType == 'shopper' ? 'Shopper' : 'Rider'}',
                      style: AppTextStyles.h4,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Full Name', style: AppTextStyles.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter full name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Phone Number', style: AppTextStyles.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    hintText: 'Enter phone (e.g., 785796401)',
                    prefixText: '+256',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Text('Password', style: AppTextStyles.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Minimum 6 characters',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Email (Optional)', style: AppTextStyles.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (nameController.text.isEmpty ||
                                phoneController.text.isEmpty ||
                                passwordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please fill in all required fields'),
                                ),
                              );
                              return;
                            }

                            if (phoneController.text.length != 9) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Phone must be 9 digits'),
                                ),
                              );
                              return;
                            }

                            if (passwordController.text.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Password must be at least 6 characters'),
                                ),
                              );
                              return;
                            }

                            if (emailController.text.isNotEmpty) {
                              final emailRegex =
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                              if (!emailRegex.hasMatch(emailController.text)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please enter a valid email address'),
                                  ),
                                );
                                return;
                              }
                            }

                            setState(() => isSubmitting = true);

                            try {
                              final authProvider =
                                  context.read<AuthProvider>();
                              final token = authProvider.token;
                              if (token == null) {
                                throw Exception('No auth token');
                              }

                              final success =
                                  await AdminUserService.createStaff(
                                phone: '+256${phoneController.text}',
                                password: passwordController.text,
                                name: nameController.text,
                                userType: userType,
                                email: emailController.text.isEmpty
                                    ? null
                                    : emailController.text,
                                token: token,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${userType == 'shopper' ? 'Shopper' : 'Rider'} added successfully!',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  _loadStats();
                                }
                              }
                            } catch (e) {
                              setState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const AppLoadingIndicator.small()
                        : Text(
                            'Add ${userType == 'shopper' ? 'Shopper' : 'Rider'}',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1200;
    final isMedium = width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isWide ? 32 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Compact greeting header ─────────────────
              _buildGreetingHeader(),
              const SizedBox(height: 28),

              // ─── Stats grid (merged - no more duplication) ──
              _buildSectionHeader('Overview', Iconsax.chart_2),
              const SizedBox(height: 16),
              _buildStatsGrid(isWide: isWide, isMedium: isMedium),
              const SizedBox(height: 32),

              // ─── Quick Actions ───────────────────────────
              _buildSectionHeader('Quick Actions', Iconsax.flash_1),
              const SizedBox(height: 16),
              _buildQuickActions(isWide: isWide, isMedium: isMedium),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(now);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, ${_getDisplayName()}',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        // Refresh button
        IconButton(
          onPressed: _statsLoading ? null : _loadStats,
          icon: _statsLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Iconsax.refresh),
          tooltip: 'Refresh stats',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppColors.grey200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.h5.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid({required bool isWide, required bool isMedium}) {
    final columns = isWide ? 5 : (isMedium ? 3 : 2);

    final statItems = [
      _StatData(
        title: 'Total Users',
        value: _stats['totalUsers'] ?? 0,
        icon: Iconsax.people,
        color: const Color(0xFF6366F1), // Indigo
        route: '/admin/users',
      ),
      _StatData(
        title: 'Orders',
        value: _stats['totalOrders'] ?? 0,
        icon: Iconsax.bag_2,
        color: const Color(0xFF10B981), // Green
        route: '/admin/orders',
      ),
      _StatData(
        title: 'Products',
        value: _stats['totalProducts'] ?? 0,
        icon: Iconsax.box,
        color: const Color(0xFFEA7702), // Orange
        route: '/admin/products',
      ),
      _StatData(
        title: 'Shoppers',
        value: _stats['shopperCount'] ?? 0,
        icon: Iconsax.shop,
        color: const Color(0xFF0EA5E9), // Sky blue
        route: '/admin/users',
      ),
      _StatData(
        title: 'Riders',
        value: _stats['riderCount'] ?? 0,
        icon: Iconsax.truck_fast,
        color: const Color(0xFFEF4444), // Red
        route: '/admin/riders',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isWide ? 1.4 : 1.25,
      ),
      itemCount: statItems.length,
      itemBuilder: (context, index) {
        final stat = statItems[index];
        return _StatCard(
          title: stat.title,
          value: _statsLoading ? null : stat.value,
          icon: stat.icon,
          color: stat.color,
          isError: _statsError,
          onTap: () => context.go(stat.route),
        );
      },
    );
  }

  Widget _buildQuickActions({required bool isWide, required bool isMedium}) {
    final actions = [
      _QuickAction(
        icon: Iconsax.user_add,
        label: 'Add Shopper',
        color: const Color(0xFF0EA5E9),
        onTap: () => _showAddStaffDialog('shopper'),
      ),
      _QuickAction(
        icon: Iconsax.truck_fast,
        label: 'Add Rider',
        color: const Color(0xFFEF4444),
        onTap: () => _showAddStaffDialog('rider'),
      ),
      _QuickAction(
        icon: Iconsax.add_square,
        label: 'Add Product',
        color: const Color(0xFFEA7702),
        onTap: () => context.go('/admin/products'),
      ),
      _QuickAction(
        icon: Iconsax.receipt_2,
        label: 'View Orders',
        color: const Color(0xFF10B981),
        onTap: () => context.go('/admin/orders'),
      ),
      _QuickAction(
        icon: Iconsax.chart_2,
        label: 'Analytics',
        color: const Color(0xFF6366F1),
        onTap: () => context.go('/admin/analytics'),
      ),
    ];

    final columns = isWide ? 5 : (isMedium ? 4 : 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 1.8 : 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _QuickActionCard(
          icon: action.icon,
          label: action.label,
          color: action.color,
          onTap: action.onTap,
        );
      },
    );
  }
}

// ─── Data classes ──────────────────────────────────────────────

class _StatData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String route;

  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// ─── Stat Card (tappable, with loading & error states) ────────

class _StatCard extends StatefulWidget {
  final String title;
  final int? value; // null = loading
  final IconData icon;
  final Color color;
  final bool isError;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isError,
    required this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.4)
                  : AppColors.grey200,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              // Value + Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.value == null)
                    // Loading skeleton
                    Container(
                      width: 40,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  else if (widget.isError)
                    Icon(Iconsax.warning_2,
                        color: AppColors.textTertiary, size: 24)
                  else
                    Text(
                      NumberFormat.compact().format(widget.value),
                      style: AppTextStyles.h3.copyWith(
                        color: widget.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    widget.title,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.3)
                  : AppColors.grey200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight:
                      _isHovered ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
