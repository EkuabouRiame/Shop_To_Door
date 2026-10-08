import 'dart:async';

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

// ============================================================
// HOME SCREEN STATE
// ============================================================

class HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;

  List<dynamic> _products = [];
  List<dynamic> _categories = [];

  int? _addingProductId;

  int? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _loadingCategoryProducts = false;

  final TextEditingController _searchController =
      TextEditingController();

  Timer? _searchDebounce;

  bool _searching = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _loadHomeData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // RESET HOME
  // ============================================================

  Future<void> resetHomeScreen() async {
    if (!mounted) return;

    _searchDebounce?.cancel();
    _searchController.clear();

    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _searchText = '';
      _searching = false;
      _loadingCategoryProducts = true;
      _error = null;
    });

    try {
      final response = await ApiService.getProducts(
        page: 1,
        perPage: 20,
      );

      if (!mounted) return;

      setState(() {
        _products =
            response['products'] as List<dynamic>? ?? [];

        _loadingCategoryProducts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCategoryProducts = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadHomeData() async {
    if (!mounted) return;

    _searchDebounce?.cancel();
    _searchController.clear();

    setState(() {
      _loading = true;
      _error = null;
      _searchText = '';
      _searching = false;

      // Always start Home with all products.
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _loadingCategoryProducts = false;
    });

    try {
      final results = await Future.wait([
        ApiService.getProducts(
          page: 1,
          perPage: 20,
        ),
        ApiService.getCategories(),
      ]);

      final productsResponse = results[0];
      final categoriesResponse = results[1];

      if (!mounted) return;

      setState(() {
        _products =
            productsResponse['products'] as List<dynamic>? ?? [];

        _categories =
            categoriesResponse['categories'] as List<dynamic>? ??
                (categoriesResponse['data'] as List<dynamic>? ?? []);

        // Home always opens showing all products.
        _selectedCategoryId = null;
        _selectedCategoryName = null;
        _loadingCategoryProducts = false;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _imageUrl(dynamic image) {
    if (image == null || image.toString().trim().isEmpty) {
      return '';
    }

    final imagePath = image.toString();

    if (imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
      return imagePath;
    }

    final serverUrl =
        ApiConfig.baseUrl.replaceFirst('/api', '');

    if (imagePath.startsWith('/')) {
      return '$serverUrl$imagePath';
    }

    return '$serverUrl/$imagePath';
  }

  String _price(dynamic product) {
    final discountPrice = product['discount_price'];
    final price = product['price'];

    final value = discountPrice ?? price ?? 0;

    return '₹$value';
  }

  Future<void> _openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _openProductDetails(
    dynamic product,
  ) async {
    final productId = product['id'];

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product ID is missing.',
          ),
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    final id = int.tryParse(
      productId.toString(),
    );

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid product ID.',
          ),
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          productId: id,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _addToCart(dynamic product) async {
    final productId = product['id'];

    if (productId == null) {
      return;
    }

    final id = int.tryParse(
      productId.toString(),
    );

    if (id == null) {
      return;
    }

    setState(() {
      _addingProductId = id;
    });

    try {
      await CartService.addToCart(
        productId: id,
        quantity: 1,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product['name'] ?? 'Product'} added to cart.',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: _openCart,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingProductId = null;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    if (mounted) {
      setState(() {});
    }

    _searchDebounce?.cancel();

    final searchText = value.trim();

    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () {
        _searchProducts(searchText);
      },
    );
  }

  Future<void> _searchProducts(String searchText) async {
    if (!mounted) return;

    setState(() {
      _searchText = searchText;
      _searching = true;
      _error = null;
    });

    try {
      final response = await ApiService.getProducts(
        page: 1,
        perPage: 100,
        search:
            searchText.isEmpty ? null : searchText,
        categoryId: _selectedCategoryId,
      );

      if (!mounted) return;

      setState(() {
        _products =
            response['products'] as List<dynamic>? ?? [];

        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _clearSearch() async {
    _searchDebounce?.cancel();
    _searchController.clear();

    await _searchProducts('');
  }

  Future<void> _selectCategory(
    dynamic category,
  ) async {
    final categoryId = int.tryParse(
      '${category['id']}',
    );

    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid category.',
          ),
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    final categoryName =
        category['name']?.toString() ?? 'Category';

    _searchDebounce?.cancel();
    _searchController.clear();

    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
      _loadingCategoryProducts = true;
      _searchText = '';
      _searching = false;
      _error = null;
    });

    try {
      final response = await ApiService.getProducts(
        page: 1,
        perPage: 100,
        categoryId: categoryId,
      );

      if (!mounted) return;

      setState(() {
        _products =
            response['products'] as List<dynamic>? ?? [];

        _loadingCategoryProducts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCategoryProducts = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showAllProducts() async {
    if (!mounted) return;

    _searchDebounce?.cancel();
    _searchController.clear();

    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _searchText = '';
      _searching = false;
      _loadingCategoryProducts = true;
      _error = null;
    });

    try {
      final response = await ApiService.getProducts(
        page: 1,
        perPage: 20,
      );

      if (!mounted) return;

      setState(() {
        _products =
            response['products'] as List<dynamic>? ?? [];

        _loadingCategoryProducts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCategoryProducts = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8D6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        centerTitle: true,

        // ======================================================
        // SHOP TO DOOR 3D BACKWARD SHADOW BRAND TITLE
        // ======================================================
        title: Stack(
          clipBehavior: Clip.none,
          children: [
            // Gold backward/extruded shadow
            const Positioned(
              left: -3,
              top: 3,
              child: Text(
                'Shop To Door',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: Color(0xFF9A7600),
                ),
              ),
            ),

            // Main dark navy text
            const Text(
              'Shop To Door',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                color: Color(0xFF172033),
              ),
            ),
          ],
        ),

        leadingWidth: 76,
        toolbarHeight: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.black,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    'assets/shop-to-door-logo.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons.shopping_bag_outlined,
                        size: 32,
                        color: Colors.blue,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        actions: [
          IconButton(
            onPressed: _openCart,
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.black,
            ),
            tooltip: 'Cart',
          ),
          const SizedBox(width: 8),
        ],
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

    if (_error != null &&
        !_searching) {
      return RefreshIndicator(
        onRefresh: _loadHomeData,
        child: ListView(
          children: [
            const SizedBox(height: 250),
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 55,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Unable to load Shop To Door',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign:
                          TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed:
                          _loadHomeData,
                      child:
                          const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: ListView(
        padding:
            const EdgeInsets.only(
          bottom: 30,
        ),
        children: [
          Container(
            color: const Color(0xFFFFC107),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding:
                      EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    8,
                  ),
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                _buildCategories(),

                _buildSearchBar(),
              ],
            ),
          ),

          _buildSectionTitle(
            _searchText.isNotEmpty
                ? 'Search Results'
                : _selectedCategoryName ==
                        null
                    ? 'Products'
                    : '$_selectedCategoryName Products',
          ),

          _buildProducts(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        2,
        16,
        14,
      ),
      child: Container(
        height: 50,
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: TextField(
          controller:
              _searchController,
          onChanged:
              _onSearchChanged,
          textInputAction:
              TextInputAction.search,
          decoration:
              InputDecoration(
            hintText:
                'Search products...',
            prefixIcon:
                const Icon(
              Icons.search,
            ),
            suffixIcon:
                _searchController
                        .text
                        .isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(
                          Icons.clear,
                        ),
                        onPressed:
                            _clearSearch,
                      )
                    : null,
            border:
                InputBorder.none,
            contentPadding:
                const EdgeInsets
                    .symmetric(
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        5,
        16,
        12,
      ),
      child: Text(
        title,
        style:
            const TextStyle(
          fontSize: 20,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON-STYLE CATEGORIES
  // ============================================================

  Widget _buildCategories() {
    if (_categories.isEmpty) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Text(
          'No categories available.',
          style: TextStyle(
            color: Colors.black87,
          ),
        ),
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        itemCount:
            _categories.length,
        itemBuilder: (
          context,
          index,
        ) {
          final category =
              _categories[index];

          final name =
              category['name']
                      ?.toString() ??
                  'Category';

          final imageUrl =
              _imageUrl(
            category['image'],
          );

          final categoryId =
              int.tryParse(
            '${category['id']}',
          );

          final isSelected =
              categoryId != null &&
                  categoryId ==
                      _selectedCategoryId;

          return GestureDetector(
            onTap:
                _loadingCategoryProducts ||
                        _searching
                    ? null
                    : () =>
                        _selectCategory(
                          category,
                        ),
            child:
                Container(
              width: 78,
              margin:
                  const EdgeInsets.only(
                right: 10,
              ),
              child:
                  Column(
                children: [
                  AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds:
                          180,
                    ),
                    width: 64,
                    height: 64,
                    decoration:
                        BoxDecoration(
                      color: isSelected
                          ? const Color(
                              0xFFFFF8D6,
                            )
                          : Colors.black,
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                      border:
                          Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.black,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .black
                              .withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 6,
                          offset:
                              const Offset(
                            0,
                            3,
                          ),
                        ),
                      ],
                    ),
                    child: Center(
                      child: imageUrl
                              .isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 38,
                              height: 38,
                              fit: BoxFit.contain,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return Icon(
                                  Icons
                                      .category_outlined,
                                  size: 28,
                                  color: isSelected
                                      ? Colors
                                          .black54
                                      : Colors
                                          .white,
                                );
                              },
                            )
                          : Icon(
                              Icons
                                  .category_outlined,
                              size: 28,
                              color: isSelected
                                  ? Colors
                                      .black54
                                  : Colors
                                      .white,
                            ),
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    name,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected
                              ? FontWeight
                                  .w700
                              : FontWeight
                                  .w500,
                      color:
                          Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProducts() {
    if (_searching ||
        _loadingCategoryProducts) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 40,
        ),
        child: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_products.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons
                    .inventory_2_outlined,
                size: 50,
                color: Colors.grey,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                _searchText.isNotEmpty
                    ? 'No products found for "$_searchText".'
                    : _selectedCategoryName ==
                            null
                        ? 'No products available.'
                        : 'No products available in $_selectedCategoryName.',
                textAlign:
                    TextAlign.center,
              ),
              if (_searchText
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 15,
                ),
                OutlinedButton(
                  onPressed:
                      _clearSearch,
                  child:
                      const Text(
                    'Clear Search',
                  ),
                ),
              ] else if (_selectedCategoryName !=
                  null) ...[
                const SizedBox(
                  height: 15,
                ),
                OutlinedButton(
                  onPressed:
                      _showAllProducts,
                  child:
                      const Text(
                    'Show All Products',
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_selectedCategoryName !=
                null &&
            _searchText.isEmpty)
          Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              16,
              0,
              16,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing products in $_selectedCategoryName',
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      _showAllProducts,
                  child:
                      const Text(
                    'Show All',
                  ),
                ),
              ],
            ),
          ),

        if (_searchText.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              16,
              0,
              16,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategoryName !=
                                null
                        ? 'Results for "$_searchText" in $_selectedCategoryName'
                        : 'Results for "$_searchText"',
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      _clearSearch,
                  child:
                      const Text(
                    'Clear',
                  ),
                ),
              ],
            ),
          ),

        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 16,
          ),
          itemCount:
              _products.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (
            context,
            index,
          ) {
            final product =
                _products[index];

            final name =
                product['name']
                        ?.toString() ??
                    'Product';

            final imageUrl =
                _imageUrl(
              product['image'],
            );

            final stock =
                int.tryParse(
                      '${product['stock'] ?? 0}',
                    ) ??
                    0;

            final productId =
                int.tryParse(
              '${product['id']}',
            );

            final isAdding =
                productId != null &&
                    _addingProductId ==
                        productId;

            return GestureDetector(
              onTap:
                  productId == null
                      ? null
                      : () =>
                          _openProductDetails(
                            product,
                          ),
              child:
                  Container(
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(
                    16,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .black
                          .withValues(
                        alpha: 0.06,
                      ),
                      blurRadius: 8,
                      offset:
                          const Offset(
                        0,
                        3,
                      ),
                    ),
                  ],
                ),
                clipBehavior:
                    Clip.antiAlias,
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Expanded(
                      child:
                          Container(
                        width:
                            double.infinity,
                        color:
                            const Color(
                          0xFFF5F5F5,
                        ),
                        child:
                            imageUrl
                                    .isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit
                                        .cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return const Icon(
                                        Icons
                                            .image_not_supported_outlined,
                                        size:
                                            45,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons
                                        .image_outlined,
                                    size:
                                        45,
                                  ),
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        12,
                        10,
                        12,
                        12,
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            _price(
                              product,
                            ),
                            style:
                                const TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Colors
                                      .blue,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            stock > 0
                                ? 'In stock: $stock'
                                : 'Out of stock',
                            style:
                                TextStyle(
                              fontSize: 12,
                              color: stock >
                                      0
                                  ? Colors
                                      .green
                                  : Colors
                                      .red,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          SizedBox(
                            width:
                                double.infinity,
                            child:
                                ElevatedButton
                                    .icon(
                              onPressed:
                                  stock >
                                              0 &&
                                          !isAdding
                                      ? () => _addToCart(
                                            product,
                                          )
                                      : null,
                              icon:
                                  isAdding
                                      ? const SizedBox(
                                          width:
                                              18,
                                          height:
                                              18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                            color:
                                                Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons
                                              .shopping_cart_outlined,
                                          size:
                                              18,
                                        ),
                              label:
                                  Text(
                                isAdding
                                    ? 'Adding...'
                                    : 'Add to Cart',
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
          },
        ),
      ],
    );
  }
}