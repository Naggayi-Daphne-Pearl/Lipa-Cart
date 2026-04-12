class Address {
  final int id;
  final String documentId;
  final int customerId;
  final String label;
  final String addressLine;
  final String city;
  final String? landmark;
  final String? deliveryInstructions;
  final double? gpsLat;
  final double? gpsLng;
  final bool isDefault;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.documentId,
    required this.customerId,
    required this.label,
    required this.addressLine,
    required this.city,
    this.landmark,
    this.deliveryInstructions,
    this.gpsLat,
    this.gpsLng,
    required this.isDefault,
    required this.createdAt,
  });

  factory Address.empty() {
    return Address(
      id: 0,
      documentId: '',
      customerId: 0,
      label: '',
      addressLine: '',
      city: '',
      isDefault: false,
      createdAt: DateTime.now(),
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    final customerData = json['customer'];
    final customerId = customerData is Map ? customerData['id'] : customerData;

    return Address(
      id: json['id'] ?? 0,
      documentId: json['documentId'] ?? '',
      customerId: customerId ?? 0,
      label: json['label'] ?? 'Address',
      addressLine: json['address_line'] ?? '',
      city: json['city'] ?? '',
      landmark: json['landmark'],
      deliveryInstructions: json['delivery_instructions'],
      gpsLat: double.tryParse(json['gps_lat']?.toString() ?? ''),
      gpsLng: double.tryParse(json['gps_lng']?.toString() ?? ''),
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get fullAddress =>
      '$addressLine, $city${landmark != null ? ', $landmark' : ''}';

  Address copyWith({
    int? id,
    String? documentId,
    int? customerId,
    String? label,
    String? addressLine,
    String? city,
    String? landmark,
    String? deliveryInstructions,
    double? gpsLat,
    double? gpsLng,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      customerId: customerId ?? this.customerId,
      label: label ?? this.label,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      landmark: landmark ?? this.landmark,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
