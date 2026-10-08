import 'package:flutter/material.dart'; 
 
import '../services/auth_service.dart'; 
 
class ResetPasswordScreen extends StatefulWidget { 
  const ResetPasswordScreen({super.key}); 
 
  @override 
  State<ResetPasswordScreen> createState() => 
      _ResetPasswordScreenState(); 
} 
 
class _ResetPasswordScreenState 
    extends State<ResetPasswordScreen> { 
  final _emailController = TextEditingController(); 
  final _otpController = TextEditingController(); 
  final _newPasswordController = TextEditingController(); 
  final _confirmPasswordController = 
      TextEditingController(); 
 
  int _step = 0; 
 
  bool _loading = false; 
  bool _showNewPassword = false; 
  bool _showConfirmPassword = false; 
 
  @override 
  void dispose() { 
    _emailController.dispose(); 
    _otpController.dispose(); 
    _newPasswordController.dispose(); 
    _confirmPasswordController.dispose(); 
    super.dispose(); 
  } 
 
  // ========================================================= 
  // SEND OTP 
  // ========================================================= 
 
  Future<void> _sendOtp() async { 
    final email = _emailController.text.trim(); 
 
    if (email.isEmpty) { 
      _showMessage( 
        'Please enter your email address.', 
      ); 
      return; 
    } 
 
    setState(() { 
      _loading = true; 
    }); 
 
    try { 
      final result = 
          await AuthService.forgotPassword( 
        email: email, 
      ); 
 
      if (!mounted) return; 
 
      setState(() { 
        _step = 1; 
      }); 
 
      _showMessage( 
        result['message']?.toString() ?? 
            'If the account exists, an OTP has been sent.', 
      ); 
    } catch (e) { 
      if (!mounted) return; 
 
      _showMessage(_cleanError(e)); 
    } finally { 
      if (mounted) { 
        setState(() { 
          _loading = false; 
        }); 
      } 
    } 
  } 
 
  // ========================================================= 
  // VERIFY OTP 
  // ========================================================= 
 
  Future<void> _verifyOtp() async { 
    final email = _emailController.text.trim(); 
    final otp = _otpController.text.trim(); 
 
    if (otp.isEmpty) { 
      _showMessage( 
        'Please enter the OTP.', 
      ); 
      return; 
    } 
 
    if (otp.length != 6) { 
      _showMessage( 
        'Please enter the 6-digit OTP.', 
      ); 
      return; 
    } 
 
    setState(() { 
      _loading = true; 
    }); 
 
    try { 
      await AuthService.verifyResetOtp( 
        email: email, 
        otp: otp, 
      ); 
 
      if (!mounted) return; 
 
      setState(() { 
        _step = 2; 
      }); 
 
      _showMessage( 
        'OTP verified successfully.', 
      ); 
    } catch (e) { 
      if (!mounted) return; 
 
      _showMessage(_cleanError(e)); 
    } finally { 
      if (mounted) { 
        setState(() { 
          _loading = false; 
        }); 
      } 
    } 
  } 
 
  // ========================================================= 
  // RESET PASSWORD 
  // ========================================================= 
 
  Future<void> _resetPassword() async { 
    final email = _emailController.text.trim(); 
    final newPassword = 
        _newPasswordController.text; 
    final confirmPassword = 
        _confirmPasswordController.text; 
 
    if (newPassword.isEmpty) { 
      _showMessage( 
        'Please enter a new password.', 
      ); 
      return; 
    } 
 
    if (newPassword.length < 6) { 
      _showMessage( 
        'Password must contain at least 6 characters.', 
      ); 
      return; 
    } 
 
    if (confirmPassword.isEmpty) { 
      _showMessage( 
        'Please confirm your new password.', 
      ); 
      return; 
    } 
 
    if (newPassword != confirmPassword) { 
      _showMessage( 
        'Passwords do not match.', 
      ); 
      return; 
    } 
 
    setState(() { 
      _loading = true; 
    }); 
 
    try { 
      final result = 
          await AuthService.resetPassword( 
        email: email, 
        newPassword: newPassword, 
        confirmPassword: confirmPassword, 
      ); 
 
      if (!mounted) return; 
 
      await _showSuccessDialog( 
        result['message']?.toString() ?? 
            'Password reset successful.', 
      ); 
    } catch (e) { 
      if (!mounted) return; 
 
      _showMessage(_cleanError(e)); 
    } finally { 
      if (mounted) { 
        setState(() { 
          _loading = false; 
        }); 
      } 
    } 
  } 
 
  // ========================================================= 
  // SUCCESS DIALOG 
  // ========================================================= 
 
  Future<void> _showSuccessDialog( 
    String message, 
  ) async { 
    await showDialog<void>( 
      context: context, 
      barrierDismissible: false, 
      builder: (context) { 
        return AlertDialog( 
          icon: const Icon( 
            Icons.check_circle, 
            color: Colors.green, 
            size: 52, 
          ), 
          title: const Text( 
            'Password Reset Successful', 
          ), 
          content: Text( 
            message, 
            textAlign: TextAlign.center, 
          ), 
          actions: [ 
            FilledButton( 
              onPressed: () { 
                Navigator.pop(context); 
              }, 
              child: const Text('Done'), 
            ), 
          ], 
        ); 
      }, 
    ); 
 
    if (mounted) { 
      Navigator.pop(context); 
    } 
  } 
 
  // ========================================================= 
  // MESSAGE 
  // ========================================================= 
 
  void _showMessage(String message) { 
    ScaffoldMessenger.of(context) 
      ..hideCurrentSnackBar() 
      ..showSnackBar( 
        SnackBar( 
          content: Text(message), 
        ), 
      ); 
  } 
 
  String _cleanError(Object error) { 
    return error 
        .toString() 
        .replaceFirst( 
          'Exception: ', 
          '', 
        ); 
  } 
 
  // ========================================================= 
  // EMAIL STEP 
  // ========================================================= 
 
  Widget _buildEmailStep() { 
    return Column( 
      crossAxisAlignment: 
          CrossAxisAlignment.stretch, 
      children: [ 
        const Icon( 
          Icons.lock_reset, 
          size: 64, 
          color: Colors.blue, 
        ), 
 
        const SizedBox(height: 16), 
 
        const Text( 
          'Reset Password', 
          textAlign: TextAlign.center, 
          style: TextStyle( 
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
          ), 
        ), 
 
        const SizedBox(height: 8), 
 
        const Text( 
          'Enter your registered email address to receive an OTP.', 
          textAlign: TextAlign.center, 
        ), 
 
        const SizedBox(height: 28), 
 
        TextField( 
          controller: _emailController, 
          keyboardType: 
              TextInputType.emailAddress, 
          textInputAction: 
              TextInputAction.done, 
          decoration: const InputDecoration( 
            labelText: 'Email Address', 
            hintText: 'Enter your email', 
            prefixIcon: 
                Icon(Icons.email_outlined), 
            border: OutlineInputBorder(), 
          ), 
        ), 
 
        const SizedBox(height: 20), 
 
        _buildButton( 
          text: 'Send OTP', 
          onPressed: _sendOtp, 
        ), 
      ], 
    ); 
  } 
 
  // ========================================================= 
  // OTP STEP 
  // ========================================================= 
 
  Widget _buildOtpStep() { 
    return Column( 
      crossAxisAlignment: 
          CrossAxisAlignment.stretch, 
      children: [ 
        const Icon( 
          Icons.mark_email_read_outlined, 
          size: 64, 
          color: Colors.blue, 
        ), 
 
        const SizedBox(height: 16), 
 
        const Text( 
          'Verify OTP', 
          textAlign: TextAlign.center, 
          style: TextStyle( 
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
          ), 
        ), 
 
        const SizedBox(height: 8), 
 
        Text( 
          'Enter the 6-digit OTP sent to ${_emailController.text.trim()}.', 
          textAlign: TextAlign.center, 
        ), 
 
        const SizedBox(height: 28), 
 
        TextField( 
          controller: _otpController, 
          keyboardType: 
              TextInputType.number, 
          textInputAction: 
              TextInputAction.done, 
          maxLength: 6, 
          textAlign: TextAlign.center, 
          style: const TextStyle( 
            fontSize: 22, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 6, 
          ), 
          decoration: const InputDecoration( 
            labelText: 'OTP', 
            hintText: '000000', 
            prefixIcon: 
                Icon(Icons.password), 
            border: OutlineInputBorder(), 
            counterText: '', 
          ), 
        ), 
 
        const SizedBox(height: 20), 
 
        _buildButton( 
          text: 'Verify OTP', 
          onPressed: _verifyOtp, 
        ), 
 
        const SizedBox(height: 10), 
 
        TextButton( 
          onPressed: 
              _loading ? null : _sendOtp, 
          child: const Text( 
            'Resend OTP', 
          ), 
        ), 
      ], 
    ); 
  } 
 
  // ========================================================= 
  // NEW PASSWORD STEP 
  // ========================================================= 
 
  Widget _buildPasswordStep() { 
    return Column( 
      crossAxisAlignment: 
          CrossAxisAlignment.stretch, 
      children: [ 
        const Icon( 
          Icons.lock_outline, 
          size: 64, 
          color: Colors.blue, 
        ), 
 
        const SizedBox(height: 16), 
 
        const Text( 
          'Create New Password', 
          textAlign: TextAlign.center, 
          style: TextStyle( 
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
          ), 
        ), 
 
        const SizedBox(height: 8), 
 
        const Text( 
          'Create a new password for your account.', 
          textAlign: TextAlign.center, 
        ), 
 
        const SizedBox(height: 28), 
 
        TextField( 
          controller: 
              _newPasswordController, 
          obscureText: !_showNewPassword, 
          textInputAction: 
              TextInputAction.next, 
          decoration: InputDecoration( 
            labelText: 'New Password', 
            hintText: 
                'Enter your new password', 
            prefixIcon: 
                const Icon(Icons.lock_outline), 
            suffixIcon: IconButton( 
              onPressed: () { 
                setState(() { 
                  _showNewPassword = 
                      !_showNewPassword; 
                }); 
              }, 
              icon: Icon( 
                _showNewPassword 
                    ? Icons.visibility_off 
                    : Icons.visibility, 
              ), 
            ), 
            border: 
                const OutlineInputBorder(), 
          ), 
        ), 
 
        const SizedBox(height: 16), 
 
        TextField( 
          controller: 
              _confirmPasswordController, 
          obscureText: 
              !_showConfirmPassword, 
          textInputAction: 
              TextInputAction.done, 
          decoration: InputDecoration( 
            labelText: 
                'Confirm New Password', 
            hintText: 
                'Re-enter your new password', 
            prefixIcon: 
                const Icon(Icons.lock_outline), 
            suffixIcon: IconButton( 
              onPressed: () { 
                setState(() { 
                  _showConfirmPassword = 
                      !_showConfirmPassword; 
                }); 
              }, 
              icon: Icon( 
                _showConfirmPassword 
                    ? Icons.visibility_off 
                    : Icons.visibility, 
              ), 
            ), 
            border: 
                const OutlineInputBorder(), 
          ), 
        ), 
 
        const SizedBox(height: 8), 
 
        const Text( 
          'Password must contain at least 6 characters.', 
          style: TextStyle( 
            fontSize: 12, 
            color: Colors.grey, 
          ), 
        ), 
 
        const SizedBox(height: 20), 
 
        _buildButton( 
          text: 'Reset Password', 
          onPressed: _resetPassword, 
        ), 
      ], 
    ); 
  } 
 
  // ========================================================= 
  // BUTTON 
  // ========================================================= 
 
  Widget _buildButton({ 
    required String text, 
    required VoidCallback onPressed, 
  }) { 
    return SizedBox( 
      height: 50, 
      child: FilledButton( 
        onPressed: 
            _loading ? null : onPressed, 
        child: _loading 
            ? const SizedBox( 
                height: 22, 
                width: 22, 
                child: 
                    CircularProgressIndicator( 
                  strokeWidth: 2, 
                ), 
              ) 
            : Text(text), 
      ), 
    ); 
  } 
 
  // ========================================================= 
  // CURRENT STEP 
  // ========================================================= 
 
  Widget _buildCurrentStep() { 
    switch (_step) { 
      case 1: 
        return _buildOtpStep(); 
 
      case 2: 
        return _buildPasswordStep(); 
 
      default: 
        return _buildEmailStep(); 
    } 
  } 
 
  // ========================================================= 
  // BUILD 
  // ========================================================= 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar( 
        backgroundColor: const Color(0xFFFFC107), 
        title: const Text( 
          'Reset Password', 
        ), 
      ), 
      body: SafeArea( 
        child: SingleChildScrollView( 
          padding: 
              const EdgeInsets.all(24), 
          child: Column( 
            children: [ 
              const SizedBox(height: 20), 
              _buildCurrentStep(), 
            ], 
          ), 
        ), 
      ), 
    ); 
  } 
} 