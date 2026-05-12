class User {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? displayName;
  final bool useDisplayName;
  final bool isActive;
  final DateTime? expiresAt;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.displayName,
    required this.useDisplayName,
    required this.isActive,
    this.expiresAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      firstName: json['user_fname'] as String,
      lastName: json['user_lname'] as String,
      email: json['user_email'] as String,
      displayName: json['user_displayname'] as String?,
      useDisplayName: json['user_use_displayname'] as bool,
      isActive: json['user_isactive'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  bool get isGuest => expiresAt != null;

  String get fullName => '$firstName $lastName'.trim();
}
