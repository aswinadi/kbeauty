import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/product.dart';

class ProductService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  final _authService = AuthService();

  Future<List<Product>> getProducts({int? categoryId, String? search}) async {
    try {
      final token = await _authService.getToken();
      String url = '$baseUrl/products?';
      if (categoryId != null) url += 'category_id=$categoryId&';
      if (search != null) url += 'search=$search';

      final response = await http.get(
        Uri.parse(url),
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
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => Category.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }
}
