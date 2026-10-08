import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  // =========================================================
  // GET PRODUCTS
  // =========================================================

  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    int? categoryId,
    String? sort,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    // CATEGORY FILTER
    if (categoryId != null) {
      queryParameters['category_id'] = categoryId.toString();
    }

    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }

    final uri = Uri.parse(
      ApiConfig.products,
    ).replace(
      queryParameters: queryParameters,
    );

    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(_timeout);

    return _handleResponse(response);
  }

  // =========================================================
  // GET SINGLE PRODUCT
  // =========================================================

  static Future<Map<String, dynamic>> getProduct(
    int productId,
  ) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.products}$productId',
          ),
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(_timeout);

    return _handleResponse(response);
  }

  // =========================================================
  // GET CATEGORIES
  // =========================================================

  static Future<Map<String, dynamic>> getCategories() async {
    final response = await http
        .get(
          Uri.parse(
            ApiConfig.categories,
          ),
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(_timeout);

    return _handleResponse(response);
  }

  // =========================================================
  // RESPONSE HANDLER
  // =========================================================

  static Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Invalid response from server (${response.statusCode}).',
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Unexpected server response.',
      );
    }

    String message =
        'Request failed (${response.statusCode}).';

    if (decoded is Map<String, dynamic>) {
      final serverMessage = decoded['message'];

      if (serverMessage != null) {
        message = serverMessage.toString();
      }
    }

    throw Exception(message);
  }
}