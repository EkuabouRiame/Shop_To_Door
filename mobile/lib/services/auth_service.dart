import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user';

  // =========================================================
  // LOGIN
  // =========================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.auth}/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final token = data['access_token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception(
          'Login succeeded but no access token was returned.',
        );
      }

      final prefs =
          await SharedPreferences.getInstance();

      // Save access token
      await prefs.setString(
        _tokenKey,
        token.toString(),
      );

      // Save user information
      if (data['user'] != null) {
        await prefs.setString(
          _userKey,
          jsonEncode(data['user']),
        );

        // Debug information
        final user = data['user'];

        if (user is Map<String, dynamic>) {
          debugPrint('========================================');
          debugPrint('LOGIN SUCCESS');
          debugPrint('USER ID: ${user['id']}');
          debugPrint('USER NAME: ${user['name']}');
          debugPrint('USER EMAIL: ${user['email']}');
          debugPrint('USER ROLE: ${user['role']}');
          debugPrint('========================================');
        }
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Login failed.',
    );
  }

  // =========================================================
  // REGISTER
  // =========================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.auth}/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final token = data['access_token'];

      if (token != null &&
          token.toString().isNotEmpty) {
        final prefs =
            await SharedPreferences.getInstance();

        // Save access token
        await prefs.setString(
          _tokenKey,
          token.toString(),
        );

        // Save user information
        if (data['user'] != null) {
          await prefs.setString(
            _userKey,
            jsonEncode(data['user']),
          );

          final user = data['user'];

          if (user is Map<String, dynamic>) {
            debugPrint('========================================');
            debugPrint('REGISTRATION SUCCESS');
            debugPrint('USER ID: ${user['id']}');
            debugPrint('USER NAME: ${user['name']}');
            debugPrint('USER EMAIL: ${user['email']}');
            debugPrint('USER ROLE: ${user['role']}');
            debugPrint('========================================');
          }
        }
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Registration failed.',
    );
  }

  // =========================================================
  // SEND PASSWORD RESET OTP
  // =========================================================

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.auth}/forgot-password',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to send password reset OTP.',
    );
  }

  // =========================================================
  // VERIFY PASSWORD RESET OTP
  // =========================================================

  static Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.auth}/verify-reset-otp',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Invalid or expired OTP.',
    );
  }

  // =========================================================
  // RESET PASSWORD
  // =========================================================

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.auth}/reset-password',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to reset password.',
    );
  }

  // =========================================================
  // GET SAVED TOKEN
  // =========================================================

  static Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  // =========================================================
  // CHECK LOGIN
  // =========================================================

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  // =========================================================
  // GET SAVED USER
  // =========================================================

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs =
        await SharedPreferences.getInstance();

    final userJson = prefs.getString(_userKey);

    if (userJson == null || userJson.isEmpty) {
      debugPrint('========================================');
      debugPrint('SAVED USER: No user found');
      debugPrint('========================================');

      return null;
    }

    try {
      final decoded = jsonDecode(userJson);

      if (decoded is Map<String, dynamic>) {
        debugPrint('========================================');
        debugPrint('SAVED USER');
        debugPrint('USER ID: ${decoded['id']}');
        debugPrint('USER NAME: ${decoded['name']}');
        debugPrint('USER EMAIL: ${decoded['email']}');
        debugPrint('USER ROLE: ${decoded['role']}');
        debugPrint('========================================');

        return decoded;
      }

      debugPrint('========================================');
      debugPrint('SAVED USER: Invalid user data');
      debugPrint('========================================');

      return null;
    } catch (e) {
      debugPrint('========================================');
      debugPrint('SAVED USER ERROR: $e');
      debugPrint('========================================');

      return null;
    }
  }

  // =========================================================
  // GET SAVED USER ROLE
  // =========================================================

  static Future<String?> getUserRole() async {
    final user = await getSavedUser();

    if (user == null) {
      return null;
    }

    final role = user['role'];

    if (role == null) {
      return null;
    }

    return role.toString().trim().toLowerCase();
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  static Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    // Clear saved login session
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    debugPrint('========================================');
    debugPrint('USER LOGGED OUT');
    debugPrint('========================================');
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