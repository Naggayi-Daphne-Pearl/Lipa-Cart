import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/shopping_list.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_bottom_nav.dart';

class ShoppingListsScreen extends StatefulWidget {
  final bool showBottomNav;

  const ShoppingListsScreen({super.key, this.showBottomNav = true});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShoppingListProvider>().loadLists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingListProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(currentIndex: 2)
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                            style: AppTextStyles.h4.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${provider.lists.length} lists',
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

              // Lists
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : provider.lists.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg,
                        ),
                        itemCount: provider.lists.length,
                        itemBuilder: (context, index) {
                          final list = provider.lists[index];
                          return _buildListCard(list);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }

  Widget _buildListCard(ShoppingList list) {
    final color = _parseColor(list.color);

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
              child: Row(
                children: [
                  // Progress indicator
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              list.isComplete
                                  ? Iconsax.tick_circle5
                                  : Iconsax.task_square,
                              color: list.isComplete
                                  ? AppColors.success
                                  : color,
                              size: 16,
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Text(
                              '${list.checkedItems}/${list.totalItems} items',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xs),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: list.progress,
                            backgroundColor: AppColors.grey100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              list.isComplete ? AppColors.success : color,
                            ),
                            minHeight: 4,
                          ),
                        ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
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
            Text(
              'No Shopping Lists Yet',
              style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Create your first shopping list to start\norganizing your groceries',
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
          ],
        ),
      ),
    );
  }

  void _showCreateListSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedEmoji = '🛒';
    String selectedColor = ShoppingListProvider.listColors[0];

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
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        context.read<ShoppingListProvider>().createList(
                          name: nameController.text,
                          description: descController.text.isEmpty
                              ? null
                              : descController.text,
                          emoji: selectedEmoji,
                          color: selectedColor,
                        );
                        Navigator.pop(context);
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () {
              context.read<ShoppingListProvider>().deleteList(list.id);
              Navigator.pop(context);

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${list.name}"'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
        addedCount++;
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
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            context.go('/customer/cart');
          },
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
