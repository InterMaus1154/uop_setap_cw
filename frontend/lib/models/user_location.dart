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
  final DateTime? sharingExpiresAt;

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
    this.sharingExpiresAt,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userLocId: json['user_loc_id'] as int,
      userId: json['user_id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isEnabled: json['is_enabled'] as bool,
      createdAt: (() {
        final s = json['created_at'] as String;
        final hasTz = s.endsWith('Z') || s.contains('+') || s.contains('-');
        final toParse = hasTz ? s : '${s}Z';
        return DateTime.parse(toParse).toUtc();
      })(),
      updatedAt: (() {
        final s = json['updated_at'] as String;
        final hasTz = s.endsWith('Z') || s.contains('+') || s.contains('-');
        final toParse = hasTz ? s : '${s}Z';
        return DateTime.parse(toParse).toUtc();
      })(),
      city: json['city'] as String?,
      street: json['street'] as String?,
      sharingExpiresAt: (() {
        final s = json['sharing_expires_at'] as String?;
        if (s == null) return null;
        try {
          // Some server responses may omit the timezone (naive datetime).
          // Treat naive ISO strings as UTC by appending 'Z' before parsing.
          final hasTz = s.endsWith('Z') || s.contains('+') || s.contains('-');
          final toParse = hasTz ? s : '${s}Z';
          return DateTime.parse(toParse).toUtc();
        } catch (_) {
          return null;
        }
      })(),
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
      'sharing_expires_at': sharingExpiresAt?.toIso8601String(),
    };
  }
}
