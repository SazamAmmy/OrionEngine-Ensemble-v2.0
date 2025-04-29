import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserIPLogPage extends StatefulWidget {
  const UserIPLogPage({super.key});

  @override
  State<UserIPLogPage> createState() => _UserIPLogPageState();
}

class _UserIPLogPageState extends State<UserIPLogPage> {
  List<dynamic> userLogs = [];
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAndFetchLogs();
  }

  Future<void> _checkAdminAndFetchLogs() async {
    final prefs = await SharedPreferences.getInstance();
    isAdmin = prefs.getBool('is_staff') ?? false;
    if (!isAdmin) {
      setState(() => isLoading = false);
      return;
    }

    String? token = prefs.getString('access_token');
    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/admin/user-ip-logs/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          userLogs = data['logs'] ?? [];
          isLoading = false;
        });
      }
      else if (response.statusCode == 429) {
        _showErrorSnackbar("Rate limit exceeded. Please wait and try again later.");
        setState(() => isLoading = false);
      }
      else {
        String errorMessage = "Failed to fetch logs. Please try again.";
        if (data != null && data['message'] != null) {
          errorMessage = data['message'];
        } else if (response.reasonPhrase != null && response.reasonPhrase!.isNotEmpty) {
          errorMessage = "Failed to fetch logs: ${response.reasonPhrase}";
        }
        _showErrorSnackbar(errorMessage);
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showErrorSnackbar("Error occurred: ${e.toString()}");
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  String _formatIP(dynamic log) {
    if (log == null) return 'N/A';
    if (log['ipv4_address'] != null && log['ipv4_address'] is String) return log['ipv4_address'];
    if (log['ipv6_address'] != null && log['ipv6_address'] is String) return log['ipv6_address'];
    if (log['ip_address'] != null && log['ip_address'] is String) return log['ip_address'];
    return 'Unknown IP';
  }

  String _formatTimestamp(dynamic log) {
    if (log == null || log['timestamp'] == null || !(log['timestamp'] is String)) return 'Unknown Date';
    String timestampStr = log['timestamp'];
    try {
      DateTime dateTime = DateTime.parse(timestampStr).toLocal();
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      print("Error parsing timestamp $timestampStr: $e");
      return timestampStr.split('.')[0].replaceAll('T', ' ');
    }
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F7EF),
        appBar: AppBar(
          title: const Text("User IP Logs"),
          backgroundColor: const Color(0xFFF1F7EF),
          foregroundColor: Colors.green.shade800,
          elevation: 1,
          titleTextStyle: TextStyle(
            color: Colors.green.shade800,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F7EF),
        appBar: AppBar(
          title: const Text("User IP Logs"),
          backgroundColor: const Color(0xFFF1F7EF),
          foregroundColor: Colors.green.shade800,
          elevation: 1,
          titleTextStyle: TextStyle(
            color: Colors.green.shade800,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: const Center(child: Text("Access Denied", style: TextStyle(fontSize: 18, color: Colors.red))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF1F7EF),
      appBar: AppBar(
        title: const Text("User IP Logs"),
        backgroundColor: const Color(0xFFF1F7EF),
        foregroundColor: Colors.green.shade800,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.green.shade800,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: userLogs.isEmpty
          ? const Center(child: Text("No logs available.", style: TextStyle(fontSize: 18, color: Colors.black54)))
          : ListView.builder(
        itemCount: userLogs.length,
        itemBuilder: (context, index) {
          final log = userLogs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
              child: ListTile(
                leading: Icon(Icons.network_check, color: Colors.blueGrey),
                title: Text("${log['username'] ?? 'Unknown User'} - ${_formatIP(log)}", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Endpoint: ${log['endpoint'] ?? 'Unknown'}"),
                    Text("Timestamp: ${_formatTimestamp(log)}"),
                    if(log['user_agent'] != null) Text("Agent: ${log['user_agent'].split(' ')[0]}...")
                  ].where((w) => w != null).cast<Widget>().toList(),
                ),
                trailing: TextButton(
                  onPressed: () {
                    _showErrorSnackbar("View details not implemented yet for ${log['username'] ?? 'user'}");
                  },
                  child: Text("View Details", style: TextStyle(fontSize: 12, color: Colors.green[700])),
                ),
                isThreeLine: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
            ),
          );
        },
      ),
    );
  }
}