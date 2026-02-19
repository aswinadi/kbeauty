import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/product.dart';
import '../config/app_config.dart';

class ProductService {
  static const String baseUrl = AppConfig.apiBaseUrl;
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

  Future<List<Unit>> getUnits() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/units'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => Unit.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching units: $e');
      return [];
    }
  }

  Future<bool> updateProduct({
    required int id,
    required String name,
    required String sku,
    required double price,
    required int categoryId,
    required int unitId,
    File? imageFile,
  }) async {
    try {
      final token = await _authService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/products/$id'));
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['name'] = name;
      request.fields['sku'] = sku;
      request.fields['price'] = price.toString();
      request.fields['category_id'] = categoryId.toString();
      request.fields['unit_id'] = unitId.toString();

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error updating product: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception updating product: $e');
      return false;
    }
  }
}
