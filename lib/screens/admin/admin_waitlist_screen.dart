import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../providers/waitlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_loading_indicator.dart';

class AdminWaitlistScreen extends StatefulWidget {
  const AdminWaitlistScreen({super.key});

  @override
  State<AdminWaitlistScreen> createState() => _AdminWaitlistScreenState();
}

class _AdminWaitlistScreenState extends State<AdminWaitlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.token != null) {
        context.read<WaitlistProvider>().getAdminWaitlist(authProvider.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Service Area Waitlist', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: AppColors.textPrimary),
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              if (authProvider.token != null) {
                context.read<WaitlistProvider>().getAdminWaitlist(authProvider.token!);
              }
            },
          ),
        ],
      ),
      body: Consumer<WaitlistProvider>(
        builder: (context, waitlistProvider, _) {
          if (waitlistProvider.isLoading) {
            return const Center(child: AppLoadingIndicator());
          }

          if (waitlistProvider.adminWaitlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.document_download, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('No waitlist entries yet', style: AppTextStyles.cardTitle),
                ],
              ),
            );
          }

          final highPriority = waitlistProvider.getHighPriorityAreas();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildSummaryCards(waitlistProvider, highPriority),
                const SizedBox(height: 24),
                Text('Areas by Requests', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                ..._buildAreaCards(context, waitlistProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSummaryCards(WaitlistProvider waitlistProvider, List<dynamic> highPriority) {
    final totalAreas = waitlistProvider.adminWaitlist.length;
    final totalSignups = (waitlistProvider.adminWaitlist as List).fold<int>(0, (sum, area) => sum + (area['count'] as int? ?? 0));

    return [
      Row(
        children: [
          Expanded(
            child: _buildSummaryCard(icon: Iconsax.location, title: 'Total Areas', value: '$totalAreas', color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(icon: Iconsax.people, title: 'Total Signups', value: '$totalSignups', color: AppColors.accent),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (highPriority.isNotEmpty) _buildSummaryCard(icon: Iconsax.warning_2, title: 'High Priority Areas', value: '${highPriority.length}', color: AppColors.error),
    ];
  }

  Widget _buildSummaryCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: AppTextStyles.navLabel.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  List<Widget> _buildAreaCards(BuildContext context, WaitlistProvider waitlistProvider) {
    return (waitlistProvider.adminWaitlist as List).asMap().entries.map((entry) {
      final area = entry.value as Map<String, dynamic>;
      final areaName = area['area_name'] as String;
      final region = area['region'] as String;
      final count = area['count'] as int;
      final priority = area['priority'] as String;
      final entries = area['entries'] as List;
      final priorityColor = _getPriorityColor(priority);

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: AppColors.grey200), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(areaName, style: AppTextStyles.cardTitle),
                          const SizedBox(height: 4),
                          Text(region, style: AppTextStyles.navLabel.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: priorityColor.withOpacity(0.3))),
                      child: Text('$count ${count == 1 ? 'request' : 'requests'}', style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: AppColors.grey200, height: 12),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        priority == 'high' ? Iconsax.arrow_up_3 : priority == 'medium' ? Iconsax.minus : Iconsax.arrow_down,
                        size: 14,
                        color: priorityColor,
                      ),
                      const SizedBox(width: 6),
                      Text('${priority[0].toUpperCase()}${priority.substring(1)} Priority',
                          style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Notify Customers?'),
                          content: Text('Send notification to $count customers waiting for $areaName?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.token != null) {
                          final success = await context.read<WaitlistProvider>().notifyArea(
                                region: region,
                                areaName: areaName,
                                authToken: authProvider.token!,
                              );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Notified $count customers' : 'Failed to notify customers'),
                                backgroundColor: success ? AppColors.success : AppColors.error,
                              ),
                            );
                            if (success) {
                              if (authProvider.token != null) {
                                context.read<WaitlistProvider>().getAdminWaitlist(authProvider.token!);
                              }
                            }
                          }
                        }
                      }
                    },
                    child: const Text('Send Notification', style: TextStyle(color: AppColors.textWhite)),
                  ),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('View Signups'),
                  children: [
                    const Divider(height: 12),
                    ..._buildSignupsList(entries),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  List<Widget> _buildSignupsList(List entries) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return entries.map((entry) {
      final user = entry['user'] as Map<String, dynamic>?;
      final phoneNumber = entry['phone_number'] as String? ?? user?['phone_number'];
      final email = entry['email'] as String? ?? user?['email'];
      final createdAt = entry['createdAt'] as String?;
      final date = createdAt != null ? DateTime.parse(createdAt) : null;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (phoneNumber != null)
                Row(
                  children: [const Icon(Iconsax.call, size: 14, color: AppColors.textSecondary), const SizedBox(width: 8), Text(phoneNumber, style: AppTextStyles.navLabel)],
                ),
              if (email != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [const Icon(Iconsax.sms, size: 14, color: AppColors.textSecondary), const SizedBox(width: 8), Text(email, style: AppTextStyles.navLabel)],
                ),
              ],
              if (date != null) ...[
                const SizedBox(height: 4),
                Text('Joined ${dateFormat.format(date)}',
                    style: AppTextStyles.navLabel.copyWith(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.accent;
      default:
        return AppColors.success;
    }
  }
}
