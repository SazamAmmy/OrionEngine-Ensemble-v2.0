import 'package:flutter/material.dart';
import 'package:sustainableapp/services/api_service.dart';
import 'dart:convert';
import 'package:provider/provider.dart'; // Import Provider
import 'package:sustainableapp/theme_provider.dart'; // Import ThemeProvider

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (newPasswordController.text.trim() != confirmPasswordController.text.trim()) {
      _showMessage('New passwords do not match', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      const url = 'https://direct-frog-amused.ngrok-free.app/api/change-password/';
      final response = await ApiService.post(
        url,
        body: {
          'current_password': currentPasswordController.text.trim(),
          'new_password': newPasswordController.text.trim(),
        },
      );

      if (!mounted) return; // Check mounted after await
      final Map<String, dynamic>? data = jsonDecode(response.body) as Map<String, dynamic>?;


      if (response.statusCode == 200) {
        _showMessage('Password changed successfully!');
        if (mounted) { // Check mounted before navigation
          Navigator.pushReplacementNamed(context, '/profile');
        }
      } else {
        _showMessage(data?['message'] as String? ?? data?['detail'] as String? ?? 'Failed to change password', isError: true);
      }
    } catch (e) {
      if (mounted) { // Check mounted before showing message
        _showMessage('Error: $e', isError: true);
      }
    } finally {
      if (mounted) { // Check mounted before setState
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return; // Check if the widget is still in the tree
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : theme.primaryColor, // Theme-aware
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Define a specific background gradient for this page, can be adapted for dark mode
    final LinearGradient pageGradient = themeProvider.isDarkMode
        ? LinearGradient( // Dark mode gradient
      colors: [colorScheme.surface.withOpacity(0.8), colorScheme.background],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    )
        : const LinearGradient( // Light mode gradient (original)
      colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );


    return Scaffold(
      extendBodyBehindAppBar: true, // Make gradient behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Keep transparent to show gradient
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.isDarkMode ? colorScheme.onSurface : Colors.white), // Theme-aware
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: pageGradient, // Use the theme-aware gradient
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
                        color: theme.cardColor, // Theme-aware card color
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
                          Icon(Icons.lock, size: 60, color: colorScheme.primary), // Theme-aware
                          const SizedBox(height: 20),
                          Text(
                            "Change Password",
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary, // Theme-aware
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Update your account password",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), // Theme-aware
                          ),
                          const SizedBox(height: 30),

                          // Current Password
                          TextFormField(
                            controller: currentPasswordController,
                            obscureText: obscureCurrent,
                            validator: _validatePassword,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Current Password',
                              // hintStyle, prefixIconColor, suffixIconColor, fillColor, border are handled by theme.inputDecorationTheme
                              prefixIcon: Icon(Icons.lock, color: colorScheme.onSurfaceVariant),
                              suffixIcon: IconButton(
                                icon: Icon(obscureCurrent ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurfaceVariant),
                                onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // New Password
                          TextFormField(
                            controller: newPasswordController,
                            obscureText: obscureNew,
                            validator: _validatePassword,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'New Password',
                              prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                              suffixIcon: IconButton(
                                icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurfaceVariant),
                                onPressed: () => setState(() => obscureNew = !obscureNew),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirm,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Confirm your password';
                              if (value != newPasswordController.text) return 'Passwords do not match';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Confirm New Password',
                              prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                              suffixIcon: IconButton(
                                icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurfaceVariant),
                                onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _changePassword,
                              // Style is handled by theme.elevatedButtonTheme
                              // Explicit foreground/background can be set if needed:
                              // style: ElevatedButton.styleFrom(
                              //   backgroundColor: colorScheme.primary,
                              //   foregroundColor: colorScheme.onPrimary,
                              // ),
                              child: isLoading
                                  ? SizedBox(
                                height: 24, // Consistent height for indicator
                                width: 24,  // Consistent width for indicator
                                child: CircularProgressIndicator(
                                  color: colorScheme.onPrimary, // Theme-aware
                                  strokeWidth: 3,
                                ),
                              )
                                  : const Text('Change Password'),
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
