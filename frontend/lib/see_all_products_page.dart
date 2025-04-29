import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_details_page.dart';

class SeeAllProductsPage extends StatefulWidget {
  final List<Map<String, String>> products;

  const SeeAllProductsPage({Key? key, required this.products}) : super(key: key);

  @override
  _SeeAllProductsPageState createState() => _SeeAllProductsPageState();
}

class _SeeAllProductsPageState extends State<SeeAllProductsPage> {
  List<Map<String, String>> displayedProducts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    displayedProducts = widget.products; // Initially show passed-in products
  }

  Future<void> fetchProducts(String query) async {
    if (query.isEmpty) return; // Don't make a request on empty query

    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/recommendations/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': query, // Send the query inside body
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['products'] != null) {
          setState(() {
            displayedProducts = List<Map<String, String>>.from(
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
          displayedProducts = [];
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All AI Recommendations'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Describe what you want...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onSubmitted: (value) {
                fetchProducts(value); // Now triggers POST request when search submitted
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                itemCount: displayedProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final product = displayedProducts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsPage(product: product),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product['image'] != null && product['image']!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                product['image']!,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(height: 100),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            product['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green.shade800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              product['description'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
