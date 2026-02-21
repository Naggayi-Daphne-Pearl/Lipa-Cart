class Rating {
  final String id;
  final String orderId;
  final double stars;
  final String? comment;
  final DateTime createdAt;
  final String? ratedById; // User who gave the rating
  final String? ratedToId; // User who received the rating

  Rating({
    required this.id,
    required this.orderId,
    required this.stars,
    this.comment,
    required this.createdAt,
    this.ratedById,
    this.ratedToId,
  });

  bool get isValid => stars > 0 && stars <= 5;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'stars': stars,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'ratedById': ratedById,
      'ratedToId': ratedToId,
    };
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      stars: (json['stars'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      ratedById: json['ratedById'] as String?,
      ratedToId: json['ratedToId'] as String?,
    );
  }

  Rating copyWith({
    String? id,
    String? orderId,
    double? stars,
    String? comment,
    DateTime? createdAt,
    String? ratedById,
    String? ratedToId,
  }) {
    return Rating(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      stars: stars ?? this.stars,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      ratedById: ratedById ?? this.ratedById,
      ratedToId: ratedToId ?? this.ratedToId,
    );
  }
}
