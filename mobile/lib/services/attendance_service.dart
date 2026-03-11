import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/office.dart';
import '../config/app_config.dart';

class AttendanceService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  final _authService = AuthService();

  Future<List<Office>> getOffices() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/offices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => Office.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching offices: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'checked_in': false, 'checked_out': false, 'attendance': null};
    } catch (e) {
      print('Error fetching attendance status: $e');
      return {'checked_in': false, 'checked_out': false, 'attendance': null};
    }
  }

  Future<Map<String, dynamic>> getHistory() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'attendances': [], 'absents': []};
    } catch (e) {
      print('Error fetching history: $e');
      return {'attendances': [], 'absents': []};
    }
  }

  Future<bool> checkIn({
    required int officeId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-in'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'office_id': officeId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Check-in failed');
      }
    } catch (e) {
      print('Check-in error: $e');
      rethrow;
    }
  }

  Future<bool> checkOut({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-out'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Check-out failed');
      }
    } catch (e) {
      print('Check-out error: $e');
      rethrow;
    }
  }

  Future<bool> submitAbsent({
    required int officeId,
    required String date,
    required String type,
    required String reason,
    List<File>? images,
  }) async {
    try {
      final token = await _authService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/attendance/request'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['office_id'] = officeId.toString();
      request.fields['date'] = date;
      request.fields['type'] = type;
      if (reason.isNotEmpty) request.fields['reason'] = reason;

      if (images != null) {
        for (var image in images) {
          request.files.add(
            await http.MultipartFile.fromPath('images[]', image.path),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Submit absent failed');
      }
    } catch (e) {
      print('Submit absent error: $e');
      rethrow;
    }
  }
}
