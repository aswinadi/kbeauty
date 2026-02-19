import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  // Use 10.0.2.2 for Android Emulator to access localhost
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  final _storage = const FlutterSecureStorage();

  Future<User?> login(String username, String password) async {
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
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
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
}
