
class ApiConfig {
  // Production backend hosted on Google Cloud Run
  static const String baseUrl =
      'https://shop-to-door-backend-294288480400.asia-south2.run.app/api';

  // API endpoints
  static const String products = '$baseUrl/products/';
  static const String categories = '$baseUrl/categories/';
  static const String auth = '$baseUrl/auth';
  static const String cart = '$baseUrl/cart';
  static const String orders = '$baseUrl/orders';
  static const String payments = '$baseUrl/payments';
}