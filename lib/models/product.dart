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

  factory Product.fromStrapi(Map<String, dynamic> json, {String? baseUrl}) {
    String imageUrl = '';
    final imageData = json['image'];
    if (imageData != null) {
      final url = imageData['url'] as String? ?? '';
      imageUrl = url.startsWith('http') ? url : '${baseUrl ?? ""}$url';
    }

    final units = json['common_units'];
    String unit = 'piece';
    if (units is List && units.isNotEmpty) {
      unit = units[0].toString();
    } else if (units is String) {
      unit = units;
    }

    final category = json['category'];
    String categoryId = '';
    String categoryName = '';
    if (category != null) {
      categoryId = (category['documentId'] ?? category['id']).toString();
      categoryName = category['name'] as String? ?? '';
    }

    return Product(
      id: (json['documentId'] ?? json['id']).toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      image: imageUrl,
      price: (json['estimated_price'] as num?)?.toDouble() ?? 0,
      unit: unit,
      categoryId: categoryId,
      categoryName: categoryName,
      isAvailable: json['is_active'] as bool? ?? true,
    );
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
      // Fruits & Vegetables
      Product(
        id: '1',
        name: 'Bananas (Matooke)',
        description: 'Fresh green bananas for cooking. The staple food of Uganda — steam and mash for the perfect matoke.',
        image: 'https://images.unsplash.com/photo-1603833665858-e61d17a86224?w=400',
        price: 5000,
        unit: 'bunch',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        isFeatured: true,
        rating: 4.8,
        reviewCount: 95,
        tags: ['local', 'staple'],
      ),
      Product(
        id: '2',
        name: 'Mangoes',
        description: 'Sweet, juicy mangoes sourced from local farms. Perfect for snacking or fresh juice.',
        image: 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=400',
        price: 2000,
        unit: 'piece',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        rating: 4.7,
        reviewCount: 73,
        tags: ['fresh', 'local'],
      ),
      Product(
        id: '3',
        name: 'Pineapple',
        description: 'Ripe, sweet pineapple from Eastern Uganda. Great for juice, desserts, or eating fresh.',
        image: 'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?w=400',
        price: 3000,
        unit: 'piece',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        rating: 4.5,
        reviewCount: 48,
        tags: ['fresh', 'local'],
      ),
      Product(
        id: '4',
        name: 'Watermelon',
        description: 'Large, refreshing watermelon. Perfect for hot days and fresh juice.',
        image: 'https://images.unsplash.com/photo-1589984662646-e7b2e4962f18?w=400',
        price: 8000,
        unit: 'piece',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        rating: 4.6,
        reviewCount: 61,
        tags: ['fresh'],
      ),
      Product(
        id: '5',
        name: 'Passion Fruit',
        description: 'Tangy passion fruit for fresh juice or desserts. Rich in vitamins.',
        image: 'https://images.unsplash.com/photo-1604495772376-9657f0035eb5?w=400',
        price: 500,
        unit: 'piece',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        rating: 4.4,
        reviewCount: 39,
        tags: ['fresh', 'local'],
      ),
      Product(
        id: '6',
        name: 'Tomatoes',
        description: 'Ripe red tomatoes from local farms. Perfect for salads, cooking, and sauces.',
        image: 'https://images.unsplash.com/photo-1546470427-0d4db154ceb8?w=400',
        price: 3000,
        originalPrice: 3500,
        unit: 'kg',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        isFeatured: true,
        rating: 4.5,
        reviewCount: 128,
        tags: ['local', 'staple'],
      ),
      Product(
        id: '7',
        name: 'Onions',
        description: 'Red onions perfect for cooking and salads. A kitchen essential.',
        image: 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=400',
        price: 3500,
        unit: 'kg',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        rating: 4.4,
        reviewCount: 89,
        tags: ['local', 'staple'],
      ),
      Product(
        id: '8',
        name: 'Cabbage',
        description: 'Fresh green cabbage. Great for salads, stir-fry, or steaming.',
        image: 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=400',
        price: 2000,
        unit: 'piece',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        rating: 4.3,
        reviewCount: 56,
        tags: ['local'],
      ),
      Product(
        id: '9',
        name: 'Nakati (African Nightshade)',
        description: 'Traditional Ugandan leafy green vegetable. Nutritious and delicious when steamed.',
        image: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400',
        price: 1000,
        unit: 'bunch',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        rating: 4.6,
        reviewCount: 34,
        tags: ['local', 'traditional'],
      ),
      Product(
        id: '10',
        name: 'Sukuma Wiki (Collard Greens)',
        description: 'Popular East African leafy greens. A staple side dish in Kenya and Uganda.',
        image: 'https://images.unsplash.com/photo-1574316071802-0d684efa7bf5?w=400',
        price: 1000,
        unit: 'bunch',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        rating: 4.5,
        reviewCount: 45,
        tags: ['local', 'traditional'],
      ),
      Product(
        id: '11',
        name: 'Coriander (Dania)',
        description: 'Fresh coriander leaves for garnishing and flavouring. Essential for East African cooking.',
        image: 'https://images.unsplash.com/photo-1592928302636-c83cf1e1c887?w=400',
        price: 500,
        unit: 'bunch',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        rating: 4.3,
        reviewCount: 28,
        tags: ['fresh', 'herbs'],
      ),
      Product(
        id: '12',
        name: 'Ginger',
        description: 'Fresh ginger root for tea, cooking, and natural remedies.',
        image: 'https://images.unsplash.com/photo-1615485500704-8e990f9900f7?w=400',
        price: 2000,
        unit: 'piece',
        categoryId: '1',
        categoryName: 'Fruits & Vegetables',
        rating: 4.7,
        reviewCount: 52,
        tags: ['fresh', 'herbs'],
      ),
      // Meat & Poultry
      Product(
        id: '13',
        name: 'Whole Chicken',
        description: 'Fresh whole chicken, locally raised. Perfect for roasting or stewing.',
        image: 'https://images.unsplash.com/photo-1587593810167-a84920ea0781?w=400',
        price: 18000,
        unit: 'piece',
        categoryId: '2',
        categoryName: 'Meat & Poultry',
        isFeatured: true,
        rating: 4.7,
        reviewCount: 87,
        tags: ['fresh', 'local'],
      ),
      Product(
        id: '14',
        name: 'Chicken Breast',
        description: 'Boneless chicken breast. Lean, versatile, and great for grilling or stir-fry.',
        image: 'https://images.unsplash.com/photo-1604503468506-a8da13d82571?w=400',
        price: 12000,
        unit: 'kg',
        categoryId: '2',
        categoryName: 'Meat & Poultry',
        rating: 4.5,
        reviewCount: 64,
        tags: ['fresh'],
      ),
      Product(
        id: '15',
        name: 'Beef Stew Meat',
        description: 'Tender beef chunks ideal for slow-cooked stews and curries.',
        image: 'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=400',
        price: 15000,
        unit: 'kg',
        categoryId: '2',
        categoryName: 'Meat & Poultry',
        rating: 4.6,
        reviewCount: 71,
        tags: ['fresh', 'local'],
      ),
      Product(
        id: '16',
        name: 'Minced Beef',
        description: 'Freshly minced beef. Perfect for samosas, bolognese, or chapati fillings.',
        image: 'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=400',
        price: 16000,
        unit: 'kg',
        categoryId: '2',
        categoryName: 'Meat & Poultry',
        rating: 4.4,
        reviewCount: 43,
        tags: ['fresh'],
      ),
      Product(
        id: '17',
        name: 'Tilapia',
        description: 'Freshly caught tilapia from Lake Victoria. Perfect for grilling or frying.',
        image: 'https://images.unsplash.com/photo-1510130387422-82bed34b37e9?w=400',
        price: 12000,
        unit: 'piece',
        categoryId: '2',
        categoryName: 'Meat & Poultry',
        isFeatured: true,
        rating: 4.6,
        reviewCount: 67,
        tags: ['fresh', 'local'],
      ),
      Product(
        id: '18',
        name: 'Nile Perch',
        description: 'Premium Nile Perch fillet from Lake Victoria. A Ugandan delicacy.',
        image: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
        price: 18000,
        unit: 'kg',
        categoryId: '2',
        categoryName: 'Meat & Poultry',
        rating: 4.8,
        reviewCount: 38,
        tags: ['fresh', 'local', 'premium'],
      ),
      // Dairy & Eggs
      Product(
        id: '19',
        name: 'Fresh Milk (1L)',
        description: 'Pasteurized fresh milk from local dairy farms.',
        image: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400',
        price: 3500,
        unit: 'litre',
        categoryId: '3',
        categoryName: 'Dairy & Eggs',
        rating: 4.7,
        reviewCount: 210,
        tags: ['fresh', 'local'],
      ),
      Product(
        id: '20',
        name: 'Yogurt (500ml)',
        description: 'Creamy natural yogurt. Great for breakfast or as a snack.',
        image: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400',
        price: 3000,
        unit: 'piece',
        categoryId: '3',
        categoryName: 'Dairy & Eggs',
        rating: 4.5,
        reviewCount: 82,
        tags: ['fresh'],
      ),
      Product(
        id: '21',
        name: 'Eggs (Tray of 30)',
        description: 'Fresh eggs from free-range chickens. A kitchen essential.',
        image: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400',
        price: 12000,
        unit: 'tray',
        categoryId: '3',
        categoryName: 'Dairy & Eggs',
        isFeatured: true,
        rating: 4.8,
        reviewCount: 312,
        tags: ['fresh', 'local'],
      ),
      // Grains & Cereals
      Product(
        id: '22',
        name: 'Rice (1kg)',
        description: 'High-quality long grain rice for everyday meals.',
        image: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
        price: 5000,
        unit: 'kg',
        categoryId: '4',
        categoryName: 'Grains & Cereals',
        rating: 4.6,
        reviewCount: 234,
        tags: ['staple'],
      ),
      Product(
        id: '23',
        name: 'Maize Flour (Posho) 2kg',
        description: 'Fine maize flour for making posho/ugali. A staple across East Africa.',
        image: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400',
        price: 4000,
        unit: 'packet',
        categoryId: '4',
        categoryName: 'Grains & Cereals',
        isFeatured: true,
        rating: 4.5,
        reviewCount: 156,
        tags: ['staple', 'local'],
      ),
      Product(
        id: '24',
        name: 'Bread (Loaf)',
        description: 'Freshly baked white bread loaf. Perfect for breakfast or sandwiches.',
        image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
        price: 5000,
        unit: 'loaf',
        categoryId: '4',
        categoryName: 'Grains & Cereals',
        rating: 4.4,
        reviewCount: 189,
        tags: ['fresh'],
      ),
      // Beverages
      Product(
        id: '25',
        name: 'Mineral Water (1.5L)',
        description: 'Pure mineral water. Stay hydrated throughout the day.',
        image: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400',
        price: 1500,
        unit: 'bottle',
        categoryId: '5',
        categoryName: 'Beverages',
        rating: 4.3,
        reviewCount: 98,
        tags: [],
      ),
      Product(
        id: '26',
        name: 'Orange Juice (1L)',
        description: 'Fresh orange juice packed with vitamin C. No added sugars.',
        image: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400',
        price: 5000,
        unit: 'packet',
        categoryId: '5',
        categoryName: 'Beverages',
        rating: 4.5,
        reviewCount: 67,
        tags: ['fresh'],
      ),
      // Household & Cleaning
      Product(
        id: '27',
        name: 'Washing Soap (Bar)',
        description: 'Multipurpose washing soap bar for laundry and cleaning.',
        image: 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=400',
        price: 2000,
        unit: 'piece',
        categoryId: '6',
        categoryName: 'Household & Cleaning',
        rating: 4.2,
        reviewCount: 45,
        tags: [],
      ),
      Product(
        id: '28',
        name: 'Cooking Oil (1L)',
        description: 'Vegetable cooking oil for everyday frying and cooking.',
        image: 'https://images.unsplash.com/photo-1474979266404-7eabd7875faf?w=400',
        price: 8000,
        unit: 'litre',
        categoryId: '6',
        categoryName: 'Household & Cleaning',
        isFeatured: true,
        rating: 4.6,
        reviewCount: 178,
        tags: ['staple'],
      ),
    ];
  }
}
