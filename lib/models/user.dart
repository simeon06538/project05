enum UserRole { customer, courier }

/// A customer or courier returned by the server. Earnings are demo money.
class User {
  const User({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.earningsCents = 0,
  });

  final int id;
  final String name;
  final String? email;
  final UserRole role;
  final int earningsCents;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String?,
    role: UserRole.values.byName(json['role'] as String),
    earningsCents: ((json['earnings'] as num) * 100).round(),
  );

  /// Serializes the API model, not a POST /users request body.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'earnings': earningsCents / 100,
  };
}
