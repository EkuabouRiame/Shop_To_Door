import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class AdminOrderService {
  // =========================================================
  // GET ALL ADMIN ORDERS
  // =========================================================

  static Future<List<dynamic>> getOrders() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final orders = data['orders'];

      if (orders is List) {
        return orders;
      }

      return [];
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load orders.',
    );
  }

  // =========================================================
  // GET SINGLE ORDER
  // =========================================================

  static Future<Map<String, dynamic>> getOrder(
    int orderId,
  ) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/orders/$orderId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final order = data['order'];

      if (order is Map<String, dynamic>) {
        return order;
      }

      throw Exception(
        'Invalid order response.',
      );
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load order.',
    );
  }

  // =========================================================
  // UPDATE ORDER STATUS
  // =========================================================

  static Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/orders/$orderId/status',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final order = data['order'];

      if (order is Map<String, dynamic>) {
        return order;
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to update order status.',
    );
  }

  // =========================================================
  // RESPONSE DECODER
  // =========================================================

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'message': 'Unexpected server response.',
      };
    } catch (_) {
      return {
        'message':
            'Unable to understand server response (${response.statusCode}).',
      };
    }
  }
}