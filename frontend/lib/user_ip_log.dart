import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sustainableapp/services/api_service.dart';
import 'dart:convert';
import 'package:sustainableapp/theme_provider.dart'; // Import ThemeProvider


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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
    _checkAdminAndFetchLogs();
  }

  Future<void> _checkAdminAndFetchLogs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    isAdmin = prefs.getBool('is_staff') ?? false;
    if (!isAdmin) {
      setState(() => isLoading = false);
      return;
    }

    const url = 'https://direct-frog-amused.ngrok-free.app/api/admin/user-ip-logs/';

    try {
      final response = await ApiService.get(url);
      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          userLogs = data['logs'] ?? [];
          isLoading = false;
        });
      }
      else if (response.statusCode == 429) {
        _showErrorSnackbar("Rate limit exceeded. Please wait and try again later.");
        if(mounted) setState(() => isLoading = false);
      }
      else {
        String errorMessage = "Failed to fetch logs. Please try again.";
        if (data != null && data['message'] != null) {
          errorMessage = data['message'];
        } else if (response.reasonPhrase != null && response.reasonPhrase!.isNotEmpty) {
          errorMessage = "Failed to fetch logs: ${response.reasonPhrase}";
        }
        _showErrorSnackbar(errorMessage);
        if(mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      _showErrorSnackbar("Error occurred: ${e.toString()}");
      if(mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context); // Access theme for SnackBar color
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error, // Theme-aware error color
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Theme-aware
        appBar: AppBar(
          title: const Text("User IP Logs"),
          backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface, // Theme-aware
          foregroundColor: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface, // Theme-aware
          elevation: theme.appBarTheme.elevation ?? 1,
          titleTextStyle: theme.appBarTheme.titleTextStyle ?? textTheme.titleLarge?.copyWith(color: colorScheme.onSurface), // Theme-aware
        ),
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)), // Theme-aware
      );
    }
    if (!isAdmin) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Theme-aware
        appBar: AppBar(
          title: const Text("User IP Logs"),
          backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface, // Theme-aware
          foregroundColor: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface, // Theme-aware
          elevation: theme.appBarTheme.elevation ?? 1,
          titleTextStyle: theme.appBarTheme.titleTextStyle ?? textTheme.titleLarge?.copyWith(color: colorScheme.onSurface), // Theme-aware
        ),
        body: Center(child: Text("Access Denied", style: textTheme.titleLarge?.copyWith(color: colorScheme.error))), // Theme-aware
      );
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Theme-aware
      appBar: AppBar(
        title: const Text("User IP Logs"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface, // Theme-aware
        foregroundColor: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface, // Theme-aware
        elevation: theme.appBarTheme.elevation ?? 1,
        centerTitle: true,
        titleTextStyle: theme.appBarTheme.titleTextStyle ?? textTheme.titleLarge?.copyWith(color: colorScheme.onSurface), // Theme-aware
      ),
      body: userLogs.isEmpty
          ? Center(child: Text("No logs available.", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant))) // Theme-aware
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
              color: theme.cardColor, // Theme-aware
              child: ListTile(
                leading: Icon(Icons.network_check, color: colorScheme.secondary), // Theme-aware
                title: Text("${log['username'] ?? 'Unknown User'} - ${_formatIP(log)}", style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)), // Theme-aware
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Endpoint: ${log['endpoint'] ?? 'Unknown'}", style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)), // Theme-aware
                    Text("Timestamp: ${_formatTimestamp(log)}", style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)), // Theme-aware
                    if(log['user_agent'] != null) Text("Agent: ${log['user_agent'].split(' ')[0]}...", style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)) // Theme-aware
                  ].where((w) => w != null).cast<Widget>().toList(),
                ),
                trailing: TextButton(
                  onPressed: () {
                    _showErrorSnackbar("View details not implemented yet for ${log['username'] ?? 'user'}");
                  },
                  child: Text("View Details", style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)), // Theme-aware
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
