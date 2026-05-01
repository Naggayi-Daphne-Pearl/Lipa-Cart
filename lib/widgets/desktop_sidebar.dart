import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_sizes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class DesktopSidebar extends StatefulWidget {
  final String activeSection;
  final bool initiallyCollapsed;

  const DesktopSidebar({
    super.key,
    required this.activeSection,
    this.initiallyCollapsed = false,
  });

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  late bool _collapsed;
  bool _categoriesExpanded = true;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initiallyCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    final width = _collapsed ? 64.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.grey200)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSizes.sm),
            Row(
              mainAxisAlignment: _collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!_collapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSizes.md),
                    child: Text(
                      'Browse',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: _collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                  icon: Icon(
                    _collapsed ? Icons.chevron_right : Icons.chevron_left,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xs),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                children: [
                  _navItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Home',
                    route: '/customer/home',
                    selected: widget.activeSection == 'home',
                  ),
                  _navItem(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    label: 'My lists',
                    route: '/customer/shopping-lists',
                    selected: widget.activeSection == 'lists',
                  ),
                  _navItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    label: 'Recipes',
                    route: '/customer/recipes',
                    selected: widget.activeSection == 'recipes',
                  ),
                  _navItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    route: '/customer/orders',
                    selected: widget.activeSection == 'orders',
                  ),
                  _navItem(
                    context,
                    icon: Icons.favorite_border,
                    label: 'Favorites',
                    route: '/customer/home',
                    selected: widget.activeSection == 'favorites',
                  ),
                  if (!_collapsed)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        _categoriesExpanded
                            ? Icons.expand_more
                            : Icons.chevron_right,
                        size: 16,
                      ),
                      title: Text(
                        'Browse categories',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () =>
                          setState(() => _categoriesExpanded = !_categoriesExpanded),
                    ),
                  if (!_collapsed && _categoriesExpanded)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSizes.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _CategoryNode('Fresh Produce'),
                          _CategoryNode('Dairy & Eggs'),
                          _CategoryNode('Bakery'),
                          _CategoryNode('Snacks'),
                          _CategoryNode('Beverages'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool selected,
  }) {
    final tile = ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 20,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: _collapsed
          ? null
          : Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
      selected: selected,
      selectedTileColor: AppColors.primarySoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      onTap: () => context.go(route),
      minLeadingWidth: 20,
      horizontalTitleGap: AppSizes.sm,
    );

    if (_collapsed) {
      return Tooltip(message: label, child: tile);
    }
    return tile;
  }
}

class _CategoryNode extends StatelessWidget {
  final String label;
  const _CategoryNode(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
