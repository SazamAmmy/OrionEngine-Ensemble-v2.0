
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'product_details_page.dart';
import 'see_all_products_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "Guest";
  String homeResponse = "";
  List<Map<String, String>> aiRecommendations = [];
  bool isTipsLoading = true;
  bool isRecommendationsLoading = true;
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchTips();
    _fetchRecommendations();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('username') ?? "Guest";
    });
  }

  // Fetch AI-generated eco tips for the user
  Future<void> _fetchTips() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/userhome/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          homeResponse = data['home_response'] ?? "No tips available.";
          isTipsLoading = false;
        });
      }
      else if (response.statusCode == 429) {   // 🚀 Handle rate limit
        setState(() {
          homeResponse = "Rate limit exceeded. Please slow down.";
          isTipsLoading = false;
        });
      }
      else {
        setState(() {
          homeResponse = "Failed to fetch tips.";
          isTipsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        homeResponse = "An error occurred: $e";
        isTipsLoading = false;
      });
    }
  }


  // Fetch AI product recommendations
  Future<void> _fetchRecommendations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    // Updated: POST request to /recommendations/
    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/recommendations/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['products'] != null) {
          setState(() {
            aiRecommendations = List<Map<String, String>>.from(
              (data['products'] as List).map((item) => {
                'title': item['title']?.toString() ?? '',
                'description': item['description']?.toString() ?? '',
                'link': item['site-link']?.toString() ?? '',
                'image': item['image-link']?.toString() ?? '',
              }),
            );
          });
        }
      } else if (response.statusCode == 429) {
        setState(() {
          aiRecommendations = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rate limit exceeded for recommendations. Please slow down.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        debugPrint("Unexpected status code ${response.statusCode} while fetching recommendations.");
      }
    } catch (e) {
      debugPrint("Error fetching recommendations: $e");
    }

    setState(() => isRecommendationsLoading = false);
  }


  void _navigateToChatWithTip(String tip) {
    Navigator.pushNamed(context, '/chat', arguments: tip);
  }

  Widget _buildShimmerCard() {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 100, color: Colors.white),
            const SizedBox(height: 10),
            Container(height: 16, width: 100, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 14, width: 140, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFFBF1), Color(0xFFDDF6E3)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting header card
                Container(
                  padding: const EdgeInsets.all(30),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 40, color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome, $userName",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.eco, size: 18, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  "How are you feeling today?",
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

                // AI Magic Picks for You
                if (isRecommendationsLoading)
                  Row(children: List.generate(2, (_) => _buildShimmerCard()))
                else if (aiRecommendations.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text("✨ ", style: TextStyle(fontSize: 18)),
                            Text(
                              "EcoGenie AI Recommendations",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SeeAllProductsPage(products: aiRecommendations),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                          ),
                          child: const Text("See All", style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 2),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final cardWidth = screenWidth * 0.7;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 20),
                        child: Row(
                          children: aiRecommendations.take(5).map((product) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailsPage(product: product),
                                  ),
                                );
                              },
                              child: Container(
                                width: cardWidth,
                                height: 300,
                                margin: const EdgeInsets.only(right: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (product['image'] != '')
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.network(
                                          product['image']!,
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      product['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product['description'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                ],

                // Personalized Eco Tips section
                Text(
                  "\uD83C\uDF3F Your Personalized Eco Tips",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 20),

                if (isTipsLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  AnimationLimiter(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: homeResponse.split('\n').length,
                      itemBuilder: (context, index) {
                        final tip = homeResponse.split('\n')[index].trim();
                        if (tip.isEmpty) return const SizedBox.shrink();

                        final cleanTip = tip.replaceAll('*', '');
                        final parts = cleanTip.split(':');
                        final title = parts.length > 1 ? parts[0].trim() : '';
                        final body = parts.length > 1 ? parts.sublist(1).join(':').trim() : cleanTip;

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 400),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: InkWell(
                                onTap: () => _navigateToChatWithTip(cleanTip),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.eco, color: Colors.green.shade700),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (title.isNotEmpty)
                                              Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade800,
                                                ),
                                              ),
                                            if (body.isNotEmpty) const SizedBox(height: 4),
                                            if (body.isNotEmpty)
                                              Text(
                                                body,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  height: 1.4,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
