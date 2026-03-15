import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../models/shopping_list.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_loading_indicator.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.minQuantity.toInt();
  }

  void _incrementQuantity() {
    if (_quantity < widget.product.maxQuantity) {
      setState(() => _quantity++);
    }
  }

  void _decrementQuantity() {
    if (_quantity > widget.product.minQuantity) {
      setState(() => _quantity--);
    }
  }

  void _addToList(Product product) {
    final listProvider = context.read<ShoppingListProvider>();
    final authToken = context.read<AuthProvider>().token;
    final lists = listProvider.lists;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add to Shopping List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (lists.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('No lists yet', style: TextStyle(color: Colors.grey[500])),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/customer/shopping-lists');
                        },
                        child: const Text('Create a list'),
                      ),
                    ],
                  ),
                )
              else
                ...lists.map((list) => ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse('FF${list.color.replaceAll('#', '')}', radix: 16)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(list.emoji ?? '🛒', style: const TextStyle(fontSize: 18))),
                  ),
                  title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${list.totalItems} items'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final item = ShoppingListItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: product.name,
                      quantity: 1,
                      unit: product.unit,
                      unitPrice: product.price,
                      linkedProduct: product,
                    );
                    listProvider.addItemToList(list.id, item, authToken: authToken);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to ${list.name}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                )),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart() {
    final cartProvider = context.read<CartProvider>();
    cartProvider.addToCart(widget.product, quantity: _quantity.toDouble());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getProductBgColor() {
    // Return a color based on category for visual variety
    final category = widget.product.categoryName.toLowerCase();
    if (category.contains('fruit')) return const Color(0xFFFFF3C7);
    if (category.contains('vegetable')) return const Color(0xFFE8F5E9);
    if (category.contains('meat')) return const Color(0xFFFFEBEE);
    if (category.contains('dairy')) return const Color(0xFFE3F2FD);
    if (category.contains('bakery')) return const Color(0xFFFFF8E1);
    return const Color(0xFFFFF8E1); // Default warm yellow
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final productProvider = context.watch<ProductProvider>();
    final isInCart = cartProvider.isInCart(widget.product.id);
    final totalPrice = widget.product.price * _quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Section
                  Container(
                    height: 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _getProductBgColor(),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Stack(
                        children: [
                          // Product Image
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.xl),
                              child: CachedNetworkImage(
                                imageUrl: widget.product.image,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: AppLoadingIndicator.small(),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Iconsax.image,
                                  size: 64,
                                  color: AppColors.grey400,
                                ),
                              ),
                            ),
                          ),
                          // Back Button
                          Positioned(
                            top: AppSizes.sm,
                            left: AppSizes.md,
                            child: GestureDetector(
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
                                  shape: BoxShape.circle,
                                  boxShadow: AppColors.shadowSm,
                                ),
                                child: const Icon(
                                  Iconsax.arrow_left,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // Favorite Button
                          Positioned(
                            top: AppSizes.sm,
                            right: AppSizes.md,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isFavorite = !_isFavorite),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: AppColors.shadowSm,
                                ),
                                child: Icon(
                                  _isFavorite ? Iconsax.heart5 : Iconsax.heart,
                                  size: 20,
                                  color: _isFavorite
                                      ? AppColors.heartActive
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Product Info Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSizes.radiusXl),
                      ),
                    ),
                    transform: Matrix4.translationValues(0, -24, 0),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and Price Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product.name,
                                      style: AppTextStyles.h4.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'per ${widget.product.unit}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(widget.product.price),
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),

                          // Tags Row
                          Row(
                            children: [
                              _buildTag(
                                icon: Iconsax.verify,
                                label: 'Fresh',
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              _buildTag(
                                icon: Icons.star_rounded,
                                label:
                                    '${widget.product.rating} (${widget.product.reviewCount})',
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              _buildTag(
                                icon: Iconsax.tick_circle,
                                label: widget.product.isAvailable
                                    ? 'In Stock'
                                    : 'Out of Stock',
                                color: widget.product.isAvailable
                                    ? AppColors.primary
                                    : AppColors.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.lg),

                          // About Section
                          Text(
                            'About',
                            style: AppTextStyles.h5.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            widget.product.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),

                          // Delivery Info Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildDeliveryCard(
                                  icon: Iconsax.truck_fast,
                                  title: 'Free Delivery',
                                  subtitle: 'Orders above UGX 50,000',
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: _buildDeliveryCard(
                                  icon: Iconsax.clock,
                                  title: 'Fast Delivery',
                                  subtitle: 'Within 45-60 minutes',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.lg),

                          // Quantity Section
                          Text(
                            'Quantity',
                            style: AppTextStyles.h5.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          Row(
                            children: [
                              // Quantity Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusMd),
                                ),
                                child: Row(
                                  children: [
                                    _buildQuantityButton(
                                      icon: Iconsax.minus,
                                      onTap: _decrementQuantity,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSizes.lg,
                                      ),
                                      child: Text(
                                        _quantity.toString(),
                                        style: AppTextStyles.h5.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _buildQuantityButton(
                                      icon: Iconsax.add,
                                      onTap: _incrementQuantity,
                                      isAdd: true,
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Total Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(totalPrice),
                                    style: AppTextStyles.h5.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.xl),

                          // You May Also Like Section
                          Text(
                            'You May Also Like',
                            style: AppTextStyles.h5.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: productProvider.products.length > 5
                                  ? 5
                                  : productProvider.products.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSizes.sm),
                              itemBuilder: (context, index) {
                                final relatedProduct =
                                    productProvider.products[index];
                                if (relatedProduct.id == widget.product.id) {
                                  return const SizedBox.shrink();
                                }
                                return _buildRelatedProductCard(relatedProduct);
                              },
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Total Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Price',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(totalPrice),
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add to Cart Button & Add to List
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _addToCart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.xl,
                            vertical: AppSizes.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isInCart ? Iconsax.tick_circle5 : Iconsax.bag_2,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text(
                                isInCart ? 'Update Cart' : 'Add to Cart',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _addToList(widget.product),
                        icon: const Icon(Iconsax.clipboard_text, size: 16),
                        label: const Text('Add to List'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isAdd = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isAdd ? AppColors.grey300 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildRelatedProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusMd),
                ),
                child: CachedNetworkImage(
                  imageUrl: product.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: AppColors.grey100,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.grey100,
                    child: Icon(
                      Iconsax.image,
                      color: AppColors.grey400,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.xs),
              child: Text(
                product.name,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
