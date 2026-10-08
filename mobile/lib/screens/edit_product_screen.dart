import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/admin_product_service.dart';

class EditProductScreen extends StatefulWidget {
  final int productId;

  const EditProductScreen({
    super.key,
    required this.productId,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _categoryIdController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  bool _isFeatured = false;
  bool _isActive = true;

  String? _errorMessage;

  List<dynamic> _images = [];
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _categoryIdController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await AdminProductService.getProduct(
        widget.productId,
      );

      final images = await AdminProductService.getProductImages(
        widget.productId,
      );

      if (!mounted) return;

      _nameController.text = product['name']?.toString() ?? '';

      _brandController.text = product['brand']?.toString() ?? '';

      _descriptionController.text =
          product['description']?.toString() ?? '';

      _skuController.text = product['sku']?.toString() ?? '';

      _categoryIdController.text =
          product['category_id']?.toString() ?? '';

      _priceController.text = product['price']?.toString() ?? '';

      _discountPriceController.text =
          product['discount_price']?.toString() ?? '';

      _stockController.text = product['stock']?.toString() ?? '';

      _isFeatured =
          product['is_featured'] == true ||
          product['is_featured']?.toString().toLowerCase() == 'true';

      _isActive =
          product['is_active'] == true ||
          product['is_active']?.toString().toLowerCase() == 'true';

      if (!mounted) return;

      setState(() {
        _images = images;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null || !mounted) return;

      setState(() {
        _selectedImage = File(picked.path);
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to select image.',
        isError: true,
      );
    }
  }

  Future<void> _uploadSelectedImage() async {
    if (_selectedImage == null) {
      _showMessage(
        'Please select an image first.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isUploading = true;
    });

    try {
      await AdminProductService.uploadProductImage(
        productId: widget.productId,
        imageFile: _selectedImage!,
      );

      if (!mounted) return;

      setState(() {
        _selectedImage = null;
      });

      await _loadImages();

      if (!mounted) return;

      _showMessage(
        'Product image uploaded successfully.',
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
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _loadImages() async {
    try {
      final images = await AdminProductService.getProductImages(
        widget.productId,
      );

      if (!mounted) return;

      setState(() {
        _images = images;
      });
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

  Future<void> _setPrimaryImage(
    dynamic image,
  ) async {
    final imageId = _toInt(
      image is Map ? image['id'] : null,
    );

    if (imageId == null) {
      _showMessage(
        'Invalid image ID.',
        isError: true,
      );
      return;
    }

    try {
      await AdminProductService.setPrimaryProductImage(
        productId: widget.productId,
        imageId: imageId,
      );

      await _loadImages();

      if (!mounted) return;

      _showMessage(
        'Primary image updated successfully.',
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

  Future<void> _deleteImage(
    dynamic image,
  ) async {
    final imageId = _toInt(
      image is Map ? image['id'] : null,
    );

    if (imageId == null) {
      _showMessage(
        'Invalid image ID.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text(
            'Are you sure you want to delete this product image?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await AdminProductService.deleteProductImage(
        productId: widget.productId,
        imageId: imageId,
      );

      await _loadImages();

      if (!mounted) return;

      _showMessage(
        'Product image deleted successfully.',
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final categoryId = int.tryParse(
      _categoryIdController.text.trim(),
    );

    if (categoryId == null) {
      _showMessage(
        'Enter a valid category ID.',
        isError: true,
      );
      return;
    }

    final price = double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null) {
      _showMessage(
        'Enter a valid price.',
        isError: true,
      );
      return;
    }

    final stock = int.tryParse(
      _stockController.text.trim(),
    );

    if (stock == null) {
      _showMessage(
        'Enter a valid stock quantity.',
        isError: true,
      );
      return;
    }

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'brand': _brandController.text.trim(),
      'description': _descriptionController.text.trim(),
      'sku': _skuController.text.trim(),
      'category_id': categoryId,
      'price': price,
      'stock': stock,
      'is_featured': _isFeatured,
      'is_active': _isActive,
    };

    final discount = _discountPriceController.text.trim();

    if (discount.isNotEmpty) {
      final discountValue = double.tryParse(discount);

      if (discountValue == null) {
        _showMessage(
          'Enter a valid discount price.',
          isError: true,
        );
        return;
      }

      data['discount_price'] = discountValue;
    } else {
      data['discount_price'] = null;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await AdminProductService.updateProduct(
        productId: widget.productId,
        data: data,
      );

      if (!mounted) return;

      // Clear focus before leaving the screen so the keyboard/text
      // editing system is detached before the controllers are disposed.
      FocusManager.instance.primaryFocus?.unfocus();

      // IMPORTANT:
      // Set saving state before Navigator.pop().
      // Do not call setState() after Navigator.pop(), because the route
      // may already be in the process of being disposed.
      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Product updated successfully.',
      );

      await Future.delayed(
        const Duration(milliseconds: 600),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
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

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage product images and choose the primary image.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          if (_images.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 40,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No product images',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 145,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildImageCard(
                    _images[index],
                  );
                },
              ),
            ),
          const SizedBox(height: 18),
          if (_selectedImage != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Image',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _isUploading ? null : _pickImage,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                        label: const Text(
                          'Change Image',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading
                            ? null
                            : _uploadSelectedImage,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.cloud_upload_outlined,
                              ),
                        label: Text(
                          _isUploading
                              ? 'Uploading...'
                              : 'Upload',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _isUploading ? null : _pickImage,
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                ),
                label: const Text(
                  'Select New Image',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard(dynamic image) {
    final Map<String, dynamic> item =
        image is Map<String, dynamic>
            ? image
            : Map<String, dynamic>.from(
                image as Map,
              );

    final imageUrl = _getImageUrl(item);

    final imageId = _toInt(item['id']);

    final isPrimary =
        item['is_primary'] == true ||
        item['is_primary']?.toString().toLowerCase() == 'true';

    return SizedBox(
      width: 135,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: 135,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl.isEmpty
                      ? const Icon(
                          Icons.image_outlined,
                          size: 38,
                          color: Color(0xFF9CA3AF),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(0xFF9CA3AF),
                            );
                          },
                        ),
                ),
                if (isPrimary)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRIMARY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'primary') {
                        _setPrimaryImage(image);
                      } else if (value == 'delete') {
                        _deleteImage(image);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isPrimary)
                        const PopupMenuItem(
                          value: 'primary',
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_outline,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Set Primary'),
                            ],
                          ),
                        ),
                      if (imageId != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red,
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Product',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
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
                size: 56,
                color: Colors.red,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadProduct,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImageSection(),
          const SizedBox(height: 18),
          _buildFormSection(),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  _isSaving ? null : _saveProduct,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Save Changes',
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _nameController,
            label: 'Product Name',
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Enter product name.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _brandController,
            label: 'Brand',
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Enter brand.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _skuController,
            label: 'SKU',
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Enter SKU.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 5,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Enter description.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _categoryIdController,
            label: 'Category ID',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Enter category ID.';
              }
              if (int.tryParse(
                    value.trim(),
                  ) ==
                  null) {
                return 'Enter a valid category ID.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _priceController,
            label: 'Price',
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Enter price.';
              }
              if (double.tryParse(
                    value.trim(),
                  ) ==
                  null) {
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
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _stockController,
            label: 'Stock',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Enter stock.';
              }
              if (int.tryParse(
                    value.trim(),
                  ) ==
                  null) {
                return 'Enter a valid stock quantity.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Active Product',
            ),
            subtitle: const Text(
              'Customers can see this product.',
            ),
            value: _isActive,
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Featured Product',
            ),
            subtitle: const Text(
              'Show this product as featured.',
            ),
            value: _isFeatured,
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _isFeatured = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  String _getImageUrl(
    Map<String, dynamic> image,
  ) {
    final value =
        image['url'] ??
        image['image'] ??
        image['image_url'];

    if (value is String &&
        value.trim().isNotEmpty) {
      return value.trim();
    }

    return '';
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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Colors.green,
      ),
    );
  }
}