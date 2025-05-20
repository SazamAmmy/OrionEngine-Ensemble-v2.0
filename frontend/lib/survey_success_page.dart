import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class SurveySuccessPage extends StatefulWidget {
  const SurveySuccessPage({super.key});
  @override
  SurveySuccessPageState createState() => SurveySuccessPageState();
}

class SurveySuccessPageState extends State<SurveySuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // Auto-navigate
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top success animation
                  Lottie.asset(
                    'assets/animations/eco_success.json',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "You're all set!",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Loading your sustainable lifestyle...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Secondary animation
                  Lottie.asset(
                    'assets/animations/lets_go.json',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
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
