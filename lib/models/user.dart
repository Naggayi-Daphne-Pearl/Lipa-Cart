enum UserRole { customer, admin, rider, shopper }

extension UserRoleExtension on UserRole {
  String get name => toString().split('.').last;

  String get value => name;

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.shopper:
        return 'Shopper';
      case UserRole.rider:
        return 'Rider';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromString(String? roleString) {
    return UserRole.values.firstWhere(
      (e) => e.name == roleString,
      orElse: () => UserRole.customer,
    );
  }
}

class User {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final String? profileImage;
  final bool isPremium;
  final UserRole role;
  final String? customerId;
  final List<Address> addresses;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    this.profileImage,
    this.isPremium = false,
    this.role = UserRole.customer,
    this.customerId,
    this.addresses = const [],
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    String? profileImage,
    bool? isPremium,
    UserRole? role,
    String? customerId,
    List<Address>? addresses,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      isPremium: isPremium ?? this.isPremium,
      role: role ?? this.role,
      customerId: customerId ?? this.customerId,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'isPremium': isPremium,
      'role': role.name,
      'customerId': customerId,
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    DateTime createdAtValue;
    if (createdAtRaw is String) {
      createdAtValue = DateTime.parse(createdAtRaw);
    } else if (createdAtRaw is int) {
      createdAtValue = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      createdAtValue = DateTime.now();
    }

    return User(
      id: (json['id'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['phone'] ?? '').toString(),
      name: json['name'] as String?,
      email: json['email'] as String?,
      profileImage: (json['profileImage'] ?? json['profile_photo']) as String?,
      isPremium:
          json['isPremium'] as bool? ?? json['is_premium'] as bool? ?? false,
      role: UserRoleExtension.fromString(
        (json['role'] ?? json['user_type']) as String?,
      ),
      customerId: (json['customerId'] ?? json['customer_id'])?.toString(),
      addresses:
          (json['addresses'] as List<dynamic>?)
              ?.map((a) => Address.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: createdAtValue,
    );
  }
}

class Address {
  final String id;
  final String label;
  final String fullAddress;
  final String? landmark;
  final double latitude;
  final double longitude;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.landmark,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  Address copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? landmark,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'fullAddress': fullAddress,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      label: json['label'] as String,
      fullAddress: json['fullAddress'] as String,
      landmark: json['landmark'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
