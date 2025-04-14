import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false; // Controls loading indicator

  Future<void> _loginUser(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage(context, 'Please enter both email and password', isError: true);
      return;
    }

    setState(() {
      isLoading = true; // Show loading indicator
    });

    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/login/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      setState(() {
        isLoading = false; // Hide loading indicator
      });

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}"); // Debug API response

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if "access" and "refresh" tokens exist
        if (data.containsKey('access') && data.containsKey('refresh')) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access']); // Save access token
          await prefs.setString('refresh_token', data['refresh']); //  Save refresh token
          await prefs.setString('username', data['username']);
          await prefs.setString('email', email);

          print("Access Token Saved: ${data['access']}"); // Debug token storage
          print(" Refresh Token Saved: ${data['refresh']}");

          _showMessage(context, 'Login successful!', isError: false);
          Navigator.of(context).pushReplacementNamed('/main'); //  Navigate to main page
        } else {
          print("No Token Received in API Response");
          _showMessage(context, "Login successful, but no token received.", isError: true);
        }
      } else {
        final data = jsonDecode(response.body);
        _showMessage(context, data['message'] ?? 'Login failed', isError: true);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("API Request Failed: $e"); //  Debugging error
      _showMessage(context, 'An error occurred. Please try again.', isError: true);
    }
  }

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: EdgeInsets.all(25),
            child: Column(
              children: [
                Spacer(),
                SizedBox(height: 50),
                Text(
                  "Hello, Welcome Back",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text("Login to continue", style: TextStyle(color: Colors.white)),
                SizedBox(height: 40),
                _buildTextField('Email', emailController),
                SizedBox(height: 20),
                _buildTextField('Password', passwordController, obscureText: true),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text('Forgot Password?'),
                  ),
                ),
                SizedBox(height: 30),

                // Login Button
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _loginUser(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.black) // Show loader when logging in
                        : Text('Log In'),
                  ),
                ),

                Spacer(),
                Text('Or sign in with', style: TextStyle(color: Colors.white)),
                SizedBox(height: 16),

                // Google Login Button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/google.png', width: 30, height: 30),
                      SizedBox(width: 8),
                      Text('Login with Google'),
                    ],
                  ),
                ),

                // Signup Option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: TextStyle(color: Colors.white)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed('/signup'),
                      style: TextButton.styleFrom(foregroundColor: Colors.amber),
                      child: Text(
                        'Sign up',
                        style: TextStyle(decoration: TextDecoration.underline, decorationThickness: 1.5),
                      ),
                    ),
                  ],
                ),
                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
      ),
    );
  }
}
