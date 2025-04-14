import 'package:flutter/material.dart';
import 'package:sustainableapp/main_page.dart';
import 'package:sustainableapp/profile_page.dart';
import 'package:sustainableapp/signup_page.dart';
import 'package:sustainableapp/home_page.dart';
import 'login_page.dart';
import 'package:sustainableapp/chat_page.dart';
import 'survey_page.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white70
      ),
      initialRoute: '/main', // Use the LoginPage here
      routes: {
        '/login':(context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/main': (context) => MainPage(),
        '/profile': (context) => ProfilePage(),
        '/survey': (context) => SurveyPage(),
        '/signup': (context) => SignupPage(),
        '/chat': (context) => ChatPage(),
      },
    );
  }
}
