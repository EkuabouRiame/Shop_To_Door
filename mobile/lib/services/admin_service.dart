import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class AdminService {
  // =========================================================
  // GET ADMIN DASHBOARD
  // =========================================================

  static Future<Map<String, dynamic>> getDashboard() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/dashboard'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load admin dashboard.',
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