import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'delivery_confirmation_scanner_screen.dart';
import 'reset_password_screen.dart';
import 'login_screen.dart';
import 'product_details_screen.dart';
import 'about_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // ============================================================
  // HOME NESTED NAVIGATOR
  // ============================================================

  final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>();

  // ============================================================
  // HOME SCREEN KEY
  // ============================================================

  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();

  // ============================================================
  // CHANGE BOTTOM TAB
  // ============================================================

  void _changeTab(int index) {
    // ==========================================================
    // HOME
    // ==========================================================

    if (index == 0) {
      _homeNavigatorKey.currentState?.popUntil(
        (route) => route.isFirst,
      );

      _homeScreenKey.currentState?.resetHomeScreen();

      setState(() {
        _currentIndex = 0;
      });

      return;
    }

    // ==========================================================
    // OTHER TABS
    // ==========================================================

    setState(() {
      _currentIndex = index;
    });
  }

  // ============================================================
  // HOME NAVIGATOR
  // ============================================================

  Widget _buildHomeNavigator() {
    return Navigator(
      key: _homeNavigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => HomeScreen(
            key: _homeScreenKey,
          ),
          settings: settings,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // ======================================================
          // HOME
          // ======================================================

          _buildHomeNavigator(),

          // ======================================================
          // CATEGORIES
          // ======================================================

          CategoriesScreen(
            onBack: () => _changeTab(0),
          ),

          // ======================================================
          // CART
          // ======================================================

          CartScreen(
            onContinueShopping: () => _changeTab(0),
          ),

          // ======================================================
          // ACCOUNT
          // ======================================================

          AccountScreen(
            onBack: () => _changeTab(0),
          ),
        ],
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changeTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.shopping_cart_outlined,
            ),
            selectedIcon: Icon(
              Icons.shopping_cart,
            ),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CATEGORIES SCREEN
// ============================================================

class CategoriesScreen extends StatefulWidget {
  final VoidCallback onBack;

  const CategoriesScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<CategoriesScreen> createState() =>
      _CategoriesScreenState();
}

class _CategoriesScreenState
    extends State<CategoriesScreen> {
  List<dynamic> _categories = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _loadCategories();
  }

  // ==========================================================
  // LOAD CATEGORIES
  // ==========================================================

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response =
          await ApiService.getCategories();

      List<dynamic> categories = [];

      if (response['categories'] is List) {
        categories =
            response['categories'] as List<dynamic>;
      } else if (response['data'] is List) {
        categories =
            response['data'] as List<dynamic>;
      }

      if (!mounted) return;

      setState(() {
        _categories = categories;
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

  // ==========================================================
  // CATEGORY NAME
  // ==========================================================

  String _categoryName(dynamic category) {
    if (category is Map) {
      return category['name']?.toString() ??
          'Category';
    }

    return category.toString();
  }

  // ==========================================================
  // CATEGORY ID
  // ==========================================================

  int? _categoryId(dynamic category) {
    if (category is! Map) {
      return null;
    }

    return int.tryParse(
      '${category['id']}',
    );
  }

  // ==========================================================
  // IMAGE URL
  // ==========================================================

  String _imageUrl(dynamic image) {
    if (image == null ||
        image.toString().trim().isEmpty) {
      return '';
    }

    final imagePath = image.toString();

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

  // ==========================================================
  // OPEN CATEGORY
  // ==========================================================

  Future<void> _openCategory(
    dynamic category,
  ) async {
    final categoryId =
        _categoryId(category);

    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Category ID is missing.',
          ),
        ),
      );

      return;
    }

    final categoryName =
        _categoryName(category);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFFC107),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          tooltip: 'Back to Home',
          onPressed: widget.onBack,
        ),

        title: const Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadCategories,
        child: ListView(
          children: [
            const SizedBox(height: 180),

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

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      'Unable to load categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      _error!,
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ElevatedButton(
                      onPressed:
                          _loadCategories,
                      child:
                          const Text(
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

    if (_categories.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCategories,
        child: ListView(
          children: const [
            SizedBox(height: 180),

            Center(
              child: Icon(
                Icons.category_outlined,
                size: 70,
                color: Colors.grey,
              ),
            ),

            SizedBox(height: 15),

            Center(
              child: Text(
                'No categories available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,

      child: GridView.builder(
        padding:
            const EdgeInsets.all(16),

        itemCount: _categories.length,

        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),

        itemBuilder:
            (context, index) {
          final category =
              _categories[index];

          final name =
              _categoryName(category);

          String imageUrl = '';

          if (category is Map) {
            imageUrl = _imageUrl(
              category['image'],
            );
          }

          return Material(
            color: Colors.transparent,

            child: InkWell(
              borderRadius:
                  BorderRadius.circular(16),

              onTap: () =>
                  _openCategory(category),

              child: Container(
                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(
                        alpha: 0.06,
                      ),
                      blurRadius: 8,
                      offset:
                          const Offset(0, 3),
                    ),
                  ],
                ),

                clipBehavior:
                    Clip.antiAlias,

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          14,
                        ),

                        child:
                            imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit:
                                        BoxFit.contain,
                                    errorBuilder:
                                        (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return const Icon(
                                        Icons
                                            .category_outlined,
                                        size: 55,
                                        color:
                                            Colors.blue,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons
                                        .category_outlined,
                                    size: 55,
                                    color:
                                        Colors.blue,
                                  ),
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        10,
                        4,
                        10,
                        16,
                      ),

                      child: Text(
                        name,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        textAlign:
                            TextAlign.center,

                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// CATEGORY PRODUCTS SCREEN
// ============================================================

class CategoryProductsScreen
    extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen>
      createState() =>
          _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends State<CategoryProductsScreen> {
  List<dynamic> _products = [];

  bool _loading = true;
  String? _error;

  int? _addingProductId;

  @override
  void initState() {
    super.initState();

    _loadProducts();
  }

  // ==========================================================
  // LOAD CATEGORY PRODUCTS
  // ==========================================================

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response =
          await ApiService.getProducts(
        page: 1,
        perPage: 100,
        categoryId: widget.categoryId,
      );

      final products =
          response['products']
                  as List<dynamic>? ??
              [];

      if (!mounted) return;

      setState(() {
        _products = products;
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

  // ==========================================================
  // IMAGE URL
  // ==========================================================

  String _imageUrl(dynamic image) {
    if (image == null ||
        image.toString().trim().isEmpty) {
      return '';
    }

    final imagePath = image.toString();

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

  // ==========================================================
  // PRICE
  // ==========================================================

  String _price(dynamic product) {
    final discountPrice =
        product['discount_price'];

    final price =
        product['price'];

    final value =
        discountPrice ?? price ?? 0;

    return '₹$value';
  }

  // ==========================================================
  // OPEN PRODUCT DETAILS
  // ==========================================================

  Future<void> _openProductDetails(
    dynamic product,
  ) async {
    final productId =
        product['id'];

    if (productId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Product ID is missing.',
          ),
        ),
      );

      return;
    }

    final id =
        int.tryParse(
      productId.toString(),
    );

    if (id == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid product ID.',
          ),
        ),
      );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailsScreen(
          productId: id,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  // ==========================================================
  // ADD TO CART
  // ==========================================================

  Future<void> _addToCart(
    dynamic product,
  ) async {
    final productId =
        product['id'];

    if (productId == null) {
      return;
    }

    final id =
        int.tryParse(
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

      final messenger =
          ScaffoldMessenger.of(
        context,
      );

      messenger.removeCurrentSnackBar();

      final controller =
          messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${product['name'] ?? 'Product'} added to cart',
          ),
          duration:
              const Duration(seconds: 2),
          behavior:
              SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              messenger
                  .hideCurrentSnackBar();

              _openCart();
            },
          ),
        ),
      );

      Future.delayed(
        const Duration(seconds: 2),
        () {
          if (mounted) {
            controller.close();
          }
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .removeCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          duration:
              const Duration(seconds: 3),
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

  // ==========================================================
  // OPEN CART
  // ==========================================================

  Future<void> _openCart() async {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .removeCurrentSnackBar();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CartScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFFC107),

        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadProducts,

        child: ListView(
          children: [
            const SizedBox(
              height: 180,
            ),

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

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      'Unable to load products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      _error!,
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ElevatedButton(
                      onPressed:
                          _loadProducts,
                      child:
                          const Text(
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

    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadProducts,

        child: ListView(
          children: [
            const SizedBox(
              height: 180,
            ),

            const Center(
              child: Icon(
                Icons.inventory_2_outlined,
                size: 70,
                color: Colors.grey,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            Center(
              child: Text(
                'No products available',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,

      child: GridView.builder(
        padding:
            const EdgeInsets.all(16),

        itemCount:
            _products.length,

        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),

        itemBuilder:
            (context, index) {
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

          return Material(
            color:
                Colors.transparent,

            child: InkWell(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),

              onTap:
                  productId == null
                      ? null
                      : () =>
                          _openProductDetails(
                            product,
                          ),

              child: Container(
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(
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

                child: Column(
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
                                    errorBuilder:
                                        (
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
                                  Colors.blue,
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
                              fontSize:
                                  12,
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
                                      ? () =>
                                          _addToCart(
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
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// ACCOUNT SCREEN
// ============================================================

class AccountScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AccountScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<AccountScreen> createState() =>
      _AccountScreenState();
}

class _AccountScreenState
    extends State<AccountScreen> {
  Map<String, dynamic>? _user;

  bool _loadingUser = true;

  // ==========================================================
  // LOGOUT
  // ==========================================================

  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      await AuthService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loggingOut = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to logout: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _loadUser();
  }

  // ==========================================================
  // LOAD SAVED USER
  // ==========================================================

  Future<void> _loadUser() async {
    try {
      final user =
          await AuthService.getSavedUser();

      if (!mounted) return;

      setState(() {
        _user = user;
        _loadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingUser = false;
      });
    }
  }

  // ==========================================================
  // USER VALUES
  // ==========================================================

  String _userName() {
    final value =
        _user?['name']?.toString().trim();

    if (value == null || value.isEmpty) {
      return 'Customer';
    }

    return value;
  }

  String _userEmail() {
    final value =
        _user?['email']?.toString().trim();

    if (value == null || value.isEmpty) {
      return 'Email not available';
    }

    return value;
  }

  String _userPhone() {
    final value =
        _user?['phone']?.toString().trim();

    if (value == null || value.isEmpty) {
      return 'Phone not available';
    }

    return value;
  }

  String _userRole() {
    final value =
        _user?['role']?.toString().trim();

    if (value == null || value.isEmpty) {
      return 'customer';
    }

    return value;
  }

  // ==========================================================
  // CUSTOMER CHECK
  // ==========================================================

  bool _isCustomer() {
    return _userRole().toLowerCase() ==
        'customer';
  }

  // ==========================================================
  // DISPLAY ROLE
  // ==========================================================

  String _displayRole() {
    final role =
        _userRole().toLowerCase();

    switch (role) {
      case 'delivery_person':
        return 'Delivery Person';

      case 'admin':
        return 'Administrator';

      case 'customer':
        return 'Customer';

      default:
        return _userRole();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFFC107),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          tooltip: 'Back to Home',
          onPressed: widget.onBack,
        ),

        title: const Text(
          'Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _loadingUser
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadUser,

              child: ListView(
                padding:
                    const EdgeInsets.all(16),

                children: [
                  // ==================================================
                  // PROFILE
                  // ==================================================

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),

                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                Colors.blue
                                    .shade100,

                            child: Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.blue
                                  .shade700,
                            ),
                          ),

                          const SizedBox(
                            width: 16,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Text(
                                  _userName(),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      const TextStyle(
                                    fontSize:
                                        19,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  _userEmail(),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  _displayRole(),

                                  style:
                                      TextStyle(
                                    color: Colors
                                        .blue
                                        .shade700,
                                    fontWeight:
                                        FontWeight
                                            .w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // ACCOUNT DETAILS
                  // ==================================================

                  Card(
                    child: ExpansionTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: Colors.blue,
                      ),

                      title: const Text(
                        'Account Details',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      subtitle: const Text(
                        'View your account information',
                      ),

                      children: [
                        _detailRow(
                          icon:
                              Icons.person_outline,
                          title:
                              'Name',
                          value:
                              _userName(),
                        ),

                        const Divider(
                          height: 1,
                        ),

                        _detailRow(
                          icon:
                              Icons.email_outlined,
                          title:
                              'Email',
                          value:
                              _userEmail(),
                        ),

                        const Divider(
                          height: 1,
                        ),

                        _detailRow(
                          icon:
                              Icons.phone_outlined,
                          title:
                              'Phone',
                          value:
                              _userPhone(),
                        ),

                        const Divider(
                          height: 1,
                        ),

                        _detailRow(
                          icon:
                              Icons.badge_outlined,
                          title:
                              'Account Type',
                          value:
                              _displayRole(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // MY ORDERS
                  // ==================================================

                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.blue,
                      ),

                      title: const Text(
                        'My Orders',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      subtitle: const Text(
                        'View and track your orders',
                      ),

                      trailing:
                          const Icon(
                        Icons.chevron_right,
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const OrdersScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  // ==================================================
                  // DELIVERY QR SCANNER
                  // CUSTOMER ONLY
                  // ==================================================

                  if (_isCustomer()) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.blue,
                        ),

                        title: const Text(
                          'Scan Delivery QR',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        subtitle: const Text(
                          'Scan the QR shown by the delivery person',
                        ),

                        trailing:
                            const Icon(
                          Icons.chevron_right,
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const DeliveryConfirmationScannerScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),
                  ],

                  // ==================================================
                  // SETTINGS
                  // ==================================================

                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.settings_outlined,
                        color: Colors.blue,
                      ),

                      title: const Text(
                        'Settings',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      subtitle: const Text(
                        'Manage your account settings',
                      ),

                      trailing:
                          const Icon(
                        Icons.chevron_right,
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ResetPasswordScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  // ==================================================
                  // ABOUT
                  // ==================================================

                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                      ),

                      title: const Text(
                        'About Shop To Door',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      trailing:
                          const Icon(
                        Icons.chevron_right,
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AboutScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ==================================================
                  // LOGOUT
                  // ==================================================

                  SizedBox(
                    height: 50,

                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _loggingOut
                              ? null
                              : _logout,

                      icon: _loggingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.logout,
                            ),

                      label: Text(
                        _loggingOut
                            ? 'Logging out...'
                            : 'Logout',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blue,
        size: 22,
      ),

      title: Text(
        title,
        style:
            const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),

      subtitle: Text(
        value,
        style:
            const TextStyle(
          fontSize: 15,
          fontWeight:
              FontWeight.w500,
        ),
      ),
    );
  }
}