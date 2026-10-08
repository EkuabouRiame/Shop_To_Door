import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class CartService {
  // =========================================================
  // AUTH HEADERS
  // =========================================================

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login to use your cart.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // =========================================================
  // GET CART
  // =========================================================

  static Future<Map<String, dynamic>> getCart() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.cart}/'),
      headers: await _headers(),
    );

    // DEBUG: Show the actual response from Flask
    debugPrint('========================================');
    debugPrint('CART STATUS: ${response.statusCode}');
    debugPrint('CART RESPONSE: ${response.body}');
    debugPrint('========================================');

    return _handleResponse(response);
  }

  // =========================================================
  // ADD TO CART
  // =========================================================

  static Future<Map<String, dynamic>> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.cart}/items'),
      headers: await _headers(),
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
      }),
    );

    // DEBUG: Show add-to-cart response
    debugPrint('========================================');
    debugPrint('ADD TO CART STATUS: ${response.statusCode}');
    debugPrint('ADD TO CART RESPONSE: ${response.body}');
    debugPrint('========================================');

    return _handleResponse(response);
  }

  // =========================================================
  // UPDATE CART ITEM
  // =========================================================

  static Future<Map<String, dynamic>> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.cart}/items/$itemId'),
      headers: await _headers(),
      body: jsonEncode({
        'quantity': quantity,
      }),
    );

    // DEBUG: Show update response
    debugPrint('========================================');
    debugPrint('UPDATE CART STATUS: ${response.statusCode}');
    debugPrint('UPDATE CART RESPONSE: ${response.body}');
    debugPrint('========================================');

    return _handleResponse(response);
  }

  // =========================================================
  // REMOVE CART ITEM
  // =========================================================

  static Future<Map<String, dynamic>> removeCartItem(
    int itemId,
  ) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.cart}/items/$itemId'),
      headers: await _headers(),
    );

    // DEBUG: Show remove response
    debugPrint('========================================');
    debugPrint('REMOVE CART STATUS: ${response.statusCode}');
    debugPrint('REMOVE CART RESPONSE: ${response.body}');
    debugPrint('========================================');

    return _handleResponse(response);
  }

  // =========================================================
  // CLEAR CART
  // =========================================================

  static Future<Map<String, dynamic>> clearCart() async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.cart}/clear'),
      headers: await _headers(),
    );

    // DEBUG: Show clear response
    debugPrint('========================================');
    debugPrint('CLEAR CART STATUS: ${response.statusCode}');
    debugPrint('CLEAR CART RESPONSE: ${response.body}');
    debugPrint('========================================');

    return _handleResponse(response);
  }

  // =========================================================
  // RESPONSE HANDLER
  // =========================================================

  static Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        data = {
          'message': 'Unexpected server response.',
        };
      }
    } catch (_) {
      data = {
        'message':
            'Unable to understand server response (${response.statusCode}).',
      };
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Cart request failed.',
    );
  }
}