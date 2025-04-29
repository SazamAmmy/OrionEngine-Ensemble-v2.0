import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pie_chart/pie_chart.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _checkAdminAndFetchStats();
  }

  Future<Map<String, dynamic>> _checkAdminAndFetchStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isStaff = prefs.getBool('is_staff') ?? false;

    if (!isStaff) {
      throw Exception("Access Denied: Not an admin");
    }

    return await _fetchUserStats();
  }

  Future<Map<String, dynamic>> _fetchUserStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/admin/user-stats/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    else if (response.statusCode == 429) {   // 🚀 Handle rate limit
      throw Exception('Rate limit exceeded. Please slow down and try again.');
    }
    else {
      throw Exception('Failed to load statistics');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFFBF1), Color(0xFFDDF6E3)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.green));
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                  ),
                );
              } else if (!snapshot.hasData) {
                return const Center(child: Text('No Data'));
              }

              final stats = snapshot.data!;
              final int adminUsers = stats['admin_users'];
              final int superAdminUsers = stats['super_admin_users'];
              final int regularUsers = stats['normal_users'];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card with Background Image
                    Container(
                      padding: const EdgeInsets.all(30),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/profile_bg_image.png'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.7), BlendMode.dstATop),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.green),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            // Removed 'const' here
                            child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.green.shade800),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Admin Dashboard",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    // Removed 'const' here
                                    Icon(Icons.supervised_user_circle, size: 18, color: Colors.green.shade800),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Manage and View Users",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "User Statistics",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: PieChart(
                        dataMap: {
                          "Admin Users (${adminUsers})": adminUsers.toDouble(),
                          "Super Admin Users (${superAdminUsers})": superAdminUsers.toDouble(),
                          "Regular Users (${regularUsers})": regularUsers.toDouble(),
                        },
                        animationDuration: const Duration(milliseconds: 1000),
                        chartLegendSpacing: 32,
                        chartRadius: MediaQuery.of(context).size.width / 1.7,
                        colorList: const [
                          Color(0xFF5cb85c),
                          Color(0xFF90ee90),
                          Color(0xFF4db6ac),
                        ],
                        initialAngleInDegree: 0,
                        centerText: null,
                        chartType: ChartType.ring,
                        ringStrokeWidth: 40,

                        legendOptions: const LegendOptions(
                          showLegendsInRow: true,
                          legendPosition: LegendPosition.bottom,
                          showLegends: true,
                          legendShape: BoxShape.circle,
                          legendTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        chartValuesOptions: const ChartValuesOptions(
                          showChartValueBackground: false,
                          showChartValues: true,
                          showChartValuesInPercentage: true,
                          showChartValuesOutside: false,
                          decimalPlaces: 1,
                          chartValueStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/user_ip_log');
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text("View User IP Logs"),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}