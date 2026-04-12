import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logout_helper.dart';

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({required this.child, super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late String _currentRoute;

  @override
  void initState() {
    super.initState();
    _currentRoute =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
  }

  String _getPageTitle(String route) {
    if (route.contains('/admin/dashboard')) return 'Dashboard';
    if (route.contains('/admin/products')) return 'Products';
    if (route.contains('/admin/orders')) return 'Orders';
    if (route.contains('/admin/users')) return 'Shoppers';
    if (route.contains('/admin/riders')) return 'Riders';
    if (route.contains('/admin/analytics')) return 'Analytics';
    return 'Admin';
  }

  IconData _getPageIcon(String route) {
    if (route.contains('/admin/dashboard')) return Iconsax.category;
    if (route.contains('/admin/products')) return Iconsax.box;
    if (route.contains('/admin/orders')) return Iconsax.bag_2;
    if (route.contains('/admin/users')) return Iconsax.shop;
    if (route.contains('/admin/riders')) return Iconsax.truck_fast;
    if (route.contains('/admin/analytics')) return Iconsax.chart_2;
    return Iconsax.category;
  }

  void _navigate(String route) {
    context.go(route);
    setState(() => _currentRoute = route);
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'A';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final pageTitle = _getPageTitle(_currentRoute);
    final pageIcon = _getPageIcon(_currentRoute);

    return Scaffold(
      // Mobile drawer
      drawer: isMobile ? Drawer(
        child: _buildSidebarContent(context),
      ) : null,
      // Top bar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        leading: isMobile ? Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Iconsax.menu_1),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ) : null,
        title: Row(
          children: [
            Icon(pageIcon, size: 22, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              pageTitle,
              style: AppTextStyles.h5.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Live date
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  DateFormat('EEE, MMM d').format(DateTime.now()),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          // Notification bell
          IconButton(
            onPressed: () {
              context.go('/admin/notifications');
            },
            icon: Badge(
              smallSize: 8,
              backgroundColor: AppColors.error,
              child: const Icon(Iconsax.notification, size: 22),
            ),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 4),
          // Profile menu
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final name = authProvider.user?.name ?? 'Admin';
                return PopupMenuButton(
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            _getInitials(name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Admin',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.keyboard_arrow_down,
                              size: 18, color: AppColors.textTertiary),
                        ],
                      ],
                    ),
                  ),
                  itemBuilder: (context) => <PopupMenuEntry<void>>[
                    PopupMenuItem<void>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            authProvider.user?.email ?? 'admin@lipacart.com',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<void>(
                      child: Row(
                        children: [
                          Icon(Iconsax.user,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          const Text('Profile'),
                        ],
                      ),
                      onTap: () {},
                    ),
                    PopupMenuItem<void>(
                      child: Row(
                        children: [
                          Icon(Iconsax.setting_2,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          const Text('Settings'),
                        ],
                      ),
                      onTap: () {},
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<void>(
                      child: Row(
                        children: [
                          const Icon(Iconsax.logout,
                              size: 18, color: AppColors.error),
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar (desktop only)
          if (!isMobile)
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.grey200)),
              ),
              child: _buildSidebarContent(context),
            ),
          // Main content
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context) {
    return Column(
      children: [
        // Logo
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Text('LC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
              ),
              const SizedBox(width: 10),
              Text('Lipa Cart', style: AppTextStyles.h5.copyWith(fontSize: 16)),
            ],
          ),
        ),
        Divider(color: AppColors.grey200, height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            children: [
              _SidebarItem(icon: Iconsax.category, label: 'Dashboard', isActive: _currentRoute.contains('/admin/dashboard'), onTap: () { _navigate('/admin/dashboard'); Navigator.of(context).maybePop(); }),
              _SidebarItem(icon: Iconsax.box, label: 'Products', isActive: _currentRoute.contains('/admin/products'), onTap: () { _navigate('/admin/products'); Navigator.of(context).maybePop(); }),
              _SidebarItem(icon: Iconsax.bag_2, label: 'Orders', isActive: _currentRoute.contains('/admin/orders'), onTap: () { _navigate('/admin/orders'); Navigator.of(context).maybePop(); }),
              _SidebarItem(icon: Iconsax.shop, label: 'Shoppers', isActive: _currentRoute.contains('/admin/users'), onTap: () { _navigate('/admin/users'); Navigator.of(context).maybePop(); }),
              _SidebarItem(icon: Iconsax.truck_fast, label: 'Riders', isActive: _currentRoute.contains('/admin/riders'), onTap: () { _navigate('/admin/riders'); Navigator.of(context).maybePop(); }),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Divider(height: 1)),
              _SidebarItem(icon: Iconsax.chart_2, label: 'Analytics', isActive: _currentRoute.contains('/admin/analytics'), onTap: () { _navigate('/admin/analytics'); Navigator.of(context).maybePop(); }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Iconsax.message_question, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Need help?', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      Text('Contact support', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.logout, color: AppColors.error, size: 22),
            const SizedBox(width: 10),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (!mounted) return;
              await LogoutHelper.logoutAndClear(context);
              if (!mounted) return;
              GoRouter.of(context).go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : _isHovered
                    ? AppColors.grey100
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: isActive
                    ? AppColors.primary
                    : _isHovered
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primary
                      : _isHovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
