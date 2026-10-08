import 'package:flutter/material.dart';

import '../services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await OrderService.getOrders();

      debugPrint('FULL ORDER RESPONSE: $response');

      final orders = response['orders'];

      if (!mounted) return;

      setState(() {
        _orders = orders is List ? orders : [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _value(dynamic value) {
    return value?.toString() ?? '';
  }

  String _orderStatus(dynamic order) {
    final status = _value(order['status']);

    if (status.isEmpty) {
      return 'Pending';
    }

    return _formatStatus(status);
  }

  String _paymentStatus(dynamic order) {
    final status = _value(order['payment_status']);

    if (status.isEmpty) {
      return 'Pending';
    }

    return _formatStatus(status);
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  double _amount(dynamic order) {
    final value = order['total'] ?? order['total_amount'] ?? 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;

      case 'cancelled':
      case 'canceled':
        return Colors.red;

      case 'shipped':
        return Colors.blue;

      case 'out for delivery':
        return Colors.indigo;

      case 'processing':
        return Colors.orange;

      case 'confirmed':
        return Colors.teal;

      case 'pending':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: const Text('My Orders'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Icon(
            Icons.shopping_bag_outlined,
            size: 70,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Your orders will appear here.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];

        final orderId = order['id'];
        final status = _orderStatus(order);
        final paymentStatus = _paymentStatus(order);
        final amount = _amount(order);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (orderId != null) {
                final parsedId = int.tryParse(
                  orderId.toString(),
                );

                if (parsedId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(
                        orderId: parsedId,
                      ),
                    ),
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #$orderId',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: _StatusChip(
                          label: status,
                          color: _statusColor(status),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _StatusChip(
                          label: paymentStatus,
                          color:
                              paymentStatus.toLowerCase() == 'paid'
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (order['created_at'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Placed: ${order['created_at']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================
// ORDER DETAILS SCREEN
// ============================================================

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsScreen> createState() =>
      _OrderDetailsScreenState();
}

class _OrderDetailsScreenState
    extends State<OrderDetailsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response =
          await OrderService.getOrder(widget.orderId);

      debugPrint('ORDER DETAILS RESPONSE: $response');

      final orderData = response['order'];

      if (!mounted) return;

      setState(() {
        if (orderData is Map) {
          _order = Map<String, dynamic>.from(orderData);
        } else {
          _order = Map<String, dynamic>.from(response);
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _rawStatus() {
    return (_order?['status']?.toString() ?? 'pending')
        .toLowerCase()
        .replaceAll('_', ' ')
        .trim();
  }

  String _displayStatus() {
    final status = _rawStatus();

    if (status.isEmpty) {
      return 'Pending';
    }

    return status
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  bool _isCancelled() {
    final status = _rawStatus();

    return status == 'cancelled' ||
        status == 'canceled';
  }

  int _currentStep() {
    final status = _rawStatus();

    if (status.contains('delivered')) {
      return 5;
    }

    if (status.contains('out for delivery')) {
      return 4;
    }

    if (status.contains('shipped')) {
      return 3;
    }

    if (status.contains('processing')) {
      return 2;
    }

    if (status.contains('confirmed')) {
      return 1;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: Text(
          'Order #${widget.orderId}',
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 55,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrder,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return const Center(
        child: Text(
          'Order not found.',
        ),
      );
    }

    final order = _order!;

    return RefreshIndicator(
      onRefresh: _loadOrder,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildTrackingCard(),

          const SizedBox(height: 16),

          _buildOrderSummary(order),

          const SizedBox(height: 16),

          _buildDeliveryDetails(order),

          const SizedBox(height: 16),

          _buildPaymentDetails(order),

          const SizedBox(height: 16),

          _buildAmountDetails(order),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================================
  // ORDER TRACKING
  // ==========================================================

  Widget _buildTrackingCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Tracking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Current status: ${_displayStatus()}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 22),
            if (_isCancelled())
              _buildCancelledStatus()
            else ...[
              _buildTimelineItem(
                title: 'Order Placed',
                subtitle:
                    'Your order has been placed.',
                step: 0,
              ),
              _buildTimelineItem(
                title: 'Order Confirmed',
                subtitle:
                    'Your order has been confirmed.',
                step: 1,
              ),
              _buildTimelineItem(
                title: 'Processing',
                subtitle:
                    'Your order is being prepared.',
                step: 2,
              ),
              _buildTimelineItem(
                title: 'Shipped',
                subtitle:
                    'Your order is on the way.',
                step: 3,
              ),
              _buildTimelineItem(
                title: 'Out for Delivery',
                subtitle:
                    'Your order is out for delivery.',
                step: 4,
              ),
              _buildTimelineItem(
                title: 'Delivered',
                subtitle:
                    'Your order has been delivered.',
                step: 5,
                isLast: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.cancel_outlined,
            color: Colors.red,
            size: 30,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This order has been cancelled.',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required int step,
    bool isLast = false,
  }) {
    final currentStep = _currentStep();

    final completed = step <= currentStep;
    final current = step == currentStep;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 250),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? Colors.blue
                    : Colors.grey.shade300,
                border: current
                    ? Border.all(
                        color: Colors.blue.shade700,
                        width: 3,
                      )
                    : null,
              ),
              child: Icon(
                completed
                    ? Icons.check
                    : Icons.circle,
                size: completed ? 18 : 8,
                color: completed
                    ? Colors.white
                    : Colors.grey.shade500,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 58,
                color: step < currentStep
                    ? Colors.blue
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 22),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: completed
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: completed
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: completed
                        ? Colors.grey.shade700
                        : Colors.grey,
                  ),
                ),
                if (current) ...[
                  const SizedBox(height: 5),
                  const Text(
                    'Current status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ORDER SUMMARY
  // ==========================================================

  Widget _buildOrderSummary(
    Map<String, dynamic> order,
  ) {
    return _infoCard(
      title: 'Order Summary',
      children: [
        _infoRow(
          'Order ID',
          '#${order['id'] ?? widget.orderId}',
        ),
        _infoRow(
          'Status',
          _displayStatus(),
        ),
        if (order['created_at'] != null)
          _infoRow(
            'Placed',
            order['created_at'].toString(),
          ),
      ],
    );
  }

  // ==========================================================
  // DELIVERY DETAILS
  // ==========================================================

  Widget _buildDeliveryDetails(
    Map<String, dynamic> order,
  ) {
    /*
     * Backend response:
     *
     * shipping: {
     *   address: Tamenglong,
     *   city: Imphal,
     *   name: Ekuabou,
     *   phone: 9366858430,
     *   pincode: 795141,
     *   state: Manipur
     * }
     *
     * We read these values directly from
     * the nested "shipping" object.
     */

    final shipping = order['shipping'];

    if (shipping is Map) {
      final shippingData =
          Map<String, dynamic>.from(shipping);

      return _infoCard(
        title: 'Delivery Details',
        children: [
          _infoRow(
            'Name',
            _shippingValue(
              shippingData,
              'name',
            ),
          ),
          _infoRow(
            'Phone',
            _shippingValue(
              shippingData,
              'phone',
            ),
          ),
          _infoRow(
            'Address',
            _shippingValue(
              shippingData,
              'address',
            ),
          ),
          _infoRow(
            'City',
            _shippingValue(
              shippingData,
              'city',
            ),
          ),
          _infoRow(
            'State',
            _shippingValue(
              shippingData,
              'state',
            ),
          ),
          _infoRow(
            'Pincode',
            _shippingValue(
              shippingData,
              'pincode',
            ),
          ),
        ],
      );
    }

    /*
     * Fallback in case a future backend version
     * returns the shipping fields directly.
     */

    return _infoCard(
      title: 'Delivery Details',
      children: [
        _infoRow(
          'Name',
          _firstAvailable(
            order,
            [
              'shipping_name',
              'name',
              'full_name',
              'customer_name',
            ],
          ),
        ),
        _infoRow(
          'Phone',
          _firstAvailable(
            order,
            [
              'shipping_phone',
              'phone',
              'mobile',
              'phone_number',
            ],
          ),
        ),
        _infoRow(
          'Address',
          _firstAvailable(
            order,
            [
              'shipping_address',
              'address',
              'full_address',
              'delivery_address',
            ],
          ),
        ),
        _infoRow(
          'City',
          _firstAvailable(
            order,
            [
              'shipping_city',
              'city',
            ],
          ),
        ),
        _infoRow(
          'State',
          _firstAvailable(
            order,
            [
              'shipping_state',
              'state',
            ],
          ),
        ),
        _infoRow(
          'Pincode',
          _firstAvailable(
            order,
            [
              'shipping_pincode',
              'pincode',
              'pin_code',
              'postal_code',
              'zipcode',
              'zip_code',
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SHIPPING VALUE
  // ==========================================================

  String _shippingValue(
    Map<String, dynamic> shipping,
    String key,
  ) {
    final value = shipping[key];

    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return '-';
    }

    return text;
  }

  // ==========================================================
  // FIRST AVAILABLE VALUE
  // ==========================================================

  String _firstAvailable(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null) {
        final text = value.toString().trim();

        if (text.isNotEmpty && text != 'null') {
          return text;
        }
      }
    }

    return '-';
  }

  // ==========================================================
  // PAYMENT DETAILS
  // ==========================================================

  Widget _buildPaymentDetails(
    Map<String, dynamic> order,
  ) {
    final paymentStatus =
        order['payment_status']?.toString() ??
            'Pending';

    return _infoCard(
      title: 'Payment',
      children: [
        _infoRow(
          'Method',
          order['payment_method']?.toString() ?? '-',
        ),
        _infoRow(
          'Status',
          _formatStatus(paymentStatus),
        ),
      ],
    );
  }

  // ==========================================================
  // AMOUNT DETAILS
  // ==========================================================

  Widget _buildAmountDetails(
    Map<String, dynamic> order,
  ) {
    final subtotal = order['subtotal'] ?? 0;

    final total =
        order['total'] ??
            order['total_amount'] ??
            0;

    return _infoCard(
      title: 'Order Amount',
      children: [
        _infoRow(
          'Subtotal',
          '₹$subtotal',
        ),
        _infoRow(
          'Total',
          '₹$total',
          bold: true,
        ),
      ],
    );
  }

  // ==========================================================
  // COMMON INFO CARD
  // ==========================================================

  Widget _infoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // INFO ROW
  // ==========================================================

  Widget _infoRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FORMAT STATUS
  // ==========================================================

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}