import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import '../services/admin_product_service.dart';
import '../services/auth_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;

  List<dynamic> _categories = [];
  int? _selectedCategoryId;

  bool _isLoadingCategories = false;
  bool _isSubmitting = false;
  bool _isFeatured = false;
  bool _isActive = true;

  String? _categoryError;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('You are not logged in.');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = _decodeResponse(response);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          data['message']?.toString() ??
              'Unable to load categories.',
        );
      }

      final categories = data['categories'];

      if (!mounted) return;

      setState(() {
        _categories = categories is List ? categories : [];
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCategories = false;
        _categoryError = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageError = null;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to select image.',
        isError: true,
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile =
          await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageError = null;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to take photo.',
        isError: true,
      );
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                ),
                title: const Text(
                  'Choose from Gallery',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                ),
                title: const Text(
                  'Take a Photo',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Remove Image',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitProduct() async {
    FocusScope.of(context).unfocus();

    final isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() {
        _categoryError = 'Please select a category.';
      });
      return;
    }

    final stock =
        int.tryParse(_stockController.text.trim());

    if (stock == null || stock < 0) {
      _showMessage(
        'Please enter a valid stock quantity.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AdminProductService.createProduct(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        description:
            _descriptionController.text.trim(),
        sku: _skuController.text.trim(),
        categoryId: _selectedCategoryId!,
        price: _priceController.text.trim(),
        discountPrice:
            _discountPriceController.text.trim(),
        stock: stock,
        isFeatured: _isFeatured,
        isActive: _isActive,
        imageFile: _selectedImage,
      );

      if (!mounted) return;

      _showMessage(
        'Product added successfully.',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add Product',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF111827),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            32,
          ),
          children: [
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildBasicInformationSection(),
            const SizedBox(height: 16),
            _buildPricingSection(),
            const SizedBox(height: 16),
            _buildInventorySection(),
            const SizedBox(height: 16),
            _buildSettingsSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Image',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Optional. Add a clear image of the product if available.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showImageOptions,
            child: Container(
              width: double.infinity,
              height: 210,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _imageError != null
                      ? Colors.red
                      : const Color(0xFFE5E7EB),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.blue
                                .withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            size: 30,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Add Product Image',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Optional • Tap to select an image',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed:
                                  _showImageOptions,
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_imageError != null) ...[
            const SizedBox(height: 7),
            Text(
              _imageError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Product Name',
            hint: 'Enter product name',
            icon: Icons.inventory_2_outlined,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Product name is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _brandController,
            label: 'Brand',
            hint: 'Optional',
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _skuController,
            label: 'SKU',
            hint: 'Optional',
            icon: Icons.qr_code_2_outlined,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Optional',
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          _buildCategoryDropdown(),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'Category',
            hintText: 'Select category',
            prefixIcon: const Icon(
              Icons.category_outlined,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
          ),
          items: _categories.map((category) {
            final map =
                Map<String, dynamic>.from(category);

            final id = _toInt(map['id']);
            final name =
                map['name']?.toString() ??
                    'Unnamed Category';

            if (id == null) {
              return null;
            }

            return DropdownMenuItem<int>(
              value: id,
              child: Text(name),
            );
          }).whereType<DropdownMenuItem<int>>().toList(),
          onChanged: _isLoadingCategories
              ? null
              : (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _categoryError = null;
                  });
                },
        ),
        if (_isLoadingCategories) ...[
          const SizedBox(height: 7),
          const LinearProgressIndicator(
            minHeight: 2,
          ),
        ],
        if (_categoryError != null) ...[
          const SizedBox(height: 7),
          Text(
            _categoryError!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
        if (!_isLoadingCategories &&
            _categories.isEmpty &&
            _categoryError == null) ...[
          const SizedBox(height: 7),
          const Text(
            'No categories available.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPricingSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _priceController,
            label: 'Price',
            hint: 'Enter price',
            icon: Icons.currency_rupee,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Price is required.';
              }

              final price =
                  double.tryParse(value.trim());

              if (price == null || price < 0) {
                return 'Enter a valid price.';
              }

              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _discountPriceController,
            label: 'Discount Price',
            hint: 'Optional',
            icon: Icons.local_offer_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return null;
              }

              final discount =
                  double.tryParse(value.trim());

              if (discount == null || discount < 0) {
                return 'Enter a valid discount price.';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _stockController,
            label: 'Stock Quantity',
            hint: 'Enter stock quantity',
            icon: Icons.warehouse_outlined,
            keyboardType:
                TextInputType.number,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Stock quantity is required.';
              }

              final stock =
                  int.tryParse(value.trim());

              if (stock == null || stock < 0) {
                return 'Enter a valid stock quantity.';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Settings',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Active Product',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Make this product visible in the store.',
            ),
            value: _isActive,
            activeThumbColor: Colors.blue,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Featured Product',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Mark this product as featured.',
            ),
            value: _isFeatured,
            activeThumbColor: Colors.orange,
            onChanged: (value) {
              setState(() {
                _isFeatured = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed:
            _isSubmitting ? null : _submitProduct,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
        label: Text(
          _isSubmitting
              ? 'Adding Product...'
              : 'Add Product',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              Colors.blue.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded = jsonDecode(response.body);

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

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Colors.green,
      ),
    );
  }
}