import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class SurveySuccessPage extends StatefulWidget {
  const SurveySuccessPage({super.key});
  @override
  SurveySuccessPageState createState() => SurveySuccessPageState();
}

class SurveySuccessPageState extends State<SurveySuccessPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return; //
      Navigator.pushReplacementNamed(context, '/main');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/eco_success.json',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            Text(
              "You're all set!",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Loading your sustainable lifestyle...",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.green.shade700),
            ),
            const SizedBox(height: 30),
            Lottie.asset(
              'assets/animations/lets_go.json',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
