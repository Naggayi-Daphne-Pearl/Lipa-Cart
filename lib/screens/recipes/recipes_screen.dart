import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/desktop_top_nav_bar.dart';
import '../../widgets/shimmer_loading.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeCategory = 'Ugandan Classics';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final products = context.read<ProductProvider>().products;
      context.read<RecipeProvider>().loadRecipes(products: products);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _getFilteredRecipes(RecipeProvider provider) {
    // Start from provider's filteredRecipes (which already applies tags + quick/easy filters)
    List<Recipe> recipes = provider.filteredRecipes;

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final lowercaseQuery = _searchQuery.toLowerCase();
      recipes = recipes.where((recipe) {
        return recipe.name.toLowerCase().contains(lowercaseQuery) ||
            recipe.description.toLowerCase().contains(lowercaseQuery) ||
            recipe.tags.any(
              (tag) => tag.toLowerCase().contains(lowercaseQuery),
            ) ||
            recipe.ingredients.any(
              (i) => i.name.toLowerCase().contains(lowercaseQuery),
            );
      }).toList();
    }

    final category = _activeCategory;
    if (category != 'Ugandan Classics') {
      recipes = recipes.where((recipe) {
        final tags = recipe.tags.map((e) => e.toLowerCase()).toList();
        final name = recipe.name.toLowerCase();
        switch (category) {
          case 'Quick (under 30 min)':
            return recipe.totalTime <= 30;
          case 'Family Meals':
            return recipe.servings >= 4;
          case 'Vegetarian':
            return tags.contains('vegetarian') || tags.contains('vegan');
          case 'Breakfast':
            return tags.contains('breakfast');
          case 'Snacks':
            return tags.contains('snack') || tags.contains('snacks');
          case 'Continental':
            return tags.contains('continental');
          default:
            return name.contains('rolex') ||
                name.contains('luwombo') ||
                name.contains('pilau') ||
                name.contains('matoke') ||
                tags.contains('ugandan') ||
                tags.contains('east african');
        }
      }).toList();
    }

    return recipes;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final filteredRecipes = _getFilteredRecipes(provider);
    final totalAvailableIngredients = filteredRecipes.fold<int>(
      0,
      (sum, recipe) => sum + recipe.purchasableIngredients.length,
    );
    final totalIngredients = filteredRecipes.fold<int>(
      0,
      (sum, recipe) => sum + recipe.ingredients.length,
    );
    final averageTime = filteredRecipes.isEmpty
        ? 0
        : (filteredRecipes
                    .map((r) => r.totalTime)
                    .reduce((a, b) => a + b) /
                filteredRecipes.length)
            .round();
    final averageCost = filteredRecipes.isEmpty
        ? 0.0
        : filteredRecipes
                .map((r) => r.estimatedCost)
                .reduce((a, b) => a + b) /
            filteredRecipes.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: context.isMobile
          ? const AppBottomNav(currentIndex: 0)
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: ResponsiveContainer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DesktopTopNavBar(activeSection: 'recipes'),
                // Header
                Padding(
                  padding: EdgeInsets.all(
                    context.responsive<double>(
                      mobile: AppSizes.lg,
                      tablet: AppSizes.xl,
                      desktop: 24.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (context.isMobile)
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
                      if (context.isMobile) const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recipes',
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: context.responsive<double>(
                                  mobile: 24.0,
                                  tablet: 28.0,
                                  desktop: 32.0,
                                ),
                              ),
                            ),
                            Text(
                              'Find inspiration & buy ingredients',
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
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: _buildFeaturedRecipeHero(filteredRecipes),
                ),
                const SizedBox(height: AppSizes.md),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: Container(
                    height: context.responsive<double>(
                      mobile: 52.0,
                      tablet: 56.0,
                      desktop: 60.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search recipes or ingredients...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        prefixIcon: const Icon(
                          Iconsax.search_normal,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Iconsax.close_circle,
                                  color: AppColors.textTertiary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.md,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.md,
                    tablet: AppSizes.lg,
                    desktop: AppSizes.lg,
                  ),
                ),

                // Locally relevant category chips
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.horizontalPadding,
                    ),
                    children: [
                      ...[
                        'Ugandan Classics',
                        'Quick (under 30 min)',
                        'Family Meals',
                        'Vegetarian',
                        'Breakfast',
                        'Snacks',
                        'Continental',
                      ].map(
                        (chip) => Padding(
                          padding: const EdgeInsets.only(right: AppSizes.sm),
                          child: _buildCuisineChip(chip),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.md,
                    tablet: AppSizes.lg,
                    desktop: AppSizes.lg,
                  ),
                ),

                // Results count
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: Text(
                    '${filteredRecipes.length} ${filteredRecipes.length == 1 ? 'recipe' : 'recipes'} found',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRecipeMetricChip(
                          icon: Iconsax.box,
                          label: 'Ingredients in stock',
                          value:
                              '$totalAvailableIngredients/$totalIngredients',
                        ),
                        const SizedBox(width: AppSizes.sm),
                        _buildRecipeMetricChip(
                          icon: Iconsax.clock,
                          label: 'Avg cook time',
                          value: '$averageTime min',
                        ),
                        const SizedBox(width: AppSizes.sm),
                        _buildRecipeMetricChip(
                          icon: Iconsax.wallet_2,
                          label: 'Avg basket cost',
                          value: 'UGX ${averageCost.round()}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Recipes list/grid
                Expanded(
                  child: provider.isLoading
                      ? _buildRecipesSkeleton(context)
                      : filteredRecipes.isEmpty
                      ? _buildEmptyState()
                      : _buildRecipesGrid(filteredRecipes),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeMetricChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: 1,
          ),
          boxShadow: isSelected ? null : AppColors.shadowSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesSkeleton(BuildContext context) {
    final columns = context.responsive<int>(
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );
    if (context.isMobile) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSizes.md),
          child: SizedBox(height: 220, child: ShimmerAdminRecipeCard()),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.85,
      ),
      itemCount: columns * 2,
      itemBuilder: (_, __) => const ShimmerAdminRecipeCard(),
    );
  }

  Widget _buildRecipesGrid(List<Recipe> recipes) {
    final columns = context.responsive<int>(
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );

    if (context.isMobile) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        itemCount: recipes.length,
        itemBuilder: (context, index) => _buildRecipeCard(recipes[index]),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: context.responsive<double>(
          mobile: AppSizes.md,
          tablet: AppSizes.lg,
          desktop: 24.0,
        ),
        mainAxisSpacing: context.responsive<double>(
          mobile: AppSizes.md,
          tablet: AppSizes.lg,
          desktop: 24.0,
        ),
        childAspectRatio: context.responsive<double>(
          mobile: 1.0,
          tablet: 0.75,
          desktop: 0.7,
          largeDesktop: 0.72,
        ),
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) => _buildRecipeCard(recipes[index]),
    );
  }

  Widget _buildTagChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.grey200,
            width: 1,
          ),
          boxShadow: isSelected ? null : AppColors.shadowSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final imageHeight = context.responsive<double>(
      mobile: 180.0,
      tablet: 200.0,
      desktop: 220.0,
      largeDesktop: 240.0,
    );

    return GestureDetector(
      onTap: () => context.push('/customer/recipe-detail', extra: recipe.id),
      child: Container(
        margin: EdgeInsets.only(bottom: context.isMobile ? AppSizes.md : 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(
            context.responsive<double>(
              mobile: AppSizes.radiusXl,
              tablet: 20.0,
              desktop: 24.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: context.responsive<double>(
                mobile: 8.0,
                tablet: 12.0,
                desktop: 16.0,
              ),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      context.responsive<double>(
                        mobile: AppSizes.radiusXl,
                        tablet: 20.0,
                        desktop: 24.0,
                      ),
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: recipe.image,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: imageHeight,
                      color: AppColors.grey100,
                      child: const Center(child: AppLoadingIndicator.small()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: imageHeight,
                      color: AppColors.grey100,
                      child: const Icon(
                        Iconsax.image,
                        size: 48,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: AppSizes.md,
                  right: AppSizes.md,
                  child: GestureDetector(
                    onTap: () => context.read<RecipeProvider>().toggleFavorite(
                      recipe.id,
                    ),
                    child: Container(
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
                ),
                // Time badge
                Positioned(
                  bottom: AppSizes.md,
                  left: AppSizes.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.clock,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.totalTime} min',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Difficulty badge
                Positioned(
                  bottom: AppSizes.md,
                  right: AppSizes.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(recipe.difficulty),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      recipe.difficulty,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Recipe info
            Padding(
              padding: EdgeInsets.all(
                context.responsive<double>(
                  mobile: AppSizes.md,
                  tablet: AppSizes.lg,
                  desktop: 20.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Wrap(
                    spacing: AppSizes.xs,
                    children: recipe.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  // Title
                  Text(
                    recipe.name,
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    recipe.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  // Ingredient availability
                  Text(
                    '${recipe.purchasableIngredients.length}/${recipe.ingredients.length} ingredients available',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addIngredientsQuick(recipe),
                      icon: const Icon(Iconsax.bag_2, size: 16),
                      label: const Text('Add ingredients'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  // Bottom row
                  Row(
                    children: [
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recipe.rating.toString(),
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' (${recipe.reviewCount})',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Ingredients count
                      Row(
                        children: [
                          const Icon(
                            Iconsax.shopping_bag,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.ingredients.length} ingredients',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSizes.md),
                      // Servings
                      Row(
                        children: [
                          const Icon(
                            Iconsax.people,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.servings}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedRecipeHero(List<Recipe> recipes) {
    if (recipes.isEmpty) return const SizedBox.shrink();
    final featured = recipes.first;
    return GestureDetector(
      onTap: () => context.push('/customer/recipe-detail', extra: featured.id),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          image: DecorationImage(
            image: NetworkImage(featured.image),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.65),
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                featured.name,
                style: AppTextStyles.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${featured.prepTime} min prep',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSizes.sm),
              ElevatedButton(
                onPressed: () => _addIngredientsQuick(featured),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cook tonight'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuisineChip(String label) {
    final isActive = _activeCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _addIngredientsQuick(Recipe recipe) {
    final cartProvider = context.read<CartProvider>();
    var added = 0;
    double total = 0;
    for (final ingredient in recipe.ingredients) {
      final p = ingredient.linkedProduct;
      if (p != null) {
        cartProvider.addToCart(p);
        added += 1;
        total += p.price;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added $added items - ${Formatters.formatCurrency(total)}',
        ),
        backgroundColor: AppColors.success,
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
              width: context.responsive<double>(
                mobile: 100.0,
                tablet: 120.0,
                desktop: 140.0,
              ),
              height: context.responsive<double>(
                mobile: 100.0,
                tablet: 120.0,
                desktop: 140.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.book,
                size: context.responsive<double>(
                  mobile: 48.0,
                  tablet: 56.0,
                  desktop: 64.0,
                ),
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'No recipes found',
              style: AppTextStyles.h5.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: context.responsive<double>(
                  mobile: 18.0,
                  tablet: 20.0,
                  desktop: 22.0,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Try adjusting your search\nor filters',
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

  IconData _getTagIcon(String tag) {
    final tagLower = tag.toLowerCase();
    if (tagLower.contains('kenyan') || tagLower.contains('african')) {
      return Iconsax.flag;
    }
    if (tagLower.contains('vegetarian') || tagLower.contains('vegan')) {
      return Iconsax.heart;
    }
    if (tagLower.contains('quick') || tagLower.contains('fast')) {
      return Iconsax.timer_1;
    }
    if (tagLower.contains('healthy')) return Iconsax.health;
    if (tagLower.contains('breakfast')) return Iconsax.sun_1;
    if (tagLower.contains('meat') || tagLower.contains('chicken')) {
      return Iconsax.box;
    }
    if (tagLower.contains('traditional')) return Iconsax.star;
    return Iconsax.element_4;
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
}
