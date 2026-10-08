import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class AdminProductService {
  static Future<List<dynamic>> getProducts() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/products'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final products = data['products'];

      if (products is List) {
        return products;
      }

      return [];
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load products.',
    );
  }

  static Future<Map<String, dynamic>> getProduct(
    int productId,
  ) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/products/$productId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final product = data['product'];

      if (product is Map<String, dynamic>) {
        return product;
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load product.',
    );
  }

  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String brand,
    required String description,
    required String sku,
    required int categoryId,
    required String price,
    String? discountPrice,
    required int stock,
    required bool isFeatured,
    required bool isActive,
    File? imageFile,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/products',
      ),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['name'] = name.trim();
    request.fields['brand'] = brand.trim();
    request.fields['description'] = description.trim();
    request.fields['sku'] = sku.trim();
    request.fields['category_id'] = categoryId.toString();
    request.fields['price'] = price.trim();
    request.fields['stock'] = stock.toString();
    request.fields['is_featured'] =
        isFeatured ? 'true' : 'false';
    request.fields['is_active'] =
        isActive ? 'true' : 'false';

    if (discountPrice != null &&
        discountPrice.trim().isNotEmpty) {
      request.fields['discount_price'] =
          discountPrice.trim();
    }

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );
    }

    final streamedResponse = await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final product = data['product'];

      if (product is Map<String, dynamic>) {
        return product;
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to create product.',
    );
  }

  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required Map<String, dynamic> data,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/products/$productId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    final responseData = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final product = responseData['product'];

      if (product is Map<String, dynamic>) {
        return product;
      }

      return responseData;
    }

    throw Exception(
      responseData['message']?.toString() ??
          'Unable to update product.',
    );
  }

  static Future<List<dynamic>> getProductImages(
    int productId,
  ) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/products/$productId/images',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final images = data['images'];

      if (images is List) {
        return images;
      }

      return [];
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load product images.',
    );
  }

  static Future<Map<String, dynamic>> uploadProductImage({
    required int productId,
    required File imageFile,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/products/$productId/images/upload',
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

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final image = data['image'];

      if (image is Map<String, dynamic>) {
        return image;
      }

      return data;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to upload product image.',
    );
  }

  static Future<void> setPrimaryProductImage({
    required int productId,
    required int imageId,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/products/$productId/images/$imageId/primary',
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
          'Unable to set primary image.',
    );
  }

  static Future<void> deleteProductImage({
    required int productId,
    required int imageId,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/products/$productId/images/$imageId',
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
          'Unable to delete product image.',
    );
  }

  static Future<void> deleteProduct(
    int productId,
  ) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/admin/products/$productId',
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
          'Unable to delete product.',
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