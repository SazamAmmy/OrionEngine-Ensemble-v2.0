import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "Guest";
  String userEmail = "Not Logged In";
  String recommendation = ""; // This will hold recommendation from API
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchRecommendation(); // Fetch recommendation when page loads
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? "Guest";
      userEmail = prefs.getString('email') ?? "Not Logged In";
    });
  }

  Future<void> _fetchRecommendation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      setState(() {
        recommendation = "You must log in to view personalized suggestions.";
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/userhome/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recommendation = data['recommendation'] ?? "No tips available.";
          isLoading = false;
        });
      } else {
        setState(() {
          recommendation = "Failed to fetch recommendations.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        recommendation = "An error occurred: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isLoading
          ? CircularProgressIndicator()
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/profile.png'),
          ),
          SizedBox(height: 10),
          Text("Welcome, $userName!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(userEmail, style: TextStyle(fontSize: 16, color: Colors.grey)),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "🌱 Your Sustainability Tip:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Text(
              recommendation,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
