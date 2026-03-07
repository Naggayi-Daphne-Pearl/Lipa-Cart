import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_loading_indicator.dart';

class AdminProductsDesktopScreen extends StatefulWidget {
  const AdminProductsDesktopScreen({super.key});

  @override
  State<AdminProductsDesktopScreen> createState() =>
      _AdminProductsDesktopScreenState();
}

class _AdminProductsDesktopScreenState extends State<AdminProductsDesktopScreen> {
  late List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  List<String> _categories = [];

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

      final categories = await ProductService.getCategories(token: token);
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
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final authProvider = context.read<AuthProvider>();
                final token = authProvider.token;

                if (token == null) throw Exception('No auth token');

                await ProductService.deleteProduct(product.id, token: token);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadProducts();
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
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              spacing: 12,
              children: [
                // Search
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => _loadProducts(),
                  ),
                ),
                // Refresh
                IconButton(
                  onPressed: _loadProducts,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Products Table
          Expanded(
            child: _isLoading
                ? const AppLoadingPage()
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? const Center(child: Text('No products found'))
                        : SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Category')),
                                  const DataColumn(label: Text('Price (UGX)'), numeric: true),
                                  DataColumn(label: Text('Unit')),
                                  DataColumn(label: Text('Available')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _products.map((product) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(product.name)),
                                      DataCell(Text(product.categoryName)),
                                      DataCell(Text(product.price.toStringAsFixed(2))),
                                      DataCell(Text(product.unit)),
                                      DataCell(
                                        Chip(
                                          label: Text(product.isAvailable ? 'Yes' : 'No'),
                                          backgroundColor: product.isAvailable
                                              ? Colors.green.withValues(alpha: 0.3)
                                              : Colors.red.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            spacing: 8,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18),
                                                onPressed: () =>
                                                    _showProductDialog(product: product),
                                                tooltip: 'Edit',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18),
                                                onPressed: () => _deleteProduct(product),
                                                tooltip: 'Delete',
                                                color: Colors.red,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
          ),
        ],
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
  final List<String> categories;
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
    _selectedCategory = widget.product?.categoryName;
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

      // Map frontend field names to backend schema field names
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'estimated_price': double.parse(_priceController.text),
        'common_units': _unitController.text,
        // Note: minQuantity and maxQuantity don't exist in backend schema
        // categoryName is just for display, actual category relation is handled separately
      };

      late Product result;
      if (widget.product == null) {
        result = await ProductService.createProduct(productData, token: token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product created successfully'),
              backgroundColor: Colors.green,
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
              backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
              ),
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price (UGX) *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minQtyController,
                      decoration: InputDecoration(
                        labelText: 'Min Qty',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _maxQtyController,
                      decoration: InputDecoration(
                        labelText: 'Max Qty',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: widget.categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
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
