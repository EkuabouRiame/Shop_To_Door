import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  // =========================================================
  // CONTINUE SHOPPING CALLBACK
  // =========================================================

  final VoidCallback? onContinueShopping;

  const CartScreen({
    super.key,
    this.onContinueShopping,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = true;
  bool _updating = false;
  String? _error;

  List<dynamic> _items = [];

  double _subtotal = 0;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // =========================================================
  // LOAD CART
  // =========================================================

  Future<void> _loadCart() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await CartService.getCart();

      final cart = response['cart'];

      if (cart is! Map) {
        throw Exception(
          'Invalid cart response from server.',
        );
      }

      final rawItems = cart['items'];

      final List<dynamic> items;

      if (rawItems is List) {
        items = rawItems;
      } else {
        items = [];
      }

      final subtotal = _toDouble(
        cart['subtotal'],
      );

      if (!mounted) return;

      setState(() {
        _items = items;
        _subtotal = subtotal;

        // Delivery charges are handled during checkout.
        _total = subtotal;

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
  // CONVERSION HELPERS
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

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // =========================================================
  // PRODUCT HELPERS
  // =========================================================

  dynamic _getProduct(dynamic item) {
    if (item is Map) {
      return item['product'];
    }

    return null;
  }

  int _itemId(dynamic item) {
    if (item is Map) {
      return _toInt(
        item['id'] ?? item['cart_item_id'],
      );
    }

    return 0;
  }

  int _quantity(dynamic item) {
    if (item is Map) {
      return _toInt(
        item['quantity'],
      );
    }

    return 1;
  }

  String _productName(dynamic item) {
    final product = _getProduct(item);

    if (product is Map) {
      return product['name']?.toString() ??
          'Product';
    }

    return 'Product';
  }

  dynamic _productImage(dynamic item) {
    final product = _getProduct(item);

    if (product is Map) {
      return product['image'];
    }

    return null;
  }

  // =========================================================
  // PRICE HELPERS
  // =========================================================

  double _itemPrice(dynamic item) {
    if (item is! Map) {
      return 0;
    }

    final unitPrice = item['unit_price'];

    if (unitPrice != null) {
      return _toDouble(unitPrice);
    }

    final product = _getProduct(item);

    if (product is Map) {
      final discountPrice =
          product['discount_price'];

      final originalPrice =
          product['price'];

      if (discountPrice != null) {
        return _toDouble(discountPrice);
      }

      return _toDouble(originalPrice);
    }

    return 0;
  }

  double _itemTotal(dynamic item) {
    if (item is Map) {
      final total = item['total'];

      if (total != null) {
        return _toDouble(total);
      }
    }

    return _itemPrice(item) * _quantity(item);
  }

  // =========================================================
  // IMAGE URL
  // =========================================================

  String _imageUrl(dynamic image) {
    if (image == null ||
        image.toString().trim().isEmpty) {
      return '';
    }

    final imagePath = image.toString().trim();

    if (imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
      return imagePath;
    }

    final serverUrl =
        ApiConfig.baseUrl.replaceFirst(
      '/api',
      '',
    );

    if (imagePath.startsWith('/')) {
      return '$serverUrl$imagePath';
    }

    return '$serverUrl/$imagePath';
  }

  // =========================================================
  // UPDATE QUANTITY
  // =========================================================

  Future<void> _updateQuantity(
    dynamic item,
    int quantity,
  ) async {
    final itemId = _itemId(item);

    if (itemId <= 0 || quantity < 1) {
      return;
    }

    setState(() {
      _updating = true;
    });

    try {
      await CartService.updateCartItem(
        itemId: itemId,
        quantity: quantity,
      );

      await _loadCart();
    } catch (e) {
      if (!mounted) return;

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
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  // =========================================================
  // REMOVE ITEM
  // =========================================================

  Future<void> _removeItem(dynamic item) async {
    final itemId = _itemId(item);

    if (itemId <= 0) {
      return;
    }

    setState(() {
      _updating = true;
    });

    try {
      await CartService.removeCartItem(
        itemId,
      );

      await _loadCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Item removed from cart',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

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
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  // =========================================================
  // CLEAR CART
  // =========================================================

  Future<void> _clearCart() async {
    if (_items.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Clear Cart',
          ),
          content: const Text(
            'Are you sure you want to remove all items from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Clear',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _updating = true;
    });

    try {
      await CartService.clearCart();

      await _loadCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cart cleared',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

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
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  // =========================================================
  // CONTINUE SHOPPING
  // =========================================================

  void _continueShopping() {
    // When Cart is opened as the bottom-navigation tab,
    // return to Home through MainNavigationScreen.
    if (widget.onContinueShopping != null) {
      widget.onContinueShopping!();
      return;
    }

    // When Cart was opened as a normal pushed screen,
    // return to the previous screen.
    Navigator.of(context).pop();
  }

  // =========================================================
  // PROCEED TO CHECKOUT
  // =========================================================

  void _proceedToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CheckoutScreen(),
      ),
    );
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
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 19,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        actions: [
          if (!_loading && _items.isNotEmpty)
            IconButton(
              onPressed: _updating
                  ? null
                  : _clearCart,
              icon: const Icon(
                Icons.delete_sweep_outlined,
                size: 22,
              ),
              tooltip: 'Clear cart',
            ),
        ],
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
      return RefreshIndicator(
        onRefresh: _loadCart,
        child: ListView(
          children: [
            const SizedBox(
              height: 180,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    const Text(
                      'Unable to load cart',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    ElevatedButton(
                      onPressed: _loadCart,
                      child: const Text(
                        'Retry',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCart,
        child: ListView(
          children: [
            const SizedBox(
              height: 130,
            ),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 75,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Add some products to your cart.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton.icon(
                    onPressed: _continueShopping,
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 19,
                    ),
                    label: const Text(
                      'Continue Shopping',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCart,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          24,
        ),
        children: [
          Text(
            '${_items.length} ${_items.length == 1 ? 'item' : 'items'} in your cart',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 9,
          ),
          ..._items.map(
            _buildCartItem,
          ),
          const SizedBox(
            height: 4,
          ),
          _buildPriceSummary(),
          const SizedBox(
            height: 14,
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _updating
                  ? null
                  : _proceedToCheckout,
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CART ITEM
  // =========================================================

  Widget _buildCartItem(dynamic item) {
    final imageUrl = _imageUrl(
      _productImage(item),
    );

    final name = _productName(item);
    final quantity = _quantity(item);
    final price = _itemPrice(item);
    final itemTotal = _itemTotal(item);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 5,
            offset: const Offset(
              0,
              2,
            ),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons
                            .image_not_supported_outlined,
                        size: 28,
                      );
                    },
                  )
                : const Icon(
                    Icons.image_outlined,
                    size: 28,
                  ),
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Row(
                  children: [
                    _quantityButton(
                      icon: Icons.remove,
                      onPressed: quantity > 1
                          ? () =>
                              _updateQuantity(
                                item,
                                quantity - 1,
                              )
                          : () =>
                              _removeItem(item),
                    ),
                    Container(
                      width: 30,
                      alignment:
                          Alignment.center,
                      child: Text(
                        '$quantity',
                        style:
                            const TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    _quantityButton(
                      icon: Icons.add,
                      onPressed: () =>
                          _updateQuantity(
                        item,
                        quantity + 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _updating
                    ? null
                    : () =>
                        _removeItem(item),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(
                  minWidth: 30,
                  minHeight: 30,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                '₹${itemTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // QUANTITY BUTTON
  // =========================================================

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 29,
      height: 29,
      child: IconButton(
        onPressed: _updating
            ? null
            : onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 16,
        ),
        style: IconButton.styleFrom(
          backgroundColor:
              const Color(0xFFF1F3F5),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PRICE SUMMARY
  // =========================================================

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Price Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
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
          const SizedBox(
            height: 8,
          ),
          const Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
              Text(
                'Calculated at checkout',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
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
                '₹${_total.toStringAsFixed(2)}',
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