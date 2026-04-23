import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/shopping_list.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/desktop_top_nav_bar.dart';
import '../../widgets/feature_spotlight_card.dart';
import '../../widgets/auth_bottom_sheet.dart';
import '../../widgets/web_layout_wrapper.dart';

class ShoppingListsScreen extends StatefulWidget {
  final bool showBottomNav;

  const ShoppingListsScreen({super.key, this.showBottomNav = true});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  static const _listsSpotlightDismissedKey =
      'shopping_lists_spotlight_dismissed';
  static const _listsSpotlightVisitsKey = 'shopping_lists_spotlight_visits';

  final _searchController = TextEditingController();
  bool _showListsSpotlight = false;

  @override
  void initState() {
    super.initState();
    _prepareListsSpotlight();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();

      // Only load lists if user is authenticated
      if (authProvider.isAuthenticated && authProvider.token != null) {
        context.read<ShoppingListProvider>().loadLists(
          authToken: authProvider.token,
          userId: authProvider.user?.id,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _prepareListsSpotlight() async {
    final prefs = await SharedPreferences.getInstance();
    final isDismissed = prefs.getBool(_listsSpotlightDismissedKey) ?? false;
    final visitCount = (prefs.getInt(_listsSpotlightVisitsKey) ?? 0) + 1;
    await prefs.setInt(_listsSpotlightVisitsKey, visitCount);

    final shouldShow = !isDismissed && (visitCount <= 2 || visitCount % 4 == 0);
    if (!mounted) return;

    setState(() {
      _showListsSpotlight = shouldShow;
    });
  }

  Future<void> _dismissListsSpotlight({bool remember = false}) async {
    if (remember) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_listsSpotlightDismissedKey, true);
    }

    if (!mounted) return;
    setState(() {
      _showListsSpotlight = false;
    });
  }

  double _estimateListValue(ShoppingList list) {
    return list.items.fold<double>(0, (sum, item) {
      final budget = item.budgetAmount ?? 0;
      final pricedAmount = (item.unitPrice ?? 0) * item.quantity;
      return sum + (budget > 0 ? budget : pricedAmount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingListProvider>();
    final authProvider = context.watch<AuthProvider>();
    final searchQuery = _searchController.text.trim().toLowerCase();
    final visibleLists = searchQuery.isEmpty
        ? provider.lists
        : provider.lists.where((list) {
            final matchesList =
                list.name.toLowerCase().contains(searchQuery) ||
                (list.description?.toLowerCase().contains(searchQuery) ??
                    false);
            final matchesItems = list.items.any(
              (item) => item.name.toLowerCase().contains(searchQuery),
            );
            return matchesList || matchesItems;
          }).toList();
    final visibleItemCount = visibleLists.fold<int>(
      0,
      (sum, list) => sum + list.totalItems,
    );
    final visibleEstimatedTotal = visibleLists.fold<double>(
      0,
      (sum, list) => sum + _estimateListValue(list),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(currentIndex: 2)
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
          child: WebLayoutWrapper(
            addPadding: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DesktopTopNavBar(activeSection: 'lists'),
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
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
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                            boxShadow: AppColors.shadowSm,
                          ),
                          child: const Icon(
                            Iconsax.arrow_left,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Shopping Lists',
                              style: AppTextStyles.displayMd,
                            ),
                            Text(
                              '${visibleLists.length} ${searchQuery.isEmpty ? 'lists' : 'matches'}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showListsSpotlight)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      0,
                      AppSizes.lg,
                      AppSizes.md,
                    ),
                    child: FeatureSpotlightCard(
                      icon: Iconsax.clipboard_text,
                      eyebrow: 'SMART LISTS',
                      title: 'Make repeat shopping easier',
                      description:
                          'Save weekly essentials, meal prep items, or party supplies once and bring them back in seconds.',
                      highlights: const [
                        'Plan ahead faster',
                        'Reuse favorite items',
                        'Add all to cart in one tap',
                      ],
                      primaryLabel: authProvider.isAuthenticated
                          ? 'Create a list'
                          : 'Sign in to save lists',
                      onPrimaryTap: () {
                        _dismissListsSpotlight();
                        if (authProvider.isAuthenticated) {
                          _showCreateListSheet(context);
                        } else {
                          context.go(
                            '/login?return=%2Fcustomer%2Fshopping-lists',
                          );
                        }
                      },
                      secondaryLabel: 'Browse items',
                      onSecondaryTap: () {
                        _dismissListsSpotlight();
                        context.go('/customer/browse');
                      },
                      onDismiss: () => _dismissListsSpotlight(remember: true),
                    ),
                  ),

                if (authProvider.isAuthenticated && provider.lists.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      0,
                      AppSizes.lg,
                      AppSizes.md,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search lists or items',
                            prefixIcon: const Icon(Iconsax.search_normal),
                            suffixIcon: searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Iconsax.close_circle),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Wrap(
                          spacing: AppSizes.sm,
                          runSpacing: AppSizes.sm,
                          children: [
                            _buildInsightChip(
                              icon: Iconsax.note_1,
                              label: '${visibleLists.length} lists',
                            ),
                            _buildInsightChip(
                              icon: Iconsax.box,
                              label: '$visibleItemCount items',
                            ),
                            _buildInsightChip(
                              icon: Iconsax.wallet_2,
                              label: Formatters.formatCurrency(
                                visibleEstimatedTotal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildQuickTemplateChip(
                                label: 'Weekly',
                                emoji: '🛒',
                                items: [
                                  ShoppingListItem(
                                    id: 'wk_bread',
                                    name: 'Bread',
                                    unitPrice: 4000,
                                  ),
                                  ShoppingListItem(
                                    id: 'wk_milk',
                                    name: 'Milk',
                                    unitPrice: 5000,
                                  ),
                                  ShoppingListItem(
                                    id: 'wk_eggs',
                                    name: 'Eggs',
                                    unitPrice: 6000,
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppSizes.sm),
                              _buildQuickTemplateChip(
                                label: 'Meal Prep',
                                emoji: '🥗',
                                items: [
                                  ShoppingListItem(
                                    id: 'mp_chicken',
                                    name: 'Chicken Breast',
                                    unitPrice: 18000,
                                  ),
                                  ShoppingListItem(
                                    id: 'mp_rice',
                                    name: 'Rice',
                                    unitPrice: 8000,
                                  ),
                                  ShoppingListItem(
                                    id: 'mp_veg',
                                    name: 'Mixed Vegetables',
                                    unitPrice: 7000,
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppSizes.sm),
                              _buildQuickTemplateChip(
                                label: 'BBQ',
                                emoji: '🔥',
                                items: [
                                  ShoppingListItem(
                                    id: 'bbq_beef',
                                    name: 'Beef',
                                    unitPrice: 22000,
                                  ),
                                  ShoppingListItem(
                                    id: 'bbq_soda',
                                    name: 'Soda',
                                    unitPrice: 2000,
                                  ),
                                  ShoppingListItem(
                                    id: 'bbq_charcoal',
                                    name: 'Charcoal',
                                    unitPrice: 6000,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Lists
                Expanded(
                  child: !authProvider.isAuthenticated
                      ? _buildUnauthenticatedState()
                      : provider.isLoading
                      ? const AppLoadingPage(
                          message: 'Loading your shopping lists...',
                        )
                      : provider.lists.isEmpty
                      ? _buildEmptyState()
                      : visibleLists.isEmpty
                      ? _buildNoSearchResults()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                          ),
                          itemCount: visibleLists.length,
                          itemBuilder: (context, index) {
                            final list = visibleLists[index];
                            return _buildListCard(list);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: authProvider.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateListSheet(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Iconsax.add, color: Colors.white),
              label: Text(
                'New List',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInsightChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTemplateChip({
    required String label,
    required String emoji,
    required List<ShoppingListItem> items,
  }) {
    return GestureDetector(
      onTap: () => _showCreateListSheet(
        context,
        templateName: label,
        templateItems: items,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardGreen,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: AppColors.primaryMuted),
        ),
        child: Text(
          '$emoji $label',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptiveEmptyState({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 0
                  ? constraints.maxHeight - (AppSizes.xl * 2)
                  : 0,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoSearchResults() {
    return _buildAdaptiveEmptyState(
      children: [
        const Icon(Iconsax.search_status, size: 48, color: AppColors.grey400),
        const SizedBox(height: AppSizes.md),
        Text('No matching lists found', style: AppTextStyles.displaySm),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Try a different keyword or create a new quick list from the templates above.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildListCard(ShoppingList list) {
    final color = _parseColor(list.color);
    final estimatedValue = _estimateListValue(list);
    final progressPercent = (list.progress * 100).round();

    return GestureDetector(
      onTap: () =>
          context.push('/customer/shopping-list-detail', extra: list.id),
      onLongPress: () => _showListOptions(list),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          children: [
            // Top colored section
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusXl),
                ),
              ),
              child: Row(
                children: [
                  // Emoji container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Center(
                      child: Text(
                        list.emoji ?? '🛒',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          style: AppTextStyles.h5.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (list.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            list.description!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Options menu button
                  GestureDetector(
                    onTap: () => _showListOptions(list),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(
                        Iconsax.more,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom info section
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.shopping_bag,
                                  color: color,
                                  size: 16,
                                ),
                                const SizedBox(width: AppSizes.xs),
                                Text(
                                  '${list.totalItems} item${list.totalItems != 1 ? 's' : ''}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: list.isComplete
                                        ? AppColors.success.withValues(
                                            alpha: 0.14,
                                          )
                                        : color.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    list.isComplete
                                        ? 'Completed'
                                        : '$progressPercent% done',
                                    style: AppTextStyles.caption.copyWith(
                                      color: list.isComplete
                                          ? AppColors.success
                                          : color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (estimatedValue > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Est. ${Formatters.formatCurrency(estimatedValue)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      // Add to cart button
                      if (list.purchasableItems.isNotEmpty)
                        GestureDetector(
                          onTap: () => _addListToCart(list),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                              vertical: AppSizes.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.bag_2,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: AppSizes.xs),
                                Text(
                                  'Add All',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (list.totalItems > 0) ...[
                    const SizedBox(height: AppSizes.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: list.progress,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          list.isComplete ? AppColors.success : color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildAdaptiveEmptyState(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Iconsax.clipboard_text,
            size: 56,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        Text('No Shopping Lists Yet', style: AppTextStyles.displaySm),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Save weekly essentials, meal prep, or party items once\nso reordering your groceries takes seconds.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.xl),
        GestureDetector(
          onTap: () => _showCreateListSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.add, color: Colors.white, size: 20),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'Create Your First List',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xl),
        Text(
          'Or start from a template',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          alignment: WrapAlignment.center,
          children: [
            _buildTemplatePill('🛒 Weekly Essentials', [
              ShoppingListItem(
                id: 'weekly_milk',
                name: 'Milk',
                quantity: 1,
                unitPrice: 5000,
              ),
              ShoppingListItem(
                id: 'weekly_bread',
                name: 'Bread',
                quantity: 1,
                unitPrice: 4000,
              ),
              ShoppingListItem(
                id: 'weekly_eggs',
                name: 'Eggs',
                quantity: 1,
                unitPrice: 6000,
              ),
              ShoppingListItem(
                id: 'weekly_rice',
                name: 'Rice',
                quantity: 1,
                unitPrice: 8000,
              ),
              ShoppingListItem(
                id: 'weekly_cooking_oil',
                name: 'Cooking Oil',
                quantity: 1,
                unitPrice: 13000,
              ),
              ShoppingListItem(
                id: 'weekly_sugar',
                name: 'Sugar',
                quantity: 1,
                unitPrice: 6000,
              ),
              ShoppingListItem(
                id: 'weekly_tea',
                name: 'Tea',
                quantity: 1,
                unitPrice: 5000,
              ),
              ShoppingListItem(
                id: 'weekly_tomatoes',
                name: 'Tomatoes',
                quantity: 1,
                unitPrice: 3000,
              ),
              ShoppingListItem(
                id: 'weekly_onions',
                name: 'Onions',
                quantity: 1,
                unitPrice: 2500,
              ),
            ]),
            _buildTemplatePill('🎉 Party Supplies', [
              ShoppingListItem(
                id: 'party_sodas',
                name: 'Sodas',
                quantity: 1,
                unitPrice: 2000,
              ),
              ShoppingListItem(
                id: 'party_juice',
                name: 'Juice',
                quantity: 1,
                unitPrice: 5000,
              ),
              ShoppingListItem(
                id: 'party_chips',
                name: 'Chips',
                quantity: 1,
                unitPrice: 3500,
              ),
              ShoppingListItem(
                id: 'party_cake',
                name: 'Cake',
                quantity: 1,
                unitPrice: 12000,
              ),
              ShoppingListItem(
                id: 'party_paper_plates',
                name: 'Paper Plates',
                quantity: 1,
                unitPrice: 1500,
              ),
              ShoppingListItem(
                id: 'party_napkins',
                name: 'Napkins',
                quantity: 1,
                unitPrice: 1200,
              ),
            ]),
            _buildTemplatePill('👶 Baby Needs', [
              ShoppingListItem(
                id: 'baby_formula',
                name: 'Baby Formula',
                quantity: 1,
                unitPrice: 25000,
              ),
              ShoppingListItem(
                id: 'baby_diapers',
                name: 'Diapers',
                quantity: 1,
                unitPrice: 12000,
              ),
              ShoppingListItem(
                id: 'baby_wipes',
                name: 'Baby Wipes',
                quantity: 1,
                unitPrice: 4000,
              ),
              ShoppingListItem(
                id: 'baby_food',
                name: 'Baby Food',
                quantity: 1,
                unitPrice: 7000,
              ),
              ShoppingListItem(
                id: 'baby_cereal',
                name: 'Baby Cereal',
                quantity: 1,
                unitPrice: 4500,
              ),
            ]),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplatePill(String label, List<ShoppingListItem> items) {
    return GestureDetector(
      onTap: () {
        final name = label.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        _showCreateListSheet(context, templateName: name, templateItems: items);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedState() {
    return _buildAdaptiveEmptyState(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.lock, size: 56, color: AppColors.primary),
        ),
        const SizedBox(height: AppSizes.lg),
        Text(
          'Sign In Required',
          style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Please sign in to view and create\nshopping lists',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.xl),
        GestureDetector(
          onTap: () => showAuthBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.login, color: Colors.white, size: 20),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'Sign In',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateListSheet(
    BuildContext context, {
    String? templateName,
    String? templateDescription,
    List<ShoppingListItem>? templateItems,
  }) {
    final shoppingListProvider = context.read<ShoppingListProvider>();
    final authProvider = context.read<AuthProvider>();
    final isPremium = authProvider.user?.isPremium ?? false;
    final authToken = authProvider.token;
    if (!shoppingListProvider.canCreateList(isPremium: isPremium)) {
      _showFreeTierLimitDialog(context);
      return;
    }

    final nameController = TextEditingController(text: templateName ?? '');
    final descController = TextEditingController(
      text: templateDescription ?? '',
    );
    String selectedEmoji = '🛒';
    String selectedColor = ShoppingListProvider.listColors[0];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Create New List',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSizes.lg),

                // Name field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'List Name',
                    hintText: 'e.g., Weekly Groceries',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Description field
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g., Regular household essentials',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Emoji picker
                Text(
                  'Choose an Icon',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: ShoppingListProvider.listEmojis.map((emoji) {
                    final isSelected = selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedEmoji = emoji),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primarySoft
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.lg),

                // Color picker
                Text(
                  'Choose a Color',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: ShoppingListProvider.listColors.map((colorHex) {
                    final color = _parseColor(colorHex);
                    final isSelected = selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedColor = colorHex),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.xl),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (nameController.text.isNotEmpty) {
                              setSheetState(() => isSubmitting = true);
                              try {
                                final didCreate = await context
                                    .read<ShoppingListProvider>()
                                    .createList(
                                      name: nameController.text,
                                      description: descController.text.isEmpty
                                          ? null
                                          : descController.text,
                                      emoji: selectedEmoji,
                                      color: selectedColor,
                                      items: templateItems,
                                      isPremium: isPremium,
                                      authToken: authToken,
                                    );
                                if (!context.mounted) return;
                                if (didCreate) {
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                } else {
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    _showFreeTierLimitDialog(context);
                                  }
                                }
                              } catch (e) {
                                debugPrint(
                                  'ERROR: Failed to create shopping list: $e',
                                );
                                if (!mounted) return;
                                if (mounted) {
                                  setSheetState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to create list: ${e.toString()}',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    child: isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text(
                                'Creating...',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Create List',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showListOptions(ShoppingList list) {
    final color = _parseColor(list.color);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.md),
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            // List info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Center(
                      child: Text(
                        list.emoji ?? '🛒',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          style: AppTextStyles.h5.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${list.totalItems} items',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            // Options
            ListTile(
              leading: Icon(Iconsax.edit, color: color),
              title: const Text('Edit List'),
              onTap: () {
                Navigator.pop(context);
                _showEditListSheet(list);
              },
            ),
            ListTile(
              leading: Icon(Iconsax.document_text, color: color),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                context.push('/customer/shopping-list-detail', extra: list.id);
              },
            ),
            if (list.purchasableItems.isNotEmpty)
              ListTile(
                leading: const Icon(Iconsax.bag_2, color: AppColors.primary),
                title: const Text('Add All to Cart'),
                onTap: () {
                  Navigator.pop(context);
                  _addListToCart(list);
                },
              ),
            ListTile(
              leading: const Icon(Iconsax.trash, color: AppColors.error),
              title: const Text(
                'Delete List',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteList(list);
              },
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteList(ShoppingList list) {
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          title: const Text('Delete List?'),
          content: Text(
            'Are you sure you want to delete "${list.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        final authToken = context.read<AuthProvider>().token;
                        await context.read<ShoppingListProvider>().deleteList(
                          list.id,
                          authToken: authToken,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Deleted "${list.name}"'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        setDialogState(() => isDeleting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to delete list. Please try again.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 80,
                      height: 24,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.error,
                          ),
                        ),
                      ),
                    )
                  : const Text(
                      'Delete',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditListSheet(ShoppingList list) {
    final nameController = TextEditingController(text: list.name);
    final descController = TextEditingController(text: list.description ?? '');
    String selectedEmoji = list.emoji ?? '🛒';
    String selectedColor = list.color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Edit List',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSizes.lg),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'List Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Choose an Icon',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: ShoppingListProvider.listEmojis.map((emoji) {
                    final isSelected = selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedEmoji = emoji),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primarySoft
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Choose a Color',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: ShoppingListProvider.listColors.map((colorHex) {
                    final color = _parseColor(colorHex);
                    final isSelected = selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedColor = colorHex),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      try {
                        final authToken = context.read<AuthProvider>().token;
                        final didUpdate = await context
                            .read<ShoppingListProvider>()
                            .updateList(
                              list.copyWith(
                                name: nameController.text.trim(),
                                description: descController.text.trim().isEmpty
                                    ? null
                                    : descController.text.trim(),
                                emoji: selectedEmoji,
                                color: selectedColor,
                              ),
                              authToken: authToken,
                            );

                        if (!context.mounted) return;
                        if (didUpdate) {
                          Navigator.pop(context);
                        }
                      } catch (_) {
                        if (!context.mounted || !mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update list.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addListToCart(ShoppingList list) {
    final cartProvider = context.read<CartProvider>();
    int addedCount = 0;

    // Add all purchasable items to cart
    for (final item in list.purchasableItems) {
      if (item.linkedProduct != null) {
        cartProvider.addToCart(
          item.linkedProduct!,
          quantity: item.quantity.toDouble(),
        );
        addedCount += item.quantity;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle5, color: Colors.white, size: 20),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                'Added $addedCount items to cart',
                style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Checkout',
          textColor: Colors.white,
          onPressed: () {
            GoRouter.of(context).go('/customer/checkout');
          },
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _showFreeTierLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Text('Free Plan Limit Reached'),
        content: Text(
          'You can create up to ${ShoppingListProvider.freeTierListLimit} shopping lists on the free plan. Upgrade to premium for unlimited lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
