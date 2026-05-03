import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_sizes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/responsive.dart';
import 'app_bottom_nav.dart';
import 'desktop_top_nav_bar.dart';
import 'desktop_sidebar.dart';
import 'desktop_breadcrumbs.dart';

class AdaptivePageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget mobileBody;
  final Widget? desktopBody;
  final int? currentIndex;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Gradient? backgroundGradient;
  final double? maxWidth;
  final String desktopActiveSection;
  final List<DesktopBreadcrumbItem> desktopBreadcrumbs;

  const AdaptivePageScaffold({
    super.key,
    required this.title,
    required this.mobileBody,
    this.subtitle,
    this.desktopBody,
    this.currentIndex,
    this.showBackButton = true,
    this.onBack,
    this.actions,
    this.backgroundGradient,
    this.maxWidth,
    this.desktopActiveSection = 'home',
    this.desktopBreadcrumbs = const [],
  });

  @override
  Widget build(BuildContext context) {
    final body = context.isDesktop && desktopBody != null
        ? desktopBody!
        : mobileBody;

    final desktopContent = SafeArea(
      child: ResponsiveContainer(
        maxWidth: maxWidth ?? (context.isDesktop ? 1440 : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!context.isMobile)
              DesktopTopNavBar(activeSection: desktopActiveSection),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.horizontalPadding,
                context.responsive<double>(
                  mobile: AppSizes.lg,
                  tablet: AppSizes.xl,
                  desktop: 24.0,
                ),
                context.horizontalPadding,
                context.responsive<double>(
                  mobile: AppSizes.md,
                  tablet: AppSizes.lg,
                  desktop: 20.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBackButton && context.isMobile) ...[
                    _buildBackButton(context),
                    const SizedBox(width: AppSizes.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: context.responsive<double>(
                              mobile: 24.0,
                              tablet: 28.0,
                              desktop: 32.0,
                            ),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: context.responsive<double>(
                                mobile: 13.0,
                                tablet: 14.0,
                                desktop: 15.0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions != null && actions!.isNotEmpty)
                    Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.sm,
                      alignment: WrapAlignment.end,
                      children: actions!,
                    ),
                ],
              ),
            ),
            if (context.isDesktop && desktopBreadcrumbs.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalPadding,
                  0,
                  context.horizontalPadding,
                  AppSizes.sm,
                ),
                child: DesktopBreadcrumbs(items: desktopBreadcrumbs),
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: currentIndex != null && context.isMobile
          ? AppBottomNav(currentIndex: currentIndex!)
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: backgroundGradient ?? AppColors.elegantBgGradient,
        ),
        child: context.isDesktop
            ? Row(
                children: [
                  DesktopSidebar(activeSection: desktopActiveSection),
                  Expanded(child: desktopContent),
                ],
              )
            : desktopContent,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap:
          onBack ??
          () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer/home');
            }
          },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: AppColors.shadowSm,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}
