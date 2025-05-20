import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sustainableapp/services/api_service.dart';
import 'dart:convert';
import 'package:pie_chart/pie_chart.dart'; // For the pie chart
import 'package:sustainableapp/theme_provider.dart'; // Import ThemeProvider

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
    _statsFuture = _checkAdminAndFetchStats();
  }

  // Checks admin status and fetches user statistics.
  Future<Map<String, dynamic>> _checkAdminAndFetchStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isStaff = prefs.getBool('is_staff') ?? false;

    if (!isStaff) {
      throw Exception("Access Denied: You do not have administrative privileges.");
    }
    return _fetchUserStats();
  }

  // Fetches user statistics from the API.
  Future<Map<String, dynamic>> _fetchUserStats() async {
    const url = 'https://direct-frog-amused.ngrok-free.app/api/admin/user-stats/';
    try {
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to load statistics (Error ${response.statusCode})');
      }
    } catch (e) {
      // Catch network errors or other exceptions during the API call.
      throw Exception('Failed to connect or parse data: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // final textTheme = theme.textTheme; // Defined but not used directly, using theme.textTheme instead for brevity below

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Theme-aware
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary)); // Theme-aware
          } else if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error.toString().replaceFirst("Exception: ", ""));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildErrorState(context, "No statistics data found.");
          }

          // Data is available, build the dashboard.
          final stats = snapshot.data!;
          final int totalUsers = (stats['admin_users'] as int? ?? 0) +
              (stats['super_admin_users'] as int? ?? 0) +
              (stats['normal_users'] as int? ?? 0);

          return CustomScrollView(
            slivers: [
              _buildDashboardAppBar(context, totalUsers),
              _buildStatsCardsSliver(context, stats),
              _buildPieChartSliver(context, stats),
              _buildActionsSliver(context),
              const SliverToBoxAdapter(child: SizedBox(height: 30)), // Bottom padding
            ],
          );
        },
      ),
    );
  }

  // Builds the error state UI.
  Widget _buildErrorState(BuildContext context, String errorMessage) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 60), // Theme-aware
            const SizedBox(height: 20),
            Text(
              "Oops! Something went wrong",
              style: textTheme.headlineSmall?.copyWith(color: colorScheme.error, fontSize: 20), // Theme-aware
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage,
              style: textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4, color: colorScheme.onErrorContainer), // Theme-aware
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Try Again"),
              onPressed: () {
                if(mounted){
                  setState(() {
                    _statsFuture = _checkAdminAndFetchStats();
                  });
                }
              },
              // ElevatedButton style is handled by theme.elevatedButtonTheme
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16,),
              label: const Text("Go Back"),
              onPressed: () => Navigator.of(context).pop(),
              // TextButton style is handled by theme.textButtonTheme
            )
          ],
        ),
      ),
    );
  }

  // Builds the main AppBar for the dashboard.
  SliverAppBar _buildDashboardAppBar(BuildContext context, int totalUsers) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return SliverAppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.primary, // Theme-aware
      foregroundColor: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary, // Theme-aware
      pinned: true,
      expandedHeight: 160.0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        centerTitle: false,
        title: Text(
          "Admin Dashboard",
          style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 18) ?? textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontSize: 18), // Theme-aware
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeProvider.isDarkMode
                  ? [colorScheme.surface, colorScheme.surface.withOpacity(0.7)] // Dark mode gradient
                  : [colorScheme.primary, Color.lerp(colorScheme.primary, Colors.black, 0.35)!], // Light mode gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Platform Overview",
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.85), fontSize: 16), // Theme-aware
                ),
                const SizedBox(height: 4),
                Text(
                  "$totalUsers Total Users",
                  style: textTheme.headlineMedium?.copyWith(color: colorScheme.onPrimary), // Theme-aware
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds individual stat cards.
  Widget _buildStatCard(BuildContext context, String title, int count, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2.5,
      shadowColor: Colors.black.withOpacity(0.1), // Generic shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: theme.cardColor, // Theme-aware
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(child: Text(title, style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant))), // Theme-aware
                Icon(icon, color: colorScheme.primary, size: 28), // Theme-aware
              ],
            ),
            Text(
              count.toString(),
              style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold), // Theme-aware
            ),
          ],
        ),
      ),
    );
  }

  // Builds the sliver containing stat cards.
  Widget _buildStatsCardsSliver(BuildContext context, Map<String, dynamic> stats) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      sliver: SliverGrid.count(
        crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: MediaQuery.of(context).size.width > 700 ? 1.4 : 1.2,
        children: <Widget>[
          _buildStatCard(context, "Admin Users", stats['admin_users'] as int? ?? 0, Icons.shield_rounded),
          _buildStatCard(context, "Super Admins", stats['super_admin_users'] as int? ?? 0, Icons.star_rounded),
          _buildStatCard(context, "Regular Users", stats['normal_users'] as int? ?? 0, Icons.people_alt_rounded),
        ],
      ),
    );
  }

  // Builds the sliver containing the pie chart.
  Widget _buildPieChartSliver(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final dataMap = {
      "Admin": (stats['admin_users'] as int? ?? 0).toDouble(),
      "Super Admin": (stats['super_admin_users'] as int? ?? 0).toDouble(),
      "Regular": (stats['normal_users'] as int? ?? 0).toDouble(),
    };

    final filteredDataMap = Map<String, double>.fromEntries(
        dataMap.entries.where((entry) => entry.value > 0)
    );

    if (filteredDataMap.isEmpty) {
      return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text("No user data for chart.", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))), // Theme-aware
          )
      );
    }

    final List<Color> colorList = [ // These colors might need adjustment for dark theme contrast
      colorScheme.primary,
      colorScheme.secondary,
      theme.brightness == Brightness.dark ? Colors.orange.shade300 : Colors.orange.shade700,
      theme.brightness == Brightness.dark ? Colors.blue.shade300 : Colors.blue.shade600,
      theme.brightness == Brightness.dark ? Colors.purple.shade300 : Colors.purple.shade600,
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Card(
          elevation: 2.5,
          shadowColor: Colors.black.withOpacity(0.1), // Generic shadow
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          color: theme.cardColor, // Theme-aware
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User Distribution", style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)), // Theme-aware
                const SizedBox(height: 24),
                SizedBox(
                  height: 210,
                  child: PieChart(
                    dataMap: filteredDataMap,
                    animationDuration: const Duration(milliseconds: 900),
                    chartLegendSpacing: 52,
                    chartRadius: MediaQuery.of(context).size.width / 4.5,
                    colorList: colorList, // Theme-aware (conditionally)
                    initialAngleInDegree: -90,
                    chartType: ChartType.ring,
                    ringStrokeWidth: 30,
                    legendOptions: LegendOptions(
                      showLegendsInRow: false,
                      legendPosition: LegendPosition.right,
                      showLegends: true,
                      legendTextStyle: textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500, color: colorScheme.onSurface), // Theme-aware
                    ),
                    chartValuesOptions: ChartValuesOptions(
                      showChartValueBackground: false,
                      showChartValues: true,
                      showChartValuesInPercentage: true,
                      showChartValuesOutside: true,
                      decimalPlaces: 1,
                      chartValueStyle: textTheme.labelSmall!.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold), // Theme-aware
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for creating styled admin tool ListTiles.
  Widget _buildAdminToolTile({
    required BuildContext context, // Pass context for theme access
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: theme.cardColor, // Theme-aware
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Icon(icon, color: colorScheme.primary, size: 26), // Theme-aware
        title: Text(title, style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)), // Theme-aware
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurfaceVariant), // Theme-aware
        onTap: onTap ?? () {
          // Placeholder action for tools not yet implemented
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title feature coming soon!")),
          );
        },
      ),
    );
  }


  // Builds the sliver for admin actions.
  Widget _buildActionsSliver(BuildContext context) {
    final theme = Theme.of(context); // Access theme here for the section title
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text("Admin Tools", style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontSize: 19)), // Theme-aware
          const SizedBox(height: 16),
          _buildAdminToolTile( // Pass context to helper
            context: context,
            icon: Icons.admin_panel_settings_outlined, // Original icon
            title: "View User IP Logs",
            onTap: () {
              Navigator.pushNamed(context, '/user_ip_log');
            },
          ),
          _buildAdminToolTile(
            context: context,
            icon: Icons.manage_accounts_outlined, // Icon for user management
            title: "User Management",
            // onTap: () { Navigator.pushNamed(context, '/admin/user-management'); }
          ),
          _buildAdminToolTile(
            context: context,
            icon: Icons.dynamic_feed_outlined, // Icon for content/feed management
            title: "Content Management",
            // onTap: () { Navigator.pushNamed(context, '/admin/content-management'); }
          ),
          _buildAdminToolTile(
            context: context,
            icon: Icons.analytics_outlined, // Icon for analytics
            title: "System Analytics",
            // onTap: () { Navigator.pushNamed(context, '/admin/analytics'); }
          ),
          _buildAdminToolTile(
            context: context,
            icon: Icons.settings_suggest_outlined, // Icon for app settings
            title: "App Configuration",
            // onTap: () { Navigator.pushNamed(context, '/admin/app-settings'); }
          ),
        ]),
      ),
    );
  }
}
