class Category {
  final String id;
  final String name;
  final String image;
  final String? description;
  final int productCount;
  final String color;

  Category({
    required this.id,
    required this.name,
    required this.image,
    this.description,
    this.productCount = 0,
    this.color = '#FF8C00',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
      'productCount': productCount,
      'color': color,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      description: json['description'] as String?,
      productCount: json['productCount'] as int? ?? 0,
      color: json['color'] as String? ?? '#FF8C00',
    );
  }

  factory Category.fromStrapi(Map<String, dynamic> json, {String? baseUrl}) {
    String imageUrl = '';
    final imageData = json['image'];
    if (imageData != null) {
      final url = imageData['url'] as String? ?? '';
      imageUrl = url.startsWith('http') ? url : '${baseUrl ?? ""}$url';
    }

    final products = json['products'] as List<dynamic>?;

    return Category(
      id: (json['documentId'] ?? json['id']).toString(),
      name: json['name'] as String? ?? '',
      image: imageUrl,
      description: json['description'] as String?,
      productCount: products?.length ?? 0,
      color: json['color'] as String? ?? '#FF8C00',
    );
  }

  static List<Category> getSampleCategories() {
    return [
      Category(
        id: '1',
        name: 'Vegetables',
        image: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
        description: 'Fresh vegetables from local farms',
        productCount: 45,
        color: '#2ECC71',
      ),
      Category(
        id: '2',
        name: 'Fruits',
        image: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=400',
        description: 'Seasonal fruits',
        productCount: 38,
        color: '#FF8C00',
      ),
      Category(
        id: '3',
        name: 'Meat & Fish',
        image: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=400',
        description: 'Fresh meat and seafood',
        productCount: 25,
        color: '#E74C3C',
      ),
      Category(
        id: '4',
        name: 'Dairy',
        image: 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=400',
        description: 'Milk, cheese, eggs and more',
        productCount: 20,
        color: '#3498DB',
      ),
      Category(
        id: '5',
        name: 'Pantry',
        image: 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=400',
        description: 'Essential pantry items',
        productCount: 60,
        color: '#F39C12',
      ),
      Category(
        id: '6',
        name: 'Beverages',
        image: 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400',
        description: 'Drinks and beverages',
        productCount: 30,
        color: '#9B59B6',
      ),
    ];
  }
}
