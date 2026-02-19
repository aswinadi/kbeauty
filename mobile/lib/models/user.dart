class User {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String? token;
  final List<String> roles;

  User({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.token,
    this.roles = const [],
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    List<String> roles = [];
    if (json['roles'] != null) {
      if (json['roles'] is List) {
        roles = (json['roles'] as List).map((r) => r['name'].toString()).toList();
      }
    }

    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      token: token,
      roles: roles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'roles': roles.map((r) => {'name': r}).toList(),
    };
  }
}
