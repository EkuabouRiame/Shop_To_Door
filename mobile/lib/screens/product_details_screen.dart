import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  Map<String, dynamic>? _product;

  bool _loading = true;
  bool _addingToCart = false;

  int _quantity = 1;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  // =========================================================
  // LOAD PRODUCT
  // =========================================================

  Future<void> _loadProduct() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.getProduct(
        widget.productId,
      );

      if (!mounted) return;

      setState(() {
        _product = _extractProduct(response);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // =========================================================
  // EXTRACT PRODUCT
  // =========================================================

  Map<String, dynamic> _extractProduct(
    Map<String, dynamic> response,
  ) {
    final product = response['product'];

    if (product is Map<String, dynamic>) {
      return product;
    }

    final data = response['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    // Some APIs return the product directly.
    return response;
  }

  // =========================================================
  // IMAGE URL
  // =========================================================

  String? _imageUrl(dynamic image) {
    if (image == null) {
      return null;
    }

    final value = image.toString().trim();

    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return 'http://10.0.2.2:5000$value';
    }

    return 'http://10.0.2.2:5000/$value';
  }

  // =========================================================
  // PRICE
  // =========================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // ADD TO CART
  // =========================================================

  Future<void> _addToCart() async {
    if (_product == null || _addingToCart) {
      return;
    }

    final productId = _product!['id'];

    if (productId == null) {
      _showMessage(
        'Product ID is missing.',
        isError: true,
      );
      return;
    }

    final parsedProductId =
        int.tryParse(productId.toString());

    if (parsedProductId == null) {
      _showMessage(
        'Invalid product ID.',
        isError: true,
      );
      return;
    }

    final stock = int.tryParse(
          _product!['stock']?.toString() ?? '0',
        ) ??
        0;

    if (stock <= 0) {
      _showMessage(
        'This product is out of stock.',
        isError: true,
      );
      return;
    }

    if (_quantity > stock) {
      _showMessage(
        'Only $stock item${stock == 1 ? '' : 's'} available.',
        isError: true,
      );
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    try {
      await CartService.addToCart(
        productId: parsedProductId,
        quantity: _quantity,
      );

      if (!mounted) return;

      _showMessage(
        '$_quantity item${_quantity > 1 ? 's' : ''} added to cart.',
      );

      // Stay on Product Details.
      // The user can continue shopping or add another quantity.
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingToCart = false;
        });
      }
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        action: isError
            ? null
            : SnackBarAction(
                label: 'View Cart',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CartScreen(),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // =========================================================
  // QUANTITY
  // =========================================================

  void _increaseQuantity() {
    if (_product == null) {
      return;
    }

    final stock = int.tryParse(
          _product!['stock']?.toString() ?? '0',
        ) ??
        0;

    if (_quantity < stock) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  // =========================================================
  // PRODUCT IMAGE
  // =========================================================

  Widget _buildProductImage() {
    final images = _product?['images'];

    String? imagePath;

    if (images is List && images.isNotEmpty) {
      dynamic primaryImage;

      for (final item in images) {
        if (item is Map &&
            item['is_primary'] == true) {
          primaryImage = item;
          break;
        }
      }

      primaryImage ??= images.first;

      if (primaryImage is Map) {
        imagePath =
            primaryImage['image_url']?.toString();
      }
    }

    imagePath ??=
        _product?['image']?.toString();

    final imageUrl = _imageUrl(imagePath);

    if (imageUrl == null) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          color: Colors.grey.shade100,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 60,
              color: Colors.grey,
            ),
          ),
        );
      },
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadProduct,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return const Center(
        child: Text('Product not found.'),
      );
    }

    final product = _product!;

    final name =
        product['name']?.toString() ??
            'Unnamed Product';

    final description =
        product['description']?.toString() ?? '';

    final category =
        product['category'] is Map
            ? product['category']['name']
                    ?.toString() ??
                ''
            : product['category_name']
                    ?.toString() ??
                '';

    final brand =
        product['brand']?.toString() ?? '';

    final sku =
        product['sku']?.toString() ?? '';

    final stock = int.tryParse(
          product['stock']?.toString() ?? '0',
        ) ??
        0;

    final price =
        _toDouble(product['price']);

    final discountPrice =
        product['discount_price'] != null
            ? _toDouble(
                product['discount_price'],
              )
            : null;

    final hasDiscount =
        discountPrice != null &&
            discountPrice > 0 &&
            discountPrice < price;

    final sellingPrice =
        hasDiscount
            ? discountPrice
            : price;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ===================================================
          // IMAGE
          // ===================================================

          SizedBox(
            height: 240,
            width: double.infinity,
            child: _buildProductImage(),
          ),

          const Divider(height: 1),

          // ===================================================
          // PRODUCT INFORMATION
          // ===================================================

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (category.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.blue.shade50,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.blue.shade700,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // =================================================
                // PRICE
                // =================================================

                Wrap(
                  crossAxisAlignment:
                      WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      '₹${sellingPrice.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        fontSize: 23,
                        fontWeight:
                            FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    if (hasDiscount)
                      Text(
                        '₹${price.toStringAsFixed(2)}',
                        style:
                            const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          decoration:
                              TextDecoration
                                  .lineThrough,
                        ),
                      ),

                    if (hasDiscount)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.red.shade50,
                          borderRadius:
                              BorderRadius
                                  .circular(5),
                        ),
                        child: Text(
                          '${(((price - sellingPrice) / price) * 100).round()}% OFF',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Colors.red.shade700,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // =================================================
                // STOCK
                // =================================================

                Row(
                  children: [
                    Icon(
                      stock > 0
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: stock > 0
                          ? Colors.green
                          : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stock > 0
                          ? '$stock available in stock'
                          : 'Out of stock',
                      style: TextStyle(
                        fontSize: 13,
                        color: stock > 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // =================================================
                // DESCRIPTION
                // =================================================

                if (description.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color:
                          Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 14),
                ],

                // =================================================
                // PRODUCT DETAILS
                // =================================================

                const Text(
                  'Product Information',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                if (brand.isNotEmpty)
                  _infoRow(
                    'Brand',
                    brand,
                  ),

                if (sku.isNotEmpty)
                  _infoRow(
                    'SKU',
                    sku,
                  ),

                if (category.isNotEmpty)
                  _infoRow(
                    'Category',
                    category,
                  ),

                const SizedBox(height: 16),

                // =================================================
                // QUANTITY
                // =================================================

                const Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    Container(
                      height: 42,
                      decoration:
                          BoxDecoration(
                        border: Border.all(
                          color:
                              Colors.grey.shade300,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              padding:
                                  EdgeInsets.zero,
                              onPressed:
                                  _decreaseQuantity,
                              icon: const Icon(
                                Icons.remove,
                                size: 18,
                              ),
                            ),
                          ),

                          Text(
                            '$_quantity',
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              padding:
                                  EdgeInsets.zero,
                              onPressed:
                                  _increaseQuantity,
                              icon: const Icon(
                                Icons.add,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '₹${(sellingPrice * _quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // =================================================
                // ADD TO CART
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        stock <= 0 ||
                                _addingToCart
                            ? null
                            : _addToCart,
                    icon: _addingToCart
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .shopping_cart_outlined,
                            size: 20,
                          ),
                    label: Text(
                      _addingToCart
                          ? 'Adding...'
                          : 'Add to Cart',
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INFORMATION ROW
  // =========================================================

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}