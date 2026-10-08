import 'package:flutter/material.dart';

import '../services/admin_delivery_service.dart';

class AdminDeliveryAccountsScreen extends StatefulWidget {
  const AdminDeliveryAccountsScreen({super.key});

  @override
  State<AdminDeliveryAccountsScreen> createState() =>
      _AdminDeliveryAccountsScreenState();
}

class _AdminDeliveryAccountsScreenState
    extends State<AdminDeliveryAccountsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _deliveryPersons = [];

  @override
  void initState() {
    super.initState();
    _loadDeliveryPersons();
  }

  Future<void> _loadDeliveryPersons() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deliveryPersons =
          await AdminDeliveryService.getDeliveryPersons();

      if (mounted) {
        setState(() {
          _deliveryPersons = deliveryPersons;
        });
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

  Future<void> _showCreateDeliveryAccount() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscurePassword = true;
    bool obscureConfirmPassword = true;
    bool isCreating = false;

    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.delivery_dining),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Create Delivery Account'),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon:
                                Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter the delivery person\'s name.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: emailController,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon:
                                Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email =
                                value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Enter an email address.';
                            }

                            if (!email.contains('@') ||
                                !email.contains('.')) {
                              return 'Enter a valid email address.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone (optional)',
                            prefixIcon:
                                Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon:
                                const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  obscurePassword =
                                      !obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Enter a password.';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon:
                                const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Confirm the password.';
                            }

                            if (value !=
                                passwordController.text) {
                              return 'Passwords do not match.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (!formKey.currentState!
                              .validate()) {
                            return;
                          }

                          setDialogState(() {
                            isCreating = true;
                          });

                          try {
                            await AdminDeliveryService
                                .createDeliveryAccount(
                              name: nameController.text,
                              email: emailController.text,
                              phone: phoneController.text,
                              password:
                                  passwordController.text,
                              confirmPassword:
                                  confirmPasswordController.text,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(
                                dialogContext,
                                true,
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(
                                dialogContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                  ),
                                ),
                              );

                              setDialogState(() {
                                isCreating = false;
                              });
                            }
                          }
                        },
                  icon: isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(
                    isCreating
                        ? 'Creating...'
                        : 'Create',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    if (created == true && mounted) {
      await _loadDeliveryPersons();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Delivery account created successfully.'),
          ),
        );
      }
    }
  }

  Future<void> _removeDeliveryAccount(
    Map<String, dynamic> person,
  ) async {
    final id = _getId(person);

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify this delivery account.'),
        ),
      );
      return;
    }

    final name = _getString(person, 'name');
    final email = _getString(person, 'email');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Delivery Account'),
          content: Text(
            'Are you sure you want to remove '
            '${name.isNotEmpty ? name : 'this delivery person'}'
            '${email.isNotEmpty ? ' ($email)' : ''}?'
            '\n\nThis account will no longer be available for delivery login.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AdminDeliveryService.deleteDeliveryAccount(id);

      if (!mounted) return;

      await _loadDeliveryPersons();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${name.isNotEmpty ? name : 'Delivery account'} removed successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
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

  String _getString(
    Map<String, dynamic> person,
    String key,
  ) {
    return person[key]?.toString() ?? '';
  }

  int? _getId(Map<String, dynamic> person) {
    final value = person['id'];

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  bool _isActive(Map<String, dynamic> person) {
    final value = person['is_active'];

    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Management'),
        actions: [
          IconButton(
            onPressed:
                _isLoading ? null : _loadDeliveryPersons,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDeliveryAccount,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Delivery Person'),
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
      return RefreshIndicator(
        onRefresh: _loadDeliveryPersons,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Icon(
              Icons.error_outline,
              size: 56,
              color:
                  Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: _loadDeliveryPersons,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      );
    }

    if (_deliveryPersons.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadDeliveryPersons,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.delivery_dining_outlined,
              size: 72,
              color:
                  Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'No delivery personnel found.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: Text(
                  'Create a delivery account to start assigning orders.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed:
                    _showCreateDeliveryAccount,
                icon: const Icon(
                  Icons.person_add_alt_1,
                ),
                label: const Text(
                  'Create Delivery Account',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveryPersons,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: _deliveryPersons.length,
        itemBuilder: (context, index) {
          final item = _deliveryPersons[index];

          if (item is! Map<String, dynamic>) {
            return const SizedBox.shrink();
          }

          return _buildDeliveryCard(item);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(
    Map<String, dynamic> person,
  ) {
    final name = _getString(person, 'name');
    final email = _getString(person, 'email');
    final phone = _getString(person, 'phone');
    final id = _getId(person);
    final active = _isActive(person);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 27,
              child: Text(
                name.isNotEmpty
                    ? name.substring(0, 1).toUpperCase()
                    : 'D',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty
                              ? 'Delivery Person'
                              : name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _removeDeliveryAccount(person),
                        tooltip: 'Remove Delivery Account',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (id != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'ID: $id',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(email),
                        ),
                      ],
                    ),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(phone),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.green.withValues(
                              alpha: 0.12,
                            )
                          : Colors.red.withValues(
                              alpha: 0.12,
                            ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      active ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.green.shade700
                            : Colors.red.shade700,
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
  }
}