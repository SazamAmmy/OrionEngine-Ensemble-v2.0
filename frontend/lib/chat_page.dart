import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:sustainableapp/services/api_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:sustainableapp/main.dart'; // Required for routeObserver
import 'package:sustainableapp/theme_provider.dart'; // Import ThemeProvider
import 'package:url_launcher/url_launcher.dart'; // Added for launching URLs

// --- Styling Constants (These will be replaced by theme-derived values in the build method) ---
// const Color kPrimaryGreen = Color(0xFF2E7D32);
// const Color kUserMessageColor = Color(0xFFDCF8C6);
// const Color kModelMessageColor = Colors.white;
// const Color kPrimaryTextColor = Color(0xFF212121);
// const Color kSecondaryTextColor = Color(0xFF757575);
// const Color kAccentColor = Color(0xFF66BB6A);

// const TextStyle kAppBarTitleTextStyle = TextStyle(
//   fontSize: 20,
//   fontWeight: FontWeight.w600,
//   color: Colors.white,
// );
// const TextStyle kMessageTextStyle = TextStyle(
//   fontSize: 15.5,
//   color: kPrimaryTextColor,
//   height: 1.4,
// );
// const TextStyle kTimestampTextStyle = TextStyle(
//   fontSize: 11.5,
//   color: kSecondaryTextColor,
// );
// const TextStyle kSubtitleTextStyle = TextStyle(
//   fontSize: 13.0,
//   color: kSecondaryTextColor,
// );
// --- End of Styling Constants ---

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> with RouteAware {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late FocusNode _focusNode;
  bool _isLoading = false;
  bool _initialTipHandled = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard on initial load
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route); // Subscribe for route events
    }

    // Handle initial tip passed as argument, only once.
    if (!_initialTipHandled) {
      final tip = ModalRoute.of(context)?.settings.arguments as String?;
      if (tip != null && tip.isNotEmpty) {
        // Add user message for the tip and send it.
        WidgetsBinding.instance.addPostFrameCallback((_) { // Defer state update
          if(mounted) {
            _addMessage("user", tip);
            _sendMessageInternal(tip); // Send the tip as the first message
          }
        });
        _initialTipHandled = true;
      }
    }
  }

  @override
  void dispose() {
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when navigating back to this page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus(); // Ensure keyboard is dismissed
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Adds a message to the local list and triggers a UI update.
  void _addMessage(String role, String text) {
    if(mounted) {
      setState(() {
        _messages.add({
          "role": role,
          "text": text,
          "timestamp": DateTime.now().toIso8601String(),
        });
      });
    }
    _scrollToBottom();
  }

  // Handles sending the message to the API.
  Future<void> _sendMessageInternal(String messageText) async {
    if (messageText.isEmpty) return;

    if(mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Prepare chat history for the API.
    final chatHistory = _messages.map((msg) {
      return {
        "role": msg["role"] == "user" ? "user" : "model",
        "parts": msg["text"] // API expects "parts"
      };
    }).toList();

    try {
      final response = await ApiService.post(
        'https://direct-frog-amused.ngrok-free.app/api/ai/chat/',
        body: {"chat_history": chatHistory},
      );

      if (!mounted) return;

      String aiReplyText;
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        aiReplyText = data['ai_response'] ?? "Sorry, I couldn't process that.";
      } else if (response.statusCode == 429) {
        aiReplyText = "⏳ Looks like I'm a bit busy. Please try again in a moment.";
      } else {
        aiReplyText = "❌ Error ${response.statusCode}: I'm having trouble connecting.";
      }
      _addMessage("model", aiReplyText);

    } catch (e) {
      if (!mounted) return;
      _addMessage("model", "❌ An error occurred: ${e.toString()}");
      debugPrint("SendMessage Error: $e");
    }

    if(mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Triggered by send button or text field submission.
  void _handleSubmittedMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _addMessage("user", text);
      _sendMessageInternal(text);
      _controller.clear();
      // _focusNode.requestFocus(); // Optionally keep focus; often better to let user re-tap.
    }
  }

  // Enhances markdown for specific label patterns like "Tip:", "Benefit:".
  String _formatMarkdownLabels(String input) {
    // Bolds "Label:" patterns at the start of a line or after a newline.
    return input.replaceAllMapped(RegExp(r'(^\s*|\n\s*)([A-Za-z\s]+):(\s*)', multiLine: true), (match) {
      String prefix = match.group(1) ?? '';
      String label = match.group(2)?.trim() ?? '';
      String suffix = match.group(3) ?? '';
      return '$prefix**$label:**$suffix'; // Makes the label bold in Markdown.
    });
  }

  // Handles launching URLs from Markdown links.
  void _launchURL(BuildContext context, String urlString) async {
    if (urlString.isEmpty) return;

    final Uri? uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $urlString');
      if(mounted) { // Check mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link: $urlString')),
        );
      }
    }
  }


  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final bool isUser = message["role"] == "user";
    final String text = message["text"] ?? "";
    final DateTime timestamp = DateTime.parse(message["timestamp"]);

    // Define message bubble colors based on theme
    final Color userMessageBubbleColor = themeProvider.isDarkMode ? colorScheme.primaryContainer.withOpacity(0.7) : const Color(0xFFDCF8C6);
    final Color modelMessageBubbleColor = theme.cardColor; // Use card color for model bubbles, adapts to theme
    final Color userMessageTextColor = themeProvider.isDarkMode ? colorScheme.onPrimaryContainer : Colors.black87;
    final Color modelMessageTextColor = colorScheme.onSurface;


    // Defines the shape and style of message bubbles.
    final BoxDecoration bubbleDecoration = BoxDecoration(
      color: isUser ? userMessageBubbleColor : modelMessageBubbleColor,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isUser ? 18 : 4), // Creates a "tail" effect.
        bottomRight: Radius.circular(isUser ? 4 : 18), // Tail effect.
      ),
      boxShadow: [ // Subtle shadow for depth.
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );

    final TextStyle messageTextStyle = textTheme.bodyLarge!.copyWith(color: isUser ? userMessageTextColor : modelMessageTextColor, height: 1.4);
    final TextStyle timestampTextStyle = textTheme.bodySmall!.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7));


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end, // Aligns avatar with bottom of bubble.
        children: [
          // AI (Model) Avatar
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary, // Theme-aware
              child: Icon(Icons.smart_toy_outlined, color: colorScheme.onPrimary, size: 18), // Changed icon
            ),
          if (!isUser) const SizedBox(width: 8),

          // Message Content
          Flexible( // Allows bubble to take available width without overflowing.
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: bubbleDecoration,
                  child: isUser
                      ? SelectableText(text, style: messageTextStyle) // User messages are plain text.
                      : MarkdownBody( // AI messages can use Markdown.
                    data: _formatMarkdownLabels(text),
                    selectable: true,
                    onTapLink: (text, href, title) { // Handle link taps
                      if (href != null) {
                        _launchURL(context, href);
                      }
                    },
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: messageTextStyle,
                      strong: messageTextStyle.copyWith(fontWeight: FontWeight.bold),
                      listBullet: messageTextStyle.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 15),
                      code: messageTextStyle.copyWith(
                        fontFamily: 'monospace',
                        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5), // Theme-aware
                        color: colorScheme.onSurfaceVariant, // Theme-aware
                      ),
                      a: TextStyle(color: colorScheme.primary, decoration: TextDecoration.underline), // Theme-aware links
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Timestamp display.
                Padding(
                  padding: EdgeInsets.only(right: isUser ? 0 : 5, left: isUser ? 5 : 0),
                  child: Text(
                    DateFormat('hh:mm a').format(timestamp),
                    style: timestampTextStyle,
                  ),
                ),
              ],
            ),
          ),
          // User Avatar (Optional) - Removed for a cleaner look, can be re-added if desired.
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);


    return GestureDetector(
      onTap: () => _focusNode.unfocus(), // Dismiss keyboard on tap outside input.
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make scaffold transparent for the background image.
        appBar: AppBar(
          // Enhanced AppBar title
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology_alt_outlined, color: colorScheme.onPrimary.withOpacity(0.9), size: 22), // Theme-aware
              const SizedBox(width: 10),
              Text("EcoGenie AI", style: theme.appBarTheme.titleTextStyle ?? textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)), // Theme-aware
            ],
          ),
          backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.primary, // Theme-aware
          elevation: theme.appBarTheme.elevation ?? 1.0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary), // Theme-aware
            onPressed: () {
              if (canPop) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/main'); // Fallback navigation.
              }
            },
          ),
        ),
        body: Container( // This container holds the background image.
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg_image.png'), // Consider making this theme-dependent if needed
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea( // SafeArea ensures content is not obscured by system UI.
            child: Container( // This container provides a semi-transparent overlay for readability.
              color: themeProvider.isDarkMode
                  ? Colors.black.withOpacity(0.75) // Darker overlay for dark mode
                  : Colors.white.withOpacity(0.85), // Light overlay for light mode
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _buildMessageBubble(context, _messages[index]),
                    ),
                  ),
                  // Typing indicator displayed when AI is processing.
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                      color: theme.cardColor.withOpacity(0.95), // Theme-aware
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: colorScheme.primary, // Theme-aware
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white /* Or colorScheme.onPrimary */),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text("EcoGenie is typing...", style: textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant)), // Theme-aware
                        ],
                      ),
                    ),

                  // Message Input Area
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor, // Solid background for input area, theme-aware
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, -1),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.08), // Generic shadow, could be theme.shadowColor
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _handleSubmittedMessage(),
                            minLines: 1,
                            maxLines: 5,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface), // Theme-aware text input color
                            decoration: InputDecoration(
                              hintText: "Type your message...",
                              // hintStyle, fillColor, border, focusedBorder are handled by theme.inputDecorationTheme
                              // If not fully handled, you can specify them:
                              // hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                              // fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                              // focusedBorder: OutlineInputBorder(
                              //   borderRadius: BorderRadius.circular(25.0),
                              //   borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.7), width: 1.0),
                              // ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                              filled: true, // Ensure this is true if fillColor is set in InputDecorationTheme
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: BorderSide.none, // Usually covered by InputDecorationTheme
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: colorScheme.primary, // Theme-aware
                          borderRadius: BorderRadius.circular(25),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: _isLoading ? null : _handleSubmittedMessage,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(Icons.send_rounded, color: colorScheme.onPrimary, size: 22), // Theme-aware
                            ),
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
  }
}
