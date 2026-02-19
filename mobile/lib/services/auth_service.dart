import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = AppConfig.apiBaseUrl;
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
}
