import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import '../config/api_config.dart';
import '../services/auth_service.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState
    extends State<DeliveryDashboardScreen> {
  List<Map<String, dynamic>> _orders = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  bool _isGeneratingQr = false;

  @override
  void initState() {
    super.initState();
    _loadAssignedOrders();
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _loadAssignedOrders({
    bool refresh = false,
  }) async {
    if (refresh) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.orders}/delivery/my-orders',
        ),
        headers: await _headers(),
      );

      final body = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(
          body['message']?.toString() ??
              'Failed to load assigned delivery orders.',
        );
      }

      final data = body['orders'];

      final orders = <Map<String, dynamic>>[];

      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            orders.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  Future<void> _updateDeliveryStatus(
    int orderId,
    String status,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.orders}/delivery/$orderId/status',
        ),
        headers: await _headers(),
        body: jsonEncode({
          'status': status,
        }),
      );

      final body = _decodeResponse(response);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          body['message']?.toString() ??
              'Unable to update delivery status.',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'out_for_delivery'
                ? 'Order marked as out for delivery.'
                : 'Delivery status updated.',
          ),
        ),
      );

      await _loadAssignedOrders(refresh: true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // GENERATE DELIVERY CONFIRMATION QR
  // ------------------------------------------------------------

  Future<void> _generateConfirmationQr(
    int orderId,
  ) async {
    if (_isGeneratingQr) {
      return;
    }

    setState(() {
      _isGeneratingQr = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.orders}/delivery/$orderId/confirmation-qr',
        ),
        headers: await _headers(),
      );

      final body = _decodeResponse(response);

      debugPrint(
        'QR RESPONSE STATUS: ${response.statusCode}',
      );

      debugPrint(
        'QR RESPONSE BODY: ${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          body['message']?.toString() ??
              body['error']?.toString() ??
              'Unable to generate delivery confirmation QR.',
        );
      }

      // The backend returns confirmation_url directly.
      // Also support a nested data object in case the response
      // structure changes later.
      String? confirmationUrl;

      if (body['confirmation_url'] != null) {
        confirmationUrl =
            body['confirmation_url'].toString().trim();
      }

      if ((confirmationUrl == null ||
              confirmationUrl.isEmpty) &&
          body['data'] is Map) {
        final data =
            Map<String, dynamic>.from(body['data']);

        if (data['confirmation_url'] != null) {
          confirmationUrl =
              data['confirmation_url'].toString().trim();
        }
      }

      if (confirmationUrl == null ||
          confirmationUrl.isEmpty) {
        throw Exception(
          'The server did not return a confirmation QR URL.',
        );
      }

      DateTime? expiresAt;

      final expiresAtValue = body['expires_at'];

      if (expiresAtValue != null) {
        expiresAt = DateTime.tryParse(
          expiresAtValue.toString(),
        );
      }

      if (!mounted) return;

      setState(() {
        _isGeneratingQr = false;
      });

      // Pass the freshly received URL directly to the dialog.
      // This ensures the QR is generated from the actual server
      // response immediately.
      _showQrDialog(
        confirmationUrl,
        orderId,
        expiresAt,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGeneratingQr = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SHOW DELIVERY QR
  // ------------------------------------------------------------

  void _showQrDialog(
    String confirmationUrl,
    int orderId,
    DateTime? expiresAt,
  ) {
    if (confirmationUrl.trim().isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.qr_code_2,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivery Confirmation',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order #$orderId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: 280,
                  height: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: QrImageView(
                      data: confirmationUrl,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel:
                          QrErrorCorrectLevel.M,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Ask the customer to scan this QR code to confirm delivery.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),

                if (expiresAt != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Expires: ${_formatDateTime(expiresAt)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                Text(
                  'The customer does not need to log in to scan this QR.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${twoDigits(local.day)}/'
        '${twoDigits(local.month)}/'
        '${local.year} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}';
  }

  String _orderStatus(
    Map<String, dynamic> order,
  ) {
    return order['status']
            ?.toString()
            .trim()
            .toLowerCase() ??
        'unknown';
  }

  int? _orderId(
    Map<String, dynamic> order,
  ) {
    final value = order['id'];

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  String _customerName(
    Map<String, dynamic> order,
  ) {
    return order['customer_name']?.toString() ??
        order['user_name']?.toString() ??
        order['customer']?['name']?.toString() ??
        'Customer';
  }

  String _customerPhone(
    Map<String, dynamic> order,
  ) {
    return order['customer_phone']?.toString() ??
        order['user_phone']?.toString() ??
        order['customer']?['phone']?.toString() ??
        '';
  }

  String _deliveryAddress(
    Map<String, dynamic> order,
  ) {
    return order['delivery_address']?.toString() ??
        order['shipping_address']?.toString() ??
        order['address']?.toString() ??
        'Address not available';
  }

  String _paymentStatus(
    Map<String, dynamic> order,
  ) {
    return order['payment_status']?.toString() ??
        'pending';
  }

  String _orderTotal(
    Map<String, dynamic> order,
  ) {
    final value =
        order['total_amount'] ??
        order['total'] ??
        order['grand_total'] ??
        order['amount'];

    if (value == null) {
      return 'N/A';
    }

    return '₹${value.toString()}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'out_for_delivery':
        return Colors.orange;

      case 'delivered':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      case 'processing':
      case 'confirmed':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  String _prettyStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}'
                  '${word.substring(1)}',
        )
        .join(' ');
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: Colors.indigo,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
  ) {
    final orderId = _orderId(order);

    if (orderId == null) {
      return const SizedBox.shrink();
    }

    final status = _orderStatus(order);
    final customerName = _customerName(order);
    final customerPhone = _customerPhone(order);
    final address = _deliveryAddress(order);
    final paymentStatus = _paymentStatus(order);
    final total = _orderTotal(order);

    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #$orderId',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    _prettyStatus(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            _infoRow(
              Icons.person_outline,
              'Customer',
              customerName,
            ),

            if (customerPhone.isNotEmpty)
              _infoRow(
                Icons.phone_outlined,
                'Phone',
                customerPhone,
              ),

            _infoRow(
              Icons.location_on_outlined,
              'Address',
              address,
            ),

            _infoRow(
              Icons.currency_rupee,
              'Total',
              total,
            ),

            _infoRow(
              Icons.payment_outlined,
              'Payment',
              paymentStatus,
            ),

            const SizedBox(height: 12),

            if (status == 'assigned' ||
                status == 'confirmed' ||
                status == 'processing')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _updateDeliveryStatus(
                      orderId,
                      'out_for_delivery',
                    );
                  },
                  icon: const Icon(
                    Icons.local_shipping_outlined,
                  ),
                  label: const Text(
                    'Start Delivery',
                  ),
                ),
              ),

            if (status == 'out_for_delivery')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingQr
                      ? null
                      : () {
                          _generateConfirmationQr(
                            orderId,
                          );
                        },
                  icon: _isGeneratingQr
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.qr_code_2,
                        ),
                  label: Text(
                    _isGeneratingQr
                        ? 'Generating QR...'
                        : 'Show Delivery QR',
                  ),
                ),
              ),

            if (status == 'delivered')
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Delivery completed.',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (status == 'cancelled')
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This order has been cancelled.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.redAccent,
              ),

              const SizedBox(height: 16),

              const Text(
                'Unable to load delivery orders',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () {
                  _loadAssignedOrders();
                },
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () {
          return _loadAssignedOrders(
            refresh: true,
          );
        },
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),

            Icon(
              Icons.local_shipping_outlined,
              size: 70,
              color: Colors.grey,
            ),

            SizedBox(height: 16),

            Center(
              child: Text(
                'No orders assigned yet.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: 8),

            Center(
              child: Text(
                'Pull down to refresh.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        return _loadAssignedOrders(
          refresh: true,
        );
      },
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_orders.length} Assigned Order'
                  '${_orders.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (_isRefreshing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          ..._orders.map(_buildOrderCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delivery Dashboard',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isRefreshing
                ? null
                : () {
                    _loadAssignedOrders(
                      refresh: true,
                    );
                  },
            icon: const Icon(
              Icons.refresh,
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}