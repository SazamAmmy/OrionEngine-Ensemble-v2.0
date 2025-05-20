import 'package:flutter/material.dart';
import 'dart:io'; // For exit(0)
import 'package:provider/provider.dart'; // Import Provider
import 'package:sustainableapp/chat_page.dart';
import 'package:sustainableapp/profile_page.dart';
import 'package:sustainableapp/home_page.dart';
import 'package:sustainableapp/theme_provider.dart'; // Import ThemeProvider

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    ChatPage(),
    ProfilePage(),
  ];

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    // ThemeData and ColorScheme for dialog theming
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Use theme colors for the dialog
    final Color primaryActionColor = colorScheme.primary;
    final Color dismissiveActionColor = colorScheme.onSurface.withOpacity(0.7); // Or a specific color from theme
    final Color dialogTextColor = colorScheme.onSurface;
    final Color titleColor = colorScheme.primary;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // AlertDialog's own background and shape will be themed by global ThemeData
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          actionsPadding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          title: Row(
            children: [
              Icon(Icons.exit_to_app_rounded, color: titleColor, size: 26),
              const SizedBox(width: 12),
              Text(
                'Exit App?',
                style: textTheme.headlineSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to close EcoGenie?',
            style: textTheme.bodyLarge?.copyWith(
              color: dialogTextColor,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                foregroundColor: dismissiveActionColor,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'NO',
                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: dismissiveActionColor),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryActionColor,
                foregroundColor: colorScheme.onPrimary, // Text color on primary button
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'YES',
                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data
    final bottomNavTheme = theme.bottomNavigationBarTheme; // Get specific BottomNav theme

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_currentIndex == 0) {
          final shouldExit = await _showExitConfirmationDialog(context);
          if (shouldExit) exit(0);
        } else {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          // Use the BottomNavigationBarTheme's background color
          // Fallback to cardColor or surface if not specified in theme
          color: bottomNavTheme.backgroundColor ?? theme.cardColor,
          // The shadow is part of the BottomNavigationBar itself if elevation > 0
          // If you want a custom shadow on the container, it needs to be theme-aware too.
          // For simplicity, relying on BottomNavigationBar's own elevation.
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            // backgroundColor is now handled by the Container or by bottomNavTheme.backgroundColor
            // If bottomNavTheme.backgroundColor is set, this can be Colors.transparent
            // or remove this line to let the theme dictate.
            backgroundColor: bottomNavTheme.backgroundColor ?? theme.cardColor,
            elevation: bottomNavTheme.elevation ?? 8.0, // Use theme elevation
            selectedItemColor: bottomNavTheme.selectedItemColor ?? theme.colorScheme.primary, // Theme-aware
            unselectedItemColor: bottomNavTheme.unselectedItemColor ?? theme.colorScheme.onSurface.withOpacity(0.6), // Theme-aware
            iconSize: 19, // Consider making these part of the theme if they need to change
            selectedFontSize: 11,
            unselectedFontSize: 10,
            type: bottomNavTheme.type ?? BottomNavigationBarType.fixed, // Use theme type
            // Use theme styles for labels if defined
            selectedLabelStyle: bottomNavTheme.selectedLabelStyle,
            unselectedLabelStyle: bottomNavTheme.unselectedLabelStyle,
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2.0),
                  child: Icon(Icons.home_outlined),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2.0),
                  child: Icon(Icons.home),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2.0),
                  child: Icon(Icons.chat_bubble_outline_rounded),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2.0),
                  child: Icon(Icons.chat_bubble_rounded),
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2.0),
                  child: Icon(Icons.person_outline_rounded),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2.0),
                  child: Icon(Icons.person_rounded),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
