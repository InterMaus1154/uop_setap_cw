class InvitationCode {
  final int id;
  final int creatorId;
  final String code;
  final int? guestUserId; 
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;

  InvitationCode({
    required this.id,
    required this.creatorId,
    required this.code,
    required this.guestUserId,
    required this.createdAt,
    required this.expiresAt,
    required this.isUsed,
});

/// Parse JSON response from beckend into InviationCode object
factory InvitationCode.fromJson(Map<String, dynamic> json) {
  return InvitationCode(
    id: json['id'] as int,
    creatorId: json['creator_id'] as int,
    code: json['code'] as String,
    guestUserId: json['guest_user_id'] as int?,
    createdAt: DateTime.parse(json['created_at'] as String),
    expiresAt: DateTime.parse(json['expires_at'] as String),
    isUsed: json['is_used'] as bool,
  );

}

/// Helper: Check if code is still active (not used and not expired)
bool get isActive => !isUsed && DateTime.now().isBefore(expiresAt);

String get expirationText {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inHours < 1) {
      return 'Expires in ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'Expires in ${difference.inHours} hours';
    } else {
      return 'Expires in ${difference.inDays} days';
    }
  }
}