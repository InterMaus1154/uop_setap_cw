class UserLocation {
  final int userLocId;
  final int userId;
  final double latitude;
  final double longitude;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? city;
  final String? street;

  UserLocation({
    required this.userLocId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.city,
    this.street,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userLocId: json['user_loc_id'] as int,
      userId: json['user_id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isEnabled: json['is_enabled'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      city: json['city'] as String?,
      street: json['street'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_loc_id': userLocId,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'is_enabled': isEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
