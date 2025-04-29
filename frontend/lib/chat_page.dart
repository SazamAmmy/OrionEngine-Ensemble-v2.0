import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialTipHandled) {
      final tip = ModalRoute.of(context)?.settings.arguments as String?;
      if (tip != null && tip.isNotEmpty) {
        _controller.clear();
        _messages.add({
          "role": "user",
          "text": tip,
          "timestamp": DateTime.now().toIso8601String()
        });
        _sendMessage(initial: true, message: tip);
        _initialTipHandled = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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

  String formatAsMarkdown(String input) {
    final regex = RegExp(r'(^|\n)([^:\n]+):');
    return input.replaceAllMapped(regex, (match) {
      final prefix = match.group(1) ?? '';
      final label = match.group(2) ?? '';
      return '$prefix$label:';
    });
  }


  Future<void> _sendMessage({bool initial = false, String? message}) async {
    final userMessage = initial ? message! : _controller.text.trim();
    if (userMessage.isEmpty) return;

    if (!initial) {
      setState(() {
        _messages.add({
          "role": "user",
          "text": userMessage,
          "timestamp": DateTime.now().toIso8601String()
        });
        _isLoading = true;
      });
      _controller.clear();
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    final chatHistory = _messages.map((msg) {
      return {
        "role": msg["role"] == "user" ? "user" : "model",
        "parts": msg["text"]
      };
    }).toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        setState(() {
          _messages.add({
            "role": "model",
            "text": "⚠️ You're not logged in. Please login first.",
            "timestamp": DateTime.now().toIso8601String()
          });
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      final response = await http.post(
        Uri.parse('https://direct-frog-amused.ngrok-free.app/api/ai/chat/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"chat_history": chatHistory}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiReply = data['ai_response'] ?? "No response from EcoGenie.";

        setState(() {
          _messages.add({
            "role": "model",
            "text": aiReply,
            "timestamp": DateTime.now().toIso8601String()
          });
        });
      }
      else if (response.statusCode == 429) {   // 🚀 Handle rate limit error
        setState(() {
          _messages.add({
            "role": "model",
            "text": "⏳ Rate limit exceeded. Please wait and try again later.",
            "timestamp": DateTime.now().toIso8601String()
          });
        });
      }
      else {
        setState(() {
          _messages.add({
            "role": "model",
            "text": "❌ Error ${response.statusCode}",
            "timestamp": DateTime.now().toIso8601String()
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "model",
          "text": "❌ Exception: ${e.toString()}",
          "timestamp": DateTime.now().toIso8601String()
        });
      });
    }

    setState(() {
      _isLoading = false;
    });

    _scrollToBottom();
    _focusNode.requestFocus();
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message["role"] == "user";
    final time = DateFormat('hh:mm a').format(DateTime.parse(message["timestamp"]));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            const CircleAvatar(radius: 18, backgroundColor: Colors.green, child: Icon(Icons.eco, color: Colors.white, size: 18)),
          if (!isUser) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.green[100] : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(message["text"], style: const TextStyle(fontSize: 15))
                      : MarkdownBody(
                    data: formatAsMarkdown(message["text"].trim()),
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: const TextStyle(fontSize: 15, height: 1.4),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                      listBullet: const TextStyle(fontSize: 14),
                      code: const TextStyle(fontFamily: 'monospace', backgroundColor: Color(0xFFEFEFEF)),
                    ),
                    selectable: true,
                  ),
                ),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 10),
          if (isUser)
            const CircleAvatar(radius: 18, backgroundColor: Colors.green, child: Icon(Icons.person, color: Colors.white, size: 18)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        // Background image decoration
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          // Use a Stack to place a semi-transparent layer over the image
          child: Stack(
            children: [
              // Layer for messages and header/input area with reduced opacity
              Container(
                color: Colors.white.withOpacity(0.8), // Adjust opacity for desired transparency
                child: Column(
                  children: [
                    // Header - Removed previous background color
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.green),
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacementNamed(context, '/main');
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "🌿 Ask EcoGenie AI",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildMessage(_messages[index]),
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(),
                      ),
                    // Input area - Removed previous background color
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              autofocus: true,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: InputDecoration(
                                hintText: "Type your question...",
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                                filled: true,
                                fillColor: Colors.white, // Keep TextField fill color as white
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: Colors.green.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: Colors.green.shade600, width: 1.4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.green,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _isLoading ? null : _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}