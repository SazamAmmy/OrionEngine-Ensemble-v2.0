import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:sustainableapp/verify_signup_otp.dart';
import 'package:sustainableapp/theme_provider.dart';
import 'package:sustainableapp/themes.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoGenie',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      navigatorObservers: [routeObserver],
      initialRoute: '/',
      routes: {
        '/': (context) => const SessionHandler(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/main': (context) => const MainPage(),
        '/profile': (context) => const ProfilePage(),
        '/survey': (context) => const SurveyPage(),
        '/signup': (context) => const SignupPage(),
        '/verify_signup_otp': (context) => const VerifySignupOTPPage(),
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
