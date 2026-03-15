import 'package:flutter/foundation.dart' hide Category;
import '../models/product.dart';
import '../models/category.dart';
import '../services/strapi_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Filter properties
  final double _minPrice = 0;
  final double _maxPrice = 1000000;
  double _selectedMinPrice = 0;
  double _selectedMaxPrice = 1000000;
  double _minRating = 0;
  bool _inStockOnly = false;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Product> get searchResults => _applyFilters(_searchResults);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Filter getters
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double get selectedMinPrice => _selectedMinPrice;
  double get selectedMaxPrice => _selectedMaxPrice;
  double get minRating => _minRating;
  bool get inStockOnly => _inStockOnly;
  bool get hasActiveFilters =>
      _selectedMinPrice != _minPrice ||
      _selectedMaxPrice != _maxPrice ||
      _minRating > 0 ||
      _inStockOnly;

  List<Product> get featuredProducts =>
      _products.where((p) => p.isFeatured).toList();

  List<Product> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  List<Product> getFilteredProductsByCategory(String categoryId) {
    return _applyFilters(getProductsByCategory(categoryId));
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        StrapiService.getProducts(),
        StrapiService.getCategories(),
      ]);
      _products = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
    } catch (e) {
      // CRITICAL: Using sample data means order creation will fail!
      // Products from sample data have hardcoded IDs ('13', '15', etc.)
      // that don't exist in the Strapi database, causing "product does not exist" errors
      _products = Product.getSampleProducts();
      _categories = Category.getSampleCategories();

      _errorMessage =
          'Products loaded from sample data. Backend API is unavailable. '
          'Orders created from recipes/shopping lists may fail. '
          'Check that the Strapi backend is running.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      final lowercaseQuery = query.toLowerCase();
      _searchResults = _products.where((product) {
        return product.name.toLowerCase().contains(lowercaseQuery) ||
            product.description.toLowerCase().contains(lowercaseQuery) ||
            product.categoryName.toLowerCase().contains(lowercaseQuery) ||
            product.tags.any(
              (tag) => tag.toLowerCase().contains(lowercaseQuery),
            );
      }).toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // Filter methods
  List<Product> _applyFilters(List<Product> products) {
    return products.where((product) {
      final priceMatch =
          product.price >= _selectedMinPrice &&
          product.price <= _selectedMaxPrice;
      final ratingMatch = product.rating >= _minRating;
      final stockMatch = !_inStockOnly || product.isAvailable;
      return priceMatch && ratingMatch && stockMatch;
    }).toList();
  }

  void setPriceRange(double min, double max) {
    _selectedMinPrice = min;
    _selectedMaxPrice = max;
    notifyListeners();
  }

  void setMinRating(double rating) {
    _minRating = rating;
    notifyListeners();
  }

  void setInStockOnly(bool value) {
    _inStockOnly = value;
    notifyListeners();
  }

  void resetFilters() {
    _selectedMinPrice = _minPrice;
    _selectedMaxPrice = _maxPrice;
    _minRating = 0;
    _inStockOnly = false;
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }
}
