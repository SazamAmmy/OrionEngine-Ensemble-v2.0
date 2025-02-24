import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false; // For showing a loading indicator

  Future<void> _registerUser(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      _showMessage(context, 'Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true; // Show loading indicator
    });

    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/register/');

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
      print("Response Body: ${response.body}"); //  Debug API response

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        //  Check if "access" and "refresh" tokens exist
        if (data.containsKey('access') && data.containsKey('refresh')) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access']); // Save access token
          await prefs.setString('refresh_token', data['refresh']); // Save refresh token
          await prefs.setString('email', email);

          print(" Access Token Saved: ${data['access']}"); //  Debug token storage
          print(" Refresh Token Saved: ${data['refresh']}");

          _showMessage(context, 'Account created successfully!');
          Navigator.of(context).pushReplacementNamed('/main'); //  Auto login after sign-up
        } else {
          print("No Token Received in API Response");
          _showMessage(context, "Signup successful, but no token received.");
        }
      } else {
        _showMessage(context, "Signup failed: ${data['message'] ?? 'Unknown error'}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("API Request Failed: $e"); //  Debugging error
      _showMessage(context, 'An error occurred: $e');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                  "Sign Up",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text("Create your account", style: TextStyle(color: Colors.white)),
                SizedBox(height: 40),
                _buildTextField('Type your Email', emailController),
                SizedBox(height: 15),
                _buildTextField('Password', passwordController, obscureText: true),
                SizedBox(height: 15),
                _buildTextField('Confirm Password', confirmPasswordController, obscureText: true),
                SizedBox(height: 30),

                // Sign up button
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _registerUser(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.black) // Show loader when submitting
                        : Text('Sign up'),
                  ),
                ),

                Spacer(),
                Text('Or sign in with', style: TextStyle(color: Colors.white)),
                SizedBox(height: 16),

                // Google sign-in button
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
                      Text('Sign up with Google'),
                    ],
                  ),
                ),

                // Already have an account?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?", style: TextStyle(color: Colors.white)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed('/login'),
                      style: TextButton.styleFrom(foregroundColor: Colors.amber),
                      child: Text(
                        'Log in',
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
