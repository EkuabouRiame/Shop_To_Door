import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../services/admin_category_service.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState
    extends State<AdminCategoriesScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories =
          await AdminCategoryService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  String _categoryName(dynamic category) {
    if (category is Map) {
      return category['name']?.toString() ?? 'Unnamed Category';
    }

    return 'Unnamed Category';
  }

  int? _categoryId(dynamic category) {
    if (category is! Map) return null;

    final value = category['id'];

    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '');
  }

  String _categoryDescription(dynamic category) {
    if (category is Map) {
      return category['description']?.toString() ?? '';
    }

    return '';
  }

  bool _isCategoryActive(dynamic category) {
    if (category is! Map) return true;

    final value = category['is_active'];

    if (value is bool) return value;

    if (value is num) return value != 0;

    final text = value?.toString().toLowerCase();

    return text != 'false' && text != '0';
  }

  String? _categoryImage(dynamic category) {
    if (category is! Map) return null;

    final value = category['image'];

    if (value == null) return null;

    final image = value.toString().trim();

    if (image.isEmpty) return null;

    return _resolveImageUrl(image);
  }

  String _resolveImageUrl(String image) {
    if (image.startsWith('http://') ||
        image.startsWith('https://')) {
      return image;
    }

    final baseUrl = ApiConfig.baseUrl;

    if (image.startsWith('/')) {
      final host = baseUrl.replaceFirst('/api', '');

      return '$host$image';
    }

    final host = baseUrl.replaceFirst('/api', '');

    return '$host/$image';
  }

  Future<void> _showCategoryForm({
    Map<String, dynamic>? category,
  }) async {
    final isEditing = category != null;

    final nameController = TextEditingController(
      text: category?['name']?.toString() ?? '',
    );

    final slugController = TextEditingController(
      text: category?['slug']?.toString() ?? '',
    );

    final descriptionController =
        TextEditingController(
      text: category?['description']?.toString() ?? '',
    );

    bool isActive = category == null
        ? true
        : _isCategoryActive(category);

    File? selectedImage;

    final picker = ImagePicker();

    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          bool isSaving = false;

          return StatefulBuilder(
            builder: (
              context,
              setSheetState,
            ) {
              Future<void> pickImage(
                ImageSource source,
              ) async {
                try {
                  final picked =
                      await picker.pickImage(
                    source: source,
                    imageQuality: 85,
                    maxWidth: 1200,
                  );

                  if (picked == null) return;

                  setSheetState(() {
                    selectedImage = File(picked.path);
                  });
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to select image: $e',
                      ),
                    ),
                  );
                }
              }

              Future<void> saveCategory() async {
                final name =
                    nameController.text.trim();

                // Category Name is the only mandatory field.
                // Slug, Description and Image are optional.
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Category name is required.',
                      ),
                    ),
                  );
                  return;
                }

                setSheetState(() {
                  isSaving = true;
                });

                try {
                  Map<String, dynamic> savedCategory;

                  if (isEditing) {
                    savedCategory =
                        await AdminCategoryService
                            .updateCategory(
                      categoryId:
                          _categoryId(category)!,
                      name: name,
                      slug:
                          slugController.text.trim(),
                      description:
                          descriptionController.text
                              .trim(),
                      image:
                          category['image']
                              ?.toString(),
                      isActive: isActive,
                    );
                  } else {
                    savedCategory =
                        await AdminCategoryService
                            .createCategory(
                      name: name,
                      slug:
                          slugController.text.trim(),
                      description:
                          descriptionController.text
                              .trim(),
                      isActive: isActive,
                    );
                  }

                  final savedId =
                      _categoryId(savedCategory);

                  final categoryId =
                      savedId ?? _categoryId(category);

                  if (selectedImage != null &&
                      categoryId != null) {
                    await AdminCategoryService
                        .uploadCategoryImage(
                      categoryId: categoryId,
                      imageFile: selectedImage!,
                    );
                  }

                  if (!context.mounted) return;

                  Navigator.pop(
                    context,
                    true,
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  setSheetState(() {
                    isSaving = false;
                  });

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        e
                            .toString()
                            .replaceFirst(
                              'Exception: ',
                              '',
                            ),
                      ),
                    ),
                  );
                }
              }

              return SafeArea(
                child: Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context)
                            .viewInsets
                            .bottom +
                        20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isEditing
                                    ? 'Edit Category'
                                    : 'Add Category',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () =>
                                      Navigator.pop(
                                        context,
                                      ),
                              icon: const Icon(
                                Icons.close,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Category Name - REQUIRED
                        TextField(
                          controller: nameController,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration:
                              const InputDecoration(
                            labelText: 'Category Name *',
                            hintText:
                                'Example: Vegetables',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.category_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Slug - OPTIONAL
                        TextField(
                          controller: slugController,
                          decoration:
                              const InputDecoration(
                            labelText: 'Slug',
                            hintText:
                                'Optional',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.link,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Description - OPTIONAL
                        TextField(
                          controller:
                              descriptionController,
                          maxLines: 3,
                          decoration:
                              const InputDecoration(
                            labelText: 'Description',
                            hintText:
                                'Optional',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.description_outlined,
                            ),
                            alignLabelWithHint: true,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Image - OPTIONAL
                        const Text(
                          'Category Image',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (selectedImage != null)
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(16),
                            child: Image.file(
                              selectedImage!,
                              width: double.infinity,
                              height: 170,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (category != null &&
                            _categoryImage(category) !=
                                null)
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(16),
                            child: Image.network(
                              _categoryImage(category)!,
                              width: double.infinity,
                              height: 170,
                              fit: BoxFit.cover,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return _imagePlaceholder();
                              },
                            ),
                          )
                        else
                          _imagePlaceholder(),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  OutlinedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => pickImage(
                                          ImageSource
                                              .gallery,
                                        ),
                                icon: const Icon(
                                  Icons
                                      .photo_library_outlined,
                                ),
                                label: const Text(
                                  'Gallery',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child:
                                  OutlinedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => pickImage(
                                          ImageSource
                                              .camera,
                                        ),
                                icon: const Icon(
                                  Icons
                                      .camera_alt_outlined,
                                ),
                                label: const Text(
                                  'Camera',
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        SwitchListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          title: const Text(
                            'Active Category',
                          ),
                          subtitle: const Text(
                            'Customers can see this category.',
                          ),
                          value: isActive,
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setSheetState(() {
                                    isActive = value;
                                  });
                                },
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                isSaving
                                    ? null
                                    : saveCategory,
                            child: isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isEditing
                                        ? 'Update Category'
                                        : 'Create Category',
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
        },
      );

      if (result == true) {
        await _loadCategories();
      }
    } finally {
      nameController.dispose();
      slugController.dispose();
      descriptionController.dispose();
    }
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: const Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 46,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'No category image',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(
    Map<String, dynamic> category,
  ) async {
    final categoryId = _categoryId(category);

    if (categoryId == null) {
      return;
    }

    final name = _categoryName(category);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Category?',
          ),
          content: Text(
            'Are you sure you want to delete "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await AdminCategoryService.deleteCategory(
        categoryId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Category deleted successfully.',
          ),
        ),
      );

      await _loadCategories();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  void _showCategoryMenu(
    Map<String, dynamic> category,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                ),
                title: const Text(
                  'Edit Category',
                ),
                onTap: () {
                  Navigator.pop(context);

                  _showCategoryForm(
                    category: category,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete Category',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);

                  _deleteCategory(category);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
  ) {
    final imageUrl = _categoryImage(category);
    final isActive =
        _isCategoryActive(category);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(14),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _cardImagePlaceholder();
                      },
                    )
                  : _cardImagePlaceholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _categoryName(category),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_categoryDescription(
                    category,
                  ).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _categoryDescription(
                        category,
                      ),
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green
                              .withValues(alpha: 0.10)
                          : Colors.red
                              .withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive
                          ? 'Active'
                          : 'Inactive',
                      style: TextStyle(
                        color: isActive
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  _showCategoryMenu(category),
              icon: const Icon(
                Icons.more_vert,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardImagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.category_outlined,
        color: Colors.blue.shade400,
        size: 30,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null &&
        _categories.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCategories,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 120),
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load categories',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text('Retry'),
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
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.category_outlined,
              size: 70,
              color: Colors.blue.shade300,
            ),
            const SizedBox(height: 18),
            const Text(
              'No Categories Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first product category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: FilledButton.icon(
                onPressed: () =>
                    _showCategoryForm(),
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'Add Category',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category =
              _categories[index];

          if (category is Map<String, dynamic>) {
            return _buildCategoryCard(
              category,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                _isLoading ? null : _loadCategories,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () =>
            _showCategoryForm(),
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Category',
        ),
      ),
    );
  }
}