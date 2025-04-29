import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool isDarkMode = false;
  bool isNotificationsEnabled = true;
  String selectedLanguage = "English";
  String userName = "Guest";
  String userEmail = "Not Logged In";
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userName = prefs.getString('username') ?? "Guest";
      userEmail = prefs.getString('email') ?? "Not Logged In";
      isAdmin = prefs.getBool('is_staff') ?? false;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F7EF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            Center(
              child: Text(
                "Profile & Settings",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Profile Card with Background Image
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                image: DecorationImage(
                  // *** REPLACE THIS WITH YOUR IMAGE PATH ***
                  image: AssetImage('assets/images/profile_bg_image.png'),
                  fit: BoxFit.cover,
                  // Tints the image. Adjust opacity (e.g., 0.5 to 1.0) or remove based on image.
                  // Or experiment with different BlendModes. Multiply or srcOver are common.
                  colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.7), BlendMode.dstATop), // Slightly less transparent
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade100,
                    ),
                    child: const Icon(Icons.person, color: Colors.green, size: 36),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userEmail,
                    // Adjusted color to look like the muted email in the image
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]), // Example: Darker grey
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      // Adjusted color to look like the muted username in the image
                      // Example: A slightly darker, potentially tinted grey or black with transparency
                      color: Colors.green.shade800.withOpacity(0.8), // Example: Muted dark green
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Admin Button
            if (isAdmin) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin');
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("Admin Features"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
            ],

            _buildTile(Icons.quiz, "Your Survey", onTap: () {
              Navigator.pushNamed(context, '/survey', arguments: {'retake': true});
            }, trailing: const Icon(Icons.refresh)),

            _buildSwitchTile(Icons.dark_mode, "Dark Mode", isDarkMode, (value) {
              setState(() => isDarkMode = value);
            }),

            _buildSwitchTile(Icons.notifications, "Notifications", isNotificationsEnabled, (value) {
              setState(() => isNotificationsEnabled = value);
            }),

            ListTile(
              leading: const Icon(Icons.language, color: Colors.green),
              title: const Text("Language"),
              trailing: DropdownButton<String>(
                value: selectedLanguage,
                underline: const SizedBox(),
                onChanged: (value) => setState(() => selectedLanguage = value!),
                items: ['English', 'Spanish', 'French'].map((lang) {
                  return DropdownMenuItem(value: lang, child: Text(lang));
                }).toList(),
              ),
            ),

            _buildTile(Icons.color_lens, "App Theme", onTap: () { /* Enhancement */ }),

            _buildTile(Icons.lock, "Change Password", onTap: () {
              Navigator.pushNamed(context, '/change_password');
            }),

            _buildTile(Icons.privacy_tip, "Privacy Policy", onTap: () {
              Navigator.pushNamed(context, '/privacy-policy');
            }),

            _buildTile(Icons.help_outline, "Help & Support", onTap: () {
              Navigator.pushNamed(context, '/support');
            }),

            _buildTile(Icons.info_outline, "About EcoGenie", onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "EcoGenie",
                applicationVersion: "v1.0.0",
                children: const [
                  Text("An AI-powered sustainability assistant built to help you live greener."),
                ],
              );
            }),

            _buildTile(Icons.logout, "Logout",
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: _logout),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title,
      {void Function()? onTap, Widget? trailing, Color? textColor, Color? iconColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(icon, color: iconColor ?? Colors.green),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value,
      ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}