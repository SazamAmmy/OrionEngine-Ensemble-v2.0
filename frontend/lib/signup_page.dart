// lib/signup_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert'; // For jsonDecode
import 'package:provider/provider.dart'; // For ThemeProvider
import 'package:shared_preferences/shared_preferences.dart';
import 'package:email_validator/email_validator.dart'; // For email validation
import 'package:sustainableapp/theme_provider.dart'; // Your ThemeProvider

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  SignupPageState createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  bool isLoading = false;
  bool acceptTerms = false; // From new version, also present in old
  bool _hasAttemptedSubmit = false; // From new version, for improved UX on terms validation

  // Granular validation state for dynamic UI feedback (from new version)
  // These replace the simpler booleans like isUsernameValid, isEmailValid from the old version,
  // providing more immediate feedback via listeners.
  bool isUsernameValidState = true; // Renamed from new version's isUsernameValid to avoid conflict if old logic was different
  bool isEmailValidState = true; // Retained from new version
  bool isPasswordCriteriaMet = true; // Retained from new version
  bool doPasswordsMatch = true; // Retained from new version

  bool obscurePassword = true; // Common to both
  bool obscureConfirmPassword = true; // Common to both

  List<Map<String, String>> countries = []; // Common to both
  String termsAndConditionsText = ""; // Common to both
  String? selectedGender; // Common to both
  String? selectedCountry; // Common to both

  // emailErrorMessage from old version is handled by validator and isEmailValidState in new version
  // String? emailErrorMessage;

  @override
  void initState() {
    super.initState();
    // Dismiss keyboard on initial load (Common good practice)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    });
    fetchRegisterInfo(); // Common to both

    // Listeners for real-time validation feedback (from new version's approach)
    usernameController.addListener(_updateUsernameFeedback);
    emailController.addListener(_updateEmailFeedback);
    passwordController.addListener(_updatePasswordFeedback);
    confirmPasswordController.addListener(_updateConfirmPasswordFeedback);
  }

  @override
  void dispose() {
    // Removing listeners
    usernameController.removeListener(_updateUsernameFeedback);
    emailController.removeListener(_updateEmailFeedback);
    passwordController.removeListener(_updatePasswordFeedback);
    confirmPasswordController.removeListener(_updateConfirmPasswordFeedback);

    // Disposing controllers
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    dobController.dispose();
    super.dispose();
  }

  // _showTermsAndConditions from new version (more theme aware)
  void _showTermsAndConditions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: theme.cardColor,
          title: Text(
            'Terms and Conditions',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                termsAndConditionsText.isNotEmpty
                    ? termsAndConditionsText
                    : 'No terms and conditions available.', // Fallback text
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  // Real-time feedback updaters (from new version's pattern)
  // These methods update the granular boolean states for UI styling.
  // The actual validation rules are also in the TextFormField validators.

  // Corresponds to old _validateUsername's logic but for immediate feedback
  void _updateUsernameFeedback() {
    final username = usernameController.text.trim();
    if (mounted) {
      setState(() {
        // Username is considered "valid" for styling if empty (validator will catch it) or matches regex
        isUsernameValidState = username.isEmpty || RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
      });
    }
  }

  // Corresponds to old _validateEmail's logic but for immediate feedback
  void _updateEmailFeedback() {
    final email = emailController.text.trim();
    if (mounted) {
      setState(() {
        // Email is considered "valid" for styling if empty (validator will catch it) or passes EmailValidator
        isEmailValidState = email.isEmpty || EmailValidator.validate(email);
        // Old version had: emailErrorMessage = EmailValidator.validate(email) ? null : 'Enter a valid email address';
        // This is now implicitly handled by the TextFormField's validator.
      });
    }
  }

  void _updatePasswordFeedback() {
    final password = passwordController.text;
    if (mounted) {
      setState(() {
        // Password criteria met if empty (validator catches) or passes _validatePassword
        isPasswordCriteriaMet = password.isEmpty || _validatePassword(password) == null;
        // Also check if confirm password still matches if it's not empty
        doPasswordsMatch = confirmPasswordController.text.isEmpty ||
            (confirmPasswordController.text.isNotEmpty && password == confirmPasswordController.text);
      });
    }
  }

  void _updateConfirmPasswordFeedback() {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    if (mounted) {
      setState(() {
        // Passwords match if confirm is empty (validator catches) or equals password
        doPasswordsMatch = confirmPassword.isEmpty || password == confirmPassword;
      });
    }
  }

  // _validatePassword (validation logic is consistent across versions, using new version's placement)
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    // Regex for ensuring at least one uppercase, one lowercase, and one special character.
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must have at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must have at least one lowercase letter';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Password must have at least one special character';
    return null; // Return null if password is valid
  }

  // fetchRegisterInfo (logic is similar, using new version's structure with a debugPrint for errors)
  Future<void> fetchRegisterInfo() async {
    try {
      // API endpoint to fetch registration auxiliary information (countries, T&C)
      final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/register-info/');
      final response = await http.get(url);

      if (!mounted) return; // Check if the widget is still in the tree

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          final List<dynamic> countriesRaw = data['countries'];
          countries = countriesRaw.map((country) => {
            'name': country['name'] as String,
            'code': country['code'] as String,
          }).toList();
          termsAndConditionsText = data['terms_and_conditions_text'] as String? ?? ""; // Ensure it's a string
        });
      } else {
        // Log error if fetching countries fails
        debugPrint('Failed to load countries or T&C: ${response.statusCode}');
        _showMessage('Could not load registration details. Please try again later.', isError: true);
      }
    } catch (e) {
      // Log any other error during the fetch process
      debugPrint('Error fetching register info: $e');
      if(mounted) _showMessage('An error occurred while fetching registration details.', isError: true);
    }
  }

  // _selectDate (using new version's theme-aware DatePicker)
  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    // User must be at least 16 years old.
    final latestAllowed = DateTime(now.year - 16, now.month, now.day);
    // Try to parse existing date or default to latestAllowed.
    final initialDateToUse = dobController.text.isNotEmpty
        ? (DateFormat('yyyy-MM-dd').tryParse(dobController.text) ?? latestAllowed)
        : latestAllowed;

    final pickedDate = await showDatePicker(
      context: context,
      // Ensure initialDate is not after lastDate.
      initialDate: initialDateToUse.isAfter(latestAllowed) ? latestAllowed : initialDateToUse,
      firstDate: DateTime(1900), // Earliest selectable date.
      lastDate: latestAllowed, // Latest selectable date (16 years ago).
      builder: (context, child) {
        // Apply custom theme to the date picker.
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary, // Picker header background, selected day
              onPrimary: theme.colorScheme.onPrimary, // Picker header text, selected day text
              onSurface: theme.colorScheme.onSurface, // Picker text (days of the month)
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary, // OK/Cancel button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        // Format the picked date and update the controller.
        dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  // _registerUser (using new version's more detailed error handling and structure)
  Future<void> _registerUser(BuildContext context) async {
    setState(() {
      _hasAttemptedSubmit = true; // Mark that a submission attempt has been made for UI feedback
    });

    // Validate the form. If not valid, do nothing.
    if (!_formKey.currentState!.validate()) {
      _showMessage('Please correct the errors in the form.', isError: true);
      return;
    }

    // Check if terms and conditions are accepted.
    if (!acceptTerms) {
      // Message is shown via CheckboxListTile subtitle, but an extra SnackBar can be added if desired.
      // _showMessage('You must accept the Terms and Conditions to register.', isError: true);
      return; // Stop registration if terms are not accepted.
    }

    setState(() => isLoading = true); // Show loading indicator.

    // API endpoint for user registration.
    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/register/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(), // Password is sent directly
          'date_of_birth': dobController.text.trim(),
          'gender': selectedGender,
          'region': selectedCountry, // This should be the country code
          'terms_and_conditions_accepted': acceptTerms,
        }),
      );

      if (!mounted) return; // Check if the widget is still mounted.
      final data = jsonDecode(response.body); // Decode response body.

      if (response.statusCode == 201 && data.containsKey('access')) {
        // Successful registration.
        final prefs = await SharedPreferences.getInstance();
        // Store tokens and user information.
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        await prefs.setString('username', usernameController.text.trim());
        await prefs.setString('email', emailController.text.trim());
        // Store other registration details.
        await prefs.setString('date_of_birth', dobController.text.trim());
        await prefs.setString('gender', selectedGender ?? '');
        await prefs.setString('region', selectedCountry ?? '');
        // Mark survey as incomplete for new users
        await prefs.setBool('survey_completed', false);


        if (mounted) {
          setState(() {
            isLoading = false;
            _hasAttemptedSubmit = false; // Reset submission attempt flag.
          });
        }

        await _sendOtpToEmail(); // Send OTP for email verification.
        if (!mounted) return;
        // Navigate to OTP verification page.
        Navigator.of(context).pushReplacementNamed('/verify_signup_otp');
        _showMessage('Registration successful! Please verify your email.');

      } else if (response.statusCode == 429) { // Handle rate limiting
        final errorMessage = (data['error'] as String?) ?? (data['detail'] as String?) ?? "Rate limit exceeded. Please try again later.";
        _showMessage(errorMessage, isError: true);
        if (mounted) setState(() => isLoading = false);
      }
      else {
        // Handle other errors from the server.
        String errorMessage = "Signup failed.";
        if (data is Map && data.containsKey('error')) {
          errorMessage = data['error'] as String;
        } else if (data is Map && data.isNotEmpty) {
          // Concatenate multiple error messages if present.
          StringBuffer sb = StringBuffer();
          data.forEach((key, value) {
            if (value is List) {
              sb.writeln("$key: ${value.join(', ')}");
            } else {
              sb.writeln("$key: $value");
            }
          });
          if (sb.isNotEmpty) errorMessage = sb.toString().trim();
        } else if (data is Map && data.containsKey('detail')) {
          errorMessage = data['detail'] as String;
        }
        _showMessage(errorMessage, isError: true);
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      // Handle network or other unexpected errors.
      if (!mounted) return;
      debugPrint('Error during registration: ${e.toString()}');
      if (mounted) setState(() => isLoading = false);
      _showMessage('An error occurred: ${e.toString()}', isError: true);
    }
  }

  // _showMessage (using new version's theme-aware SnackBar)
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? theme.colorScheme.error : theme.colorScheme.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20,0,20,20), // Consistent margin
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Consistent shape
      ),
    );
  }

  // _inputDecoration (using new version's theme-aware and dynamic state-based styling)
  // This is a key part of the new version's UI enhancements.
  InputDecoration _inputDecoration(
      BuildContext context,
      String hint, {
        Widget? icon, // Changed from IconData to Widget to allow more flexibility if needed, though Icon is typical
        Color? dynamicFillColor, // Fill color determined by validation state and theme
        required bool isValid, // Indicates if the current input is valid for styling purposes
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final baseDecoration = theme.inputDecorationTheme; // For inheriting default styles

    // Define border colors based on theme and validity
    final Color lightGreenBorderColor = themeProvider.isDarkMode
        ? colorScheme.primary.withOpacity(0.6) // Softer green for dark mode
        : Colors.lightGreen.shade400; // Light green for light mode
    final Color defaultOutlineColor = colorScheme.outline.withOpacity(0.7);
    final Color errorColor = colorScheme.error;

    // Determine current border color for enabled (non-focused) state
    final Color currentEnabledBorderColor = isValid ? lightGreenBorderColor : defaultOutlineColor;
    // Determine current border color for focused state
    final Color currentFocusedBorderColor = isValid ? lightGreenBorderColor : colorScheme.primary;

    return InputDecoration(
      hintText: hint,
      hintStyle: baseDecoration.hintStyle ?? TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
      filled: true,
      fillColor: dynamicFillColor ?? baseDecoration.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.5),
      prefixIcon: icon != null
          ? (icon is Icon ? Icon(icon.icon, color: baseDecoration.prefixIconColor ?? colorScheme.primary) : icon)
          : null,
      border: OutlineInputBorder( // Default border
        borderRadius: BorderRadius.circular(12), // Consistent border radius
        borderSide: BorderSide(color: defaultOutlineColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder( // Border when enabled and not focused
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: currentEnabledBorderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder( // Border when focused
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: currentFocusedBorderColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder( // Border for validation errors
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder( // Border for validation errors when focused
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1.8),
      ),
      errorStyle: baseDecoration.errorStyle ?? TextStyle(color: errorColor, fontSize: 12, height: 0.8), // Error text style
      contentPadding: baseDecoration.contentPadding ?? const EdgeInsets.symmetric(vertical: 18, horizontal: 16), // Padding inside the field
    );
  }

  // _sendOtpToEmail (logic is similar, using new version's more detailed debug messages and error handling)
  Future<void> _sendOtpToEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token'); // Retrieve access token

    if (token == null) {
      debugPrint('No access token found for sending OTP.');
      // Optionally show a message to the user, though this is more of a developer log.
      // _showMessage('Could not verify session to send OTP. Please try logging in.', isError: true);
      return;
    }

    // API endpoint for sending OTP.
    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/signup/send-otp/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Send token for authorization
          'Content-Type': 'application/json',
        },
        // No body is typically needed if the backend identifies the user via token
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        debugPrint('OTP sent successfully.');
        // _showMessage('Verification OTP sent to your email.'); // Message shown after successful registration
      } else {
        final data = jsonDecode(response.body);
        String errorMessage = (data['error'] as String?) ??
            (data['detail'] as String?) ??
            'Failed to send OTP. Please try again.';
        debugPrint('Failed to send OTP: $errorMessage. Status: ${response.statusCode}');
        // _showMessage(errorMessage, isError: true); // Avoid double messaging if registration itself failed
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      // if (mounted) _showMessage('An error occurred while sending OTP: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final viewInsets = MediaQuery.of(context).viewInsets; // For keyboard visibility

    // Define page gradient based on theme (from new version)
    final LinearGradient pageGradient = themeProvider.isDarkMode
        ? LinearGradient(
      colors: [colorScheme.surface.withOpacity(0.8), colorScheme.background],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : const LinearGradient( // Original light mode gradient
      colors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Function to get dynamic fill color for TextFormFields (from new version)
    Color getDynamicFillColor(bool isValidProperty, bool isEmpty) {
      final defaultFill = theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.5);
      if (isEmpty) return defaultFill; // Default fill if empty (validator handles requirement)

      // Define fill colors for valid/invalid states in light/dark modes
      final validLight = Colors.green.shade50; // Lighter green for light mode valid
      final errorLight = Colors.red.shade50;   // Lighter red for light mode error

      final validDark = colorScheme.primaryContainer.withOpacity(0.2); // Theme-based for dark mode valid
      final errorDark = colorScheme.errorContainer.withOpacity(0.2);   // Theme-based for dark mode error

      return isValidProperty
          ? (themeProvider.isDarkMode ? validDark : validLight)
          : (themeProvider.isDarkMode ? errorDark : errorLight);
    }

    return Scaffold(
      resizeToAvoidBottomInset: true, // Ensure UI resizes when keyboard appears
      body: Container(
        decoration: BoxDecoration(
          gradient: pageGradient, // Apply the dynamic gradient
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // Padding adjusts for keyboard
              padding: EdgeInsets.fromLTRB(20, 20, 20, viewInsets.bottom + 20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: theme.cardColor, // Theme-aware card color
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30), // Inner padding for the card
                  child: Form(
                    key: _formKey,
                    // Autovalidate on user interaction for immediate feedback after first submit attempt or change
                    autovalidateMode: _hasAttemptedSubmit ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Card takes minimum necessary height
                      children: [
                        // App Title/Logo
                        Text(
                          "🌱 EcoGenie",
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Text(
                          "Create your eco-friendly account",
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Username TextFormField
                        TextFormField(
                            controller: usernameController,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            decoration: _inputDecoration(
                              context,
                              'Username*', // Hint text
                              icon: const Icon(Icons.person_outline),
                              dynamicFillColor: getDynamicFillColor(isUsernameValidState, usernameController.text.isEmpty),
                              isValid: isUsernameValidState,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Username is required';
                              // Regex for alphanumeric and underscores only
                              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) return 'Alphanumeric & underscores only';
                              return null;
                            },
                            onChanged: (value) {
                              _updateUsernameFeedback(); // Update feedback state
                              if(_hasAttemptedSubmit) _formKey.currentState?.validate(); // Re-validate if already attempted submit
                            }
                        ),
                        const SizedBox(height: 12),

                        // Email TextFormField
                        TextFormField(
                            controller: emailController,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            decoration: _inputDecoration(
                              context,
                              'Email*',
                              icon: const Icon(Icons.email_outlined),
                              dynamicFillColor: getDynamicFillColor(isEmailValidState, emailController.text.isEmpty),
                              isValid: isEmailValidState,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Email is required';
                              if (!EmailValidator.validate(value.trim())) return 'Enter a valid email address';
                              return null;
                            },
                            onChanged: (value) {
                              _updateEmailFeedback();
                              if(_hasAttemptedSubmit) _formKey.currentState?.validate();
                            }
                        ),
                        const SizedBox(height: 12),

                        // Password TextFormField
                        TextFormField(
                            controller: passwordController,
                            obscureText: obscurePassword, // Toggle password visibility
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            decoration: _inputDecoration(
                              context,
                              'Password*',
                              icon: const Icon(Icons.lock_outline),
                              dynamicFillColor: getDynamicFillColor(isPasswordCriteriaMet, passwordController.text.isEmpty),
                              isValid: isPasswordCriteriaMet,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: colorScheme.onSurfaceVariant),
                                onPressed: () => setState(() => obscurePassword = !obscurePassword),
                              ),
                            ),
                            validator: _validatePassword, // Use the dedicated password validation function
                            onChanged: (value) {
                              _updatePasswordFeedback();
                              if(_hasAttemptedSubmit) _formKey.currentState?.validate();
                            }
                        ),
                        const SizedBox(height: 12),

                        // Confirm Password TextFormField
                        TextFormField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirmPassword,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            decoration: _inputDecoration(
                              context,
                              'Confirm Password*',
                              icon: const Icon(Icons.lock_reset_outlined),
                              dynamicFillColor: getDynamicFillColor(doPasswordsMatch, confirmPasswordController.text.isEmpty),
                              isValid: doPasswordsMatch,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: colorScheme.onSurfaceVariant),
                                onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please confirm your password';
                              if (value != passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                            onChanged: (value) {
                              _updateConfirmPasswordFeedback();
                              if(_hasAttemptedSubmit) _formKey.currentState?.validate();
                            }
                        ),
                        const SizedBox(height: 12),

                        // Gender Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedGender,
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                          decoration: _inputDecoration(context, 'Select Gender*',
                            icon: const Icon(Icons.wc_outlined),
                            isValid: selectedGender != null, // Valid if a gender is selected
                            dynamicFillColor: getDynamicFillColor(selectedGender != null, selectedGender == null),
                          ),
                          dropdownColor: theme.cardColor, // Background color of the dropdown menu
                          items: ['Male', 'Female','Prefer not to say']
                              .map((gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender, style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface))))
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedGender = value);
                            if(_hasAttemptedSubmit) _formKey.currentState?.validate();
                          },
                          validator: (value) => value == null ? 'Please select your gender' : null,
                        ),
                        const SizedBox(height: 12),

                        // Country Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedCountry,
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                          decoration: _inputDecoration(
                            context,
                            'Select Country*',
                            icon: const Icon(Icons.public_outlined),
                            isValid: selectedCountry != null, // Valid if a country is selected
                            dynamicFillColor: getDynamicFillColor(selectedCountry != null, selectedCountry == null),
                          ),
                          dropdownColor: theme.cardColor,
                          isExpanded: true, // Allows the dropdown to take full width if needed
                          items: countries.map((country) {
                            // Handle potential encoding issues in country names, though ideally backend sends clean UTF-8
                            String rawName = country['name'] ?? 'Unknown';
                            String safeName = rawName; // Default to rawName
                            try {
                              // This is a basic attempt; robust decoding might need more context if issues persist
                              utf8.decode(rawName.runes.toList()); // Test if decodable
                            } catch (_) {
                              // If decoding fails, fallback to a sanitized version or keep raw
                              safeName = rawName.replaceAll(RegExp(r'[^\x20-\x7E]'), ''); // Basic ASCII sanitation
                            }
                            return DropdownMenuItem(
                              value: country['code'], // Use country code as value
                              child: Text(safeName, overflow: TextOverflow.ellipsis, style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedCountry = value);
                            if(_hasAttemptedSubmit) _formKey.currentState?.validate();
                          },
                          validator: (value) => value == null ? 'Please select your country' : null,
                        ),
                        const SizedBox(height: 12),

                        // Date of Birth TextFormField (tapped to show DatePicker)
                        GestureDetector(
                          onTap: () => _selectDate(context), // Show date picker on tap
                          child: AbsorbPointer( // Makes the TextFormField itself not focusable
                            child: TextFormField(
                                controller: dobController,
                                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                                decoration: _inputDecoration(context, 'Date of Birth*',
                                  icon: const Icon(Icons.calendar_today_outlined),
                                  isValid: dobController.text.isNotEmpty, // Valid if date is selected
                                  dynamicFillColor: getDynamicFillColor(dobController.text.isNotEmpty, dobController.text.isEmpty),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Please select your date of birth' : null,
                                onChanged: (value) { // Though typically not changed directly by typing
                                  if(_hasAttemptedSubmit) _formKey.currentState?.validate();
                                }
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Terms and Conditions Checkbox
                        CheckboxListTile(
                          value: acceptTerms,
                          onChanged: (value) {
                            setState(() => acceptTerms = value ?? false);
                            // If user accepts after an attempt to submit, re-validate to clear the error.
                            if (_hasAttemptedSubmit && (value ?? false)) {
                              _formKey.currentState?.validate(); // This won't directly validate the checkbox but can refresh form state
                            }
                          },
                          controlAffinity: ListTileControlAffinity.leading, // Checkbox on the left
                          contentPadding: EdgeInsets.zero,
                          activeColor: colorScheme.primary, // Color of the checkbox when checked
                          title: Row( // Using Row to include asterisk and link
                            children: [
                              Text(
                                "I accept the ",
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              GestureDetector(
                                onTap: _showTermsAndConditions, // Show T&C dialog
                                child: Text(
                                  "Terms and Conditions",
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.secondary, // Use secondary color for link
                                    decoration: TextDecoration.underline,
                                    decorationColor: colorScheme.secondary,
                                  ),
                                ),
                              ),
                              Text("*", style: textTheme.bodySmall?.copyWith(color: colorScheme.error)), // Asterisk for required
                            ],
                          ),
                          // Show error message if terms not accepted after submission attempt
                          subtitle: !acceptTerms && _hasAttemptedSubmit
                              ? Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'You must accept the terms to continue.',
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.error, fontSize: 12),
                            ),
                          )
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Create Account Button
                        SizedBox(
                          width: double.infinity, // Button takes full width
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // backgroundColor and foregroundColor will be derived from theme
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            onPressed: isLoading ? null : () => _registerUser(context), // Disable if loading
                            child: isLoading
                                ? SizedBox(height: 22, width: 22, child:CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2.5,))
                                : Text('Create Account', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Navigation to Login Page
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account?', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'), // Navigate to login
                              style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(horizontal: 6)),
                              child: Text('Log in', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
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

