// lib/login_page.dart
import
'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart'; // Import Provider (from new version for theme)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sustainableapp/theme_provider.dart'; // Import ThemeProvider (from new version for theme)

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
  bool isGoogleLoading = false;
  bool obscurePassword = true;
  bool isEmailRegexValid = true; // Assume true initially, updated by listeners
  bool isPasswordLengthValid = true; // Assume true initially, updated by listeners
  final int minPasswordLength = 6;

  // Initialize GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Client ID for Google Sign In, (Original Comment)
    // backend validates the ID token against a specific client ID. (Original Comment)
    serverClientId: '312754101857-0grvbu6cpgt6p6q6ih2p4ep8acu3jepk.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    // Dismiss keyboard on initial load (Original Comment)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    });
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

  // Original logic for email feedback
  void _updateEmailFeedback() {
    final email = emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (mounted) {
      setState(() {
        isEmailRegexValid = emailRegex.hasMatch(email);
      });
    }
  }

  // Original logic for password feedback
  void _updatePasswordFeedback() {
    final password = passwordController.text.trim();
    if (mounted) {
      setState(() {
        isPasswordLengthValid = password.length >= minPasswordLength;
      });
    }
  }

  Future<void> _loginUser() async {
    // Trigger validation feedback update before submitting (from new version, good practice)
    _updateEmailFeedback();
    _updatePasswordFeedback();

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (mounted) setState(() => isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    // Replace with your actual login API endpoint (Original Comment)
    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/login/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (!mounted) return;

      Map<String, dynamic>? data;
      try {
        var decodedJson = jsonDecode(response.body);
        if (decodedJson is Map<String, dynamic>) {
          data = decodedJson;
        } else {
          debugPrint("❌ Manual Login: Decoded JSON is not a Map: ${decodedJson.runtimeType}. Body: ${response.body}");
        }
      } catch(e) {
        _showMessage('Unexpected response from server. Please try again.', isError: true);
        debugPrint("❌ Manual Login JSON Decode error: $e. Response body: ${response.body}");
        if (mounted) setState(() => isLoading = false);
        return;
      }

      if (data == null) {
        _showMessage('Login failed. Invalid response from server.', isError: true);
        if (mounted) setState(() => isLoading = false);
        return;
      }

      if (response.statusCode == 200) {
        await _handleSuccessfulLogin(data, "Login successful!");
      } else {
        String errorMessage = (data['detail'] as String?) ??
            (data['error'] as String?) ??
            (data['message'] as String?) ??
            'Login failed. Status: ${response.statusCode}';
        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      if (mounted) _showMessage('An error occurred: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (mounted) setState(() => isGoogleLoading = true);

    try {
      // Sign out before attempting a new sign-in to ensure the account picker shows. (Original Comment)
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in dialog (Original Comment)
        if (mounted) setState(() => isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint("❌ Google Sign-In: ID token is null or empty.");
        if (mounted) {
          _showMessage('Could not retrieve a valid Google ID token. Please try again.', isError: true);
        }
        return;
      }

      // Replace with your actual Google Sign-In API endpoint (Original Comment)
      final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/auth/google/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (!mounted) return;

      Map<String, dynamic>? data;
      try {
        var decodedJson = jsonDecode(response.body);
        if (decodedJson is Map<String, dynamic>) {
          data = decodedJson;
        } else {
          debugPrint("❌ Google Sign-In Backend: Decoded JSON is not a Map: ${decodedJson.runtimeType}. Body: ${response.body}");
        }
      } catch (e) {
        _showMessage('Unexpected response from server after Google Sign-In. Malformed JSON?', isError: true);
        debugPrint("❌ Google Sign-In Backend JSON Decode error: $e. Server response body: ${response.body}");
        return;
      }

      if (data == null) {
        _showMessage('Google login failed. Server returned no data or invalid data structure.', isError: true);
        debugPrint("🔍 Google Sign-In: Server response body that resulted in null or non-map data: ${response.body}");
        return;
      }

      if (response.statusCode == 200) {
        await _handleSuccessfulLogin(data, "Login successful!");
      } else {
        String errorMessage = (data['error'] as String?) ??
            (data['message'] as String?) ??
            'Google login failed. Status: ${response.statusCode}';
        _showMessage(errorMessage, isError: true);
        debugPrint("❌ Google Sign-In failed with backend. Status: ${response.statusCode}. Response: $data");
      }
    } catch (error, stacktrace) {
      if (mounted) {
        String errorMessageToShow = 'Google Sign-In failed.';
        if (error is TypeError) {
          errorMessageToShow = 'Google Sign-In failed due to a data handling error.';
          debugPrint("❌ Google Sign-In TypeError: $error");
        } else {
          errorMessageToShow = 'An unexpected error occurred during Google Sign-In: ${error.toString()}';
          debugPrint("❌ Google Sign-In other error: $error");
        }
        debugPrint("🔍 Google Sign-In Stacktrace:\n$stacktrace");
        _showMessage(errorMessageToShow, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleSuccessfulLogin(Map<String, dynamic> data, String successMessage) async {
    final prefs = await SharedPreferences.getInstance();

    final String? accessToken = data['access'] as String?;
    final String? refreshToken = data['refresh'] as String?;

    if (accessToken == null || refreshToken == null) {
      _showMessage('Login failed: Essential authentication information not received.', isError: true);
      debugPrint("❌ Login Error: Access or Refresh token is null. Data: $data");
      return;
    }

    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('username', (data['username'] as String?) ?? 'N/A');
    await prefs.setString('email', (data['email'] as String?) ?? 'N/A');

    final String? dateOfBirth = data['date_of_birth'] as String?;
    if (dateOfBirth != null) {
      await prefs.setString('date_of_birth', dateOfBirth);
    } else {
      await prefs.remove('date_of_birth');
    }

    final bool isStaff = (data['is_staff'] as bool?) ?? false;
    final bool surveyCompleted = (data['survey_completed'] as bool?) ?? false;
    final bool isVerified = (data['user_verified'] as bool?) ?? false; // ✅ New line

    await prefs.setBool('is_staff', isStaff);
    await prefs.setBool('survey_completed', surveyCompleted);
    await prefs.setBool('is_verified', isVerified); // ✅ Store locally too if needed

    _showMessage(successMessage);

    if (!mounted) return;

    // ✅ Decide route based on verification status
    if (!isVerified) {
      Navigator.of(context).pushReplacementNamed('/verify_signup_otp');
    } else {
      Navigator.of(context).pushReplacementNamed(surveyCompleted ? '/main' : '/survey');
    }
  }


  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context); // Using theme for colors (from new version)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? theme.colorScheme.error : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20,0,20,20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // MODIFIED InputDecoration (from new version, essential for dark mode and enhanced UI)
  // This decoration method is kept from the new version as it handles theming and dynamic states.
  // The original's logic for fill colors is now handled by getDynamicFillColor and the 'isValid' parameter.
  InputDecoration _loginInputDecoration({
    required BuildContext context,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    Color? dynamicFillColor,
    required bool isValid, // Added to control border color based on validity
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Define your light green color
    final Color lightGreenBorderColor = themeProvider.isDarkMode
        ? colorScheme.primary.withOpacity(0.6) // Softer green for dark mode
        : Colors.lightGreen.shade400;
    final Color defaultOutlineColor = colorScheme.outline.withOpacity(0.5);
    final Color errorColor = colorScheme.error;

    // Determine current border color
    // If not valid (and not empty, handled by validator), it will show errorBorder.
    // This 'isValid' is for when it's NOT in an error state but we want to show green.
    final Color currentEnabledBorderColor = isValid ? lightGreenBorderColor : defaultOutlineColor;

    final baseDecoration = theme.inputDecorationTheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: baseDecoration.hintStyle ?? TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: baseDecoration.prefixIconColor ?? colorScheme.primary), // Theme-aware icon color
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: dynamicFillColor ?? baseDecoration.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.5),
      border: OutlineInputBorder( // Default border
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: defaultOutlineColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder( // Border when enabled and not focused
        borderRadius: BorderRadius.circular(14),
        // Use determined color, which relies on the updated isEmailRegexValid/isPasswordLengthValid
        borderSide: BorderSide(color: currentEnabledBorderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder( // Border when focused
        borderRadius: BorderRadius.circular(14),
        // If valid and focused, show green, otherwise primary color
        borderSide: BorderSide(color: isValid ? lightGreenBorderColor : colorScheme.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder( // Border when there's a validation error
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder( // Border when focused and there's an error
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: errorColor, width: 1.8),
      ),
      contentPadding: baseDecoration.contentPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      errorStyle: baseDecoration.errorStyle ?? TextStyle(fontSize: 12, color: errorColor, height: 0.8),
    );
  }


  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    final LinearGradient pageGradient = themeProvider.isDarkMode
        ? LinearGradient(
      colors: [colorScheme.surface.withOpacity(0.8), colorScheme.background],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : const LinearGradient( // Original gradient for light mode
      colors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // This function is from the new version, works with the new _loginInputDecoration
    Color getDynamicFillColor(bool isValid, bool isEmpty) {
      final defaultFill = theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.5);
      if (isEmpty) return defaultFill;

      final validLight = Colors.green.shade50; // Original's valid fill color for light
      final errorLight = Colors.red.shade50;   // Original's error fill color for light

      final validDark = colorScheme.primaryContainer.withOpacity(0.2);
      final errorDark = colorScheme.errorContainer.withOpacity(0.2);

      return isValid
          ? (themeProvider.isDarkMode ? validDark : validLight)
          : (themeProvider.isDarkMode ? errorDark : errorLight);
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: pageGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // Added padding that considers keyboard visibility (Original Comment)
              padding: EdgeInsets.fromLTRB(24, 24, 24, viewInsets.bottom + 24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: theme.cardColor, // Theme-aware card color
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Card doesn't take full height (Original Comment)
                      children: [
                        Text(
                          "🌱 EcoGenie", // Original Title
                          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary), // Themed style
                        ),
                        const SizedBox(height: 8),
                        Text("Login to your account", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)), // Themed style
                        const SizedBox(height: 30),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                          decoration: _loginInputDecoration(
                            context: context,
                            hint: 'Email',
                            icon: Icons.email_outlined,
                            dynamicFillColor: getDynamicFillColor(isEmailRegexValid, emailController.text.isEmpty),
                            isValid: isEmailRegexValid,
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
                          onChanged: (value) => _updateEmailFeedback(), // Keep onChanged for live feedback
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                          decoration: _loginInputDecoration(
                            context: context,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            dynamicFillColor: getDynamicFillColor(isPasswordLengthValid, passwordController.text.isEmpty),
                            isValid: isPasswordLengthValid,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: colorScheme.onSurfaceVariant, // Themed icon color
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
                          onChanged: (value) => _updatePasswordFeedback(), // Keep onChanged for live feedback
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement navigation to forgot password screen (Original Comment)
                              Navigator.pushNamed(context, '/forgot_password');
                            },
                            style: TextButton.styleFrom(foregroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 8)),
                            child: Text('Forgot Password?', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _loginUser,
                            style: ElevatedButton.styleFrom( // Using new version's theming for buttons
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                              // backgroundColor and foregroundColor will be derived from theme or default ElevatedButton style
                            ),
                            child: isLoading
                                ? SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2.5),
                            )
                                : Text('Log In', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Text('Or connect with', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 16),

                        isGoogleLoading
                            ? CircularProgressIndicator(color: colorScheme.primary)
                            : OutlinedButton.icon(
                          icon: Image.asset('assets/images/google.png', width: 22, height: 22), // Original asset
                          label: Text('Login with Google', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)), // Themed text
                          onPressed: _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom( // Using new version's theming
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            side: BorderSide(color: colorScheme.outline),
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account?", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushNamed('/signup'),
                              style: TextButton.styleFrom(foregroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(horizontal: 6)),
                              child: Text('Sign up', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
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