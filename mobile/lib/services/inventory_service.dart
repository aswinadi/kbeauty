import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/product.dart';
import '../models/stock_opname.dart';
import '../config/app_config.dart';

class InventoryService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  final _authService = AuthService();

  Future<List<Category>> getLocations() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/locations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        // We'll reuse the Category model for simple name/id pairs like locations
        return data.map((item) => Category.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching locations: $e');
      return [];
    }
  }

  Future<List<Product>> getOpnameProducts() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/opname-products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching opname products: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching stats: $e');
      return {};
    }
  }

  Future<bool> recordMovement(int productId, int locationId, double qty, String type) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/move'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': productId,
          'location_id': locationId,
          'qty': qty,
          'type': type,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error recording movement: $e');
      return false;
    }
  }

  Future<bool> recordTransfer(int productId, int fromLocationId, int toLocationId, double qty) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/transfer'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': productId,
          'from_location_id': fromLocationId,
          'to_location_id': toLocationId,
          'qty': qty,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error recording transfer: $e');
      return false;
    }
  }

  Future<bool> submitStockOpname(int locationId, List<StockOpnameItem> items) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/stock-opname'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'location_id': locationId,
          'items': items.map((i) => i.toJson()).toList(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error submitting stock opname: $e');
      return false;
    }
  }

  Future<bool> recordBulkTransaction({
    required String type,
    required int locationId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/bulk-transaction'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': type,
          'location_id': locationId,
          'items': items,
          'notes': notes,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error recording bulk transaction: $e');
      return false;
    }
  }
}
