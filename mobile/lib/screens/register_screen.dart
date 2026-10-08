import 'package:flutter/material.dart'; 
 
import '../services/auth_service.dart'; 
import 'login_screen.dart'; 
 
class RegisterScreen extends StatefulWidget { 
  const RegisterScreen({super.key}); 
 
  @override 
  State<RegisterScreen> createState() => _RegisterScreenState(); 
} 
 
class _RegisterScreenState extends State<RegisterScreen> { 
  final _formKey = GlobalKey<FormState>(); 
 
  final _nameController = TextEditingController(); 
  final _emailController = TextEditingController(); 
  final _phoneController = TextEditingController(); 
  final _passwordController = TextEditingController(); 
  final _confirmPasswordController = TextEditingController(); 
 
  bool _loading = false; 
  bool _obscurePassword = true; 
  bool _obscureConfirmPassword = true; 
 
  @override 
  void dispose() { 
    _nameController.dispose(); 
    _emailController.dispose(); 
    _phoneController.dispose(); 
    _passwordController.dispose(); 
    _confirmPasswordController.dispose(); 
    super.dispose(); 
  } 
 
  // ============================================================ 
  // REGISTER 
  // ============================================================ 
 
  Future<void> _register() async { 
    FocusScope.of(context).unfocus(); 
 
    if (!_formKey.currentState!.validate()) { 
      return; 
    } 
 
    setState(() { 
      _loading = true; 
    }); 
 
    try { 
      await AuthService.register( 
        name: _nameController.text.trim(), 
        email: _emailController.text.trim(), 
        phone: _phoneController.text.trim(), 
        password: _passwordController.text, 
      ); 
 
      if (!mounted) return; 
 
      ScaffoldMessenger.of(context).showSnackBar( 
        const SnackBar( 
          content: Text( 
            'Registration successful. Please login.', 
          ), 
          duration: Duration(seconds: 3), 
        ), 
      ); 
 
      // Clear registration data before returning to login. 
      _nameController.clear(); 
      _emailController.clear(); 
      _phoneController.clear(); 
      _passwordController.clear(); 
      _confirmPasswordController.clear(); 
 
      // Return to Login screen. 
      Navigator.pushAndRemoveUntil( 
        context, 
        MaterialPageRoute( 
          builder: (_) => const LoginScreen(), 
        ), 
        (route) => false, 
      ); 
    } catch (e) { 
      if (!mounted) return; 
 
      String message = e.toString(); 
 
      if (message.startsWith('Exception: ')) { 
        message = message.substring('Exception: '.length); 
      } 
 
      ScaffoldMessenger.of(context).showSnackBar( 
        SnackBar( 
          content: Text(message), 
          duration: const Duration(seconds: 4), 
        ), 
      ); 
    } finally { 
      if (mounted) { 
        setState(() { 
          _loading = false; 
        }); 
      } 
    } 
  } 
 
  // ============================================================ 
  // GO TO LOGIN 
  // ============================================================ 
 
  void _goToLogin() { 
    if (_loading) { 
      return; 
    } 
 
    Navigator.pushReplacement( 
      context, 
      MaterialPageRoute( 
        builder: (_) => const LoginScreen(), 
      ), 
    ); 
  } 
 
  // ============================================================ 
  // BUILD 
  // ============================================================ 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      backgroundColor: const Color(0xFFF7F7F7), 
 
      // ======================================================== 
      // APP BAR 
      // ======================================================== 
 
      appBar: AppBar( 
        backgroundColor: const Color(0xFFFFC107), 
        foregroundColor: Colors.black, 
        elevation: 0, 
 
        title: const Text( 
          'Create Account', 
          style: TextStyle( 
            fontWeight: FontWeight.bold, 
          ), 
        ), 
      ), 
 
      // ======================================================== 
      // BODY 
      // ======================================================== 
 
      body: SafeArea( 
        child: Center( 
          child: SingleChildScrollView( 
            padding: const EdgeInsets.fromLTRB( 
              24, 
              20, 
              24, 
              30, 
            ), 
 
            child: Form( 
              key: _formKey, 
 
              child: Column( 
                crossAxisAlignment: CrossAxisAlignment.stretch, 
 
                children: [ 
                  // ================================================== 
                  // SHOP TO DOOR LOGO 
                  // ================================================== 
 
                  Center( 
                    child: Image.asset( 
                      'assets/shop-to-door-logo.png', 
                      height: 100, 
                      fit: BoxFit.contain, 
 
                      errorBuilder: ( 
                        context, 
                        error, 
                        stackTrace, 
                      ) { 
                        return const Icon( 
                          Icons.shopping_bag_outlined, 
                          size: 80, 
                          color: Colors.blue, 
                        ); 
                      }, 
                    ), 
                  ), 
 
                  const SizedBox(height: 18), 
 
                  // ================================================== 
                  // TITLE 
                  // ================================================== 
 
                  const Text( 
                    'Create your account', 
                    textAlign: TextAlign.center, 
 
                    style: TextStyle( 
                      fontSize: 26, 
                      fontWeight: FontWeight.bold, 
                    ), 
                  ), 
 
                  const SizedBox(height: 8), 
 
                  const Text( 
                    'Join Shop To Door today', 
                    textAlign: TextAlign.center, 
 
                    style: TextStyle( 
                      fontSize: 15, 
                      color: Colors.grey, 
                    ), 
                  ), 
 
                  const SizedBox(height: 30), 
 
                  // ================================================== 
                  // FULL NAME 
                  // ================================================== 
 
                  TextFormField( 
                    controller: _nameController, 
                    enabled: !_loading, 
 
                    keyboardType: TextInputType.name, 
 
                    textCapitalization: 
                        TextCapitalization.words, 
 
                    textInputAction: 
                        TextInputAction.next, 
 
                    decoration: InputDecoration( 
                      labelText: 'Full Name', 
                      hintText: 'Enter your full name', 
 
                      prefixIcon: const Icon( 
                        Icons.person_outline, 
                      ), 
 
                      filled: true, 
                      fillColor: Colors.white, 
 
                      border: OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            BorderSide.none, 
                      ), 
 
                      enabledBorder: 
                          OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            BorderSide.none, 
                      ), 
 
                      focusedBorder: 
                          OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            const BorderSide( 
                          color: Colors.blue, 
                          width: 1.5, 
                        ), 
                      ), 
                    ), 
 
                    validator: (value) { 
                      if (value == null || 
                          value.trim().isEmpty) { 
                        return 'Please enter your name'; 
                      } 
 
                      if (value.trim().length < 2) { 
                        return 'Name must be at least 2 characters'; 
                      } 
 
                      return null; 
                    }, 
                  ), 
 
                  const SizedBox(height: 16), 
 
                  // ================================================== 
                  // EMAIL 
                  // ================================================== 
 
                  TextFormField( 
                    controller: _emailController, 
                    enabled: !_loading, 
 
                    keyboardType: 
                        TextInputType.emailAddress, 
 
                    textInputAction: 
                        TextInputAction.next, 
 
                    autocorrect: false, 
 
                    decoration: InputDecoration( 
                      labelText: 'Email', 
                      hintText: 'Enter your email', 
 
                      prefixIcon: const Icon( 
                        Icons.email_outlined, 
                      ), 
 
                      filled: true, 
                      fillColor: Colors.white, 
 
                      border: OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            BorderSide.none, 
                      ), 
 
                      enabledBorder: 
                          OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            BorderSide.none, 
                      ), 
 
                      focusedBorder: 
                          OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            const BorderSide( 
                          color: Colors.blue, 
                          width: 1.5, 
                        ), 
                      ), 
                    ), 
 
                    validator: (value) { 
                      final email = 
                          value?.trim() ?? ''; 
 
                      if (email.isEmpty) { 
                        return 'Please enter your email'; 
                      } 
 
                      if (!email.contains('@') || 
                          !email.contains('.')) { 
                        return 'Please enter a valid email'; 
                      } 
 
                      return null; 
                    }, 
                  ), 
 
                  const SizedBox(height: 16), 
 
                  // ================================================== 
                  // PHONE NUMBER 
                  // ================================================== 
 
                  TextFormField( 
                    controller: _phoneController, 
                    enabled: !_loading, 
 
                    keyboardType: 
                        TextInputType.phone, 
 
                    textInputAction: 
                        TextInputAction.next, 
 
                    decoration: InputDecoration( 
                      labelText: 'Phone Number', 
                      hintText: 'Enter your phone number', 
 
                      prefixIcon: const Icon( 
                        Icons.phone_outlined, 
                      ), 
 
                      filled: true, 
                      fillColor: Colors.white, 
 
                      border: OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            BorderSide.none, 
                      ), 
 
                      enabledBorder: 
                          OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            BorderSide.none, 
                      ), 
 
                      focusedBorder: 
                          OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            const BorderSide( 
                          color: Colors.blue, 
                          width: 1.5, 
                        ), 
                      ), 
                    ), 
 
                    validator: (value) { 
                      final phone = 
                          value?.trim() ?? ''; 
 
                      if (phone.isEmpty) { 
                        return 'Please enter your phone number'; 
                      } 
 
                      // Remove spaces and common separators. 
                      final cleanPhone = 
                          phone.replaceAll( 
                        RegExp(r'[\s\-()]'), 
                        '', 
                      ); 
 
                      if (cleanPhone.length < 10) { 
                        return 'Please enter a valid phone number'; 
                      } 
 
                      return null; 
                    }, 
                  ), 
 
                  const SizedBox(height: 16), 
 
                  // ================================================== 
                  // PASSWORD 
                  // ================================================== 
 
                  TextFormField( 
                    controller: _passwordController, 
                    enabled: !_loading, 
 
                    obscureText: 
                        _obscurePassword, 
 
                    textInputAction: 
                        TextInputAction.next, 
 
                    decoration: InputDecoration( 
                      labelText: 'Password', 
                      hintText: 'Create a password', 
 
                      prefixIcon: const Icon( 
                        Icons.lock_outline, 
                      ), 
 
                      suffixIcon: 
                          IconButton( 
                        onPressed: _loading 
                            ? null 
                            : () { 
                                setState(() { 
                                  _obscurePassword = 
                                      !_obscurePassword; 
                                }); 
                              }, 
 
                        icon: Icon( 
                          _obscurePassword 
                              ? Icons 
                                  .visibility_outlined 
                              : Icons 
                                  .visibility_off_outlined, 
                        ), 
                      ), 
 
                      filled: true, 
                      fillColor: Colors.white, 
 
                      border: OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            BorderSide.none, 
                      ), 
 
                      enabledBorder: 
                          OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            BorderSide.none, 
                      ), 
 
                      focusedBorder: 
                          OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            const BorderSide( 
                          color: Colors.blue, 
                          width: 1.5, 
                        ), 
                      ), 
                    ), 
 
                    validator: (value) { 
                      if (value == null || 
                          value.isEmpty) { 
                        return 'Please enter a password'; 
                      } 
 
                      if (value.length < 6) { 
                        return 'Password must be at least 6 characters'; 
                      } 
 
                      return null; 
                    }, 
                  ), 
 
                  const SizedBox(height: 16), 
 
                  // ================================================== 
                  // CONFIRM PASSWORD 
                  // ================================================== 
 
                  TextFormField( 
                    controller: 
                        _confirmPasswordController, 
 
                    enabled: !_loading, 
 
                    obscureText: 
                        _obscureConfirmPassword, 
 
                    textInputAction: 
                        TextInputAction.done, 
 
                    onFieldSubmitted: (_) { 
                      if (!_loading) { 
                        _register(); 
                      } 
                    }, 
 
                    decoration: InputDecoration( 
                      labelText: 'Confirm Password', 
                      hintText: 
                          'Re-enter your password', 
 
                      prefixIcon: const Icon( 
                        Icons.lock_reset_outlined, 
                      ), 
 
                      suffixIcon: 
                          IconButton( 
                        onPressed: _loading 
                            ? null 
                            : () { 
                                setState(() { 
                                  _obscureConfirmPassword = 
                                      !_obscureConfirmPassword; 
                                }); 
                              }, 
 
                        icon: Icon( 
                          _obscureConfirmPassword 
                              ? Icons 
                                  .visibility_outlined 
                              : Icons 
                                  .visibility_off_outlined, 
                        ), 
                      ), 
 
                      filled: true, 
                      fillColor: Colors.white, 
 
                      border: OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            BorderSide.none, 
                      ), 
 
                      enabledBorder: 
                          OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            BorderSide.none, 
                      ), 
 
                      focusedBorder: 
                          OutlineInputBorder( 
                        borderRadius: 
                            BorderRadius.circular(14), 
                        borderSide: 
                            const BorderSide( 
                          color: Colors.blue, 
                          width: 1.5, 
                        ), 
                      ), 
                    ), 
 
                    validator: (value) { 
                      if (value == null || 
                          value.isEmpty) { 
                        return 'Please confirm your password'; 
                      } 
 
                      if (value != 
                          _passwordController.text) { 
                        return 'Passwords do not match'; 
                      } 
 
                      return null; 
                    }, 
                  ), 
 
                  const SizedBox(height: 25), 
 
                  // ================================================== 
                  // CREATE ACCOUNT BUTTON 
                  // ================================================== 
 
                  SizedBox( 
                    height: 52, 
 
                    child: ElevatedButton( 
                      onPressed: 
                          _loading ? null : _register, 
 
                      style: 
                          ElevatedButton.styleFrom( 
                        shape: 
                            RoundedRectangleBorder( 
                          borderRadius: 
                              BorderRadius.circular(14), 
                        ), 
                      ), 
 
                      child: _loading 
                          ? const SizedBox( 
                              width: 24, 
                              height: 24, 
 
                              child: 
                                  CircularProgressIndicator( 
                                strokeWidth: 2, 
                                color: Colors.white, 
                              ), 
                            ) 
                          : const Text( 
                              'Create Account', 
 
                              style: TextStyle( 
                                fontSize: 16, 
                                fontWeight: 
                                    FontWeight.bold, 
                              ), 
                            ), 
                    ), 
                  ), 
 
                  const SizedBox(height: 18), 
 
                  // ================================================== 
                  // LOGIN 
                  // ================================================== 
 
                  TextButton( 
                    onPressed: 
                        _loading ? null : _goToLogin, 
 
                    child: const Text( 
                      'Already have an account? Login', 
                    ), 
                  ), 
                ], 
              ), 
            ), 
          ), 
        ), 
      ), 
    ); 
  } 
} 