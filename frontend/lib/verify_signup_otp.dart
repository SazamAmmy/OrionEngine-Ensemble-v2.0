
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class VerifySignupOTPPage extends StatefulWidget {
  const VerifySignupOTPPage({super.key});

  @override
  State<VerifySignupOTPPage> createState() => _VerifySignupOTPPageState();
}

class _VerifySignupOTPPageState extends State<VerifySignupOTPPage> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  bool isResending = false;
  int resendAttempts = 0;
  int resendCooldown = 60;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
    _startCooldown();
  }

  void _startCooldown() {
    setState(() => resendCooldown = 60);
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown <= 1) {
        timer.cancel();
        setState(() => resendCooldown = 0);
      } else {
        setState(() => resendCooldown -= 1);
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (otpController.text.trim().length != 6) {
      _showMessage('Please enter a valid 6-digit OTP', isError: true);
      return;
    }

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/signup/verify-otp/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'otp': otpController.text.trim()}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage('Account verified successfully!');
        Navigator.of(context).pushReplacementNamed('/survey');
      } else {
        _showMessage(data['error'] ?? 'Invalid OTP', isError: true);
      }
    } catch (e) {
      _showMessage('Error verifying OTP: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (resendAttempts >= 3) {
      _showMessage("You've reached the resend limit. Try again later.", isError: true);
      return;
    }

    setState(() {
      isResending = true;
      resendAttempts += 1;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/signup/send-otp/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showMessage("OTP resent to your email.");
        _startCooldown();
      } else {
        final data = jsonDecode(response.body);
        _showMessage(data['error'] ?? "Failed to resend OTP", isError: true);
      }
    } catch (e) {
      _showMessage("Error resending OTP: $e", isError: true);
    }

    setState(() => isResending = false);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        const Icon(Icons.verified_user, size: 60, color: Colors.green),
                        const SizedBox(height: 20),
                        const Text(
                          "Almost There!",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Your account has been created. Please verify your email to continue.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.security),
                            hintText: 'Enter 6-digit OTP',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _verifyOtp,
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
                                : const Text('Verify & Continue'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: (isResending || resendCooldown > 0 || resendAttempts >= 3)
                              ? null
                              : _resendOtp,
                          child: Text(
                            resendAttempts >= 3
                                ? "Resend limit reached"
                                : resendCooldown > 0
                                ? "Resend in ${resendCooldown}s"
                                : "Didn't receive code? Resend OTP",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
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
    );
  }
}
