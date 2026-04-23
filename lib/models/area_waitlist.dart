class AreaWaitlist {
  final String id;
  final String areaName;
  final String region;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? email;
  final String status;
  final String areaPriority;
  final int areaCount;
  final DateTime? notificationSentAt;
  final String? notes;
  final DateTime createdAt;

  AreaWaitlist({
    required this.id,
    required this.areaName,
    required this.region,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.email,
    required this.status,
    this.areaPriority = 'medium',
    this.areaCount = 1,
    this.notificationSentAt,
    this.notes,
    required this.createdAt,
  });

  bool get isWaitlisted => status == 'waitlisted';
  bool get isNotified => status == 'notified';
  bool get isServiceStarted => status == 'service_started';
  bool get isInactive => status == 'inactive';

  // Format region for display
  String get regionDisplay {
    switch (region.toLowerCase()) {
      case 'kampala':
        return 'Kampala';
      case 'entebbe':
        return 'Entebbe';
      case 'wakiso':
        return 'Wakiso';
      case 'kcc':
        return 'KCC';
      case 'nairobi':
        return 'Nairobi';
      case 'kisumu':
        return 'Kisumu';
      case 'mombasa':
        return 'Mombasa';
      default:
        return areaName;
    }
  }

  // Status badge text
  String get statusDisplay {
    switch (status) {
      case 'waitlisted':
        return 'On Waitlist';
      case 'notified':
        return 'Notified';
      case 'service_started':
        return 'Service Available';
      case 'inactive':
        return 'Removed';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'areaName': areaName,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'email': email,
      'status': status,
      'areaPriority': areaPriority,
      'areaCount': areaCount,
      'notificationSentAt': notificationSentAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AreaWaitlist.fromStrapi(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? json;
    return AreaWaitlist(
      id: (json['documentId'] ?? json['id']).toString(),
      areaName: attributes['area_name'] ?? '',
      region: attributes['region'] ?? '',
      latitude: attributes['latitude'] != null
          ? double.tryParse(attributes['latitude'].toString())
          : null,
      longitude: attributes['longitude'] != null
          ? double.tryParse(attributes['longitude'].toString())
          : null,
      phoneNumber: attributes['phone_number'],
      email: attributes['email'],
      status: attributes['status'] ?? 'waitlisted',
      areaPriority: attributes['area_priority'] ?? 'medium',
      areaCount: attributes['area_count'] ?? 1,
      notificationSentAt: attributes['notification_sent_at'] != null
          ? DateTime.tryParse(attributes['notification_sent_at'])
          : null,
      notes: attributes['notes'],
      createdAt: attributes['createdAt'] != null
          ? DateTime.parse(attributes['createdAt'])
          : DateTime.now(),
    );
  }
}
