import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sustainableapp/theme_provider.dart'; // Ensure this import is correct

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  // bool isDarkMode = false; // Remove this local state for dark mode
  bool isNotificationsEnabled = true;
  String userName = "Guest";
  String userEmail = "Not Logged In";
  String? rawDateOfBirth;
  DateTime? parsedDateOfBirth;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
    _loadUserData();
    // No need to load theme here, ThemeProvider handles it.
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userName = prefs.getString('username') ?? "Guest";
      userEmail = prefs.getString('email') ?? "Not Logged In";
      isAdmin = prefs.getBool('is_staff') ?? false;
      rawDateOfBirth = prefs.getString('date_of_birth');
      if (rawDateOfBirth != null) {
        parsedDateOfBirth = DateTime.tryParse(rawDateOfBirth!);
      }
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // This will also clear the saved theme preference.
    // Consider if you want to preserve theme on logout.
    // If so, save themeProvider.isDarkMode before clear and restore after.
    if (!mounted) return;
    // Optionally, reset theme to light mode on logout if desired
    // Provider.of<ThemeProvider>(context, listen: false).setTheme(false);
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    // Access ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Define colors based on theme for elements not automatically handled by ThemeData
    // For example, if you have custom colored containers or text that needs to adapt.
    // However, try to rely on Theme.of(context) properties as much as possible.
    // Color profileCardBackgroundColor = themeProvider.isDarkMode ? const Color(0xFF2C3D2C) : Colors.white;
    // Color profileTextColor = themeProvider.isDarkMode ? Colors.white.withOpacity(0.87) : Colors.black87;
    // Color profileIconColor = themeProvider.isDarkMode ? Colors.green.shade300 : Colors.green;


    return Scaffold(
      // backgroundColor is handled by ThemeData.scaffoldBackgroundColor
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
                  color: Theme.of(context).colorScheme.primary, // Use color from theme
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Use cardColor from theme or a specific surface color from ColorScheme
                color: Theme.of(context).cardColor,
                image: DecorationImage(
                  image: const AssetImage('assets/images/profile_bg_image.png'),
                  fit: BoxFit.cover,
                  // Adjust opacity based on theme if needed, or use a different image for dark mode
                  colorFilter: ColorFilter.mode(
                      (themeProvider.isDarkMode ? Colors.black : Colors.white).withOpacity(0.7),
                      BlendMode.dstATop
                  ),
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.12),
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
                      // Use a color that contrasts well with the card background
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 36),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userEmail,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary, // Or Theme.of(context).textTheme.titleLarge?.color
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (parsedDateOfBirth != null)
                    Text(
                      "DOB: ${DateFormat.yMMMMd().format(parsedDateOfBirth!)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? (themeProvider.isDarkMode ? Colors.red.shade700.withOpacity(0.3) : Colors.red.shade100)
                          : (themeProvider.isDarkMode ? Colors.green.shade700.withOpacity(0.3) : Colors.green.shade100),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAdmin ? "🛡️ Admin" : "🌱 Sustainable User",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isAdmin
                            ? (themeProvider.isDarkMode ? Colors.red.shade200 : Colors.red.shade800)
                            : (themeProvider.isDarkMode ? Colors.green.shade200 : Colors.green.shade800),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (isAdmin) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin');
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("Admin Features"),
                // ElevatedButton style is handled by ThemeData.elevatedButtonTheme
              ),
              const SizedBox(height: 20),
            ],

            // Dark Mode Switch
            _buildSwitchTile(
                Icons.dark_mode,
                "Dark Mode",
                themeProvider.isDarkMode, // Use value from ThemeProvider
                    (value) {
                  themeProvider.toggleTheme(); // Call toggleTheme on ThemeProvider
                },
                iconColor: Theme.of(context).iconTheme.color, // Use icon color from theme
                textColor: Theme.of(context).textTheme.bodyLarge?.color
            ),

            _buildSwitchTile(
                Icons.notifications,
                "Notifications",
                isNotificationsEnabled,
                    (value) {
                  setState(() => isNotificationsEnabled = value);
                },
                iconColor: Theme.of(context).iconTheme.color,
                textColor: Theme.of(context).textTheme.bodyLarge?.color
            ),

            _buildTile(
                Icons.color_lens,
                "App Theme",
                onTap: () {
                  // Potentially show a dialog to pick themes if you have more than light/dark
                  // For now, dark mode switch handles it.
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Theme selection (Dark/Light) is above.")));
                },
                iconColor: Theme.of(context).iconTheme.color,
                textColor: Theme.of(context).textTheme.bodyLarge?.color
            ),
            _buildTile(
                Icons.lock,
                "Change Password",
                onTap: () {
                  Navigator.pushNamed(context, '/change_password');
                },
                iconColor: Theme.of(context).iconTheme.color,
                textColor: Theme.of(context).textTheme.bodyLarge?.color
            ),
            _buildTile(
                Icons.privacy_tip,
                "Privacy Policy",
                onTap: () {
                  Navigator.pushNamed(context, '/privacy-policy');
                },
                iconColor: Theme.of(context).iconTheme.color,
                textColor: Theme.of(context).textTheme.bodyLarge?.color
            ),
            _buildTile(
                Icons.help_outline,
                "Help & Support",
                onTap: () {
                  Navigator.pushNamed(context, '/support');
                },
                iconColor: Theme.of(context).iconTheme.color,
                textColor: Theme.of(context).textTheme.bodyLarge?.color
            ),
            _buildTile(
                Icons.info_outline,
                "About EcoGenie",
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      // AlertDialog background and text colors will be handled by ThemeData and ColorScheme
                      title: Row(
                        children: [
                          Icon(Icons.eco_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            "About EcoGenie",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        "EcoGenie is your AI-powered sustainability assistant, designed to help you make greener lifestyle choices through smart insights and personalized tips.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          height: 1.4,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          // TextButton style is handled by ThemeData.textButtonTheme
                          child: const Text(
                            "CLOSE",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                iconColor: Theme.of(context).iconTheme.color,
                textColor: Theme.of(context).textTheme.bodyLarge?.color
            ),

            _buildTile(
                Icons.logout,
                "Logout",
                textColor: themeProvider.isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                iconColor: themeProvider.isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                onTap: _logout
            ),

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
      leading: Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color), // Use theme default if not specified
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color, // Use theme default if not specified
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16), // Default trailing icon
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value,
      ValueChanged<bool> onChanged, {Color? textColor, Color? iconColor}) {
    // Access ThemeProvider to style the switch based on the current theme
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color),
      title: Text(
          title,
          style: TextStyle(
              color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500
          )
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        // activeColor and activeTrackColor are handled by ThemeData.switchTheme
        // inactiveThumbColor and inactiveTrackColor are also handled by ThemeData.switchTheme
      ),
    );
  }
}
