import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    _currentRoute = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
  }

  String _getPageTitle(String route) {
    if (route.contains('/admin/dashboard')) return 'Dashboard';
    if (route.contains('/admin/products')) return 'Products Management';
    if (route.contains('/admin/orders')) return 'Orders Management';
    if (route.contains('/admin/users')) return 'Shoppers Management';
    if (route.contains('/admin/riders')) return 'Riders Management';
    if (route.contains('/admin/analytics')) return 'Analytics';
    return 'Admin';
  }

  List<String> _getBreadcrumbs(String route) {
    if (route.contains('/admin/dashboard')) return ['Dashboard'];
    if (route.contains('/admin/products')) return ['Dashboard', 'Products'];
    if (route.contains('/admin/orders')) return ['Dashboard', 'Orders'];
    if (route.contains('/admin/users')) return ['Dashboard', 'Shoppers'];
    if (route.contains('/admin/riders')) return ['Dashboard', 'Riders'];
    if (route.contains('/admin/analytics')) return ['Dashboard', 'Analytics'];
    return ['Dashboard'];
  }

  void _navigate(String route) {
    context.go(route);
    setState(() => _currentRoute = route);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final breadcrumbs = _getBreadcrumbs(_currentRoute);
    final pageTitle = _getPageTitle(_currentRoute);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pageTitle, style: AppTextStyles.h5),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  breadcrumbs.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Text(
                          breadcrumbs[index],
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (index < breadcrumbs.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) => PopupMenuButton(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (authProvider.user?.name?.isNotEmpty ?? false)
                              ? authProvider.user!.name![0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.user?.name ?? 'Admin',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Admin',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
                itemBuilder: (context) => <PopupMenuEntry<void>>[
                  PopupMenuItem<void>(
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Text('Profile'),
                      ],
                    ),
                    onTap: () {}, // TODO: Implement profile page
                  ),
                  PopupMenuItem<void>(
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 18, color: AppColors.accent),
                        const SizedBox(width: 12),
                        const Text('Settings'),
                      ],
                    ),
                    onTap: () {}, // TODO: Implement settings page
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<void>(
                    child: Row(
                      children: [
                        const Icon(Icons.logout, size: 18, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text('Logout'),
                      ],
                    ),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          if (!isMobile)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                children: [
                  // Logo/Brand
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'LC',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Lipa Cart',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey[200], height: 1),
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        _SidebarItem(
                          icon: Icons.dashboard,
                          label: 'Dashboard',
                          isActive: _currentRoute.contains('/admin/dashboard'),
                          onTap: () => _navigate('/admin/dashboard'),
                        ),
                        _SidebarItem(
                          icon: Icons.inventory_2,
                          label: 'Products',
                          isActive: _currentRoute.contains('/admin/products'),
                          onTap: () => _navigate('/admin/products'),
                        ),
                        _SidebarItem(
                          icon: Icons.receipt,
                          label: 'Orders',
                          isActive: _currentRoute.contains('/admin/orders'),
                          onTap: () => _navigate('/admin/orders'),
                        ),
                        _SidebarItem(
                          icon: Icons.store,
                          label: 'Shoppers',
                          isActive: _currentRoute.contains('/admin/users'),
                          onTap: () => _navigate('/admin/users'),
                        ),
                        _SidebarItem(
                          icon: Icons.two_wheeler,
                          label: 'Riders',
                          isActive: _currentRoute.contains('/admin/riders'),
                          onTap: () => _navigate('/admin/riders'),
                        ),
                        _SidebarItem(
                          icon: Icons.bar_chart,
                          label: 'Analytics',
                          isActive: _currentRoute.contains('/admin/analytics'),
                          onTap: () => _navigate('/admin/analytics'),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey[200], height: 1),
                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Need help?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contact support for any issues',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Main Content
          Expanded(
            child: widget.child,
          ),
        ],
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
              Navigator.of(dialogContext).pop();
              if (!mounted) return;
              await LogoutHelper.logoutAndClear(context);
              if (!mounted) return;
              GoRouter.of(context).go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.primary : Colors.black87,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
