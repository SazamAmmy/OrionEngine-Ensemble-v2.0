import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const refreshUrl = 'https://direct-frog-amused.ngrok-free.app/api/token/refresh/';

  // Call this to always get a valid access token
  static Future<String?> getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    // Try test API or decode JWT to check expiration here if needed

    final success = await refreshToken();
    if (success) {
      accessToken = prefs.getString('access_token');
    }

    return accessToken;
  }

  // Refresh token logic
  static Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse(refreshUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      prefs.setString('access_token', data['access']);
      if (data.containsKey('refresh')) {
        prefs.setString('refresh_token', data['refresh']);
      }
      return true;
    }
    return false;
  }
}
