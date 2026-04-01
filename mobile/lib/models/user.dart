import 'employee.dart';

class User {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String? token;
  final List<String> roles;
  final List<String> permissions;
  final Employee? employee;

  User({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.token,
    this.roles = const [],
    this.permissions = const [],
    this.employee,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    List<String> roles = [];
    if (json['roles'] != null) {
      if (json['roles'] is List) {
        roles = (json['roles'] as List).map((r) => r['name'].toString()).toList();
      }
    }

    List<String> permissions = [];
    if (json['permissions'] != null) {
      if (json['permissions'] is List) {
        permissions = (json['permissions'] as List).map((p) => p.toString()).toList();
      }
    }

    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      token: token,
      roles: roles,
      permissions: permissions,
      employee: json['employee'] != null ? Employee.fromJson(json['employee']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'roles': roles.map((r) => {'name': r}).toList(),
      'permissions': permissions,
      'employee': employee?.toJson(),
    };
  }
}
