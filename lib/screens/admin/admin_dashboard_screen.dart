import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../core/utils/logout_helper.dart';
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

  @override
  void initState() {
    super.initState();
    _validateRole();
    _loadStats();
  }

  void _validateRole() {
    final authProvider = context.read<AuthProvider>();

    // Validate user role - only admins can access this screen
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

  int _getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 4; // Desktop: 4 columns
    } else if (width > 800) {
      return 3; // Tablet: 3 columns
    } else {
      return 2; // Mobile: 2 columns
    }
  }

  Future<void> _loadStats() async {
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
        setState(() => _statsLoading = false);
      }
    }
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
                // Header
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

                // Full Name
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

                // Phone Number
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

                // Password
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
                      onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email (optional)
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

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            // Validate
                            if (nameController.text.isEmpty ||
                                phoneController.text.isEmpty ||
                                passwordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill in all required fields'),
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
                                  content: Text('Password must be at least 6 characters'),
                                ),
                              );
                              return;
                            }

                            // Validate email format if provided
                            if (emailController.text.isNotEmpty) {
                              final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                              if (!emailRegex.hasMatch(emailController.text)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid email address (e.g., test@example.com)'),
                                  ),
                                );
                                return;
                              }
                            }

                            setState(() => isSubmitting = true);

                            try {
                              final authProvider = context.read<AuthProvider>();
                              final token = authProvider.token;
                              if (token == null) throw Exception('No auth token');

                              final success = await AdminUserService.createStaff(
                                phone: '+256${phoneController.text}',
                                password: passwordController.text,
                                name: nameController.text,
                                userType: userType,
                                email: emailController.text.isEmpty ? null : emailController.text,
                                token: token,
                              );

                              if (mounted) {
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
                              if (mounted) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin Header - Modern Light Theme
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.name ?? 'Admin'}',
                        style: AppTextStyles.h4.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user?.email ?? 'admin@lipacart.com',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Stats - Orange/Green Theme
                Text(
                  'Quick Stats',
                  style: AppTextStyles.h5.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: _getGridColumns(context),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.15,
                  children: [
                    _StatCard(
                      title: 'Total Users',
                      value: _statsLoading ? '...' : '${_stats['totalUsers']}',
                      icon: Icons.people_outline,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFF9500).withValues(alpha: 0.15),
                          const Color(0xFFFF9500).withValues(alpha: 0.05),
                        ],
                      ),
                      accentColor: const Color(0xFFFF9500),
                    ),
                    _StatCard(
                      title: 'Total Orders',
                      value: _statsLoading ? '...' : '${_stats['totalOrders']}',
                      icon: Icons.shopping_bag_outlined,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.15),
                          const Color(0xFF10B981).withValues(alpha: 0.05),
                        ],
                      ),
                      accentColor: const Color(0xFF10B981),
                    ),
                    _StatCard(
                      title: 'Total Products',
                      value: _statsLoading ? '...' : '${_stats['totalProducts']}',
                      icon: Icons.inventory_2_outlined,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFF9500).withValues(alpha: 0.15),
                          const Color(0xFFFF9500).withValues(alpha: 0.05),
                        ],
                      ),
                      accentColor: const Color(0xFFFF9500),
                    ),
                    _StatCard(
                      title: 'Total Shoppers',
                      value: _statsLoading ? '...' : '${_stats['shopperCount']}',
                      icon: Icons.storefront_outlined,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.15),
                          const Color(0xFF10B981).withValues(alpha: 0.05),
                        ],
                      ),
                      accentColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Management Sections
                Text(
                  'Management',
                  style: AppTextStyles.h5.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: _getGridColumns(context),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.25,
                  children: [
                    _ManagementCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Products',
                      count: _statsLoading ? '...' : '${_stats['totalProducts']}',
                      accentColor: const Color(0xFFFF9500),
                      onTap: () => context.go('/admin/products'),
                    ),
                    _ManagementCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Orders',
                      count: _statsLoading ? '...' : '${_stats['totalOrders']}',
                      accentColor: const Color(0xFF10B981),
                      onTap: () => context.go('/admin/orders'),
                    ),
                    _ManagementCard(
                      icon: Icons.storefront_outlined,
                      title: 'Shoppers',
                      count: _statsLoading ? '...' : '${_stats['shopperCount']}',
                      accentColor: const Color(0xFFFF9500),
                      onTap: () => context.go('/admin/users'),
                    ),
                    _ManagementCard(
                      icon: Icons.two_wheeler_outlined,
                      title: 'Riders',
                      count: _statsLoading ? '...' : '${_stats['riderCount']}',
                      accentColor: const Color(0xFF10B981),
                      onTap: () => context.go('/admin/riders'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Quick Actions - Modern Buttons
                Text(
                  'Quick Actions',
                  style: AppTextStyles.h5.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  spacing: 16,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddStaffDialog('shopper'),
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Add Shopper'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9500),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddStaffDialog('rider'),
                        icon: const Icon(Icons.two_wheeler_outlined),
                        label: const Text('Add Rider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await LogoutHelper.logoutAndClear(context);
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              GoRouter.of(context).go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.h4.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String count;
  final Color accentColor;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ManagementCard> createState() => _ManagementCardState();
}

class _ManagementCardState extends State<_ManagementCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered
                    ? widget.accentColor.withValues(alpha: 0.3)
                    : Colors.grey[200]!,
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.accentColor.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.05),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.accentColor,
                    size: 28,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.count,
                      style: AppTextStyles.h4.copyWith(
                        color: widget.accentColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
