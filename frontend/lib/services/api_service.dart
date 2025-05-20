import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sustainableapp/auth_service.dart';
import 'package:flutter/material.dart';

class ApiService {
  static Future<http.Response> get(String url) async {
    return _authenticatedRequest(() async {
      final token = await AuthService.getValidAccessToken();
      return http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    });
  }

  static Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    return _authenticatedRequest(() async {
      final token = await AuthService.getValidAccessToken();
      return http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    });
  }

  static Future<http.Response> _authenticatedRequest(Future<http.Response> Function() requestFunc) async {
    http.Response response = await requestFunc();

    if (response.statusCode == 401) {
      final refreshed = await AuthService.refreshToken();
      if (!refreshed) {
        await _forceLogout();
        throw Exception("Session expired. Please log in again.");
      }
      response = await requestFunc();
    }

    return response;
  }

  static Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Add global navigation or logout handling if needed
  }
}
