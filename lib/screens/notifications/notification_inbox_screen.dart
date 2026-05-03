import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../widgets/app_loading_indicator.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in to view notifications';
      });
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.apiUrl}/notifications/mine?pageSize=50'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List? ?? [];
        setState(() {
          _notifications = data.cast<Map<String, dynamic>>();
          _unreadCount = body['meta']?['unreadCount'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load notifications';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not connect to server';
      });
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final docId = notification['documentId'] ?? notification['id'];
    if (docId == null) return;

    try {
      await http.patch(
        Uri.parse('${AppConstants.apiUrl}/notifications/$docId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      setState(() {
        notification['is_read'] = true;
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await http.patch(
        Uri.parse('${AppConstants.apiUrl}/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      setState(() {
        for (final n in _notifications) {
          n['is_read'] = true;
        }
        _unreadCount = 0;
      });
    } catch (_) {}
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'order_status':
        return Iconsax.box;
      case 'new_task':
        return Iconsax.shopping_bag;
      case 'new_delivery':
        return Iconsax.truck_fast;
      case 'substitute_suggestion':
        return Iconsax.arrow_swap_horizontal;
      case 'substitute_response':
        return Iconsax.message_text;
      case 'promo':
        return Iconsax.discount_shape;
      case 'delivery_code':
        return Iconsax.password_check;
      default:
        return Iconsax.notification;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'order_status':
        return AppColors.primary;
      case 'new_task':
        return AppColors.info;
      case 'new_delivery':
        return AppColors.accent;
      case 'substitute_suggestion':
        return AppColors.warning;
      case 'substitute_response':
        return AppColors.success;
      case 'promo':
        return AppColors.warning;
      case 'delivery_code':
        return AppColors.success;
      default:
        return AppColors.grey500;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    if (notification['is_read'] != true) {
      _markAsRead(notification);
    }

    final data = notification['data'] is Map<String, dynamic>
        ? notification['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    final route = (data['route'] as String?) ?? '';
    final type =
        (data['type'] as String?) ?? (notification['type'] as String?) ?? '';

    if (route.isNotEmpty) {
      context.go(route);
      return;
    }

    switch (type) {
      case 'order_status':
      case 'substitute_suggestion':
        context.go('/customer/orders');
        break;
      case 'substitute_response':
        context.go('/shopper/active-tasks');
        break;
      case 'new_task':
        context.go('/shopper/available-tasks');
        break;
      case 'new_delivery':
        context.go('/rider/available-deliveries');
        break;
      case 'delivery_code':
        context.go('/customer/orders');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final role = context.read<AuthProvider>().user?.role;
              if (role == UserRole.shopper) {
                context.go('/shopper/home');
              } else if (role == UserRole.rider) {
                context.go('/rider/home');
              } else if (role == UserRole.admin) {
                context.go('/admin/dashboard');
              } else {
                context.go('/customer/home');
              }
            }
          },
        ),
        title: Text('Notifications', style: AppTextStyles.h4),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingIndicator.page()
          : _error != null
          ? _buildError()
          : _notifications.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: AppColors.accent,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSizes.xs),
                itemBuilder: (context, index) {
                  return _buildNotificationCard(_notifications[index]);
                },
              ),
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] == true;
    final type = notification['type'] as String?;

    return GestureDetector(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isRead ? AppColors.surface : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: isRead
              ? Border.all(color: AppColors.grey200, width: 0.5)
              : Border.all(color: AppColors.primaryMuted, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _colorForType(type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                _iconForType(type),
                color: _colorForType(type),
                size: AppSizes.iconMd,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? '',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification['body'] ?? '',
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification['createdAt']),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.notification, size: 64, color: AppColors.grey300),
          const SizedBox(height: AppSizes.md),
          Text(
            'No notifications yet',
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            "We'll notify you about your orders here",
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
          const SizedBox(height: AppSizes.md),
          Text(_error!, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSizes.md),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadNotifications();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
