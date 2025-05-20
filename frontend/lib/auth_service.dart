import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  static const refreshUrl = 'https://direct-frog-amused.ngrok-free.app/api/token/refresh/';

  /// Checks if token is expired
  static bool isAccessTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  /// Returns access token (even if expired)
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Refreshes token using refresh token
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

    // Logout if refresh is invalid
    await prefs.clear();
    return false;
  }

  /// Automatically gets valid access token (tries refresh)
  static Future<String?> getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    if (accessToken == null || isAccessTokenExpired(accessToken)) {
      final refreshed = await refreshToken();
      if (!refreshed) return null;
      accessToken = prefs.getString('access_token');
    }

    return accessToken;
  }
}
