import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sustainableapp/services/api_service.dart';
import 'dart:convert';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sustainableapp/theme_provider.dart'; // Import ThemeProvider
import 'product_details_page.dart';
import 'see_all_products_page.dart';

// It's highly recommended to remove these page-level constants
// and rely solely on the central Theme in themes.dart for styling.
// const Color kPrimaryGreen = Color(0xFF2E7D32);
// const Color kLightGreenBackground = Color(0xFFE8F5E9);
// const Color kCardBackgroundColor = Colors.white;
// const Color kPrimaryTextColor = Color(0xFF212121);
// const Color kSecondaryTextColor = Color(0xFF757575);
// const Color kAccentColor = Color(0xFF66BB6A);

// const TextStyle kHeadlineTextStyle = TextStyle(
//   fontSize: 22,
//   fontWeight: FontWeight.bold,
//   color: kPrimaryGreen, // Problematic
// );
// ... and other text style constants ...

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
    _loadUserData();
    _fetchData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userName = prefs.getString('username') ?? "Guest";
    });
  }

  Future<void> _fetchData() async {
    if (mounted) {
      setState(() {
        isTipsLoading = true;
        isRecommendationsLoading = true;
      });
    }
    await Future.wait([
      _fetchTipsInternal(),
      _fetchRecommendationsInternal(),
    ]);
  }

  Future<void> _fetchTipsInternal() async {
    String fetchedHomeResponse = "";
    // bool encounteredError = false; // Not directly used to change state here

    const url = 'https://direct-frog-amused.ngrok-free.app/api/userhome/';

    try {
      final response = await ApiService.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        fetchedHomeResponse = data['home_response'] ?? "No tips available today. Check back later!";
      } else if (response.statusCode == 404) {
        // encounteredError = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Your profile is incomplete. Let's finish your survey first."),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/survey');
        });
        fetchedHomeResponse = "";
      } else {
        // encounteredError = true;
        fetchedHomeResponse = response.statusCode == 429
            ? "Too many requests for tips! Please wait a moment."
            : "Oops! Couldn't fetch your eco tips right now.";
      }
    } catch (e) {
      if (!mounted) return;
      // encounteredError = true;
      fetchedHomeResponse = "An error occurred while fetching tips.";
      debugPrint("FetchTips Error: $e");
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            homeResponse = fetchedHomeResponse;
            isTipsLoading = false;
          });
        }
      });
    }
  }

  Future<void> _fetchRecommendationsInternal() async {
    List<Map<String, String>> fetchedAiRecommendations = [];
    // bool encounteredError = false; // Not directly used

    const url = 'https://direct-frog-amused.ngrok-free.app/api/recommendations/';

    try {
      final response = await ApiService.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['products'] != null && data['products'] is List) {
          fetchedAiRecommendations = List<Map<String, String>>.from(
            (data['products'] as List).map((item) {
              if (item is Map) {
                return {
                  'title': item['title']?.toString() ?? 'Untitled Product',
                  'description': item['description']?.toString() ?? 'No description available.',
                  'link': item['site-link']?.toString() ?? '',
                  'image': item['image-link']?.toString() ?? '',
                };
              }
              return {};
            }).where((product) => product.isNotEmpty),
          );
        } else {
          fetchedAiRecommendations = [];
        }
      } else if (response.statusCode == 429) {
        // encounteredError = true;
        fetchedAiRecommendations = List.from(aiRecommendations);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rate limit exceeded for recommendations. Please slow down.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      } else {
        // encounteredError = true;
        debugPrint("Recommendations: Unexpected status code ${response.statusCode}");
        fetchedAiRecommendations = [];
      }
    } catch (e) {
      if (!mounted) return;
      // encounteredError = true;
      debugPrint("FetchRecommendations Error: $e");
      fetchedAiRecommendations = [];
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            aiRecommendations = fetchedAiRecommendations;
            isRecommendationsLoading = false;
          });
        }
      });
    }
  }

  void _navigateToChatWithTip(String tip) {
    Navigator.pushNamed(context, '/chat', arguments: tip);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme
    final colorScheme = theme.colorScheme; // Get the color scheme
    final textTheme = theme.textTheme; // Get text themes
    // final themeProvider = Provider.of<ThemeProvider>(context); // If needed for specific logic

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Theme-aware
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: colorScheme.primary, // Theme-aware
          backgroundColor: theme.scaffoldBackgroundColor, // Theme-aware
          child: CustomScrollView(
            slivers: [
              _buildGreetingHeader(context, theme, colorScheme, textTheme),
              _buildSectionHeaderSliver(
                context,
                theme,
                "✨ EcoGenie AI Picks",
                onSeeAll: aiRecommendations.isNotEmpty
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeeAllProductsPage(products: aiRecommendations),
                    ),
                  );
                }
                    : null,
              ),
              _buildRecommendationsListSliver(context, theme, colorScheme, textTheme),
              _buildSectionHeaderSliver(context, theme, "\uD83C\uDF3F Your Personalized Eco Tips"),
              _buildEcoTipsListSliver(context, theme, colorScheme, textTheme),
              _buildEcoTipsLoadingIndicatorSliver(context, colorScheme),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary.withOpacity(0.8)], // Theme-aware
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3), // Theme-aware
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colorScheme.onPrimary.withOpacity(0.9), // Theme-aware
              child: Icon(Icons.eco_rounded, size: 32, color: colorScheme.primary), // Theme-aware
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, $userName!",
                    style: textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary), // Theme-aware
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ready for a greener day?",
                    style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.9)), // Theme-aware
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeaderSliver(BuildContext context, ThemeData theme, String title, {VoidCallback? onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)), // Theme-aware
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary, // Theme-aware
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text("See All", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)), // Theme-aware
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsListSliver(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    if (isRecommendationsLoading && aiRecommendations.isEmpty) {
      return _buildHorizontalListShimmerSliver(context, theme, itemCount: 3, cardWidthProvider: _getRecommendationCardWidth);
    }
    if (aiRecommendations.isEmpty && !isRecommendationsLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
          child: Center(child: Text("No recommendations for you right now!", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant))), // Theme-aware
        ),
      );
    }
    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommendationsLoading && aiRecommendations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2.0)), // Theme-aware
            ),
          SizedBox(
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 4, top: 8, bottom: 16),
              itemCount: aiRecommendations.length > 5 ? 5 : aiRecommendations.length,
              itemBuilder: (context, index) {
                final product = aiRecommendations[index];
                return _buildRecommendationCard(context, theme, colorScheme, textTheme, product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme, Map<String, String> product) {
    double cardWidth = MediaQuery.of(context).size.width * 0.65;
    if (MediaQuery.of(context).size.width > 600) {
      cardWidth = 300;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product)),
        );
      },
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.cardColor, // Theme-aware
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Generic shadow, consider theme.shadowColor
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: (product['image'] != null && product['image']!.isNotEmpty)
                  ? Image.network(
                product['image']!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150,
                    color: colorScheme.surfaceVariant.withOpacity(0.5), // Theme-aware placeholder
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2.0,
                        color: colorScheme.secondary, // Theme-aware
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: colorScheme.surfaceVariant.withOpacity(0.5), // Theme-aware placeholder
                  child: Icon(Icons.image_not_supported_outlined, color: colorScheme.onSurfaceVariant, size: 40), // Theme-aware
                ),
              )
                  : Container(
                height: 150,
                color: colorScheme.surfaceVariant.withOpacity(0.5), // Theme-aware placeholder
                child: Icon(Icons.eco_outlined, color: colorScheme.onSurfaceVariant, size: 40), // Theme-aware
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      product['title'] ?? 'Product',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface), // Theme-aware
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product['description'] ?? '',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant), // Theme-aware
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalListShimmerSliver(BuildContext context, ThemeData theme, {required int itemCount, required double Function() cardWidthProvider, double height = 290}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return SliverToBoxAdapter(
      child: SizedBox(
        height: height,
        child: Shimmer.fromColors(
          baseColor: themeProvider.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!, // Theme-aware shimmer
          highlightColor: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!, // Theme-aware shimmer
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 4, top: 8, bottom: 16),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final cardWidth = cardWidthProvider();
              return Container(
                width: cardWidth,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor, // Shimmer background should match card
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: theme.cardColor, // Shimmer element color
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(height: 16, width: cardWidth * 0.7, color: theme.cardColor),
                            const SizedBox(height: 8),
                            Container(height: 14, width: cardWidth * 0.9, color: theme.cardColor),
                            const SizedBox(height: 4),
                            Container(height: 14, width: cardWidth * 0.5, color: theme.cardColor),
                          ],
                        ),
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

  double _getRecommendationCardWidth() {
    double cardWidth = MediaQuery.of(context).size.width * 0.65;
    if (MediaQuery.of(context).size.width > 600) {
      cardWidth = 300;
    }
    return cardWidth;
  }

  Widget _buildEcoTipsListSliver(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    if (isTipsLoading && homeResponse.isEmpty) {
      return _buildVerticalListShimmerSliver(context, theme, itemCount: 5);
    }

    final tipsList = homeResponse.split('\n').where((tip) => tip.trim().isNotEmpty).toList();

    if (tipsList.isEmpty && !isTipsLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 48, color: colorScheme.onSurfaceVariant), // Theme-aware
                const SizedBox(height: 16),
                Text(
                  homeResponse.isNotEmpty && (homeResponse.toLowerCase().contains("error") || homeResponse.toLowerCase().contains("oops") || homeResponse.toLowerCase().contains("no tips available"))
                      ? homeResponse
                      : "No eco tips available at the moment.",
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant), // Theme-aware
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
          final tip = tipsList[index];
          final cleanTip = tip.replaceAll('*', '').trim();
          final parts = cleanTip.split(RegExp(r':\s*'));
          final title = parts.length > 1 ? parts[0].trim() : '';
          final body = parts.length > 1 ? parts.sublist(1).join(': ').trim() : cleanTip;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildTipCard(context, theme, colorScheme, textTheme, title, body, cleanTip),
                ),
              ),
            ),
          );
        },
        childCount: tipsList.length,
      ),
    );
  }

  Widget _buildEcoTipsLoadingIndicatorSliver(BuildContext context, ColorScheme colorScheme) {
    if (isTipsLoading && homeResponse.isNotEmpty && homeResponse.split('\n').where((tip) => tip.trim().isNotEmpty).toList().isNotEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2.0)), // Theme-aware
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildTipCard(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme, String title, String body, String fullTip) {
    return Card(
      elevation: 2.0,
      shadowColor: Colors.black.withOpacity(0.1), // Generic shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: theme.cardColor, // Theme-aware
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _navigateToChatWithTip(fullTip),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer.withOpacity(0.5), // Theme-aware
                child: Icon(Icons.lightbulb_outline_rounded, color: colorScheme.primary, size: 22), // Theme-aware
                radius: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary), // Theme-aware
                      ),
                    if (title.isNotEmpty && body.isNotEmpty) const SizedBox(height: 6),
                    if (body.isNotEmpty) Text(body, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)), // Theme-aware
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurfaceVariant.withOpacity(0.7)), // Theme-aware
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalListShimmerSliver(BuildContext context, ThemeData theme, {required int itemCount}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return Shimmer.fromColors(
              baseColor: themeProvider.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!, // Theme-aware shimmer
              highlightColor: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!, // Theme-aware shimmer
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                color: theme.cardColor, // Shimmer background should match card
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: theme.cardColor), // Shimmer element color
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 16, width: MediaQuery.of(context).size.width * 0.4, color: theme.cardColor),
                            const SizedBox(height: 8),
                            Container(height: 14, width: MediaQuery.of(context).size.width * 0.6, color: theme.cardColor),
                            const SizedBox(height: 4),
                            Container(height: 14, width: MediaQuery.of(context).size.width * 0.5, color: theme.cardColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }
}
