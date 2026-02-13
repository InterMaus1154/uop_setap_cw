class User {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? displayName;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.displayName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      firstName: json['user_fname'] as String,
      lastName: json['user_lname'] as String,
      email: json['user_email'] as String,
      displayName: json['user_displayname'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';
}
