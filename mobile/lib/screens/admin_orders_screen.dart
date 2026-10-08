import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/admin_order_service.dart';
import '../services/auth_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // =========================================================
  // LOAD ORDERS
  // =========================================================

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await AdminOrderService.getOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // =========================================================
  // INTEGER HELPER
  // =========================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // DOUBLE HELPER
  // =========================================================

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // TEXT HELPER
  // =========================================================

  String _text(
    dynamic value, {
    String fallback = '-',
  }) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  // =========================================================
  // ORDER ID
  // =========================================================

  int? _getOrderId(Map<String, dynamic> order) {
    final id = order['id'];

    if (id is int) {
      return id;
    }

    return int.tryParse(
      id?.toString() ?? '',
    );
  }

  // =========================================================
  // STATUS COLOR
  // =========================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;

      case 'assigned':
        return Colors.indigo;

      case 'packed':
        return Colors.deepPurple;

      case 'shipped':
        return Colors.blue;

      case 'picked_up':
        return Colors.cyan.shade700;

      case 'out_for_delivery':
        return Colors.teal;

      case 'delivered':
        return Colors.green;

      case 'delivery_failed':
        return Colors.redAccent;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // =========================================================
  // STATUS TEXT
  // =========================================================

  String _formatStatus(String status) {
    if (status.isEmpty) {
      return 'Unknown';
    }

    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) {
            if (word.isEmpty) return word;

            return word[0].toUpperCase() +
                word.substring(1).toLowerCase();
          },
        )
        .join(' ');
  }

  // =========================================================
  // PAYMENT STATUS
  // =========================================================

  String _getPaymentStatus(
    Map<String, dynamic> order,
  ) {
    return _text(
      order['payment_status'],
      fallback: 'Unknown',
    );
  }

  // =========================================================
  // CUSTOMER NAME
  // =========================================================

  String _getCustomerName(
    Map<String, dynamic> order,
  ) {
    final customer = order['user'];

    if (customer is Map<String, dynamic>) {
      final name = customer['name'];

      if (name != null &&
          name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }

    if (order['customer'] is Map<String, dynamic>) {
      final customerData =
          order['customer'] as Map<String, dynamic>;

      final name = customerData['name'];

      if (name != null &&
          name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }

    return _text(
      order['customer_name'],
      fallback: 'Customer',
    );
  }

  // =========================================================
  // ORDER TOTAL
  // =========================================================

  double _getOrderTotal(
    Map<String, dynamic> order,
  ) {
    return _toDouble(
      order['total_amount'] ??
          order['total'] ??
          order['grand_total'] ??
          order['amount'],
    );
  }

  // =========================================================
  // GET DELIVERY PERSON NAME
  // =========================================================

  String _getDeliveryPersonName(
    Map<String, dynamic> order,
  ) {
    final deliveryPerson =
        order['delivery_person'];

    if (deliveryPerson is Map<String, dynamic>) {
      return _text(
        deliveryPerson['name'],
        fallback: 'Delivery Person',
      );
    }

    if (order['delivery_person_name'] != null) {
      return _text(
        order['delivery_person_name'],
        fallback: 'Delivery Person',
      );
    }

    if (order['assigned_delivery_person'] is
        Map<String, dynamic>) {
      final person =
          order['assigned_delivery_person']
              as Map<String, dynamic>;

      return _text(
        person['name'],
        fallback: 'Delivery Person',
      );
    }

    return 'Not assigned';
  }

  // =========================================================
  // GET DELIVERY PERSON ID
  // =========================================================

  int? _getDeliveryPersonId(
    Map<String, dynamic> order,
  ) {
    final directId =
        order['delivery_person_id'];

    if (directId != null) {
      final id = int.tryParse(
        directId.toString(),
      );

      if (id != null) {
        return id;
      }
    }

    final deliveryPerson =
        order['delivery_person'];

    if (deliveryPerson is Map<String, dynamic>) {
      final id = deliveryPerson['id'];

      if (id != null) {
        return int.tryParse(
          id.toString(),
        );
      }
    }

    if (order['assigned_delivery_person'] is
        Map<String, dynamic>) {
      final person =
          order['assigned_delivery_person']
              as Map<String, dynamic>;

      final id = person['id'];

      if (id != null) {
        return int.tryParse(
          id.toString(),
        );
      }
    }

    return null;
  }

  // =========================================================
  // LOAD DELIVERY PERSONS
  // =========================================================

  Future<List<dynamic>> _getDeliveryPersons() async {
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
      final deliveryPersons =
          data['delivery_persons'];

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

  // =========================================================
  // ASSIGN DELIVERY PERSON
  // =========================================================

  Future<void> _assignDeliveryPerson({
    required int orderId,
    required int deliveryPersonId,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/orders/admin/$orderId/assign',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'delivery_person_id': deliveryPersonId,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to assign delivery person.',
    );
  }

  // =========================================================
  // UNASSIGN DELIVERY PERSON
  // =========================================================

  Future<void> _unassignDeliveryPerson(
    int orderId,
  ) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/orders/admin/$orderId/unassign',
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
          'Unable to unassign delivery person.',
    );
  }

  // =========================================================
  // RESPONSE DECODER
  // =========================================================

  Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded = jsonDecode(
        response.body,
      );

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

  // =========================================================
  // ASSIGNMENT DIALOG
  // =========================================================

  Future<void> _showDeliveryAssignmentDialog(
    Map<String, dynamic> order,
  ) async {
    final orderId = _getOrderId(order);

    if (orderId == null) {
      _showMessage(
        'Invalid order ID.',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const AlertDialog(
          content: SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading delivery persons...',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final deliveryPersons =
          await _getDeliveryPersons();

      if (!mounted) return;

      Navigator.pop(context);

      _showDeliveryPersonSelection(
        order,
        deliveryPersons,
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  // =========================================================
  // DELIVERY PERSON SELECTION
  // =========================================================

  void _showDeliveryPersonSelection(
    Map<String, dynamic> order,
    List<dynamic> deliveryPersons,
  ) {
    final orderId = _getOrderId(order);

    if (orderId == null) {
      return;
    }

    final currentDeliveryPersonId =
        _getDeliveryPersonId(order);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    5,
                    20,
                    10,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Assign Delivery Person',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Order #$orderId',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: deliveryPersons.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(
                              30,
                            ),
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons
                                      .delivery_dining_outlined,
                                  size: 60,
                                  color:
                                      Colors.grey.shade400,
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                const Text(
                                  'No delivery persons found.',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  'Create a delivery account first.',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    color: Colors
                                        .grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            20,
                          ),
                          itemCount:
                              deliveryPersons.length,
                          separatorBuilder: (_, _) => const SizedBox(
                            height: 8,
                          ),
                          itemBuilder:
                              (context, index) {
                            final item =
                                deliveryPersons[index];

                            if (item
                                is! Map<String, dynamic>) {
                              return const SizedBox
                                  .shrink();
                            }

                            final personId =
                                _toInt(item['id']);

                            final name = _text(
                              item['name'],
                              fallback:
                                  'Delivery Person',
                            );

                            final email = _text(
                              item['email'],
                              fallback: '',
                            );

                            final phone = _text(
                              item['phone'],
                              fallback: '',
                            );

                            final isSelected =
                                currentDeliveryPersonId ==
                                    personId;

                            return Card(
                              elevation: 0,
                              margin:
                                  EdgeInsets.zero,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors
                                          .blue
                                          .shade600
                                      : Colors
                                          .grey
                                          .shade200,
                                  width: isSelected
                                      ? 1.5
                                      : 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                leading:
                                    CircleAvatar(
                                  backgroundColor:
                                      Colors.blue
                                          .shade50,
                                  child: Text(
                                    name
                                            .isNotEmpty
                                        ? name[0]
                                            .toUpperCase()
                                        : 'D',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .blue
                                          .shade700,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    if (email
                                        .isNotEmpty)
                                      Text(email),
                                    if (phone
                                        .isNotEmpty)
                                      Text(phone),
                                  ],
                                ),
                                trailing:
                                    isSelected
                                        ? const Icon(
                                            Icons
                                                .check_circle,
                                            color:
                                                Colors
                                                    .green,
                                          )
                                        : const Icon(
                                            Icons
                                                .chevron_right,
                                          ),
                                onTap: () async {
                                  Navigator.pop(
                                    sheetContext,
                                  );

                                  if (isSelected) {
                                    _showMessage(
                                      'This delivery person is already assigned.',
                                    );
                                    return;
                                  }

                                  await _performAssignment(
                                    orderId:
                                        orderId,
                                    deliveryPersonId:
                                        personId,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // PERFORM ASSIGNMENT
  // =========================================================

  Future<void> _performAssignment({
    required int orderId,
    required int deliveryPersonId,
  }) async {
    try {
      _showLoadingMessage(
        'Assigning delivery person...',
      );

      await _assignDeliveryPerson(
        orderId: orderId,
        deliveryPersonId: deliveryPersonId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Delivery person assigned successfully.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

      await _loadOrders();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  // =========================================================
  // CONFIRM UNASSIGN
  // =========================================================

  Future<void> _confirmUnassign(
    Map<String, dynamic> order,
  ) async {
    final orderId = _getOrderId(order);

    if (orderId == null) {
      _showMessage(
        'Invalid order ID.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Unassign Delivery Person',
          ),
          content: const Text(
            'Are you sure you want to remove the delivery person from this order?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unassign'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      _showLoadingMessage(
        'Unassigning delivery person...',
      );

      await _unassignDeliveryPerson(
        orderId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Delivery person unassigned successfully.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      await _loadOrders();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  // =========================================================
  // UPDATE STATUS
  // =========================================================

  Future<void> _updateStatus(
    Map<String, dynamic> order,
    String newStatus,
  ) async {
    final orderId = _getOrderId(order);

    if (orderId == null) {
      _showMessage(
        'Invalid order ID.',
        isError: true,
      );
      return;
    }

    final currentStatus =
        _text(order['status'], fallback: 'pending');

    if (currentStatus.toLowerCase() ==
        newStatus.toLowerCase()) {
      return;
    }

    try {
      _showLoadingMessage(
        'Updating order status...',
      );

      final updatedOrder =
          await AdminOrderService.updateOrderStatus(
        orderId: orderId,
        status: newStatus,
      );

      if (!mounted) return;

      final index = _orders.indexWhere(
        (item) {
          if (item is! Map<String, dynamic>) {
            return false;
          }

          return _getOrderId(item) == orderId;
        },
      );

      setState(() {
        if (index >= 0) {
          _orders[index] = updatedOrder;
        }
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Order status updated successfully.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  // =========================================================
  // SHOW STATUS OPTIONS
  // =========================================================

  void _showStatusDialog(
    Map<String, dynamic> order,
  ) {
    final currentStatus =
        _text(order['status'], fallback: 'pending');

    const statuses = [
      'pending',
      'assigned',
      'packed',
      'shipped',
      'picked_up',
      'out_for_delivery',
      'delivered',
      'delivery_failed',
      'cancelled',
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(
              bottom: 20,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  14,
                ),
                child: Text(
                  'Update Order Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...statuses.map(
                (status) {
                  final selected =
                      status.toLowerCase() ==
                          currentStatus.toLowerCase();

                  final color =
                      _statusColor(status);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          color.withValues(
                        alpha: 0.12,
                      ),
                      child: Icon(
                        selected
                            ? Icons.check
                            : Icons.circle,
                        color: color,
                        size: selected ? 22 : 12,
                      ),
                    ),
                    title: Text(
                      _formatStatus(status),
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          )
                        : null,
                    onTap: selected
                        ? null
                        : () {
                            Navigator.pop(context);
                            _updateStatus(
                              order,
                              status,
                            );
                          },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // ORDER DETAILS
  // =========================================================

  void _showOrderDetails(
    Map<String, dynamic> order,
  ) {
    final orderId = _getOrderId(order);

    final status = _text(
      order['status'],
      fallback: 'pending',
    );

    final paymentStatus =
        _getPaymentStatus(order);

    final total = _getOrderTotal(order);

    final customerName =
        _getCustomerName(order);

    final deliveryPersonName =
        _getDeliveryPersonName(order);

    final deliveryPersonId =
        _getDeliveryPersonId(order);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                5,
                20,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // -------------------------------------------------
                  // TITLE
                  // -------------------------------------------------

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // -------------------------------------------------
                  // ORDER NUMBER
                  // -------------------------------------------------

                  _detailRow(
                    'Order ID',
                    orderId == null
                        ? '-'
                        : '#$orderId',
                  ),

                  _detailRow(
                    'Customer',
                    customerName,
                  ),

                  _detailRow(
                    'Total',
                    '₹${total.toStringAsFixed(2)}',
                  ),

                  const SizedBox(height: 12),

                  // -------------------------------------------------
                  // STATUS
                  // -------------------------------------------------

                  const Text(
                    'Order Status',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        status,
                      ).withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color:
                              _statusColor(status),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatStatus(status),
                          style: TextStyle(
                            color:
                                _statusColor(status),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // -------------------------------------------------
                  // PAYMENT
                  // -------------------------------------------------

                  const Text(
                    'Payment Status',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _formatStatus(paymentStatus),
                    style: TextStyle(
                      color: paymentStatus
                              .toLowerCase() ==
                          'paid'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // -------------------------------------------------
                  // DELIVERY PERSON
                  // -------------------------------------------------

                  const Text(
                    'Delivery Person',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              Colors.blue.shade50,
                          child: Icon(
                            Icons
                                .delivery_dining,
                            color:
                                Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                deliveryPersonName,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              if (deliveryPersonId !=
                                  null)
                                Text(
                                  'ID: $deliveryPersonId',
                                  style: TextStyle(
                                    color: Colors
                                        .grey
                                        .shade600,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ASSIGN / CHANGE BUTTON

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: orderId == null
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );
                              _showDeliveryAssignmentDialog(
                                order,
                              );
                            },
                      icon: Icon(
                        deliveryPersonId == null
                            ? Icons
                                .person_add_alt_1
                            : Icons.swap_horiz,
                      ),
                      label: Text(
                        deliveryPersonId == null
                            ? 'Assign Delivery Person'
                            : 'Change Delivery Person',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (deliveryPersonId != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton.icon(
                        onPressed: orderId == null
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                );
                                _confirmUnassign(
                                  order,
                                );
                              },
                        icon: const Icon(
                          Icons.person_remove_outlined,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Unassign Delivery Person',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // -------------------------------------------------
                  // ITEMS
                  // -------------------------------------------------

                  const Text(
                    'Order Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildOrderInformation(order),

                  const SizedBox(height: 24),

                  // -------------------------------------------------
                  // UPDATE BUTTON
                  // -------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: orderId == null
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );
                              _showStatusDialog(
                                order,
                              );
                            },
                      icon: const Icon(
                        Icons.edit_outlined,
                      ),
                      label: const Text(
                        'Update Order Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // DETAIL ROW
  // =========================================================

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ORDER INFORMATION
  // =========================================================

  Widget _buildOrderInformation(
    Map<String, dynamic> order,
  ) {
    final items =
        order['items'] ??
        order['order_items'];

    if (items is List && items.isNotEmpty) {
      return Column(
        children: items.map<Widget>(
          (item) {
            if (item is! Map<String, dynamic>) {
              return const SizedBox.shrink();
            }

            final product =
                item['product'];

            String productName =
                _text(
              item['product_name'],
              fallback: 'Product',
            );

            if (product is Map<String, dynamic>) {
              productName = _text(
                product['name'],
                fallback: productName,
              );
            }

            final quantity = _toInt(
              item['quantity'] ?? 1,
            );

            final price = _toDouble(
              item['price'] ??
                  item['unit_price'] ??
                  item['subtotal'],
            );

            return Container(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      productName,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'x$quantity',
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    '₹${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ).toList(),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: const Text(
        'No item details available.',
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }

  // =========================================================
  // ORDER CARD
  // =========================================================

  Widget _buildOrderCard(
    Map<String, dynamic> order,
  ) {
    final orderId = _getOrderId(order);

    final status = _text(
      order['status'],
      fallback: 'pending',
    );

    final paymentStatus =
        _getPaymentStatus(order);

    final customerName =
        _getCustomerName(order);

    final total = _getOrderTotal(order);

    final deliveryPersonName =
        _getDeliveryPersonName(order);

    final deliveryPersonId =
        _getDeliveryPersonId(order);

    final statusColor =
        _statusColor(status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: () {
          _showOrderDetails(order);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------
              // ORDER ID + STATUS
              // -------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child: Text(
                      orderId == null
                          ? 'Order'
                          : 'Order #$orderId',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
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
                      color:
                          statusColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      _formatStatus(status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // -------------------------------------------------
              // CUSTOMER
              // -------------------------------------------------

              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customerName,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // -------------------------------------------------
              // DELIVERY PERSON
              // -------------------------------------------------

              Row(
                children: [
                  Icon(
                    Icons.delivery_dining_outlined,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deliveryPersonId == null
                          ? 'Delivery: Not assigned'
                          : 'Delivery: $deliveryPersonName',
                      style: TextStyle(
                        color: deliveryPersonId ==
                                null
                            ? Colors.orange.shade700
                            : Colors.grey.shade800,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // -------------------------------------------------
              // TOTAL
              // -------------------------------------------------

              Row(
                children: [
                  Icon(
                    Icons.currency_rupee,
                    size: 19,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    total.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Payment: ',
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatStatus(
                      paymentStatus,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          paymentStatus
                                  .toLowerCase() ==
                              'paid'
                              ? Colors.green
                              : Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // -------------------------------------------------
              // ACTIONS
              // -------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showOrderDetails(
                          order,
                        );
                      },
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'View',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(
                          0,
                          44,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showStatusDialog(
                          order,
                        );
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Status',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        minimumSize:
                            const Size(
                          0,
                          44,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LOADING MESSAGE
  // =========================================================

  void _showLoadingMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          duration:
              const Duration(seconds: 30),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.shopping_bag_outlined,
          size: 80,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 18),
        const Text(
          'No orders found',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customer orders will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // -------------------------------------------------------
      // APP BAR
      // -------------------------------------------------------

      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadOrders,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      // -------------------------------------------------------
      // BODY
      // -------------------------------------------------------

      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _isLoading
            ? ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  ),
                ],
              )
            : _errorMessage != null
                ? ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 100),
                      Icon(
                        Icons.error_outline,
                        size: 70,
                        color:
                            Colors.red.shade400,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Unable to load orders',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _loadOrders,
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label: const Text(
                            'Try Again',
                          ),
                        ),
                      ),
                    ],
                  )
                : _orders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        itemCount:
                            _orders.length,
                        itemBuilder:
                            (context, index) {
                          final item =
                              _orders[index];

                          if (item
                              is Map<String, dynamic>) {
                            return _buildOrderCard(
                              item,
                            );
                          }

                          return const SizedBox
                              .shrink();
                        },
                      ),
      ),
    );
  }
}