import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart'; // Import Provider
import 'package:sustainableapp/theme_provider.dart'; // Import ThemeProvider
import 'reset_password.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  bool otpSent = false;
  final _formKey = GlobalKey<FormState>();

  // Your backend base URL (ngrok or production)
  final String baseUrl = 'https://direct-frog-amused.ngrok-free.app';

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/password-reset-request/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showMessage(' If an account with that email exists, an OTP has been sent.');
        setState(() {
          otpSent = true;
        });
      } else {
        _showMessage(data['error'] ?? data['message'] ?? 'Failed to send OTP', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error sending OTP: $e', isError: true);
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (otpController.text.trim().length != 6) {
      _showMessage('Please enter a valid 6-digit OTP', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'otp': otpController.text.trim(),
        }),
      );
      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showMessage('OTP Verified! Please reset your password.');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(email: emailController.text.trim()),
          ),
        );
      } else {
        _showMessage(data['error'] ?? data['message'] ?? 'Invalid OTP', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error verifying OTP: $e', isError: true);
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : theme.primaryColor, // Theme-aware
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    final LinearGradient pageGradient = themeProvider.isDarkMode
        ? LinearGradient(
      colors: [colorScheme.surface.withOpacity(0.8), colorScheme.background],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    )
        : const LinearGradient( // Original light mode gradient
      colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.isDarkMode ? colorScheme.onSurface : Colors.white), // Theme-aware
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: pageGradient, // Theme-aware gradient
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor, // Theme-aware
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1), // Generic shadow
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.lock_reset, size: 60, color: colorScheme.primary), // Theme-aware
                          const SizedBox(height: 20),
                          Text(
                            "Forgot Password",
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary, // Theme-aware
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            otpSent
                                ? "Enter the 6-digit OTP sent to your email"
                                : "Enter your email to reset your password",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), // Theme-aware
                          ),
                          const SizedBox(height: 30),
                          otpSent
                              ? TextFormField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.security, color: colorScheme.onSurfaceVariant), // Theme-aware
                              hintText: 'Enter OTP',
                              // Other properties like fillColor, border from theme.inputDecorationTheme
                            ),
                          )
                              : TextFormField(
                            controller: emailController,
                            validator: _validateEmail,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email, color: colorScheme.onSurfaceVariant), // Theme-aware
                              hintText: 'Email',
                              // Other properties like fillColor, border from theme.inputDecorationTheme
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : (otpSent ? _verifyOtp : _handleForgotPassword),
                              // Style handled by theme.elevatedButtonTheme
                              child: isLoading
                                  ? SizedBox(height:20, width:20, child:CircularProgressIndicator(color: colorScheme.onPrimary)) // Theme-aware
                                  : Text(otpSent ? 'Verify OTP' : 'Send OTP'),
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
