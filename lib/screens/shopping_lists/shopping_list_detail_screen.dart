import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
import '../../widgets/app_bottom_nav.dart';

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
    final authToken = context.watch<AuthProvider>().token;
    final list = listProvider.getListById(widget.listId);

    if (list == null) {
      return Scaffold(
        bottomNavigationBar: const AppBottomNav(currentIndex: 2),
        body: Center(child: Text('List not found')),
      );
    }

    final color = _parseColor(list.color);
    final uncheckedItems = list.items.where((i) => !i.isChecked).toList();
    final checkedItems = list.items.where((i) => i.isChecked).toList();
    final actionableItems = uncheckedItems;

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
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
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
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.3,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
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
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),

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
                            (item) =>
                                _buildItemCard(item, list, color, authToken),
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
                                onTap: () => listProvider.clearCheckedItems(
                                  widget.listId,
                                  authToken: authToken,
                                ),
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
                            (item) =>
                                _buildItemCard(item, list, color, authToken),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Add item button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showAddItemDialog(list, color),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: AppSizes.md),
                            Icon(Iconsax.add_circle, color: color, size: 22),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              'Add Item',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Order buttons (for all unchecked items)
              if (actionableItems.isNotEmpty) ...[
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    // Add to Cart (secondary)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _addAllToCart(list, cartProvider),
                        child: Container(
                          height: 52,
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.bag_2, size: 18),
                              const SizedBox(width: AppSizes.xs),
                              Text(
                                'Add to Cart',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    // Order This List (primary)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _orderList(list, cartProvider),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.shopping_cart,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: AppSizes.xs),
                              Text(
                                'Order Now',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: Colors.white,
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
              ],
            ],
          ),
        ),
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

    return Container(
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
              // Checkbox
              GestureDetector(
                onTap: () => context
                    .read<ShoppingListProvider>()
                    .toggleItemChecked(
                      list.id,
                      item.id,
                      authToken: authToken,
                    ),
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
                        color: item.isChecked
                            ? AppColors.success
                            : Colors.transparent,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
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
                          ),
                          if (!item.isChecked)
                            GestureDetector(
                              onTap: () =>
                                  _showEditDescriptionDialog(item, list),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  item.description != null &&
                                          item.description!.isNotEmpty
                                      ? Iconsax.document_text5
                                      : Iconsax.document_text,
                                  size: 16,
                                  color:
                                      item.description != null &&
                                          item.description!.isNotEmpty
                                      ? color
                                      : AppColors.grey400,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (item.budgetAmount != null) ...[
                            Icon(
                              Iconsax.wallet_3,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
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
                            const SizedBox(width: AppSizes.sm),
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
                            if (item.linkedProduct != null) ...[
                              const SizedBox(width: AppSizes.sm),
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
                        ],
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
                            context
                                .read<ShoppingListProvider>()
                                .updateItemQuantity(
                                  list.id,
                                  item.id,
                                  item.quantity - 1,
                                  authToken: authToken,
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
                      const SizedBox(width: AppSizes.xs),
                      GestureDetector(
                        onTap: () {
                          context.read<ShoppingListProvider>().removeItemFromList(
                            list.id,
                            item.id,
                            authToken: authToken,
                          );
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Iconsax.trash,
                            size: 14,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (item.isChecked)
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.sm),
                  child: GestureDetector(
                    onTap: () {
                      context.read<ShoppingListProvider>().removeItemFromList(
                        list.id,
                        item.id,
                        authToken: authToken,
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Iconsax.trash,
                        size: 14,
                        color: AppColors.error,
                      ),
                    ),
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
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
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

      return provider.addItemToList(
        widget.listId,
        item,
        authToken: authToken,
      );
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
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
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
          'Add Notes',
          style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Column(
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
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
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
              'Help your shopper get exactly what you want',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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
                'Remove',
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
              'Save',
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
