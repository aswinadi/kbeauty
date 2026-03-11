import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  final _storage = const FlutterSecureStorage();

  Future<User?> login(String username, String password, {bool rememberMe = true}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'device_name': 'mobile_app',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user'], token: data['token']);
        
        await _storage.write(key: 'auth_token', value: user.token);
        await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
        await _storage.write(key: 'remember_me', value: rememberMe.toString());
        
        return user;
      } else {
        print('Login failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'user_data');
    }
  }

  Future<User?> getUser() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> checkPersistentSession() async {
    final rememberMeStr = await _storage.read(key: 'remember_me');
    if (rememberMeStr != 'true') {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'user_data');
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }

  Future<List<User>> getUsers() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((u) => User.fromJson(u)).toList();
      }
    } catch (e) {
      print('Get users error: $e');
    }
    return [];
  }

  Future<User?> impersonate(int userId) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/impersonate/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user'], token: data['token']);
        
        // Switch to impersonated user
        await _storage.write(key: 'auth_token', value: user.token);
        await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
        
        return user;
      }
    } catch (e) {
      print('Impersonate error: $e');
    }
    return null;
  }
}
