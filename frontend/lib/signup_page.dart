import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For formatting the date
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController usernameController = TextEditingController(); // NEW
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  bool isLoading = false; // For showing a loading indicator

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1), // Default date
      firstDate: DateTime(1900), // Minimum year
      lastDate: DateTime.now(), // Maximum date (Today)
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate); // Save formatted date
      });
    }
  }

  // Function to register user
  Future<void> _registerUser(BuildContext context) async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final dob = dobController.text.trim();

    if (password != confirmPassword) {
      _showMessage(context, 'Passwords do not match');
      return;
    }

    if (dob.isEmpty) {
      _showMessage(context, 'Please select your Date of Birth');
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
          'username': username, // Send username
          'email': email,
          'password': password,
          'dob': dob, //  Send DOB to backend
        }),
      );

      setState(() {
        isLoading = false; // Hide loading indicator
      });

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}"); //

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        //  Check if "access" and "refresh" tokens exist
        if (data.containsKey('access') && data.containsKey('refresh')) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access']); // Save access token
          await prefs.setString('refresh_token', data['refresh']); // Save refresh token
          await prefs.setString('username', username);
          await prefs.setString('email', email);
          await prefs.setString('dob', dob); // Store DOB in SharedPreferences

          print("Access Token Saved: ${data['access']}");
          print("Refresh Token Saved: ${data['refresh']}");
          print("DOB Saved: $dob");

          _showMessage(context, 'Account created successfully!');
          Navigator.of(context).pushReplacementNamed('/survey'); // Auto login after sign-up
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
      print("API Request Failed: $e");
      _showMessage(context, 'An error occurred: $e');
    }
  }

  // Show message using Snackbar
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
                Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("Create your account", style: TextStyle(color: Colors.white)),
                SizedBox(height: 40),

                _buildTextField('Username', usernameController), // NEW FIELD
                SizedBox(height: 15),

                // Email Field
                _buildTextField('Type your Email', emailController),
                SizedBox(height: 15),

                // Password Field
                _buildTextField('Password', passwordController, obscureText: true),
                SizedBox(height: 15),

                // Confirm Password Field
                _buildTextField('Confirm Password', confirmPasswordController, obscureText: true),
                SizedBox(height: 15),

                // Date of Birth Field
                TextField(
                  controller: dobController, //  Controller added
                  readOnly: true, // Prevents manual input
                  onTap: () => _selectDate(context), // Opens Date Picker
                  decoration: InputDecoration(
                    hintText: 'Select your Date of Birth',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    suffixIcon: Icon(Icons.calendar_today, color: Colors.grey), // Calendar icon
                  ),
                ),

                SizedBox(height: 30),

                // Signup Button
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _registerUser(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: isLoading ? CircularProgressIndicator(color: Colors.black) : Text('Sign up'),
                  ),
                ),

                Spacer(),
                Text('Or sign in with', style: TextStyle(color: Colors.white)),
                SizedBox(height: 16),

                // Google sign-in button
                ElevatedButton(
                  onPressed: () {}, // Google sign-in logic here
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

                SizedBox(height: 16),

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

  // Reusable text field builder
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
