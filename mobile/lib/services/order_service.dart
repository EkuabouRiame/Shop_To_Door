import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class OrderService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login to place an order.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // =========================================================
  // CREATE ORDER
  // =========================================================

  static Future<Map<String, dynamic>> createOrder({
    required String paymentMethod,
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
    required String shippingCity,
    required String shippingState,
    required String shippingPincode,
    String notes = '',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.orders}/'),
      headers: await _headers(),
      body: jsonEncode({
        'payment_method': paymentMethod,
        'shipping_name': shippingName.trim(),
        'shipping_phone': shippingPhone.trim(),
        'shipping_address': shippingAddress.trim(),
        'shipping_city': shippingCity.trim(),
        'shipping_state': shippingState.trim(),
        'shipping_pincode': shippingPincode.trim(),
        'notes': notes.trim(),
      }),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // GET ORDERS
  // =========================================================

  static Future<Map<String, dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.orders}/'),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // GET SINGLE ORDER
  // =========================================================

  static Future<Map<String, dynamic>> getOrder(
    int orderId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.orders}/$orderId'),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // CANCEL ORDER
  // =========================================================

  static Future<Map<String, dynamic>> cancelOrder(
    int orderId,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.orders}/$orderId/cancel'),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // CHECK DELIVERY CONFIRMATION QR
  // =========================================================

  static Future<Map<String, dynamic>> getDeliveryConfirmation(
    String token,
  ) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      throw Exception('Invalid delivery confirmation token.');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.orders}/delivery-confirmation/$cleanToken',
      ),
      headers: {
        'Accept': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  // =========================================================
  // CONFIRM DELIVERY
  // =========================================================

  static Future<Map<String, dynamic>> confirmDelivery(
    String token,
  ) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      throw Exception('Invalid delivery confirmation token.');
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.orders}/delivery-confirmation/$cleanToken/confirm',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

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
          'Order request failed.',
    );
  }
}