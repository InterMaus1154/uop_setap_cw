class Pin {
  final int pinId;
  final int catId;
  final int? subCatId;
  final int userId;
  final String pinTitle;
  final String? pinDescription;
  final String? pinPicturePath;
  final double pinLatitude;
  final double pinLongitude;
  final bool pinIsActive;
  final DateTime pinExpireAt;
  final DateTime createdAt;

  Pin({
    required this.pinId,
    required this.catId,
    this.subCatId,
    required this.userId,
    required this.pinTitle,
    this.pinDescription,
    this.pinPicturePath,
    required this.pinLatitude,
    required this.pinLongitude,
    required this.pinIsActive,
    required this.pinExpireAt,
    required this.createdAt,
  });

  factory Pin.fromJson(Map<String, dynamic> json) {
    return Pin(
      pinId: json['pin_id'] as int,
      catId: json['cat_id'] as int,
      subCatId: json['sub_cat_id'] as int?,
      userId: json['user_id'] as int,
      pinTitle: json['pin_title'] as String,
      pinDescription: json['pin_description'] as String?,
      pinPicturePath: json['pin_picture_path'] as String?,
      pinLatitude: (json['pin_latitude'] as num).toDouble(),
      pinLongitude: (json['pin_longitude'] as num).toDouble(),
      pinIsActive: json['pin_isactive'] as bool,
      pinExpireAt: DateTime.parse(json['pin_expire_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pin_id': pinId,
      'cat_id': catId,
      'sub_cat_id': subCatId,
      'user_id': userId,
      'pin_title': pinTitle,
      'pin_description': pinDescription,
      'pin_picture_path': pinPicturePath,
      'pin_latitude': pinLatitude,
      'pin_longitude': pinLongitude,
      'pin_isactive': pinIsActive,
      'pin_expire_at': pinExpireAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(pinExpireAt);
}

class PinReaction {
  final int reactionId;
  final int pinId;
  final int userId;
  final int reactionValue; // 1 for upvote, -1 for downvote
  final DateTime createdAt;

  PinReaction({
    required this.reactionId,
    required this.pinId,
    required this.userId,
    required this.reactionValue,
    required this.createdAt,
  });

  factory PinReaction.fromJson(Map<String, dynamic> json) {
    return PinReaction(
      reactionId: json['reaction_id'] as int,
      pinId: json['pin_id'] as int,
      userId: json['user_id'] as int,
      reactionValue: json['reaction_value'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
