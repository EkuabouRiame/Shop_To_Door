import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class AdminCategoryService {
  static Future<List<dynamic>> getCategories() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/categories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final categories = data['categories'];

      if (categories is List) {
        return categories;
      }

      return [];
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load categories.',
    );
  }

  static Future<Map<String, dynamic>> getCategory(
    int categoryId,
  ) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/categories/$categoryId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final category = data['category'];

      if (category is Map<String, dynamic>) {
        return category;
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load category.',
    );
  }

  static Future<Map<String, dynamic>> createCategory({
    required String name,
    String? slug,
    String? description,
    String? image,
    required bool isActive,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final body = <String, dynamic>{
      'name': name.trim(),
      'is_active': isActive,
    };

    if (slug != null && slug.trim().isNotEmpty) {
      body['slug'] = slug.trim();
    }

    if (description != null &&
        description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }

    if (image != null && image.trim().isNotEmpty) {
      body['image'] = image.trim();
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/categories'),
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
      final category = data['category'];

      if (category is Map<String, dynamic>) {
        return category;
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to create category.',
    );
  }

  static Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
    required String name,
    String? slug,
    String? description,
    String? image,
    required bool isActive,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final body = <String, dynamic>{
      'name': name.trim(),
      'is_active': isActive,
    };

    if (slug != null && slug.trim().isNotEmpty) {
      body['slug'] = slug.trim();
    } else {
      body['slug'] = '';
    }

    if (description != null &&
        description.trim().isNotEmpty) {
      body['description'] = description.trim();
    } else {
      body['description'] = '';
    }

    if (image != null && image.trim().isNotEmpty) {
      body['image'] = image.trim();
    }

    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/categories/$categoryId',
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
      final category = data['category'];

      if (category is Map<String, dynamic>) {
        return category;
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to update category.',
    );
  }

  static Future<void> deleteCategory(
    int categoryId,
  ) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/categories/$categoryId',
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
          'Unable to delete category.',
    );
  }

  static Future<Map<String, dynamic>> uploadCategoryImage({
    required int categoryId,
    required File imageFile,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/categories/$categoryId/image',
      ),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final category = data['category'];

      if (category is Map<String, dynamic>) {
        return category;
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to upload category image.',
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