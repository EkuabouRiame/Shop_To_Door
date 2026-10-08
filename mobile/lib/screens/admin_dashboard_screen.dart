import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_delivery_accounts_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  bool _isLoading = false;
  String? _errorMessage;

  int _users = 0;
  int _categories = 0;
  int _products = 0;
  int _productImages = 0;

  final List<String> _titles = const [
    'Dashboard',
    'Orders',
    'Products',
    'Categories',
    'Delivery',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ================================================================
  // LOAD DASHBOARD API
  // ================================================================

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await AdminService.getDashboard();

      final dashboard = data['dashboard'];

      if (dashboard is Map<String, dynamic>) {
        if (mounted) {
          setState(() {
            _users = _toInt(dashboard['users']);
            _categories = _toInt(dashboard['categories']);
            _products = _toInt(dashboard['products']);
            _productImages =
                _toInt(dashboard['product_images']);
          });
        }
      } else {
        throw Exception(
          'Dashboard data was not returned by the server.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e
              .toString()
              .replaceFirst('Exception: ', '');
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ================================================================
  // LOGOUT
  // ================================================================

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _loadDashboard,
            icon: const Icon(
              Icons.refresh,
              color: Colors.blue,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ============================================================
          // ADMIN NAVIGATION
          // ============================================================

          Container(
            margin: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              0,
            ),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  _titles.length,
                  (index) {
                    final selected =
                        _selectedIndex == index;

                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF111827)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            _titles[index],
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(
                                      0xFF374151,
                                    ),
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ============================================================
          // CONTENT
          // ============================================================

          Expanded(
            child: _buildSelectedSection(),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SELECTED SECTION
  // ================================================================

  Widget _buildSelectedSection() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();

      case 1:
        return _buildOrdersSection();

      case 2:
        return _buildProductsSection();

      case 3:
        return _buildCategoriesSection();

      case 4:
        return _buildDeliverySection();

      default:
        return _buildDashboard();
    }
  }

  // ================================================================
  // DASHBOARD
  // ================================================================

  Widget _buildDashboard() {
    if (_isLoading && _users == 0 && _products == 0) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildDashboardError();
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          24,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Overview of your Shop To Door store.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------------
            // API STATISTICS
            // ----------------------------------------------------------

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _StatCard(
                  title: 'Users',
                  value: _users.toString(),
                  icon: Icons.people_outline,
                ),
                _StatCard(
                  title: 'Categories',
                  value: _categories.toString(),
                  icon: Icons.category_outlined,
                ),
                _StatCard(
                  title: 'Products',
                  value: _products.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
                _StatCard(
                  title: 'Product Images',
                  value: _productImages.toString(),
                  icon: Icons.image_outlined,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------------
            // MANAGEMENT SHORTCUTS
            // ----------------------------------------------------------

            const Text(
              'Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 12),

            _buildManagementCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Orders',
              description:
                  'View and manage customer orders.',
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),

            const SizedBox(height: 10),

            _buildManagementCard(
              icon: Icons.inventory_2_outlined,
              title: 'Products',
              description:
                  'Add and manage store products.',
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),

            const SizedBox(height: 10),

            _buildManagementCard(
              icon: Icons.category_outlined,
              title: 'Categories',
              description:
                  'Manage your product categories.',
              onPressed: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),

            const SizedBox(height: 10),

            _buildManagementCard(
              icon: Icons.delivery_dining,
              title: 'Delivery',
              description:
                  'Manage delivery persons and assignments.',
              onPressed: () {
                setState(() {
                  _selectedIndex = 4;
                });
              },
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------------
            // API INFORMATION
            // ----------------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_done_outlined,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Dashboard Data',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Statistics are loaded from the Shop To Door admin API.',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Color(0xFF6B7280),
                          ),
                        ),
                      ],
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

  // ================================================================
  // DASHBOARD ERROR
  // ================================================================

  Widget _buildDashboardError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 54,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // MANAGEMENT CARD
  // ================================================================

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue
                      .withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color:
                            Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // ORDERS
  // ================================================================

  Widget _buildOrdersSection() {
    return _buildComingSection(
      icon: Icons.shopping_bag_outlined,
      title: 'Orders',
      description:
          'Manage customer orders, statuses and delivery assignments.',
      buttonText: 'Open Orders',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AdminOrdersScreen(),
          ),
        );
      },
    );
  }

  // ================================================================
  // PRODUCTS
  // ================================================================

  Widget _buildProductsSection() {
    return _buildComingSection(
      icon: Icons.inventory_2_outlined,
      title: 'Products',
      description:
          'Add, update and manage products in your store.',
      buttonText: 'Manage Products',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AdminProductsScreen(),
          ),
        );
      },
    );
  }

  // ================================================================
  // CATEGORIES
  // ================================================================

  Widget _buildCategoriesSection() {
    return _buildComingSection(
      icon: Icons.category_outlined,
      title: 'Categories',
      description:
          'Add, update and manage product categories.',
      buttonText: 'Manage Categories',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AdminCategoriesScreen(),
          ),
        );
      },
    );
  }

  // ================================================================
  // DELIVERY
  // ================================================================

  Widget _buildDeliverySection() {
    return _buildComingSection(
      icon: Icons.delivery_dining,
      title: 'Delivery',
      description:
          'Create delivery accounts and manage delivery persons.',
      buttonText: 'Manage Delivery',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AdminDeliveryAccountsScreen(),
          ),
        );
      },
    );
  }

  // ================================================================
  // SECTION PLACEHOLDER
  // ================================================================

  Widget _buildComingSection({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    VoidCallback? onPressed,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 58,
                  color: Colors.blue,
                ),

                const SizedBox(height: 16),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: onPressed ??
                      () {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$buttonText will be connected next.',
                            ),
                          ),
                        );
                      },
                  icon: const Icon(
                    Icons.arrow_forward,
                  ),
                  label: Text(buttonText),
                  style:
                      ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// STAT CARD
// ==================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: Colors.blue,
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  title,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}