import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/recipe.dart';
import '../../models/shopping_list.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../widgets/app_bottom_nav.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedIngredients = {};
  bool _selectAll = true;
  double _servingsMultiplier = 1.0;
  bool _hideAlreadyOwned = false;
  bool _keepScreenOnWhileCooking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final cartProvider = context.watch<CartProvider>();
    final recipe = recipeProvider.getRecipeById(widget.recipeId);

    if (recipe == null) {
      return Scaffold(
        bottomNavigationBar: const AppBottomNav(currentIndex: 0),
        body: Center(child: Text('Recipe not found')),
      );
    }

    // Initialize selected ingredients
    if (_selectedIngredients.isEmpty && _selectAll) {
      _selectedIngredients.addAll(
        recipe.purchasableIngredients.map((i) => i.id),
      );
    }

    final adjustedServings = (recipe.servings * _servingsMultiplier).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/customer/home');
                }
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.shadowSm,
                ),
                child: const Icon(
                  Iconsax.arrow_left,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  final ingredients = recipe.ingredients.asMap().entries
                      .map((e) => '${e.key + 1}. ${e.value.name} — ${e.value.quantity}')
                      .join('\n');
                  final text = '🍳 *${recipe.name}*\n\n'
                      '⏱ Prep: ${recipe.prepTime} min • Cook: ${recipe.cookTime} min • Serves ${recipe.servings}\n\n'
                      '*Ingredients:*\n$ingredients\n\n'
                      '— Shared via *LipaCart*\n📲 lipacart.com';
                  launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'));
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: const Icon(Iconsax.share, color: AppColors.grey400, size: 20),
                ),
              ),
              GestureDetector(
                onTap: () => recipeProvider.toggleFavorite(recipe.id),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Icon(
                    recipe.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                    color: recipe.isFavorite
                        ? AppColors.error
                        : AppColors.grey400,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: recipe.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppColors.grey100),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.grey100,
                      child: const Icon(
                        Iconsax.image,
                        size: 64,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                  // Bottom info badges
                  Positioned(
                    bottom: AppSizes.lg,
                    left: AppSizes.lg,
                    right: AppSizes.lg,
                    child: Row(
                      children: [
                        _buildInfoBadge(
                          icon: Iconsax.clock,
                          label: '${recipe.totalTime} min',
                        ),
                        const SizedBox(width: AppSizes.sm),
                        _buildInfoBadge(
                          icon: Iconsax.people,
                          label: '$adjustedServings servings',
                        ),
                        const SizedBox(width: AppSizes.sm),
                        _buildInfoBadge(
                          icon: Iconsax.chart,
                          label: recipe.difficulty,
                          color: _getDifficultyColor(recipe.difficulty),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusXl),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags
                        Wrap(
                          spacing: AppSizes.xs,
                          runSpacing: AppSizes.xs,
                          children: recipe.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSizes.md),

                        // Title and rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                recipe.name,
                                style: AppTextStyles.h3.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: AppSizes.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe.rating.toString(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),

                        // Description
                        Text(
                          recipe.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),

                        // Servings adjuster
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Servings:',
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              GestureDetector(
                                onTap: () {
                                  if (_servingsMultiplier > 0.5) {
                                    setState(() {
                                      _servingsMultiplier -= 0.5;
                                    });
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.grey300),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.remove, size: 18),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.md,
                                ),
                                child: Text(
                                  '$adjustedServings',
                                  style: AppTextStyles.h5.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _servingsMultiplier += 0.5;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.grey300),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),

                        // Author
                        if (recipe.authorName != null)
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Iconsax.user,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.authorName!,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${recipe.reviewCount} reviews',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.grey200, width: 1),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.accent,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.accent,
                      indicatorWeight: 3,
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.shopping_bag, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Ingredients (${recipe.ingredients.length})',
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.document_text, size: 18),
                              const SizedBox(width: 8),
                              Text('Steps (${recipe.instructions.length})'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab content
          SliverFillRemaining(
            child: Container(
              color: AppColors.surface,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Ingredients tab
                  _buildIngredientsTab(recipe),
                  // Instructions tab
                  _buildInstructionsTab(recipe),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom bar with add to cart, add to list, and order now
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
              // Price estimate
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Cost',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(
                        _calculateSelectedCost(recipe) * _servingsMultiplier,
                      ),
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
              // Three buttons: Add to Cart, Add to List, Order
              Row(
                children: [
                  // Add to Cart (secondary)
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectedIngredients.isEmpty
                          ? null
                          : () => _addSelectedToCart(recipe, cartProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedIngredients.isEmpty
                              ? AppColors.grey200
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(
                            color: _selectedIngredients.isEmpty
                                ? AppColors.grey300
                                : AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.bag_2, size: 18),
                            const SizedBox(width: AppSizes.xs),
                            Text(
                              'Cart',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _selectedIngredients.isEmpty
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  // Add to List
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectedIngredients.isEmpty
                          ? null
                          : () => _addToShoppingList(recipe),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedIngredients.isEmpty
                              ? AppColors.grey200
                              : AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(
                            color: _selectedIngredients.isEmpty
                                ? AppColors.grey300
                                : AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.note_2,
                              size: 18,
                              color: _selectedIngredients.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.accent,
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Text(
                              'List',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _selectedIngredients.isEmpty
                                    ? AppColors.textSecondary
                                    : AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  // Order Ingredients (primary)
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectedIngredients.isEmpty
                          ? null
                          : () => _showOrderReview(recipe, cartProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedIngredients.isEmpty
                              ? AppColors.grey400
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.shopping_cart,
                                color: Colors.white, size: 18),
                            const SizedBox(width: AppSizes.xs),
                            Text(
                              'Order',
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
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color != null ? Colors.white : AppColors.textPrimary,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color != null ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _adjustQuantity(String quantityStr) {
    if (_servingsMultiplier == 1.0) return quantityStr;

    final match = RegExp(r'(\d+\.?\d*)').firstMatch(quantityStr);
    if (match != null) {
      final original = double.tryParse(match.group(1)!) ?? 1.0;
      final adjusted = original * _servingsMultiplier;
      final adjustedStr = adjusted == adjusted.roundToDouble()
          ? adjusted.round().toString()
          : adjusted.toStringAsFixed(1);
      return quantityStr.replaceFirst(match.group(1)!, adjustedStr);
    }
    return quantityStr;
  }

  Widget _buildIngredientsTab(Recipe recipe) {
    final visibleIngredients = _hideAlreadyOwned
        ? recipe.ingredients
              .where((ingredient) => _selectedIngredients.contains(ingredient.id))
              .toList()
        : recipe.ingredients;

    return ListView(
      padding: const EdgeInsets.all(AppSizes.lg),
      children: [
        SwitchListTile.adaptive(
          value: _hideAlreadyOwned,
          onChanged: (v) => setState(() => _hideAlreadyOwned = v),
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Hide what I already have',
            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Only show ingredients you plan to buy',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        // Select all toggle
        Row(
          children: [
            Text(
              'SELECT INGREDIENTS',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectAll) {
                    _selectedIngredients.clear();
                  } else {
                    _selectedIngredients.addAll(
                      recipe.purchasableIngredients.map((i) => i.id),
                    );
                  }
                  _selectAll = !_selectAll;
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _selectAll
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _selectAll
                            ? AppColors.primary
                            : AppColors.grey300,
                        width: 2,
                      ),
                    ),
                    child: _selectAll
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    'Select All',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        // Ingredients list
        ...visibleIngredients.map((ingredient) {
          final isSelectable = ingredient.linkedProduct != null;
          final isSelected = _selectedIngredients.contains(ingredient.id);

          return Container(
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primarySoft : AppColors.grey50,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey200,
                width: 1,
              ),
            ),
            child: ListTile(
              leading: isSelectable
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIngredients.remove(ingredient.id);
                            _selectAll = false;
                          } else {
                            _selectedIngredients.add(ingredient.id);
                            if (_selectedIngredients.length ==
                                recipe.purchasableIngredients.length) {
                              _selectAll = true;
                            }
                          }
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.grey300,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Iconsax.close_circle,
                        color: AppColors.grey400,
                        size: 16,
                      ),
                    ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (ingredient.isOptional)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Optional',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Row(
                children: [
                  Text(
                    _adjustQuantity(ingredient.quantity),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (ingredient.linkedProduct != null) ...[
                    const Spacer(),
                    Text(
                      Formatters.formatCurrency(
                        ingredient.linkedProduct!.price * _servingsMultiplier,
                      ),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: ingredient.linkedProduct != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: ingredient.linkedProduct!.image,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.grey100,
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.grey100,
                          child: const Icon(
                            Iconsax.image,
                            size: 20,
                            color: AppColors.grey400,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          );
        }),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildInstructionsTab(Recipe recipe) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.lg),
      children: [
        SwitchListTile.adaptive(
          value: _keepScreenOnWhileCooking,
          onChanged: (v) {
            setState(() => _keepScreenOnWhileCooking = v);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  v
                      ? 'Keep screen on enabled for cooking session'
                      : 'Keep screen on disabled',
                ),
              ),
            );
          },
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Keep screen on while cooking',
            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        ...recipe.instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final durationMatch = RegExp(r'(\d+)\s*(minute|minutes|min)').firstMatch(step.toLowerCase());

          return Container(
            margin: const EdgeInsets.only(bottom: AppSizes.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step,
                          style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.6,
                            fontSize: 16,
                          ),
                        ),
                        if (durationMatch != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Timer started for ${durationMatch.group(1)} minutes'),
                                ),
                              );
                            },
                            icon: const Icon(Iconsax.timer_1, size: 14),
                            label: Text('Set ${durationMatch.group(1)} min timer'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  double _calculateSelectedCost(Recipe recipe) {
    double total = 0;
    for (final ingredient in recipe.ingredients) {
      if (_selectedIngredients.contains(ingredient.id) &&
          ingredient.linkedProduct != null) {
        total += ingredient.linkedProduct!.price;
      }
    }
    return total;
  }

  double _extractQuantityFromString(String quantityStr) {
    // Extract numeric part from strings like "2 cups", "500g", "3 pieces"
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(quantityStr);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 1.0;
    }
    return 1.0; // Default to 1 if no number found
  }

  void _addSelectedToCart(Recipe recipe, CartProvider cartProvider) {
    int addedCount = 0;
    int skippedCount = 0;

    for (final ingredient in recipe.ingredients) {
      if (_selectedIngredients.contains(ingredient.id)) {
        if (ingredient.linkedProduct != null) {
          // Extract numeric quantity from ingredient quantity string
          final quantity = _extractQuantityFromString(ingredient.quantity) *
              _servingsMultiplier;
          cartProvider.addToCart(ingredient.linkedProduct!, quantity: quantity);
          addedCount++;
        } else {
          skippedCount++;
        }
      }
    }

    String message =
        'Added $addedCount ingredient${addedCount != 1 ? 's' : ''} to cart';
    if (skippedCount > 0) {
      message += ' ($skippedCount unavailable)';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.accent;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _addToShoppingList(Recipe recipe) {
    final listProvider = context.read<ShoppingListProvider>();
    final lists = listProvider.lists;

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
                'Add to Shopping List',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              if (lists.isEmpty)
                Text(
                  'No shopping lists yet. Create one first.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...lists.map(
                  (list) => ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(
                            'FF${list.color.replaceAll('#', '')}',
                            radix: 16,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          list.emoji ?? '\u{1F6D2}',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    title: Text(list.name),
                    subtitle: Text('${list.totalItems} items'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _addIngredientsToList(recipe, list.id);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addIngredientsToList(Recipe recipe, String listId) {
    final listProvider = context.read<ShoppingListProvider>();
    final authToken = context.read<AuthProvider>().token;
    int added = 0;

    for (final ingredient in recipe.ingredients) {
      if (_selectedIngredients.contains(ingredient.id)) {
        final item = ShoppingListItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_$added',
          name: ingredient.name,
          quantity: 1,
          unit: _adjustQuantity(ingredient.quantity),
          linkedProduct: ingredient.linkedProduct,
          unitPrice: ingredient.linkedProduct?.price,
        );
        listProvider.addItemToList(listId, item, authToken: authToken);
        added++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$added ingredients added to list'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }

  void _showOrderReview(Recipe recipe, CartProvider cartProvider) {
    final selectedItems = recipe.ingredients
        .where((i) =>
            _selectedIngredients.contains(i.id) && i.linkedProduct != null)
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No items available to order'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      );
      return;
    }

    final totalCost = selectedItems.fold<double>(
      0,
      (sum, i) => sum + (i.linkedProduct!.price * _servingsMultiplier),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        title: Text(
          'Order Summary',
          style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${selectedItems.length} ingredient${selectedItems.length != 1 ? 's' : ''} will be added to cart:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: selectedItems.length,
                  itemBuilder: (context, index) {
                    final item = selectedItems[index];
                    final qty = _extractQuantityFromString(item.quantity) *
                        _servingsMultiplier;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                          Text(
                            'x${qty == qty.roundToDouble() ? qty.round().toString() : qty.toStringAsFixed(1)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            Formatters.formatCurrency(
                              item.linkedProduct!.price * _servingsMultiplier,
                            ),
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(totalCost),
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
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
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _orderIngredients(recipe, cartProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            child: const Text(
              'Confirm & Checkout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _orderIngredients(Recipe recipe, CartProvider cartProvider) {
    // Build cart items from selected ingredients
    int addedCount = 0;

    for (final ingredient in recipe.ingredients) {
      if (_selectedIngredients.contains(ingredient.id)) {
        if (ingredient.linkedProduct != null) {
          final quantity = _extractQuantityFromString(ingredient.quantity) *
              _servingsMultiplier;
          cartProvider.addToCart(ingredient.linkedProduct!, quantity: quantity);
          addedCount++;
        }
      }
    }

    // Navigate to checkout
    if (addedCount > 0) {
      GoRouter.of(context).go('/customer/checkout');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No items available to order'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      );
    }
  }
}
