import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "Guest"; // Default name
  String userEmail = "Not Logged In";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? "Guest";
      userEmail = prefs.getString('email') ?? "Not Logged In";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/profile.png'), // Add a default image
          ),
          SizedBox(height: 10),
          Text("Welcome, $userName!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(userEmail, style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
