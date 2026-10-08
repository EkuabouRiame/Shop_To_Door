class ApiConfig {
  // Android Emulator → Windows host computer
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // API endpoints
  static const String products = '$baseUrl/products/';
  static const String categories = '$baseUrl/categories/';
  static const String auth = '$baseUrl/auth';
  static const String cart = '$baseUrl/cart';
  static const String orders = '$baseUrl/orders';
  static const String payments = '$baseUrl/payments';
}