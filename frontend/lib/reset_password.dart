import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordPage extends StatefulWidget {
  final String email; // Pass the user's email here

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if passwords match before sending
    if (newPasswordController.text.trim() != confirmPasswordController.text.trim()) {
      _showMessage('Passwords do not match', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://direct-frog-amused.ngrok-free.app/api/reset-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'new_password': newPasswordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showMessage('Password reset successfully!');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        _showMessage(data['message'] ?? 'Failed to reset password', isError: true);
      }
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.lock_outline, size: 60, color: Colors.green),
                          const SizedBox(height: 20),
                          const Text(
                            "Reset Password",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Create a new password for your account",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 30),

                          // New Password Field
                          TextFormField(
                            controller: newPasswordController,
                            obscureText: obscureNewPassword,
                            validator: _validatePassword,
                            decoration: InputDecoration(
                              hintText: 'New Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () => setState(() => obscureNewPassword = !obscureNewPassword),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Confirm Password Field
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirmPassword,
                            validator: (value) {
                              if (value != newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Confirm New Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Reset Password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
