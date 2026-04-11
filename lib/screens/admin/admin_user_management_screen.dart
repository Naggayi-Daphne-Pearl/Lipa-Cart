import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_user_service.dart';
import '../../widgets/app_loading_indicator.dart';

/// Admin User Management Screen
/// Allows admins to view, search, and manage user roles
class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  // User data
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _filterUsers();
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      final usersData = await AdminUserService.getAllUsers(token);

      _allUsers = usersData.map((userData) {
        return UserProfile(
          id: userData['id'] ?? '',
          name: userData['name'] ?? userData['phone'] ?? 'Unknown',
          phoneNumber: userData['phone'] ?? '',
          role: UserRoleExtension.fromString(
            userData['user_type'] ?? 'customer',
          ),
          isActive: userData['is_active'] ?? true,
        );
      }).toList();

      _filterUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final currentTab = _tabController.index;

    List<UserProfile> filtered = _allUsers;

    // Filter by role based on tab
    if (currentTab == 1) {
      filtered = filtered.where((u) => u.role == UserRole.customer).toList();
    } else if (currentTab == 2) {
      filtered = filtered.where((u) => u.role == UserRole.shopper).toList();
    } else if (currentTab == 3) {
      filtered = filtered.where((u) => u.role == UserRole.rider).toList();
    } else if (currentTab == 4) {
      filtered = filtered.where((u) => u.role == UserRole.admin).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.phoneNumber.contains(_searchQuery);
      }).toList();
    }

    setState(() {
      _filteredUsers = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterUsers();
    });
  }

  Future<void> _changeUserRole(UserProfile user, UserRole newRole) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      await AdminUserService.updateUserRole(user.id, newRole, token);

      setState(() {
        final index = _allUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _allUsers[index] = user.copyWith(role: newRole);
        }
        _filterUsers();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.name}\'s role changed to ${newRole.displayName}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(UserProfile user) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      await AdminUserService.toggleUserStatus(user.id, token);

      setState(() {
        final index = _allUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _allUsers[index] = user.copyWith(isActive: !user.isActive);
        }
        _filterUsers();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.name} ${!user.isActive ? 'activated' : 'deactivated'} successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management', style: AppTextStyles.h4),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: const Icon(Iconsax.search_normal),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Iconsax.close_circle),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Customers'),
                  Tab(text: 'Shoppers'),
                  Tab(text: 'Riders'),
                  Tab(text: 'Admins'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const AppLoadingPage()
          : TabBarView(
              controller: _tabController,
              children: List.generate(5, (index) => _buildUserList()),
            ),
    );
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.user_search, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
          child: Icon(
            _getRoleIcon(user.role),
            color: _getRoleColor(user.role),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(user.name, style: AppTextStyles.h5)),
            if (!user.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Inactive',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.phoneNumber, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.role.displayName,
                style: AppTextStyles.caption.copyWith(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Iconsax.more),
          onSelected: (value) {
            if (value == 'change_role') {
              _showChangeRoleDialog(user);
            } else if (value == 'toggle_status') {
              _toggleUserStatus(user);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'change_role',
              child: Row(
                children: [
                  Icon(Iconsax.user_edit, size: 20),
                  SizedBox(width: 12),
                  Text('Change Role'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(user.isActive ? Iconsax.lock : Iconsax.unlock, size: 20),
                  const SizedBox(width: 12),
                  Text(user.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${user.name}', style: AppTextStyles.h5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select new role:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...UserRole.values.map((role) {
              return RadioListTile<UserRole>(
                title: Row(
                  children: [
                    Icon(
                      _getRoleIcon(role),
                      size: 20,
                      color: _getRoleColor(role),
                    ),
                    const SizedBox(width: 12),
                    Text(role.displayName),
                  ],
                ),
                value: role,
                groupValue: user.role,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context);
                    _changeUserRole(user, value);
                  }
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return Iconsax.user;
      case UserRole.shopper:
        return Iconsax.shopping_cart;
      case UserRole.rider:
        return Iconsax.driving;
      case UserRole.admin:
        return Iconsax.shield_security;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return AppColors.primary;
      case UserRole.shopper:
        return AppColors.success;
      case UserRole.rider:
        return AppColors.warning;
      case UserRole.admin:
        return AppColors.beverages;
    }
  }
}

/// User profile model for admin user management
class UserProfile {
  final String id;
  final String name;
  final String phoneNumber;
  final UserRole role;
  final bool isActive;

  UserProfile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.isActive,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    UserRole? role,
    bool? isActive,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
