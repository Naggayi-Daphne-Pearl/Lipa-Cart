import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/shopping_list.dart';
import '../../models/product.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_loading_indicator.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final String listId;

  const ShoppingListDetailScreen({super.key, required this.listId});

  @override
  State<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ShoppingListProvider>();
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final authToken = context.watch<AuthProvider>().token;
    final list = listProvider.getListById(widget.listId);

    if (list == null) {
      return Scaffold(
        bottomNavigationBar: const AppBottomNav(currentIndex: 2),
        body: Center(child: Text('List not found')),
      );
    }

    final color = _parseColor(list.color);
    final pastSuggestions = orderProvider.frequentlyOrderedProducts.where((
      product,
    ) {
      return list.items.every((item) => item.linkedProduct?.id != product.id);
    }).toList();
    final uncheckedItems = list.items.where((i) => !i.isChecked).toList();
    final checkedItems = list.items.where((i) => i.isChecked).toList();
    final actionableItems = uncheckedItems;

    double estimatedTotal = 0;
    for (final item in uncheckedItems) {
      if (item.linkedProduct != null) {
        estimatedTotal += item.linkedProduct!.price * item.quantity;
      } else if (item.unitPrice != null) {
        estimatedTotal += item.unitPrice! * item.quantity;
      } else if (item.budgetAmount != null) {
        estimatedTotal += item.budgetAmount!;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: Column(
          children: [
            // Header with colored background
            Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSizes.radiusXl),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Column(
                    children: [
                      // Top bar
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                              ),
                              child: const Icon(
                                Iconsax.arrow_left,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showOptionsMenu(context, list),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                              ),
                              child: const Icon(
                                Iconsax.more,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.lg),
                      // List info
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                list.emoji ?? '🛒',
                                style: const TextStyle(fontSize: 32),
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
                                  style: AppTextStyles.h4.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (list.description != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    list.description!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      // Item count
                      Text(
                        '${list.totalItems} item${list.totalItems != 1 ? 's' : ''}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Items list
            Expanded(
              child: list.items.isEmpty
                  ? _buildEmptyState(color)
                  : RefreshIndicator(
                      onRefresh: () async {
                        final auth = context.read<AuthProvider>();
                        await context.read<ShoppingListProvider>().loadLists(
                          authToken: auth.token,
                        );
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        children: [
                          if (pastSuggestions.isNotEmpty) ...[
                            _buildSuggestionSection(
                              pastSuggestions,
                              list,
                              color,
                              authToken,
                            ),
                            const SizedBox(height: AppSizes.lg),
                          ],
                          // Shopping cart stats header
                          Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Iconsax.bag_2,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: AppSizes.sm),
                                    Expanded(
                                      child: Text(
                                        '${actionableItems.length} item${actionableItems.length != 1 ? 's' : ''} ready for order',
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Estimated total cost
                                if (estimatedTotal > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Iconsax.wallet_2,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: AppSizes.sm),
                                      Text(
                                        'Estimated: ${Formatters.formatCurrency(estimatedTotal)}',
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Wrap(
                            spacing: AppSizes.sm,
                            runSpacing: AppSizes.sm,
                            children: [
                              _buildOverviewChip(
                                icon: Iconsax.task_square,
                                label:
                                    '${checkedItems.length}/${list.totalItems} checked',
                                color: checkedItems.isEmpty
                                    ? AppColors.textSecondary
                                    : AppColors.success,
                              ),
                              _buildOverviewChip(
                                icon: Iconsax.note_1,
                                label:
                                    '${uncheckedItems.length} pending',
                                color: color,
                              ),
                              if (estimatedTotal > 0)
                                _buildOverviewChip(
                                  icon: Iconsax.wallet_money,
                                  label: Formatters.formatCurrency(
                                    estimatedTotal,
                                  ),
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.lg),

                          // All items — unchecked first, then checked
                          ...[...uncheckedItems, ...checkedItems].map(
                            (item) =>
                                _buildItemCard(item, list, color, authToken),
                          ),
                          if (checkedItems.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.sm),
                            GestureDetector(
                              onTap: () => listProvider.clearCheckedItems(
                                widget.listId,
                                authToken: authToken,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.trash,
                                      size: 16,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Clear ${checkedItems.length} checked item${checkedItems.length != 1 ? 's' : ''}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(list, color),
        backgroundColor: color,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text(
          'Add Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: actionableItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Estimated total
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${actionableItems.length} items',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(estimatedTotal),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add to Cart
                    GestureDetector(
                      onTap: () => _addAllToCart(list, cartProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Iconsax.bag_2, size: 18),
                            const SizedBox(width: 6),
                            Text('Cart', style: AppTextStyles.labelMedium),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    // Order Now
                    GestureDetector(
                      onTap: () => _orderList(list, cartProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                        child: Text(
                          'Order Now',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    ShoppingListItem item,
    ShoppingList list,
    Color color,
    String? authToken,
  ) {
    final cartProvider = context.watch<CartProvider>();
    final isInCart =
        item.linkedProduct != null &&
        cartProvider.isInCart(item.linkedProduct!.id);
    final hasNote = item.description?.trim().isNotEmpty ?? false;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            title: const Text('Remove item?'),
            content: Text('Remove "${item.name}" from ${list.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<ShoppingListProvider>().removeItemFromList(
          list.id,
          item.id,
          authToken: authToken,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                context.read<ShoppingListProvider>().addItemToList(
                  list.id,
                  item,
                  authToken: authToken,
                );
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: AppSizes.sm),
                // Product image
                if (item.linkedProduct != null &&
                    item.linkedProduct!.image.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.linkedProduct!.image,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Item info — tap to edit
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showEditItemDialog(item, list, color),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (!item.isChecked) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () =>
                                      _showEditDescriptionDialog(item, list),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasNote
                                          ? color.withValues(alpha: 0.12)
                                          : AppColors.grey100,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: hasNote
                                            ? color.withValues(alpha: 0.28)
                                            : AppColors.grey200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          hasNote
                                              ? Icons.edit_note
                                              : Icons.note_add_outlined,
                                          size: 16,
                                          color: hasNote
                                              ? color
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hasNote ? 'Edit note' : 'Add note',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: hasNote
                                                    ? color
                                                    : AppColors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (hasNote) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () =>
                                  _showEditDescriptionDialog(item, list),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSizes.sm),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.sticky_note_2_outlined,
                                      size: 16,
                                      color: color,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.description!,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textPrimary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else if (!item.isChecked) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () =>
                                  _showEditDescriptionDialog(item, list),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSizes.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.grey50,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                  border: Border.all(color: AppColors.grey200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.note_alt_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Add a note for brand, size, ripeness, or other preferences',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (item.budgetAmount != null) ...[
                                Icon(
                                  Iconsax.wallet_3,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                Text(
                                  'Worth ${Formatters.formatCurrency(item.budgetAmount!)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ] else if (item.unitPrice != null) ...[
                                Text(
                                  '${item.quantity} ${item.unit ?? ''}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${Formatters.formatCurrency(item.unitPrice!)} each',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  '${item.quantity} ${item.unit ?? ''}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (item.linkedProduct != null)
                                  Text(
                                    Formatters.formatCurrency(
                                      item.linkedProduct!.price,
                                    ),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Quantity controls
                if (!item.isChecked)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSizes.sm),
                    child: Row(
                      children: [
                        _buildQuantityButton(
                          icon: Iconsax.minus,
                          onTap: () async {
                            if (item.quantity > 1) {
                              context
                                  .read<ShoppingListProvider>()
                                  .updateItemQuantity(
                                    list.id,
                                    item.id,
                                    item.quantity - 1,
                                    authToken: authToken,
                                  );
                            } else {
                              final shouldRemove = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusLg,
                                    ),
                                  ),
                                  title: const Text('Remove item?'),
                                  content: Text(
                                    'Remove "${item.name}" from ${list.name}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (shouldRemove == true) {
                                context
                                    .read<ShoppingListProvider>()
                                    .removeItemFromList(
                                      list.id,
                                      item.id,
                                      authToken: authToken,
                                    );
                              }
                            }
                          },
                        ),
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: Text(
                            '${item.quantity}',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Iconsax.add,
                          onTap: () {
                            context
                                .read<ShoppingListProvider>()
                                .updateItemQuantity(
                                  list.id,
                                  item.id,
                                  item.quantity + 1,
                                  authToken: authToken,
                                );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // Add to Cart button for items with a linked product
            if (!item.isChecked && item.linkedProduct != null)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.grey200.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    if (isInCart) {
                      cartProvider.removeFromCart(item.linkedProduct!.id);
                    } else {
                      cartProvider.addToCart(
                        item.linkedProduct!,
                        quantity: item.quantity.toDouble(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${item.name} (x${item.quantity}) added to cart',
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isInCart ? Iconsax.tick_circle5 : Iconsax.bag_2,
                          size: 16,
                          color: isInCart ? AppColors.success : color,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          isInCart ? 'In Cart' : 'Add to Cart',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isInCart ? AppColors.success : color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionSection(
    List<Product> suggestions,
    ShoppingList list,
    Color color,
    String? authToken,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested from your recent orders',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
            itemBuilder: (context, index) {
              final product = suggestions[index];
              return _buildSuggestionCard(product, list, color, authToken);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(
    Product product,
    ShoppingList list,
    Color color,
    String? authToken,
  ) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            Formatters.formatCurrency(product.price),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await context.read<ShoppingListProvider>().addProductToList(
                list.id,
                product,
                authToken: authToken,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} added to ${list.name}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Center(
                child: Text(
                  'Add to list',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.clipboard_tick, size: 48, color: color),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Your list is empty',
              style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Add items to start building\nyour shopping list',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _addItem(
    String name,
    String? description,
    double? unitPrice,
    double? budgetAmount,
    ShoppingListProvider provider, {
    int quantity = 1,
    String? authToken,
  }) {
    if (name.trim().isNotEmpty) {
      // Try to find a matching product by exact name first, then partial match.
      final productProvider = context.read<ProductProvider>();
      final normalized = name.trim().toLowerCase();
      Product? matchingProduct;
      for (final product in productProvider.products) {
        if (product.name.toLowerCase() == normalized) {
          matchingProduct = product;
          break;
        }
      }
      matchingProduct ??= productProvider.products.cast<Product?>().firstWhere(
        (p) => p?.name.toLowerCase().contains(normalized) ?? false,
        orElse: () => null,
      );

      final item = ShoppingListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        description: description?.trim().isEmpty ?? true
            ? null
            : description?.trim(),
        quantity: quantity,
        unitPrice: unitPrice,
        budgetAmount: budgetAmount,
        linkedProduct: matchingProduct,
      );

      return provider.addItemToList(widget.listId, item, authToken: authToken);
    }

    return Future.value(false);
  }

  void _addAllToCart(ShoppingList list, CartProvider cartProvider) {
    int addedCount = 0;

    for (final item in list.items.where((i) => !i.isChecked)) {
      if (item.linkedProduct != null) {
        cartProvider.addToCart(
          item.linkedProduct!,
          quantity: item.quantity.toDouble(),
          specialInstructions: item.description,
        );
        addedCount += item.quantity;
      } else {
        final stubProduct = Product(
          id: 'custom_${item.id}',
          strapiId: null,
          name: item.name,
          description: item.description ?? '',
          image: '',
          price: item.unitPrice ?? 0,
          unit: item.unit ?? 'item',
          categoryId: '',
          categoryName: '',
          isAvailable: true,
        );
        cartProvider.addToCart(
          stubProduct,
          quantity: item.quantity.toDouble(),
          specialInstructions: item.description,
        );
        addedCount += item.quantity;
      }
    }

    String message = 'Added $addedCount items to cart';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Checkout',
          onPressed: () => GoRouter.of(context).go('/customer/checkout'),
        ),
      ),
    );
  }

  void _orderList(ShoppingList list, CartProvider cartProvider) {
    int linkedCount = 0;
    int freeTextCount = 0;

    // Include ALL unchecked items - both linked products and free-text
    for (final item in list.items.where((i) => !i.isChecked)) {
      if (item.linkedProduct != null) {
        // Linked item - use real product from catalog
        cartProvider.addToCart(
          item.linkedProduct!,
          quantity: item.quantity.toDouble(),
          specialInstructions: item.description,
        );
        linkedCount++;
      } else {
        // Free-text item - create stub product with null strapiId
        // This tells the backend: product_name only, no product relation
        final stubProduct = Product(
          id: 'custom_${item.id}',
          strapiId: null, // null = no backend product link
          name: item.name,
          description: item.description ?? '',
          image: '',
          price: item.unitPrice ?? 0,
          unit: item.unit ?? 'item',
          categoryId: '',
          categoryName: '',
          isAvailable: true,
        );
        cartProvider.addToCart(
          stubProduct,
          quantity: item.quantity.toDouble(),
          specialInstructions: item.description,
        );
        freeTextCount++;
      }
    }

    final total = linkedCount + freeTextCount;
    if (total > 0) {
      // Show shopper guidance note if there are free-text items
      if (freeTextCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$freeTextCount item${freeTextCount != 1 ? 's' : ''} as shopper guidance',
            ),
            backgroundColor: AppColors.accent.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      GoRouter.of(context).go('/customer/checkout');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('List is empty'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      );
    }
  }

  void _showOptionsMenu(BuildContext context, ShoppingList list) {
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
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSizes.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              ListTile(
                leading: const Icon(Iconsax.edit, color: AppColors.textPrimary),
                title: const Text('Edit List'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditListSheet(list);
                },
              ),
              ListTile(
                leading: const Icon(
                  Iconsax.share,
                  color: AppColors.textPrimary,
                ),
                title: const Text('Share via WhatsApp'),
                onTap: () {
                  Navigator.pop(context);
                  final items = list.items
                      .asMap()
                      .entries
                      .map((e) {
                        final i = e.value;
                        final qty = i.quantity % 1 == 0
                            ? i.quantity.toInt().toString()
                            : i.quantity.toString();
                        final unit = i.unit != null ? ' ${i.unit}' : '';
                        return '${e.key + 1}. ${i.name} — $qty$unit';
                      })
                      .join('\n');
                  final checked = list.items.where((i) => i.isChecked).length;
                  final total = list.items.length;
                  final progress = total > 0 ? '($checked/$total done)\n' : '';
                  final text =
                      '🛒 *${list.name}*\n$progress\n$items\n\n— Shared via *LipaCart*\n📲 lipacart.com';
                  launchUrl(
                    Uri.parse(
                      'https://wa.me/?text=${Uri.encodeComponent(text)}',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.trash, color: AppColors.error),
                title: Text(
                  'Delete List',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(list);
                },
              ),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Text('Delete List?'),
        content: Text('Are you sure you want to delete "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final authToken = context.read<AuthProvider>().token;
                await context.read<ShoppingListProvider>().deleteList(
                  list.id,
                  authToken: authToken,
                );
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);
              } catch (_) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete list. Please try again.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
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
                        await context.read<ShoppingListProvider>().updateList(
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

                        if (!mounted) return;
                        Navigator.pop(context);
                      } catch (_) {
                        if (!mounted) return;
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

  void _showProductSearchDialog(ShoppingList list, Color color) {
    final searchController = TextEditingController();
    final productProvider = context.read<ProductProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final query = searchController.text.toLowerCase();
          final products = query.isEmpty
              ? productProvider.products.take(20).toList()
              : productProvider.products
                    .where((p) => p.name.toLowerCase().contains(query))
                    .take(20)
                    .toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Add from Catalog',
                        style: AppTextStyles.h5.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: Icon(
                            Iconsax.search_normal_1,
                            color: color,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.grey300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: color, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ],
                  ),
                ),
                // Product list
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Text(
                            query.isEmpty
                                ? 'Loading products...'
                                : 'No products found',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: products.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (ctx, index) {
                            final product = products[index];
                            return ListTile(
                              leading: product.image.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product.image,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Iconsax.box_1,
                                            color: color,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Iconsax.box_1,
                                        color: color,
                                        size: 24,
                                      ),
                                    ),
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                Formatters.formatCurrency(product.price),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Iconsax.add_circle, color: color),
                                onPressed: () {
                                  // Show description dialog before adding
                                  final noteController =
                                      TextEditingController();
                                  final qtyController = TextEditingController(
                                    text: '1',
                                  );
                                  showDialog(
                                    context: ctx,
                                    builder: (dialogCtx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text('Add ${product.name}'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: qtyController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Quantity',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: noteController,
                                            maxLines: 2,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            decoration: InputDecoration(
                                              labelText: 'Note (optional)',
                                              hintText:
                                                  'e.g. ripe ones, yellow, 1kg pack...',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dialogCtx),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(dialogCtx);
                                            final qty =
                                                int.tryParse(
                                                  qtyController.text,
                                                ) ??
                                                1;
                                            final note = noteController.text
                                                .trim();
                                            final item = ShoppingListItem(
                                              id: DateTime.now()
                                                  .millisecondsSinceEpoch
                                                  .toString(),
                                              name: product.name,
                                              quantity: qty,
                                              unit: product.unit,
                                              unitPrice: product.price,
                                              description: note.isNotEmpty
                                                  ? note
                                                  : null,
                                              linkedProduct: product,
                                            );
                                            context
                                                .read<ShoppingListProvider>()
                                                .addItemToList(
                                                  list.id,
                                                  item,
                                                  authToken: context
                                                      .read<AuthProvider>()
                                                      .token,
                                                );
                                            setModalState(() {});
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${product.name} added to list',
                                                ),
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                                backgroundColor:
                                                    AppColors.success,
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: color,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddOptions(ShoppingList list, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Item',
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.edit_2, color: color),
                ),
                title: const Text(
                  'Custom Item',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Type in any item you need'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddItemDialog(list, color);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.search_normal_1, color: color),
                ),
                title: const Text(
                  'From Catalog',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Browse products with prices'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showProductSearchDialog(list, color);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog(ShoppingList list, Color color) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final budgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(Iconsax.add_circle, color: color, size: 22),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              'Add Item',
              style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item Name',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Fresh Milk, Bananas, Bread...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(AppSizes.md),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'Quantity',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g., 2',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          borderSide: BorderSide(color: color, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(AppSizes.md),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'Expected Price Per Item (Optional)',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 2500',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixText: 'UGX ',
                  prefixStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(AppSizes.md),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'Budget Amount (Optional)',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 5000',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixText: 'UGX ',
                  prefixStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(AppSizes.md),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Expanded(
                    child: Text(
                      'Specify a budget amount instead of exact quantity',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'Special Instructions (Optional)',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'e.g., "Ripe, ready to eat", "Full cream", "Sliced"...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(AppSizes.md),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Expanded(
                    child: Text(
                      'Help your shopper pick exactly what you want',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            onPressed: () async {
              final name = nameController.text.trim();
              final quantityText = quantityController.text.trim();
              final description = descriptionController.text.trim();
              final priceText = priceController.text.trim();
              final budgetText = budgetController.text.trim();
              final quantity = int.tryParse(quantityText) ?? 1;
              final unitPrice = priceText.isEmpty
                  ? null
                  : double.tryParse(priceText);
              final budgetAmount = budgetText.isEmpty
                  ? null
                  : double.tryParse(budgetText);
              final authToken = context.read<AuthProvider>().token;

              if (name.isNotEmpty) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AppLoadingPage(),
                );

                try {
                  final mergedDuplicate = await _addItem(
                    name,
                    description.isEmpty ? null : description,
                    unitPrice,
                    budgetAmount,
                    context.read<ShoppingListProvider>(),
                    quantity: quantity,
                    authToken: authToken,
                  );
                  if (!context.mounted) return;

                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        mergedDuplicate
                            ? 'Updated quantity for "$name"'
                            : 'Added "$name" to list',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to add item. Please try again.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Text(
                'Add to List',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(
    ShoppingListItem item,
    ShoppingList list,
    Color color,
  ) {
    final nameController = TextEditingController(text: item.name);
    final qtyController = TextEditingController(text: '${item.quantity}');
    final noteController = TextEditingController(text: item.description ?? '');
    final priceController = TextEditingController(
      text: item.unitPrice != null ? '${item.unitPrice!.toInt()}' : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.edit_2, color: color, size: 22),
            const SizedBox(width: 8),
            const Text('Edit item & note'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, size: 18, color: color),
                        const SizedBox(width: 8),
                        Text(
                          'Shopping note',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      minLines: 3,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'What should the shopper look for?',
                        hintText:
                            'e.g. ripe ones, yellow, 1kg pack, low sugar...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add preferences like brand, size, or ripeness so the right item is picked.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Qty',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price (UGX)',
                        prefixText: 'UGX ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<ShoppingListProvider>();
              final authToken = context.read<AuthProvider>().token;
              final newName = nameController.text.trim();
              final newQty = int.tryParse(qtyController.text) ?? item.quantity;
              final newNote = noteController.text.trim();
              final priceText = priceController.text.trim();
              final newPrice = priceText.isEmpty
                  ? null
                  : double.tryParse(priceText);

              if (newName.isEmpty) return;

              Navigator.pop(ctx);

              final updatedItem = item.copyWith(
                name: newName,
                quantity: newQty,
                unitPrice: newPrice,
                description: newNote.isNotEmpty ? newNote : null,
              );
              await provider.updateItem(
                list.id,
                item.id,
                updatedItem,
                authToken: authToken,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDescriptionDialog(ShoppingListItem item, ShoppingList list) {
    final descriptionController = TextEditingController(
      text: item.description ?? '',
    );
    final color = _parseColor(list.color);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text(
          (item.description?.trim().isNotEmpty ?? false)
              ? 'Edit shopping note'
              : 'Add shopping note',
          style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                'Add preferences like brand, size, ripeness, or pack type.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              TextField(
                controller: descriptionController,
                minLines: 3,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Note for shopper',
                  hintText:
                      'e.g., "Ripe bananas", "Low fat", "2cm thick slices"...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(AppSizes.md),
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'These notes stay visible while shopping so it is easier to pick the right item.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
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
          if (item.description != null && item.description!.isNotEmpty)
            TextButton(
              onPressed: () {
                final authToken = context.read<AuthProvider>().token;
                context.read<ShoppingListProvider>().updateItemDescription(
                  list.id,
                  item.id,
                  null,
                  authToken: authToken,
                );
                Navigator.pop(context);
              },
              child: Text(
                'Clear',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          TextButton(
            onPressed: () {
              final description = descriptionController.text.trim();
              final authToken = context.read<AuthProvider>().token;
              context.read<ShoppingListProvider>().updateItemDescription(
                list.id,
                item.id,
                description.isEmpty ? null : description,
                authToken: authToken,
              );
              Navigator.pop(context);
            },
            child: Text(
              'Save note',
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
