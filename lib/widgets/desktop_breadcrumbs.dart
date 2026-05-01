import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class DesktopBreadcrumbItem {
  final String label;
  final String? route;

  const DesktopBreadcrumbItem({required this.label, this.route});
}

class DesktopBreadcrumbs extends StatelessWidget {
  final List<DesktopBreadcrumbItem> items;

  const DesktopBreadcrumbs({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.chevron_right,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ),
          _crumb(context, items[i], isLast: i == items.length - 1),
        ],
      ],
    );
  }

  Widget _crumb(
    BuildContext context,
    DesktopBreadcrumbItem item, {
    required bool isLast,
  }) {
    final text = Text(
      item.label,
      style: AppTextStyles.caption.copyWith(
        color: isLast ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
      ),
    );

    if (isLast || item.route == null) return text;

    return InkWell(
      onTap: () => context.go(item.route!),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: text,
      ),
    );
  }
}
