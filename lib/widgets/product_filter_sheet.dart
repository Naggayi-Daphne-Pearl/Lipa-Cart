import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_sizes.dart';
import '../providers/product_provider.dart';

class ProductFilterSheet extends StatefulWidget {
  final ScrollController scrollController;
  final ProductProvider productProvider;

  const ProductFilterSheet({
    super.key,
    required this.scrollController,
    required this.productProvider,
  });

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late double _minPrice;
  late double _maxPrice;
  late double _minRating;
  late bool _inStockOnly;

  @override
  void initState() {
    super.initState();
    _minPrice = widget.productProvider.selectedMinPrice;
    _maxPrice = widget.productProvider.selectedMaxPrice;
    _minRating = widget.productProvider.minRating;
    _inStockOnly = widget.productProvider.inStockOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.lightGrey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: AppTextStyles.h4),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = widget.productProvider.minPrice;
                      _maxPrice = widget.productProvider.maxPrice;
                      _minRating = 0;
                      _inStockOnly = false;
                    });
                    widget.productProvider.resetFilters();
                  },
                  child: Text(
                    'Reset',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Filters content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                // Price Range Filter
                Text('Price Range', style: AppTextStyles.h5),
                const SizedBox(height: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'UGX ${_minPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.labelSmall,
                          ),
                          Text(
                            'UGX ${_maxPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      RangeSlider(
                        values: RangeValues(_minPrice, _maxPrice),
                        min: 0,
                        max: 1000000,
                        divisions: 100,
                        labels: RangeLabels(
                          'UGX ${_minPrice.toStringAsFixed(0)}',
                          'UGX ${_maxPrice.toStringAsFixed(0)}',
                        ),
                        activeColor: AppColors.primaryOrange,
                        inactiveColor: AppColors.lightGrey,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _minPrice = values.start;
                            _maxPrice = values.end;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Rating Filter
                Text('Minimum Rating', style: AppTextStyles.h5),
                const SizedBox(height: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final rating = index.toDouble();
                          final isSelected = _minRating == rating;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _minRating = rating);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: AppSizes.xs,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusXs,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : AppColors.lightGrey,
                                ),
                              ),
                              child: Text(
                                index == 0 ? 'All' : '$index★',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.surface
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Stock Only Filter
                Text('Availability', style: AppTextStyles.h5),
                const SizedBox(height: AppSizes.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                  child: CheckboxListTile(
                    value: _inStockOnly,
                    onChanged: (value) {
                      setState(() => _inStockOnly = value ?? false);
                    },
                    title: Text(
                      'In Stock Only',
                      style: AppTextStyles.labelMedium,
                    ),
                    activeColor: AppColors.primaryOrange,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.lightGrey)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.productProvider.setPriceRange(_minPrice, _maxPrice);
                  widget.productProvider.setMinRating(_minRating);
                  widget.productProvider.setInStockOnly(_inStockOnly);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
