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
      userId: json['user_id'],
      firstName: json['user_fname'],
      lastName: json['user_lname'],
      email: json['user_email'],
      displayName: json['user_displayname'],
    );
  }

  String get fullName => '$firstName $lastName';
}
