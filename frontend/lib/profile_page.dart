import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isDarkMode = false;
  bool isNotificationsEnabled = true;
  String selectedLanguage = "English";
  String userName = "Guest";
  String userEmail = "Not Logged In";
  String lastSurveyUpdate = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchSurveyTimestamp();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? "Guest";
      userEmail = prefs.getString('email') ?? "Not Logged In";
    });
  }

  Future<void> _fetchSurveyTimestamp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    try {
      final response = await http.get(
        Uri.parse('https://direct-frog-amused.ngrok-free.app/api/user/survey-response/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedAt = data['updated_at'];
        setState(() {
          lastSurveyUpdate = updatedAt;
        });
      }
    } catch (e) {
      print("Error fetching survey timestamp: $e");
    }
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Clear session
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile & Settings"), backgroundColor: Colors.green),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(backgroundImage: AssetImage("assets/profile.png")),
            title: Text(userName),
            subtitle: Text(userEmail),
            trailing: Icon(Icons.edit),
            onTap: () {
              Navigator.pushNamed(context, '/edit-profile');
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.quiz),
            title: Text("Your Survey"),
            subtitle: lastSurveyUpdate.isNotEmpty ? Text("Last updated: $lastSurveyUpdate") : null,
            trailing: Icon(Icons.refresh),
            onTap: () {
              Navigator.pushNamed(context, '/survey', arguments: {'retake': true});
            },
          ),

          ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text("Dark Mode"),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
              },
            ),
          ),

          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Notifications"),
            trailing: Switch(
              value: isNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  isNotificationsEnabled = value;
                });
              },
            ),
          ),

          ListTile(
            leading: Icon(Icons.language),
            title: Text("Language"),
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              onChanged: (String? newValue) {
                setState(() {
                  selectedLanguage = newValue!;
                });
              },
              items: <String>['English', 'Spanish', 'French']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),

          ListTile(
            leading: Icon(Icons.lock),
            title: Text("Change Password"),
            onTap: () {
              Navigator.pushNamed(context, '/change-password');
            },
          ),

          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text("Privacy Policy"),
            onTap: () {
              Navigator.pushNamed(context, '/privacy-policy');
            },
          ),

          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
