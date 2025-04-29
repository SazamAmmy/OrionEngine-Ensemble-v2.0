import 'package:flutter/material.dart';
import 'package:sustainableapp/main_page.dart';
import 'package:sustainableapp/profile_page.dart';
import 'package:sustainableapp/signup_page.dart';
import 'package:sustainableapp/home_page.dart';
import 'package:sustainableapp/login_page.dart';
import 'package:sustainableapp/chat_page.dart';
import 'package:sustainableapp/survey_success_page.dart';
import 'package:sustainableapp/survey_page.dart';
import 'package:sustainableapp/session_handler.dart';
import 'package:sustainableapp/admin_page.dart';
import 'package:sustainableapp/user_ip_log.dart';
import 'package:sustainableapp/forgot_password.dart';
import 'package:sustainableapp/change_password.dart';




void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Named key parameter added

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.green.shade50,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SessionHandler(),       //  const added
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/main': (context) => const MainPage(),
        '/profile': (context) => const ProfilePage(),
        '/survey': (context) => const SurveyPage(),
        '/signup': (context) => const SignupPage(),
        '/chat': (context) => const ChatPage(),
        '/survey_success': (context) => const SurveySuccessPage(),
        '/admin': (context) => const AdminPage(),
        '/user_ip_log': (context) => const UserIPLogPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/change_password': (context) => const ChangePasswordPage(),



      },
    );
  }
}