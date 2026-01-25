class Product {
  final String id;
  final String name;
  final String description;
  final String image;
  final List<String> images;
  final double price;
  final double? originalPrice;
  final String unit;
  final double minQuantity;
  final double maxQuantity;
  final String categoryId;
  final String categoryName;
  final bool isAvailable;
  final bool isFeatured;
  final double rating;
  final int reviewCount;
  final List<String> tags;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.images = const [],
    required this.price,
    this.originalPrice,
    required this.unit,
    this.minQuantity = 1,
    this.maxQuantity = 100,
    required this.categoryId,
    required this.categoryName,
    this.isAvailable = true,
    this.isFeatured = false,
    this.rating = 0,
    this.reviewCount = 0,
    this.tags = const [],
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'images': images,
      'price': price,
      'originalPrice': originalPrice,
      'unit': unit,
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'rating': rating,
      'reviewCount': reviewCount,
      'tags': tags,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      image: json['image'] as String,
      images:
          (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      unit: json['unit'] as String,
      minQuantity: (json['minQuantity'] as num?)?.toDouble() ?? 1,
      maxQuantity: (json['maxQuantity'] as num?)?.toDouble() ?? 100,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  static List<Product> getSampleProducts() {
    return [
      Product(
        id: '1',
        name: 'Fresh Tomatoes',
        description: 'Ripe red tomatoes from local farms. Perfect for salads, cooking, and sauces.',
        image: 'https://assets.bwbx.io/images/users/iqjWHBFdfxIU/i05Iza4CFkoQ/v0/-1x-1.webp',
        price: 3500,
        originalPrice: 4000,
        unit: 'kg',
        categoryId: '1',
        categoryName: 'Vegetables',
        isFeatured: true,
        rating: 4.5,
        reviewCount: 128,
        tags: ['organic', 'local'],
      ),
      Product(
        id: '2',
        name: 'Green Bananas',
        description: 'Fresh green bananas for cooking. A staple in East African cuisine.',
        image: 'https://images.unsplash.com/photo-1603833665858-e61d17a86224?w=400',
        price: 5000,
        unit: 'bunch',
        categoryId: '2',
        categoryName: 'Fruits',
        isFeatured: true,
        rating: 4.8,
        reviewCount: 95,
        tags: ['local'],
      ),
      Product(
        id: '3',
        name: 'Fresh Tilapia',
        description: 'Freshly caught tilapia from Lake Victoria. Perfect for grilling or frying.',
        image: 'https://images.unsplash.com/photo-1510130387422-82bed34b37e9?w=400',
        price: 15000,
        unit: 'kg',
        categoryId: '3',
        categoryName: 'Meat & Fish',
        rating: 4.6,
        reviewCount: 67,
        tags: ['fresh', 'local'],
      ),
      Product(
        id: '4',
        name: 'Fresh Milk',
        description: 'Pasteurized fresh milk from local dairy farms.',
        image: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400',
        price: 3000,
        unit: 'litre',
        categoryId: '4',
        categoryName: 'Dairy',
        rating: 4.7,
        reviewCount: 210,
        tags: ['fresh', 'local'],
      ),
      Product(
        id: '5',
        name: 'Avocados',
        description: 'Creamy ripe avocados. Great for guacamole, salads, or toast.',
        image: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400',
        price: 2000,
        originalPrice: 2500,
        unit: 'piece',
        categoryId: '2',
        categoryName: 'Fruits',
        isFeatured: true,
        rating: 4.9,
        reviewCount: 156,
        tags: ['organic'],
      ),
      Product(
        id: '6',
        name: 'Fresh Onions',
        description: 'Red onions perfect for cooking and salads.',
        image: 'https://images.immediate.co.uk/production/volatile/sites/30/2019/08/Onion-72ea178.jpg?resize=1366,1503',
        price: 4000,
        unit: 'kg',
        categoryId: '1',
        categoryName: 'Vegetables',
        rating: 4.4,
        reviewCount: 89,
        tags: ['local'],
      ),
      Product(
        id: '7',
        name: 'Rice - Premium',
        description: 'High-quality long grain rice for everyday meals.',
        image: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
        price: 8000,
        unit: 'kg',
        categoryId: '5',
        categoryName: 'Pantry',
        rating: 4.6,
        reviewCount: 234,
        tags: ['staple'],
      ),
      Product(
        id: '8',
        name: 'Eggs',
        description: 'Fresh eggs from free-range chickens.',
        image: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400',
        price: 15000,
        unit: 'tray',
        categoryId: '4',
        categoryName: 'Dairy',
        isFeatured: true,
        rating: 4.8,
        reviewCount: 312,
        tags: ['fresh', 'local'],
      ),
    ];
  }
}
