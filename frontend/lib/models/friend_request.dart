class FriendRequest {
  final int userRelId;
  final int userId;
  final int targetUserId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendRequest({
    required this.userRelId,
    required this.userId,
    required this.targetUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      userRelId: json['user_rel_id'] as int,
      userId: json['user_id'] as int,
      targetUserId: json['target_user_id'] as int,
      status: json['user_rel_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_rel_id': userRelId,
      'user_id': userId,
      'target_user_id': targetUserId,
      'user_rel_status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
