import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:email_validator/email_validator.dart';


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
  bool acceptTerms = false;
  bool isUsernameValid = false;
  bool isEmailValid = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  List<Map<String, String>> countries = [];
  String termsAndConditionsText = "";
  String? selectedGender;
  String? selectedCountry;

  @override
  void initState() {
    super.initState();
    fetchRegisterInfo();
    usernameController.addListener(_validateUsername);
    emailController.addListener(_validateEmail);
  }
  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Terms and Conditions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                termsAndConditionsText.isNotEmpty
                    ? termsAndConditionsText
                    : 'No terms and conditions available.',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }






  void _validateUsername() {
    final username = usernameController.text.trim();
    setState(() {
      isUsernameValid = RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
    });
  }

  String? emailErrorMessage;

  void _validateEmail() {
    final email = emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        isEmailValid = false;
        emailErrorMessage = 'Email is required';
      } else if (!EmailValidator.validate(email)) {
        isEmailValid = false;
        emailErrorMessage = 'Enter a valid email address';
      } else {
        isEmailValid = true;
        emailErrorMessage = null;
      }


    });




  }
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must have at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must have at least one lowercase letter';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Password must have at least one special character';
    return null;
  }



  Future<void> fetchRegisterInfo() async {
    try {
      final url = Uri.parse(
          'https://direct-frog-amused.ngrok-free.app/api/register-info/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          final List<dynamic> countriesRaw = data['countries'];

          setState(() {
            countries = countriesRaw.map((country) =>
            {
              'name': country['name'] as String,
              'code': country['code'] as String,
            }).toList();
            termsAndConditionsText = data['terms_and_conditions_text'];
          });
          termsAndConditionsText = data['terms_and_conditions_text'];
        });
      }
    } catch (e) {
      print('Error fetching register info: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final latestAllowed = DateTime(now.year - 16, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: latestAllowed,
      firstDate: DateTime(1900),
      lastDate: latestAllowed,
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _registerUser(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (!acceptTerms) {
      _showMessage('Please accept the Terms and Conditions.', isError: true);
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/register/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'date_of_birth': dobController.text.trim(),
          'gender': selectedGender,
          'region': selectedCountry,
          'terms_and_conditions_accepted': acceptTerms,
        }),
      );

      final data = jsonDecode(response.body);
      setState(() => isLoading = false);

      if (response.statusCode == 201 && data.containsKey('access')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        await prefs.setString('username', usernameController.text.trim());
        await prefs.setString('email', emailController.text.trim());
        await prefs.setString('date_of_birth', dobController.text.trim());
        await prefs.setString('gender', selectedGender ?? '');
        await prefs.setString('region', selectedCountry ?? '');

        _showMessage('Welcome, ${usernameController.text.trim()}! 🌱');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/survey');
      }
      else if (response.statusCode == 429) {  // 🚀 Rate limit triggered
        final errorMessage = data['error'] ?? "Rate limit exceeded. Please try again later.";
        _showMessage(errorMessage, isError: true);
      }
      else {
        _showMessage(data['error'] ?? 'Signup failed', isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage('Error: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint,
      {Widget? icon, Color? fillColor}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fillColor ?? Colors.grey.shade100,
      prefixIcon: icon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade600, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "🌱 EcoGenie",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Create your eco-friendly account",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20), // Reduced (was 25)

                        // Username
                        TextFormField(
                          controller: usernameController,
                          decoration: _inputDecoration(
                            'Username*',
                            icon: const Icon(Icons.person),
                            fillColor: usernameController.text.isEmpty
                                ? Colors.grey.shade100
                                : (isUsernameValid
                                ? Colors.green.shade100
                                : Colors.red.shade100),
                          ),
                          validator: (value) =>
                          value != null && isUsernameValid
                              ? null
                              : 'Invalid username',
                        ),
                        const SizedBox(height: 8),

                        // Email
                        TextFormField(
                          controller: emailController,
                          decoration: _inputDecoration(
                            'Email*',
                            icon: const Icon(Icons.email),
                          ).copyWith(
                            errorText: emailErrorMessage,
                            fillColor: emailController.text.isEmpty
                                ? Colors.grey.shade100
                                : (isEmailValid ? Colors.green.shade100 : Colors
                                .red.shade100),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                          value != null && isEmailValid
                              ? null
                              : 'Invalid email',
                        ),
                        const SizedBox(height: 8),

                        // Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: _inputDecoration(
                            'Password*',
                            icon: const Icon(Icons.lock),
                            fillColor: passwordController.text.isEmpty
                                ? Colors.grey.shade100
                                : (_validatePassword(passwordController.text) == null
                                ? Colors.green.shade100
                                : Colors.red.shade100),
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                          validator: _validatePassword,   // <-- use new function here
                        ),
                        const SizedBox(height: 8),
                        // Confirm Password
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          decoration: _inputDecoration(
                            'Confirm Password*',
                            icon: const Icon(Icons.lock_outline),
                            fillColor: confirmPasswordController.text.isEmpty
                                ? Colors.grey.shade100
                                : (confirmPasswordController.text == passwordController.text
                                ? Colors.green.shade100
                                : Colors.red.shade100),
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                            ),
                          ),
                          validator: (value) =>
                          value == passwordController.text ? null : 'Passwords do not match',
                        ),


                        const SizedBox(height: 8),

                        // Gender Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedGender,
                          decoration: _inputDecoration('Select Gender*',
                              icon: const Icon(Icons.person_outline)),
                          items: ['Male', 'Female', 'Prefer not to say']
                              .map((gender) =>
                              DropdownMenuItem(
                                  value: gender, child: Text(gender)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedGender = value),
                          validator: (value) =>
                          value == null
                              ? 'Select gender'
                              : null,
                        ),
                        const SizedBox(height: 8),

                        // Country Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedCountry,
                          decoration: _inputDecoration('Select Country*',
                              icon: const Icon(Icons.public)),
                          items: countries
                              .map((country) =>
                              DropdownMenuItem(
                                value: country['code'],
                                child: Text(country['name'] ?? ''),
                              ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedCountry = value),
                          validator: (value) =>
                          value == null
                              ? 'Select country'
                              : null,
                        ),
                        const SizedBox(height: 8),

                        // Date of Birth
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: dobController,
                              decoration: _inputDecoration('Date of Birth*',
                                  icon: const Icon(Icons.calendar_today)),
                              validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Select date of birth'
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Terms and Conditions
                        CheckboxListTile(
                          value: acceptTerms,
                          onChanged: (value) => setState(() => acceptTerms = value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.green.shade400,
                          title: Row(
                            children: [
                              const Text(
                                "I accept the ",
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              GestureDetector(
                                onTap: _showTermsAndConditions, // Open popup on click
                                child: const Text(
                                  "Terms and Conditions",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),


                        const SizedBox(height: 8),

                        // Create Account Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () =>
                                _registerUser(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : const Text('Create Account',
                              style: TextStyle(fontSize: 16, color:Colors.white,),),
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text('Already have an account?', style: TextStyle(
                            color: Colors.black54)),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/login'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.green.shade700),
                          child: const Text('Log in'),
                        ),
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
