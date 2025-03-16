import 'dart:convert';
import 'package:http/http.dart' as http;

import 'constants.dart';

class ApiService {
  static Future<List<dynamic>> fetchCategories() async {
    final response = await http.post(Uri.parse(ApiEndpoints.categoriesUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'storeid': '1',
      })
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['Categories'];
    } else {
      throw Exception('Failed to load categories');
    }
  }

  static Future<Map<String, dynamic>> fetchLogoAndImages() async {
    final response = await http.get(
      Uri.parse('https://raw.githubusercontent.com/JayMatawaran/APIs/refs/heads/main/logo.json'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load logo and images');
    }
  }

  static Future<List<dynamic>> fetchProducts(String storeId) async {
    final response = await http.post(
      Uri.parse('http://sellercenter.shoppazing.com/api/shop/getstoreitemsbystoreid'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'storeid': storeId,
      }),
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['Items'];
    } else {
      throw Exception('Failed to load products ${response.body}');
    }
  }



  static Future<Map<String, dynamic>> fetchItemDetails(
      String storeId,
      String itemId,
      ) async {
    final response = await http.post(
      Uri.parse(
        'http://sellercenter.shoppazing.com/api/shop/getonlineitemdetails',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'storeid': storeId, 'itemId': itemId}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return {
        "itemVariants": data['itemVariants'] ?? [],
        "itemModifiers": data['itemModifiers'] ?? [],
      }; // Prevents null errors
    } else {
      throw Exception('Failed to load item details: ${response.body}');
    }
  }
}