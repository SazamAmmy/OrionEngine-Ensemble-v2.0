import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool isEmailRegexValid = true;
  bool isPasswordLengthValid = true;
  int minPasswordLength = 6;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_updateEmailFeedback);
    passwordController.addListener(_updatePasswordFeedback);
  }

  @override
  void dispose() {
    emailController.removeListener(_updateEmailFeedback);
    passwordController.removeListener(_updatePasswordFeedback);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _updateEmailFeedback() {
    final email = emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      isEmailRegexValid = emailRegex.hasMatch(email);
    });
  }

  void _updatePasswordFeedback() {
    final password = passwordController.text.trim();
    setState(() {
      isPasswordLengthValid = password.length >= minPasswordLength;
    });
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/login/');

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        await prefs.setString('username', data['username']);
        await prefs.setString('email', data['email']);
        await prefs.setBool('is_staff', data['is_staff'] ?? false);

        _showMessage(data['message'] ?? 'Login successful!');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/main');
      }
      else if (response.statusCode == 429) {
        final errorMessage = data['error'] ?? "Rate limit exceeded. Please try again later.";
        _showMessage(errorMessage, isError: true);
      }
      else {
        _showMessage(data['detail'] ?? data['error'] ?? data['message'] ?? 'Login failed', isError: true);
      }
    } catch (e) {
      _showMessage('An error occurred. Please try again. Error: ${e.toString()}', isError: true);

    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    final backgroundColor = isError ? Colors.red.shade700 : Colors.green;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 60.0, left: 20, right: 20),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _loginInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.green.shade700),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor ?? Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.green.shade600, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      errorStyle: const TextStyle(fontSize: 12, color: Colors.red, height: 0.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "🌱 EcoGenie",
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        const Text("Login to your account", style: TextStyle(fontSize: 15, color: Colors.black54)),
                        const SizedBox(height: 25),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: _loginInputDecoration(
                            hint: 'Email',
                            icon: Icons.email,
                            fillColor: emailController.text.isEmpty
                                ? Colors.white
                                : (isEmailRegexValid ? Colors.green.shade100 : Colors.red.shade100),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: _loginInputDecoration(
                            hint: 'Password',
                            icon: Icons.lock,
                            fillColor: passwordController.text.isEmpty
                                ? Colors.white
                                : (isPasswordLengthValid ? Colors.green.shade100 : Colors.red.shade100),
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.trim().length < minPasswordLength) {
                              return 'Password must be at least $minPasswordLength characters';
                            }
                            return null;
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () { Navigator.pushNamed(context, '/forgot_password');},
                            style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 5,
                            ),
                            child: isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text('Or', style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),

                        OutlinedButton(
                          onPressed: () { /* TODO: Google Sign-In */ },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            side: BorderSide(color: Colors.grey.shade300),
                            foregroundColor: Colors.black87,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/images/google.png', width: 24, height: 24),
                              const SizedBox(width: 12),
                              const Text('Login with Google', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?", style: TextStyle(color: Colors.black54)),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushNamed('/signup'),
                              style: TextButton.styleFrom(foregroundColor: Colors.green.shade800),
                              child: const Text('Sign up', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
