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
      pinId: json['pin_id'],
      catId: json['cat_id'],
      subCatId: json['sub_cat_id'],
      userId: json['user_id'],
      pinTitle: json['pin_title'],
      pinDescription: json['pin_description'],
      pinPicturePath: json['pin_picture_path'],
      pinLatitude: (json['pin_latitude'] as num).toDouble(),
      pinLongitude: (json['pin_longitude'] as num).toDouble(),
      pinIsActive: json['pin_isactive'],
      pinExpireAt: DateTime.parse(json['pin_expire_at']),
      createdAt: DateTime.parse(json['created_at']),
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
      reactionId: json['reaction_id'],
      pinId: json['pin_id'],
      userId: json['user_id'],
      reactionValue: json['reaction_value'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
