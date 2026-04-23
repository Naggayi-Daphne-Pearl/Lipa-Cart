import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../providers/waitlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/area_waitlist.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_loading_indicator.dart';
import 'join_waitlist_screen.dart';

class CustomerWaitlistScreen extends StatefulWidget {
  const CustomerWaitlistScreen({super.key});

  @override
  State<CustomerWaitlistScreen> createState() => _CustomerWaitlistScreenState();
}

class _CustomerWaitlistScreenState extends State<CustomerWaitlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.token != null) {
        context.read<WaitlistProvider>().getMyWaitlist(authProvider.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Service Area Waitlist', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: Consumer<WaitlistProvider>(
        builder: (context, waitlistProvider, _) {
          if (waitlistProvider.isLoading) {
            return const Center(child: AppLoadingIndicator());
          }

          if (waitlistProvider.myWaitlist.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoBanner(),
                const SizedBox(height: 24),
                Text('Your Waitlist Entries', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                ..._buildWaitlistCards(context, waitlistProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => JoinWaitlistScreen()));
        },
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Iconsax.location, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('Not on any waitlist yet', style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Text('Request service in your area and we\'ll notify you when we launch', style: AppTextStyles.navLabel),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => JoinWaitlistScreen()));
            },
            child: const Text('Join Waitlist', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.info_circle, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('We\'ll send you a notification as soon as service launches in your area', style: AppTextStyles.navLabel),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWaitlistCards(BuildContext context, WaitlistProvider waitlistProvider) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return waitlistProvider.myWaitlist.map((entry) {
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
                          Text(entry.areaName, style: AppTextStyles.cardTitle),
                          const SizedBox(height: 4),
                          Text(entry.regionDisplay, style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(entry),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: AppColors.grey200, height: 16),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.calendar, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Joined ${dateFormat.format(entry.createdAt)}', style: AppTextStyles.navLabel.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                if ((entry.phoneNumber?.isNotEmpty ?? false) ||
                    (entry.email?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification contact',
                          style: AppTextStyles.navLabel.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (entry.phoneNumber?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.call,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.phoneNumber!,
                                  style: AppTextStyles.navLabel,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (entry.email?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.sms,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.email!,
                                  style: AppTextStyles.navLabel,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (entry.isNotified) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Iconsax.tick_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('We notified you on ${dateFormat.format(entry.notificationSentAt ?? DateTime.now())}',
                              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        final waitlistProvider = context.read<WaitlistProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove from Waitlist?'),
                            content: Text('You won\'t receive notifications for ${entry.areaName} anymore.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
                            ],
                          ),
                        );

                        if (confirm == true && mounted) {
                          if (authProvider.token != null) {
                            await waitlistProvider.removeFromWaitlist(entry.id, authProvider.token!);
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Removed from waitlist')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Iconsax.trash),
                      label: const Text('Remove'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  Widget _buildStatusBadge(AreaWaitlist entry) {
    final (bgColor, textColor, icon) = switch (entry.status) {
      'waitlisted' => (AppColors.primary.withValues(alpha: 0.1), AppColors.primary, Iconsax.clock),
      'notified' => (Colors.green.withValues(alpha: 0.1), Colors.green, Iconsax.tick_circle),
      'service_started' => (Colors.blue.withValues(alpha: 0.1), Colors.blue, Iconsax.verify),
      _ => (AppColors.grey200, AppColors.textSecondary, Iconsax.close_circle),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(entry.statusDisplay, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
