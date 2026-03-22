import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

class PosService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  final _authService = AuthService();

  Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/pos/items'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching POS items: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/pos/employees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching employees: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCustomers({String? search}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/pos/customers${search != null ? '?search=$search' : ''}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching customers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> registerCustomer(Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/pos/customers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error registering customer: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitTransaction(Map<String, dynamic> transactionData) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/pos/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(transactionData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to submit transaction');
      }
    } catch (e) {
      print('Error submitting transaction: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllTransactions({int page = 1}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/pos/transactions?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'data': []};
    } catch (e) {
      print('Error fetching transactions: $e');
      return {'data': []};
    }
  }

  Future<Map<String, dynamic>?> getPerformance({String? fromDate, String? toDate}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/pos/performance${fromDate != null ? '?from_date=$fromDate&to_date=$toDate' : ''}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching performance: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCustomerDetails(int customerId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/pos/customers/$customerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching customer details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerPortfolios(int customerId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/pos/customers/$customerId/portfolios'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching customer portfolios: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> addCustomerPortfolio(
    int customerId, {
    String? notes,
    List<File>? images,
    int? posTransactionId,
    int? appointmentId,
  }) async {
    try {
      final token = await _authService.getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/pos/customers/$customerId/portfolios'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (notes != null) {
        request.fields['notes'] = notes;
      }

      if (posTransactionId != null) {
        request.fields['pos_transaction_id'] = posTransactionId.toString();
      }

      if (appointmentId != null) {
        request.fields['appointment_id'] = appointmentId.toString();
      }

      if (images != null && images.isNotEmpty) {
        for (var i = 0; i < images.length; i++) {
          request.files.add(await http.MultipartFile.fromPath(
            'images[]',
            images[i].path,
          ));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error adding customer portfolio: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerHistory(int customerId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/pos/customers/$customerId/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching customer history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAppointments({String? date}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/appointments${date != null ? '?date=$date' : ''}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching appointments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> addAppointment(Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error adding appointment: $e');
      return null;
    }
  }

  // Master Data - Service Categories
  Future<List<Map<String, dynamic>>> getServiceCategories() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/master/service-categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching service categories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> saveServiceCategory(Map<String, dynamic> data, {int? id}) async {
    try {
      final token = await _authService.getToken();
      final url = id != null ? '$baseUrl/master/service-categories/$id' : '$baseUrl/master/service-categories';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error saving service category: $e');
      return null;
    }
  }

  // Master Data - Services
  Future<List<Map<String, dynamic>>> getMasterServices() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/master/services'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching master services: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> saveMasterService(Map<String, dynamic> data, {int? id}) async {
    try {
      final token = await _authService.getToken();
      final url = id != null ? '$baseUrl/master/services/$id' : '$baseUrl/master/services';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error saving master service: $e');
      return null;
    }
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/pos/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching POS settings: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDiscounts() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/discounts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching discounts: $e');
      return [];
    }
  }
}
