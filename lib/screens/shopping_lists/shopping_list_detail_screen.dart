import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/shopping_list.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_bottom_nav.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final String listId;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
  });

  @override
  State<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  final TextEditingController _itemController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ShoppingListProvider>();
    final cartProvider = context.watch<CartProvider>();
    final list = listProvider.getListById(widget.listId);

    if (list == null) {
      return Scaffold(
        bottomNavigationBar: const AppBottomNav(currentIndex: 0),
        body: Center(
          child: Text('List not found'),
        ),
      );
    }

    final color = _parseColor(list.color);
    final uncheckedItems = list.items.where((i) => !i.isChecked).toList();
    final checkedItems = list.items.where((i) => i.isChecked).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.elegantBgGradient,
        ),
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
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMd),
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
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMd),
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
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
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
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.lg),
                      // Progress
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${list.checkedItems} of ${list.totalItems} items',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${(list.progress * 100).toInt()}%',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.xs),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: list.progress,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.3),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                  : ListView(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      children: [
                        // Unchecked items
                        if (uncheckedItems.isNotEmpty) ...[
                          Text(
                            'TO BUY',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          ...uncheckedItems.map(
                            (item) => _buildItemCard(item, list, color),
                          ),
                        ],
                        // Checked items
                        if (checkedItems.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.lg),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'COMPLETED',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => listProvider
                                    .clearCheckedItems(widget.listId),
                                child: Text(
                                  'Clear all',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.sm),
                          ...checkedItems.map(
                            (item) => _buildItemCard(item, list, color),
                          ),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
            ),
          ],
        ),
      ),
      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Add item field
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      hintText: 'Add an item...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.md,
                      ),
                    ),
                    onSubmitted: (value) => _addItem(value, listProvider),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              // Add button
              GestureDetector(
                onTap: () => _addItem(_itemController.text, listProvider),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(
                    Iconsax.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              // Add all to cart
              if (list.purchasableItems.isNotEmpty)
                GestureDetector(
                  onTap: () => _addAllToCart(list, cartProvider),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.bag_2,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          'Add All',
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
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
      ShoppingListItem item, ShoppingList list, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => context
                .read<ShoppingListProvider>()
                .toggleItemChecked(list.id, item.id),
            child: Container(
              width: 60,
              height: 70,
              decoration: BoxDecoration(
                color: item.isChecked
                    ? AppColors.success.withValues(alpha: 0.1)
                    : color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSizes.radiusLg),
                ),
              ),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color:
                        item.isChecked ? AppColors.success : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.isChecked ? AppColors.success : color,
                      width: 2,
                    ),
                  ),
                  child: item.isChecked
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ),
            ),
          ),
          // Item info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  // Product image if linked
                  if (item.linkedProduct != null) ...[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        child: CachedNetworkImage(
                          imageUrl: item.linkedProduct!.image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.grey100,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.grey100,
                            child: const Icon(
                              Iconsax.image,
                              color: AppColors.grey400,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isChecked
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${item.quantity} ${item.unit ?? ''}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (item.linkedProduct != null) ...[
                              const SizedBox(width: AppSizes.sm),
                              Text(
                                Formatters.formatCurrency(
                                    item.linkedProduct!.price),
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
                ],
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
                    onTap: () {
                      if (item.quantity > 1) {
                        context.read<ShoppingListProvider>().updateItemQuantity(
                              list.id,
                              item.id,
                              item.quantity - 1,
                            );
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
                      context.read<ShoppingListProvider>().updateItemQuantity(
                            list.id,
                            item.id,
                            item.quantity + 1,
                          );
                    },
                  ),
                ],
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
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
              child: Icon(
                Iconsax.clipboard_tick,
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Your list is empty',
              style: AppTextStyles.h5.copyWith(
                fontWeight: FontWeight.w600,
              ),
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

  void _addItem(String value, ShoppingListProvider provider) {
    if (value.trim().isNotEmpty) {
      // Try to find a matching product
      final productProvider = context.read<ProductProvider>();
      final matchingProduct = productProvider.products.firstWhere(
        (p) => p.name.toLowerCase().contains(value.toLowerCase()),
        orElse: () => productProvider.products.first,
      );

      final item = ShoppingListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: value.trim(),
        quantity: 1,
        linkedProduct:
            matchingProduct.name.toLowerCase().contains(value.toLowerCase())
                ? matchingProduct
                : null,
      );

      provider.addItemToList(widget.listId, item);
      _itemController.clear();
    }
  }

  void _addAllToCart(ShoppingList list, CartProvider cartProvider) {
    int addedCount = 0;
    for (final item in list.purchasableItems) {
      if (item.linkedProduct != null) {
        for (int i = 0; i < item.quantity; i++) {
          cartProvider.addToCart(item.linkedProduct!);
        }
        addedCount++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $addedCount items to cart'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
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
                  // TODO: Show edit sheet
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.share, color: AppColors.textPrimary),
                title: const Text('Share List'),
                onTap: () {
                  Navigator.pop(context);
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
            onPressed: () {
              context.read<ShoppingListProvider>().deleteList(list.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
