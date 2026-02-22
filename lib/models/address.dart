class Address {
  final int id;
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
}
