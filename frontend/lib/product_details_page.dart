import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sustainableapp/main.dart'; // Required for routeObserver

// It's highly recommended to remove these page-level constants
// and rely solely on the central Theme in themes.dart for styling.
// const Color kPrimaryGreen = Color(0xFF2E7D32);
// const Color kLightGreenBackground = Color(0xFFE8F5E9);
// const Color kPrimaryTextColor = Color(0xFF212121);
// const Color kAccentColor = Color(0xFF66BB6A);
// ... and text style constants ...

class ProductDetailsPage extends StatefulWidget {
  final Map<String, String> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> with RouteAware {
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

  void _launchURL(BuildContext context, String urlString) async {
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No website link available for this product.')),
      );
      return;
    }

    final Uri? uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $urlString');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the website: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final String title = widget.product['title'] ?? 'Product Details';
    final String description = widget.product['description'] ?? 'No description available.';
    final String imageUrl = widget.product['image'] ?? '';
    final String productLink = widget.product['link'] ?? '';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Theme-aware
        appBar: AppBar(
          title: Text(
              title,
              style: theme.appBarTheme.titleTextStyle ?? textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary), // Theme-aware
              overflow: TextOverflow.ellipsis
          ),
          backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.primary, // Theme-aware
          elevation: theme.appBarTheme.elevation ?? 2.0,
          iconTheme: theme.appBarTheme.iconTheme ?? IconThemeData(color: colorScheme.onPrimary), // Theme-aware
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.network(
                      imageUrl,
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: 250,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          height: 250,
                          color: colorScheme.surfaceVariant.withOpacity(0.5), // Theme-aware
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
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 250,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5), // Theme-aware
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant, size: 60), // Theme-aware
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 250,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5), // Theme-aware
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Icon(Icons.eco_outlined, color: colorScheme.onSurfaceVariant, size: 80), // Theme-aware
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(color: colorScheme.onBackground, fontWeight: FontWeight.bold), // Theme-aware
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onBackground, height: 1.5), // Theme-aware
              ),
              const SizedBox(height: 32),
              if (productLink.isNotEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchURL(context, productLink),
                    icon: Icon(Icons.open_in_new_rounded, size: 20, color: colorScheme.onPrimary), // Theme-aware
                    label: Text('View on Website', style: TextStyle(color: colorScheme.onPrimary)), // Theme-aware
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary, // Theme-aware
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600), // Theme-aware
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 2.0,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
