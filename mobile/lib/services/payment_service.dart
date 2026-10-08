import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class PaymentService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login to make a payment.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> createPaymentOrder(
    int orderId,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.payments}/create/$orderId'),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.payments}/verify'),
      headers: await _headers(),
      body: jsonEncode({
        'order_id': orderId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      }),
    );

    return _handleResponse(response);
  }

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
          'Payment request failed.',
    );
  }
}