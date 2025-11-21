import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

class ChatPage extends StatefulWidget {
  final String token;
  const ChatPage({super.key, required this.token});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  late WebSocketChannel _channel;
  final List<Map<String, dynamic>> _messages = [];
  final String _currentUser = "flutter_user"; // can be dynamic

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      // Load chat history from API
      final history = await ApiService.fetchChatHistory(token: widget.token);
      if (mounted) {
        setState(() {
          _messages.addAll(history);
          _isLoading = false;
        });
      }

      // Setup WebSocket
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://127.0.0.1:8000/ws/chat/'),
      );

      _channel.stream.listen((data) {
        final jsonData = json.decode(data);
        if (mounted) {
          setState(() {
            _messages.add({
              'sender': jsonData['sender'],
              'message': jsonData['message'],
            });
          });
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error initializing chat: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _channel.sink.close();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = {'sender': _currentUser, 'message': text};

    // Send via WebSocket
    _channel.sink.add(json.encode(message));

    // Save message via API
    final res = await ApiService.sendMessage(
      token: widget.token,
      message: text,
      sender: _currentUser,
    );

    if (mounted) {
      if (res['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Failed to send message")),
        );
      }

      setState(() {
        _messages.add(message);
      });

      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                // Header
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6EC6FF), Color(0xFF0066CC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const SafeArea(
                    child: Text(
                      "Public Chat",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Chat content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isSelf = msg['sender'] == _currentUser;
                              return Align(
                                alignment: isSelf
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    gradient: isSelf
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF001F3F),
                                              Color(0xFF004AAD)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : const LinearGradient(
                                            colors: [
                                              Color(0xFFE0E0E0),
                                              Color(0xFFF5F5F5)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['sender'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelf
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        msg['message'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isSelf ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Input box
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                minLines: 1,
                                maxLines: 5,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: "Type a message...",
                                  hintStyle:
                                      const TextStyle(color: Colors.black45),
                                  filled: true,
                                  fillColor: Colors.grey.shade200,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF001F3F), Color(0xFF004AAD)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "Send",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
