import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _cityController =
      TextEditingController();

  final TextEditingController _stateController =
      TextEditingController();

  final TextEditingController _pincodeController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  late Razorpay _razorpay;

  bool _loading = true;
  bool _placingOrder = false;

  String? _error;

  List<dynamic> _items = [];

  double _subtotal = 0;

  double _shippingFee = 0;

  double _totalAmount = 0;

  String _paymentMethod = 'cod';

  int? _currentOrderId;

  // =========================================================
  // DELIVERY SETTINGS
  // =========================================================

  static const double _freeDeliveryThreshold = 2000.00;
  static const double _deliveryCharge = 49.00;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );

    _loadCart();
  }

  @override
  void dispose() {
    _razorpay.clear();

    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD CART
  // =========================================================

  Future<void> _loadCart() async {
    try {
      final response = await CartService.getCart();

      final cartData = response['cart'];

      if (cartData is! Map) {
        throw Exception(
          'Invalid cart response from server.',
        );
      }

      final rawItems = cartData['items'];

      final List<dynamic> items =
          rawItems is List ? rawItems : [];

      final subtotal = _toDouble(
        cartData['subtotal'],
      );

      final shippingFee = _calculateShippingFee(
        subtotal,
      );

      final totalAmount =
          subtotal + shippingFee;

      if (!mounted) return;

      setState(() {
        _items = items;
        _subtotal = subtotal;
        _shippingFee = shippingFee;
        _totalAmount = totalAmount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
        _loading = false;
      });
    }
  }

  // =========================================================
  // DELIVERY CHARGE
  // =========================================================

  double _calculateShippingFee(double subtotal) {
    if (subtotal >= _freeDeliveryThreshold) {
      return 0.00;
    }

    return _deliveryCharge;
  }

  // =========================================================
  // PLACE ORDER
  // =========================================================

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your cart is empty.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _placingOrder = true;
    });

    try {
      final response = await OrderService.createOrder(
        paymentMethod: _paymentMethod,
        shippingName: _nameController.text,
        shippingPhone: _phoneController.text,
        shippingAddress: _addressController.text,
        shippingCity: _cityController.text,
        shippingState: _stateController.text,
        shippingPincode: _pincodeController.text,
        notes: _notesController.text,
      );

      final order = response['order'];

      int? orderId;

      if (order is Map) {
        final value = order['id'];

        if (value is int) {
          orderId = value;
        } else if (value != null) {
          orderId = int.tryParse(
            value.toString(),
          );
        }

        // ---------------------------------------------------
        // Use backend-calculated shipping and total
        // ---------------------------------------------------

        final backendShippingFee =
            _toDouble(
          order['shipping_fee'],
        );

        final backendTotalAmount =
            _toDouble(
          order['total_amount'],
        );

        if (backendShippingFee > 0 ||
            order['shipping_fee'] != null) {
          _shippingFee = backendShippingFee;
        }

        if (backendTotalAmount > 0 ||
            order['total_amount'] != null) {
          _totalAmount = backendTotalAmount;
        }
      }

      // -------------------------------------------------------
      // COD
      // -------------------------------------------------------

      if (_paymentMethod == 'cod') {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(
              orderId: orderId,
              amount: _totalAmount,
              paymentMethod: 'Cash on Delivery',
            ),
          ),
        );

        return;
      }

      // -------------------------------------------------------
      // ONLINE PAYMENT
      // -------------------------------------------------------

      if (orderId == null) {
        throw Exception(
          'Order was created but no order ID was returned.',
        );
      }

      _currentOrderId = orderId;

      final paymentResponse =
          await PaymentService.createPaymentOrder(
        orderId,
      );

      final razorpayOrderId =
          paymentResponse['razorpay_order_id']
              ?.toString();

      final keyId =
          paymentResponse['key_id']?.toString();

      final amount = _toDouble(
        paymentResponse['amount'],
      );

      final currency =
          paymentResponse['currency']?.toString() ??
              'INR';

      if (razorpayOrderId == null ||
          razorpayOrderId.isEmpty) {
        throw Exception(
          'Razorpay order ID was not returned.',
        );
      }

      if (keyId == null || keyId.isEmpty) {
        throw Exception(
          'Razorpay key was not returned.',
        );
      }

      if (amount <= 0) {
        throw Exception(
          'Invalid payment amount.',
        );
      }

      final options = {
        'key': keyId,
        'amount': amount.round(),
        'currency': currency,
        'name': 'Shop To Door',
        'description': 'Order #$orderId',
        'order_id': razorpayOrderId,
        'prefill': {
          'name': _nameController.text.trim(),
          'contact': _phoneController.text.trim(),
        },
        'notes': {
          'order_id': orderId.toString(),
        },
        'theme': {
          'color': '#2196F3',
        },
      };

      if (!mounted) return;

      setState(() {
        _placingOrder = false;
      });

      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _placingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  // =========================================================
  // RAZORPAY SUCCESS
  // =========================================================

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    if (_currentOrderId == null) {
      _showPaymentMessage(
        'Payment succeeded, but the order ID is missing.',
        isError: true,
      );
      return;
    }

    final paymentId = response.paymentId;
    final orderId = response.orderId;
    final signature = response.signature;

    if (paymentId == null ||
        paymentId.isEmpty ||
        orderId == null ||
        orderId.isEmpty ||
        signature == null ||
        signature.isEmpty) {
      _showPaymentMessage(
        'Payment completed, but payment verification data is incomplete.',
        isError: true,
      );
      return;
    }

    if (mounted) {
      setState(() {
        _placingOrder = true;
      });
    }

    try {
      final verification =
          await PaymentService.verifyPayment(
        orderId: _currentOrderId!,
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      final verified =
          verification['success'] == true ||
              verification['status'] == 'success';

      if (!verified) {
        throw Exception(
          verification['message']?.toString() ??
              'Payment verification failed.',
        );
      }

      if (!mounted) return;

      setState(() {
        _placingOrder = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: _currentOrderId,
            amount: _totalAmount,
            paymentMethod: 'Online Payment',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _placingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment verification failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // =========================================================
  // RAZORPAY ERROR
  // =========================================================

  void _handlePaymentError(
    PaymentFailureResponse response,
  ) {
    if (!mounted) return;

    setState(() {
      _placingOrder = false;
    });

    String message = 'Payment failed.';

    if (response.message != null &&
        response.message!.isNotEmpty) {
      message = response.message!;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment failed: $message',
        ),
      ),
    );
  }

  // =========================================================
  // EXTERNAL WALLET
  // =========================================================

  void _handleExternalWallet(
    ExternalWalletResponse response,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'External wallet selected: ${response.walletName ?? 'Unknown'}',
        ),
      ),
    );
  }

  // =========================================================
  // PAYMENT MESSAGE
  // =========================================================

  void _showPaymentMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            isError ? Colors.red : null,
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        toolbarHeight: 52,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  // =========================================================
  // BODY
  // =========================================================

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
                size: 50,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load checkout',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCart,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'Your cart is empty.',
          style: TextStyle(
            fontSize: 17,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          22,
        ),
        children: [
          _buildSectionTitle(
            'Delivery Information',
          ),

          const SizedBox(height: 9),

          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 9),

          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 9),

          _buildTextField(
            controller: _addressController,
            label: 'Delivery Address',
            icon: Icons.home_outlined,
            maxLines: 3,
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  icon: Icons.map_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          _buildTextField(
            controller: _pincodeController,
            label: 'PIN Code',
            icon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 9),

          _buildTextField(
            controller: _notesController,
            label: 'Order Notes (Optional)',
            icon: Icons.note_outlined,
            maxLines: 2,
            required: false,
          ),

          const SizedBox(height: 19),

          _buildSectionTitle(
            'Payment Method',
          ),

          const SizedBox(height: 8),

          RadioGroup<String>(
            groupValue: _paymentMethod,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _paymentMethod = value;
              });
            },
            child: Column(
              children: [
                _buildPaymentOption(
                  value: 'cod',
                  title: 'Cash on Delivery',
                  subtitle:
                      'Pay when your order is delivered',
                  icon: Icons.payments_outlined,
                ),

                const SizedBox(height: 7),

                _buildPaymentOption(
                  value: 'razorpay',
                  title: 'Online Payment',
                  subtitle:
                      'Pay securely using Razorpay',
                  icon: Icons.credit_card_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 19),

          _buildOrderSummary(),

          const SizedBox(height: 17),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed:
                  _placingOrder ? null : _placeOrder,
              child: _placingOrder
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _paymentMethod == 'cod'
                          ? 'Place Order'
                          : 'Continue to Payment',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: required
          ? (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
    );
  }

  // =========================================================
  // PAYMENT OPTION
  // =========================================================

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color: _paymentMethod == value
              ? Colors.blue
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: RadioListTile<String>(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 0,
        ),
        value: value,
        secondary: Icon(
          icon,
          color: Colors.blue,
          size: 22,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ORDER SUMMARY
  // =========================================================

  Widget _buildOrderSummary() {
    final isFreeDelivery =
        _shippingFee <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
              Text(
                '${_items.length}',
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
              Text(
                '₹${_subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
              if (isFreeDelivery)
                const Text(
                  'FREE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  '₹${_shippingFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),

          if (isFreeDelivery) ...[
            const SizedBox(height: 5),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Free delivery above ₹2,000',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const Divider(
            height: 20,
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ORDER SUCCESS SCREEN
// =============================================================

class OrderSuccessScreen extends StatelessWidget {
  final int? orderId;
  final double amount;
  final String paymentMethod;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        toolbarHeight: 52,
        title: const Text(
          'Order Confirmation',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade100,
                ),
                child: Icon(
                  Icons.check,
                  size: 48,
                  color: Colors.green.shade700,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Thank you for shopping with Shop To Door.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (orderId != null) ...[
                      _infoRow(
                        'Order ID',
                        '#$orderId',
                      ),
                      const Divider(),
                    ],
                    _infoRow(
                      'Payment',
                      paymentMethod,
                    ),
                    const Divider(),
                    _infoRow(
                      'Amount',
                      '₹${amount.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text(
                    'Continue Shopping',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _infoRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}