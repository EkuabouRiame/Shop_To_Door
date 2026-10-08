import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class AdminDeliveryService {
  static Future<List<dynamic>> getDeliveryPersons() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/orders/admin/delivery-persons',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final deliveryPersons = data['delivery_persons'];

      if (deliveryPersons is List) {
        return deliveryPersons;
      }

      return [];
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load delivery personnel.',
    );
  }

  static Future<Map<String, dynamic>> createDeliveryAccount({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'confirm_password': confirmPassword,
    };

    if (phone != null && phone.trim().isNotEmpty) {
      body['phone'] = phone.trim();
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/auth/admin/delivery-accounts',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final user = data['user'];

      if (user is Map<String, dynamic>) {
        return user;
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to create delivery account.',
    );
  }

  // =====================================================
  // DELETE DELIVERY ACCOUNT
  // =====================================================

  static Future<void> deleteDeliveryAccount(
    int deliveryUserId,
  ) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/auth/admin/delivery-accounts/$deliveryUserId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to delete delivery account.',
    );
  }

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
            'Unable to understand server response '
            '(${response.statusCode}).',
      };
    }
  }
}