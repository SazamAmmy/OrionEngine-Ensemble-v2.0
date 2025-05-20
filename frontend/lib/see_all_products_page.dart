import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:sustainableapp/services/api_service.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:sustainableapp/theme_provider.dart'; // Import ThemeProvider
import 'product_details_page.dart';
import 'package:sustainableapp/main.dart'; // Required for routeObserver

// It's highly recommended to remove these page-level constants
// and rely solely on the central Theme in themes.dart for styling.
// const Color kPrimaryGreen = Color(0xFF2E7D32);
// ... and other constants ...

class SeeAllProductsPage extends StatefulWidget {
  final List<Map<String, String>> products;

  const SeeAllProductsPage({super.key, required this.products});

  @override
  State<SeeAllProductsPage> createState() => _SeeAllProductsPageState();
}

class _SeeAllProductsPageState extends State<SeeAllProductsPage> with RouteAware {
  List<Map<String, String>> displayedProducts = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    displayedProducts = List.from(widget.products);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  Future<void> _fetchProductsBySearch(String query) async {
    if (query
        .trim()
        .isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            displayedProducts = List.from(widget.products);
            isLoading = false;
          });
        }
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
    });

    List<Map<String, String>> fetchedProducts = [];
    try {
      const url = 'https://direct-frog-amused.ngrok-free.app/api/recommendations/';
      final response = await ApiService.post(
        url,
        body: {'query': query.trim()},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['products'] != null && data['products'] is List) {
          fetchedProducts = List<Map<String, String>>.from(
            (data['products'] as List).map((item) {
              if (item is Map) {
                return {
                  'title': item['title']?.toString() ?? 'Untitled Product',
                  'description': item['description']?.toString() ??
                      'No description available.',
                  'link': item['site-link']?.toString() ?? '',
                  'image': item['image-link']?.toString() ?? '',
                };
              }
              return {};
            }).where((product) => product.isNotEmpty),
          );
        } else {
          fetchedProducts = [];
        }
      } else if (response.statusCode == 429) {
        fetchedProducts = [];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rate limit for search. Please slow down.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      } else {
        debugPrint("Search: Unexpected status code ${response.statusCode}");
        fetchedProducts = [];
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("Error searching products: $e");
      fetchedProducts = [];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          displayedProducts = fetchedProducts;
          isLoading = false;
        });
      }
    });
  }

  Widget _buildProductCard(BuildContext context, ThemeData theme,
      ColorScheme colorScheme, TextTheme textTheme,
      Map<String, String> product) {
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailsPage(product: product)),
        );
      },
      child: Card(
        elevation: 3.0,
        shadowColor: Colors.black.withOpacity(0.1),
        // Generic shadow
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0)),
        color: theme.cardColor,
        // Theme-aware
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
              child: (product['image'] != null && product['image']!.isNotEmpty)
                  ? Image.network(
                product['image']!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 120,
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    // Theme-aware
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2.0,
                        color: colorScheme.secondary, // Theme-aware
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      height: 120,
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      // Theme-aware
                      child: Icon(Icons.image_not_supported_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 30), // Theme-aware
                    ),
              )
                  : Container(
                height: 120,
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                // Theme-aware
                child: Icon(
                    Icons.eco_outlined, color: colorScheme.onSurfaceVariant,
                    size: 30), // Theme-aware
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['title'] ?? 'Product',
                      style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface), // Theme-aware
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.arrow_forward_ios_rounded, size: 14,
                          color: colorScheme.onSurfaceVariant.withOpacity(
                              0.7)), // Theme-aware
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridViewShimmer(BuildContext context, ThemeData theme) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Shimmer.fromColors(
      baseColor: themeProvider.isDarkMode ? Colors.grey[800]! : Colors
          .grey[300]!, // Theme-aware
      highlightColor: themeProvider.isDarkMode ? Colors.grey[700]! : Colors
          .grey[100]!, // Theme-aware
      child: GridView.builder(
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            color: theme.cardColor, // Shimmer background
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.cardColor, // Shimmer element
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14,
                            width: double.infinity,
                            color: theme.cardColor),
                        const SizedBox(height: 6),
                        Container(height: 14, width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.3, color: theme.cardColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'All AI Recommendations',
            style: theme.appBarTheme.titleTextStyle ??
                textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
          ),
          backgroundColor: theme.appBarTheme.backgroundColor ??
              colorScheme.primary,
          elevation: theme.appBarTheme.elevation ?? 2.0,
          iconTheme: theme.appBarTheme.iconTheme ??
              IconThemeData(color: colorScheme.onPrimary),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search sustainable products...',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(
                      Icons.search, color: colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: colorScheme.outlineVariant, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: colorScheme.primary, width: 1.5),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                        Icons.clear, color: colorScheme.onSurfaceVariant),
                    onPressed: () {
                      _searchController.clear();
                      _fetchProductsBySearch('');
                      _searchFocusNode.unfocus();
                    },
                  )
                      : null,
                ),
                onSubmitted: (value) {
                  _fetchProductsBySearch(value);
                  _searchFocusNode.unfocus();
                },
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? _buildGridViewShimmer(context, theme)
                    : displayedProducts.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 60,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? "No products to display."
                            : "No products found for '${_searchController
                            .text}'.",
                        style: textTheme.bodyLarge
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  itemCount: displayedProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final product = displayedProducts[index];
                    return _buildProductCard(
                        context, theme, colorScheme, textTheme, product);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
