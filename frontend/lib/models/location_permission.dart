class LocationPermission {
  final int locPermId;
  final int userLocId;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationPermission({
    required this.locPermId,
    required this.userLocId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationPermission.fromJson(Map<String, dynamic> json) {
    return LocationPermission(
      locPermId: json['loc_perm_id'] as int,
      userLocId: json['user_loc_id'] as int,
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loc_perm_id': locPermId,
      'user_loc_id': userLocId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
