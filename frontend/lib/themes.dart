import 'package:flutter/material.dart';

// --- Light Theme ---
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.green,
  scaffoldBackgroundColor: const Color(0xFFE8F5E9), // A very light green
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    elevation: 2.0,
  ),
  cardColor: Colors.white,
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.grey[850]), // Darker grey for better readability
    bodyMedium: TextStyle(color: Colors.grey[700]),
    titleLarge: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    labelLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), // For buttons
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.green,
    ),
  ),
  iconTheme: const IconThemeData(
    color: Colors.green,
  ),
  dividerColor: Colors.grey.shade300,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.green,
    brightness: Brightness.light,
    accentColor: Colors.greenAccent.shade400, // A slightly more vibrant accent
    cardColor: Colors.white,
    backgroundColor: const Color(0xFFE8F5E9),
  ).copyWith(
    surface: Colors.white,
    onSurface: Colors.black87,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onBackground: Colors.black87,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.green; // Thumb color when on
      }
      return Colors.grey.shade200; // Thumb color when off (lighter grey)
    }),
    trackColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.green.withOpacity(0.5); // Track color when on
      }
      return Colors.grey.shade400; // Track color when off (medium grey)
    }),
    trackOutlineColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.transparent;
      }
      return Colors.grey.shade500; // Border for the track when off
    }),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white, // White background for light theme
    selectedItemColor: Colors.green,       // Green for selected item
    unselectedItemColor: Colors.grey.shade600, // Grey for unselected items
    elevation: 8.0,
    showUnselectedLabels: true, // Or false based on your preference
    type: BottomNavigationBarType.fixed, // Or shifting
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    unselectedLabelStyle: const TextStyle(fontSize: 12),
  ),
);

// --- Dark Theme ---
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.green.shade300,
  scaffoldBackgroundColor: const Color(0xFF121212), // Standard dark theme background
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF1E1E1E), // Slightly lighter dark surface for AppBar
    foregroundColor: Colors.white.withOpacity(0.87),
    elevation: 2.0,
  ),
  cardColor: const Color(0xFF1E1E1E), // Dark surface color for cards
  dividerColor: Colors.white.withOpacity(0.12),
  iconTheme: IconThemeData(
    color: Colors.green.shade300,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white.withOpacity(0.87)),
    bodyMedium: TextStyle(color: Colors.white.withOpacity(0.60)),
    titleLarge: TextStyle(color: Colors.white.withOpacity(0.87), fontWeight: FontWeight.bold),
    labelLarge: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w500),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green.shade400,
      foregroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.green.shade300,
    ),
  ),
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.green.shade300,
    onPrimary: Colors.black87,
    secondary: Colors.green.shade400,
    onSecondary: Colors.black87,
    error: Colors.red.shade400,
    onError: Colors.black,
    background: const Color(0xFF121212), // Page background
    onBackground: Colors.white.withOpacity(0.87),
    surface: const Color(0xFF1E1E1E), // Component backgrounds (Cards, Dialogs, BottomNav)
    onSurface: Colors.white.withOpacity(0.87),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C), // Darker fill for text fields
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.38)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.green.shade300, width: 1.5),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.green.shade300; // Thumb color when on
      }
      return Colors.grey.shade400; // Thumb color when off (lighter grey for dark theme)
    }),
    trackColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.green.shade300.withOpacity(0.5); // Track color when on
      }
      return Colors.grey.shade800; // Track color when off (darker grey for dark theme)
    }),
    trackOutlineColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.transparent;
      }
      return Colors.grey.shade700; // Border for the track when off
    }),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: const Color(0xFF1E1E1E), // Dark surface color
    selectedItemColor: Colors.green.shade300,    // Light green for selected item
    unselectedItemColor: Colors.grey.shade500,  // Lighter grey for unselected items
    elevation: 8.0,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.green.shade300),
    unselectedLabelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
  ),
);
