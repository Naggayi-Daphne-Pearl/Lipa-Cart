import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../services/upload_service.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/shimmer_loading.dart';

class AdminProductsDesktopScreen extends StatefulWidget {
  const AdminProductsDesktopScreen({super.key});

  @override
  State<AdminProductsDesktopScreen> createState() =>
      _AdminProductsDesktopScreenState();
}

class _AdminProductsDesktopScreenState
    extends State<AdminProductsDesktopScreen> {
  late List<Product> _products = [];
  bool _isLoading = true;
  String? _deletingProductId;
  final Set<String> _togglingProductIds = {};

  Future<void> _toggleAvailability(Product product, bool value) async {
    setState(() => _togglingProductIds.add(product.id));
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('No auth token');
      await ProductService.updateProduct(
        product.id,
        {'is_active': value},
        token: token,
      );
      if (mounted) _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _togglingProductIds.remove(product.id));
      }
    }
  }
  String? _error;
  final _searchController = TextEditingController();
  List<Category> _categories = [];
  String _selectedCategory = 'All';

  List<String> get _categoryNames =>
      _categories.map((c) => c.name).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      final categories = await CategoryService.getCategories(token: token);
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No auth token');
      }

      final products = await ProductService.getProducts(
        token: token,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'All') return _products;
    return _products
        .where((p) => p.categoryName == _selectedCategory)
        .toList();
  }

  String _formatPrice(double price) {
    return 'UGX ${NumberFormat('#,###').format(price.toInt())}';
  }

  void _showBulkImportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BulkImportDialog(
        onComplete: _loadProducts,
      ),
    );
  }

  void _showProductDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(
        product: product,
        categories: _categories,
        onSave: (_) {
          _loadProducts();
        },
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool inFlight = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Product'),
            content: Text(
              'Are you sure you want to delete "${product.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: inFlight
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: inFlight
                    ? null
                    : () async {
                        setDialogState(() => inFlight = true);
                        setState(() => _deletingProductId = product.id);
                        try {
                          final token = context.read<AuthProvider>().token;
                          if (token == null) throw Exception('No auth token');
                          await ProductService.deleteProduct(
                            product.id,
                            token: token,
                          );
                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product deleted'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadProducts();
                        } catch (e) {
                          if (!mounted) return;
                          setDialogState(() => inFlight = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _deletingProductId = null);
                          }
                        }
                      },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: inFlight
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: AppTextStyles.h3
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_filteredProducts.length} products${_selectedCategory != 'All' ? ' in $_selectedCategory' : ''}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showBulkImportDialog,
                      icon: const Icon(Iconsax.document_upload, size: 18),
                      label: const Text('Bulk Import'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.grey300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showProductDialog(),
                      icon: const Icon(Iconsax.add, size: 18),
                      label: const Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filters row
            Row(
              children: [
                // Search
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textTertiary),
                      prefixIcon: const Icon(Iconsax.search_normal,
                          size: 20, color: AppColors.textTertiary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.grey200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.grey200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    style: AppTextStyles.bodySmall,
                    onChanged: (_) => _loadProducts(),
                  ),
                ),
                const SizedBox(width: 16),
                // Category filter pills
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryPill('All'),
                        ..._categoryNames.map((cat) => _buildCategoryPill(cat)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _loadProducts,
                  icon: const Icon(Iconsax.refresh, size: 20),
                  tooltip: 'Refresh',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.grey200),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Products table
            Expanded(
              child: _isLoading
                  ? const ShimmerAdminTable()
                  : _error != null
                      ? _buildErrorState()
                      : _filteredProducts.isEmpty
                          ? _buildEmptyState()
                          : _buildProductsTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
          ),
          child: Text(
            category,
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 48, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text(
            'Failed to load products',
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '$_error',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadProducts,
            icon: const Icon(Iconsax.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.box, size: 56, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search term'
                : 'Add your first product to get started',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiary),
          ),
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Iconsax.add, size: 18),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.grey50),
            headingTextStyle: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            dataRowMinHeight: 60,
            dataRowMaxHeight: 68,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Price'), numeric: true),
              DataColumn(label: Text('Unit')),
              DataColumn(label: Text('Available')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _filteredProducts.map((product) {
              return DataRow(
                cells: [
                  // Product with image thumbnail
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: product.image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: product.image,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.grey100,
                                      child: const Icon(Iconsax.image,
                                          size: 18,
                                          color: AppColors.textTertiary),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.grey100,
                                      child: const Icon(Iconsax.image,
                                          size: 18,
                                          color: AppColors.textTertiary),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.grey100,
                                    child: const Icon(Iconsax.image,
                                        size: 18,
                                        color: AppColors.textTertiary),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            product.name,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Category badge
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.categoryName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // Price
                  DataCell(
                    Text(
                      _formatPrice(product.price),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Unit
                  DataCell(
                    Text(
                      product.unit,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  // Availability toggle
                  DataCell(
                    _togglingProductIds.contains(product.id)
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: product.isAvailable,
                            onChanged: (value) =>
                                _toggleAvailability(product, value),
                            activeTrackColor: AppColors.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                  ),
                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Iconsax.edit_2, size: 18),
                          onPressed: () =>
                              _showProductDialog(product: product),
                          tooltip: 'Edit',
                          color: AppColors.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.trash, size: 18),
                          onPressed: () => _deleteProduct(product),
                          tooltip: 'Delete',
                          color: AppColors.error,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ProductFormDialog extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final Function(Product) onSave;

  const _ProductFormDialog({
    required this.product,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _unitController;
  late TextEditingController _minQtyController;
  late TextEditingController _maxQtyController;

  bool _isLoading = false;
  String? _selectedCategory;

  Uint8List? _pickedImageBytes;
  int? _uploadedImageId;
  String? _existingImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _descriptionController =
        TextEditingController(text: widget.product?.description);
    _priceController =
        TextEditingController(text: widget.product?.price.toString());
    _unitController = TextEditingController(text: widget.product?.unit);
    _minQtyController =
        TextEditingController(text: widget.product?.minQuantity.toString());
    _maxQtyController =
        TextEditingController(text: widget.product?.maxQuantity.toString());
    final initialCategoryId = widget.product?.categoryId;
    if (initialCategoryId != null && initialCategoryId.isNotEmpty) {
      _selectedCategory = initialCategoryId;
    } else {
      final byName = widget.categories
          .where((c) => c.name == widget.product?.categoryName);
      _selectedCategory = byName.isEmpty ? null : byName.first.id;
    }
    _existingImageUrl = widget.product?.image.isNotEmpty == true
        ? widget.product!.image
        : null;
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _isUploadingImage = true;
      });

      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('No auth token');

      final result = await UploadService.uploadImageBytesWithMeta(
        bytes,
        picked.name,
        token,
      );

      if (mounted) {
        setState(() {
          _uploadedImageId = result.id;
          _existingImageUrl = result.url;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _pickedImageBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and price are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) throw Exception('No auth token');

      final units = _unitController.text
          .split(',')
          .map((u) => u.trim())
          .where((u) => u.isNotEmpty)
          .toList();

      final productData = <String, dynamic>{
        'name': _nameController.text,
        'description': _descriptionController.text,
        'estimated_price': double.parse(_priceController.text),
        'common_units': units,
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty)
          'category': _selectedCategory,
        if (_uploadedImageId != null) 'image': _uploadedImageId,
      };

      late Product result;
      if (widget.product == null) {
        result = await ProductService.createProduct(productData, token: token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        result = await ProductService.updateProduct(
          widget.product!.id,
          productData,
          token: token,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      if (mounted) {
        widget.onSave(result);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePicker() {
    final hasPicked = _pickedImageBytes != null;
    final hasExisting = _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    Widget preview;
    if (hasPicked) {
      preview = Image.memory(_pickedImageBytes!, fit: BoxFit.cover);
    } else if (hasExisting) {
      preview = CachedNetworkImage(
        imageUrl: _existingImageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(color: AppColors.grey100),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.grey100,
          child: const Icon(Iconsax.image,
              size: 32, color: AppColors.textTertiary),
        ),
      );
    } else {
      preview = Container(
        color: AppColors.grey100,
        alignment: Alignment.center,
        child: const Icon(Iconsax.gallery,
            size: 36, color: AppColors.textTertiary),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 96, height: 96, child: preview),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Image',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'JPG, PNG or WEBP. Max 10MB.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                icon: _isUploadingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Iconsax.gallery_add, size: 18),
                label: Text(
                  _isUploadingImage
                      ? 'Uploading...'
                      : (hasPicked || hasExisting)
                          ? 'Change image'
                          : 'Upload image',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.grey300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price (UGX) *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Units *',
                        hintText: 'kg, bunch, piece',
                        helperText: 'Comma-separated',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minQtyController,
                      decoration: InputDecoration(
                        labelText: 'Min Qty',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _maxQtyController,
                      decoration: InputDecoration(
                        labelText: 'Max Qty',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: widget.categories.map((cat) {
                  return DropdownMenuItem<String?>(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const AppLoadingIndicator.small()
              : Text(widget.product == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _minQtyController.dispose();
    _maxQtyController.dispose();
    super.dispose();
  }
}

class _BulkImportDialog extends StatefulWidget {
  final VoidCallback onComplete;
  const _BulkImportDialog({required this.onComplete});

  @override
  State<_BulkImportDialog> createState() => _BulkImportDialogState();
}

enum _ImportPhase { idle, validating, ready, importing, done }

class _BulkImportDialogState extends State<_BulkImportDialog> {
  final _csvController = TextEditingController();
  _ImportPhase _phase = _ImportPhase.idle;
  bool _fetchingTemplate = false;
  bool _loadingCategories = false;
  String? _error;
  String? _selectedFileName;
  BulkImportResult? _validation;
  BulkImportResult? _importResult;
  List<({String id, String name})> _categoryOptions = [];

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  Future<void> _downloadTemplate() async {
    setState(() => _fetchingTemplate = true);
    try {
      final token = context.read<AuthProvider>().token;
      final csv = await ProductService.fetchCsvTemplate(token: token);
      if (!mounted) return;
      _csvController.text = csv;
      _resetPreview();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template loaded. Edit, then Validate.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load template: $e')),
      );
    } finally {
      if (mounted) setState(() => _fetchingTemplate = false);
    }
  }

  Future<void> _showCategoryReference() async {
    setState(() => _loadingCategories = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Not signed in');
      final options = await ProductService.fetchCategoryOptions(token: token);
      if (!mounted) return;
      setState(() => _categoryOptions = options);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'Could not read the selected file.');
      return;
    }
    final text = utf8.decode(bytes, allowMalformed: true);
    setState(() {
      _csvController.text = text;
      _selectedFileName = file.name;
      _resetPreview();
    });
  }

  void _resetPreview() {
    _phase = _ImportPhase.idle;
    _validation = null;
    _importResult = null;
    _error = null;
  }

  Future<void> _validate() async {
    final csv = _csvController.text.trim();
    if (csv.isEmpty) {
      setState(() => _error = 'Add CSV content first (drop a file or paste).');
      return;
    }
    setState(() {
      _phase = _ImportPhase.validating;
      _error = null;
      _validation = null;
      _importResult = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Not signed in');
      final result = await ProductService.bulkImport(
        csv,
        token: token,
        dryRun: true,
      );
      if (!mounted) return;
      setState(() {
        _validation = result;
        _phase = _ImportPhase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ImportPhase.idle;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _import() async {
    final csv = _csvController.text.trim();
    setState(() {
      _phase = _ImportPhase.importing;
      _error = null;
      _importResult = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Not signed in');
      final result = await ProductService.bulkImport(csv, token: token);
      if (!mounted) return;
      setState(() {
        _importResult = result;
        _phase = _ImportPhase.done;
      });
      if (result.created > 0) widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ImportPhase.ready;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  bool get _busy =>
      _phase == _ImportPhase.validating || _phase == _ImportPhase.importing;

  String _phaseLabel() {
    switch (_phase) {
      case _ImportPhase.validating:
        return 'Validating...';
      case _ImportPhase.importing:
        return 'Importing... (image fetches can take ~1s each)';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _importResult ?? _validation;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Bulk import products'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Required columns: name, description, estimated_price, '
                'common_units, category_id. Optional: image_url '
                '(Cloudinary URL on our tenant). Use "|" to separate '
                'multiple units (e.g. "kg|bunch"). Max 200 rows per import.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _fetchingTemplate ? null : _downloadTemplate,
                    icon: _fetchingTemplate
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Iconsax.document_download, size: 16),
                    label: const Text('Load template'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loadingCategories ? null : _showCategoryReference,
                    icon: _loadingCategories
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Iconsax.tag_2, size: 16),
                    label: const Text('Show category IDs'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickFile,
                    icon: const Icon(Iconsax.document_upload, size: 16),
                    label: Text(_selectedFileName ?? 'Pick CSV file'),
                  ),
                ],
              ),
              if (_categoryOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  decoration: BoxDecoration(
                    color: AppColors.beige,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _categoryOptions
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: SelectableText(
                                '${c.name} → ${c.id}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _csvController,
                maxLines: 12,
                onChanged: (_) {
                  if (_phase != _ImportPhase.idle) {
                    setState(_resetPreview);
                  }
                },
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText:
                      'name,description,estimated_price,common_units,category_id,image_url',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 4),
                Text(
                  _phaseLabel(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              if (preview != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: preview.errors.isEmpty
                        ? AppColors.cardGreen
                        : AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _importResult != null
                            ? 'Imported ${preview.created} of ${preview.total} '
                                '(${preview.skipped} skipped)'
                            : 'Validated ${preview.created} of ${preview.total} '
                                'rows would import (${preview.skipped} would skip)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (preview.errors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...preview.errors.take(20).map(
                              (e) => Text(
                                'Row ${e.row}: ${e.error}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        if (preview.errors.length > 20)
                          Text(
                            '...and ${preview.errors.length - 20} more',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_phase != _ImportPhase.ready && _phase != _ImportPhase.done)
          ElevatedButton.icon(
            onPressed: _busy ? null : _validate,
            icon: const Icon(Iconsax.tick_square, size: 18),
            label: const Text('Validate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.grey900,
              foregroundColor: Colors.white,
            ),
          ),
        if (_phase == _ImportPhase.ready)
          ElevatedButton.icon(
            onPressed: _busy ? null : _import,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Iconsax.import, size: 18),
            label: Text(_busy ? 'Importing...' : 'Import for real'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
