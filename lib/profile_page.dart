import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Clear session
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile & Settings"),backgroundColor: Colors.green,), //
      body: ListView(
        children: [
          // Profile Section
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

          // Settings Section
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

          // Logout
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
