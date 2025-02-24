import 'package:flutter/material.dart';
import 'package:sustainableapp/chat_page.dart';
import 'package:sustainableapp/profile_page.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0; // Default to 0 to prevent invalid index

  final List<Widget> pages = [
    HomePage(),
    ChatPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _validateCurrentIndex();
  }

  // Ensure currentIndex is always valid
  void _validateCurrentIndex() {
    if (currentIndex >= pages.length) {
      setState(() {
        currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'), //
        ],
        currentIndex: currentIndex,
        onTap: (index) {
          //  Prevent invalid index selection
          if (index >= 0 && index < pages.length) {
            setState(() {
              currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green, // Icon color when selected
        unselectedItemColor: Colors.grey, // Icon color when not selected
      ),
    );
  }
}
