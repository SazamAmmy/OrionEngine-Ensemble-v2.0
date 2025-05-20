import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sustainableapp/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SessionHandler extends StatefulWidget {
  const SessionHandler({super.key});

  @override
  State<SessionHandler> createState() => _SessionHandlerState();
}

class _SessionHandlerState extends State<SessionHandler> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLoginStatus());
  }

  Future<void> _checkLoginStatus() async {
    final token = await AuthService.getValidAccessToken();

    if (!mounted) return;

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();

      try {
        final response = await http.get(
          Uri.parse('https://direct-frog-amused.ngrok-free.app/api/user/profile/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final bool isVerified = data['is_verified'] ?? false;
          final bool surveyCompleted = prefs.getBool('survey_completed') ?? false;

          await prefs.setBool('is_verified', isVerified);

          if (!isVerified) {
            Navigator.pushReplacementNamed(context, '/verify_signup_otp');
          } else {
            Navigator.pushReplacementNamed(context, surveyCompleted ? '/main' : '/survey');
          }
        } else {
          // Token is valid but profile fetch failed
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        debugPrint('❌ Error checking login status: $e');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
