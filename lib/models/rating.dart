class Rating {
  final String id;
  final String orderId;
  final int? overallRating; // Overall rating 1–5
  final int? shopperRating; // Shopper rating 1–5 (optional)
  final int? riderRating; // Rider rating 1–5 (optional)
  final String? comment;
  final DateTime createdAt;
  final String? ratedById; // User who gave the rating
  final String? ratedToId; // User who received the rating

  Rating({
    required this.id,
    required this.orderId,
    this.overallRating,
    this.shopperRating,
    this.riderRating,
    this.comment,
    required this.createdAt,
    this.ratedById,
    this.ratedToId,
  });

  bool get isValid =>
      overallRating != null && overallRating! > 0 && overallRating! <= 5;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'overall_rating': overallRating,
      'shopper_rating': shopperRating,
      'rider_rating': riderRating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'ratedById': ratedById,
      'ratedToId': ratedToId,
    };
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    // Extract orderId safely — backend may return order as: int, documentId string, or relation object
    String orderId = '';
    final orderField = json['order'] ?? json['orderId'];
    if (orderField is String) {
      orderId = orderField;
    } else if (orderField is int) {
      orderId = orderField.toString();
    } else if (orderField is Map && orderField['documentId'] != null) {
      orderId = orderField['documentId'].toString();
    }

    // Extract id safely — backend may return id as: int, documentId string, or string
    String id = '';
    final idField = json['id'] ?? json['documentId'];
    if (idField is String) {
      id = idField;
    } else if (idField is int) {
      id = idField.toString();
    }

    return Rating(
      id: id,
      orderId: orderId,
      overallRating: json['overall_rating'] as int?,
      shopperRating: json['shopper_rating'] as int?,
      riderRating: json['rider_rating'] as int?,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      ratedById: json['ratedById'] as String?,
      ratedToId: json['ratedToId'] as String?,
    );
  }

  Rating copyWith({
    String? id,
    String? orderId,
    int? overallRating,
    int? shopperRating,
    int? riderRating,
    String? comment,
    DateTime? createdAt,
    String? ratedById,
    String? ratedToId,
  }) {
    return Rating(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      overallRating: overallRating ?? this.overallRating,
      shopperRating: shopperRating ?? this.shopperRating,
      riderRating: riderRating ?? this.riderRating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      ratedById: ratedById ?? this.ratedById,
      ratedToId: ratedToId ?? this.ratedToId,
    );
  }
}
