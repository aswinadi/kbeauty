class User {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
    };
  }
}
