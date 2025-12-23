import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart'; // ADD THIS IMPORT
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Import your real API service
import 'api_service.dart';

class SupportChatPage extends StatefulWidget {
  final String token;
  final String? userName;
  final String? userAvatar;

  const SupportChatPage({
    Key? key,
    required this.token,
    this.userName = "You",
    this.userAvatar,
  }) : super(key: key);

  @override
  _SupportChatPageState createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _typingTimer;
  bool _isSupportTyping = false;
  File? _imageFile;

  // Flower wave colors
  static const List<Color> _flowerColors = [
    Color(0xFFFFB6C1), // Light pink
    Color(0xFFFFD700), // Gold
    Color(0xFF98FB98), // Pale green
    Color(0xFF87CEEB), // Sky blue
    Color(0xFFDDA0DD), // Plum
    Color(0xFFFFA07A), // Light salmon
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _startSupportTypingSimulation();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startSupportTypingSimulation() {
    _typingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_messages.isNotEmpty && Random().nextDouble() < 0.3) {
        setState(() {
          _isSupportTyping = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isSupportTyping = false;
            });
          }
        });
      }
    });
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    // Try to load from local storage first
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('chat_messages_${widget.token}') ?? '[]';
      final List<dynamic> localMessages = json.decode(messagesJson);
      
      if (localMessages.isNotEmpty) {
        // Convert to proper format
        final List<Map<String, dynamic>> messages = localMessages.map((msg) {
          return {
            'id': msg['id']?.toString() ?? '',
            'content': msg['content']?.toString() ?? '',
            'sender': msg['sender']?.toString() ?? 'user',
            'timestamp': msg['timestamp'] != null 
                ? DateTime.parse(msg['timestamp'].toString())
                : DateTime.now(),
            'image_path': msg['image_path'],
            'image_base64': msg['image_base64'],
            'type': msg['type'] ?? 'text',
            'is_sent': msg['is_sent'] ?? true,
            'is_error': msg['is_error'] ?? false,
            'server_id': msg['server_id'],
          };
        }).toList();
        
        // Sort messages by timestamp (oldest first for proper display)
        messages.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
        
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        
        print("📱 Loaded ${messages.length} messages from local storage");
        
        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
        
        return;
      }
    } catch (e) {
      print("❌ Error loading local messages: $e");
    }

    // Try to load from REAL API
    try {
      final chatHistory = await ApiService.fetchChatHistory(token: widget.token);
      if (chatHistory.isNotEmpty) {
        // Sort messages by timestamp (oldest first)
        chatHistory.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
        
        setState(() {
          _messages = chatHistory.map((msg) {
            return {
              ...msg,
              'is_sent': true,
              'is_error': false,
              'type': 'text',
            };
          }).toList();
          _isLoading = false;
        });
        
        // Save to local storage
        await _saveAllMessagesLocally(_messages);
        
        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
        
        return;
      }
    } catch (e) {
      print("❌ Chat history API error: $e");
      
      // If API fails, show empty chat with welcome message
      final welcomeMessage = {
        'id': '1',
        'content': 'Hello! 👋 How can I help you today?',
        'sender': 'support',
        'timestamp': DateTime.now(),
        'type': 'text',
        'is_sent': true,
        'is_error': false,
      };
      
      setState(() {
        _messages = [welcomeMessage];
        _isLoading = false;
      });
      
      // Save welcome message locally
      await _saveAllMessagesLocally([welcomeMessage]);
      
      // Scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
      return;
    }

    // If API returns empty, show welcome message
    final welcomeMessage = {
      'id': '1',
      'content': 'Hello! 👋 How can I help you today?',
      'sender': 'support',
      'timestamp': DateTime.now(),
      'type': 'text',
      'is_sent': true,
      'is_error': false,
    };
    
    setState(() {
      _messages = [welcomeMessage];
      _isLoading = false;
    });

    // Save welcome message to local storage
    await _saveAllMessagesLocally([welcomeMessage]);

    // Scroll to bottom after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Generate a unique ID for the message
    final messageId = DateTime.now().millisecondsSinceEpoch;
    final timestamp = DateTime.now();

    // Add user message to UI immediately
    final userMessage = {
      'id': 'user_$messageId',
      'content': message,
      'sender': 'user',
      'timestamp': timestamp,
      'type': 'text',
      'is_sent': false,
      'is_error': false,
    };

    setState(() {
      _messages.add(userMessage); // Add to end (most recent)
      _messageController.clear();
      _isSending = true;
    });

    // Save immediately to local storage
    await _saveMessageLocally(userMessage);

    // Scroll to bottom to show new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Find the message index for updating
    final messageIndex = _messages.indexWhere((msg) => msg['id'] == 'user_$messageId');
    
    try {
      // Try to send via REAL API
      final result = await ApiService.sendMessage(
        token: widget.token,
        message: message,
        sender: 'user',
      );

      if (result['success'] == true) {
        print("✅ Message sent successfully via API");
        
        // Update message status
        if (messageIndex != -1) {
          final updatedMessage = {
            ..._messages[messageIndex],
            'is_sent': true,
            'server_id': result['message_id'] ?? result['id'] ?? '',
          };
          
          setState(() {
            _messages[messageIndex] = updatedMessage;
          });
          
          // Update in local storage
          await _updateMessageLocally(updatedMessage);
        }
        
        // Get real support response from API if available
        if (result.containsKey('support_response') && result['support_response'] != null) {
          final supportResponse = result['support_response']?.toString() ?? _getSupportResponse(message);
          
          final supportMessageId = DateTime.now().millisecondsSinceEpoch;
          final supportMessage = {
            'id': 'support_$supportMessageId',
            'content': supportResponse,
            'sender': 'support',
            'timestamp': DateTime.now(),
            'type': 'text',
            'is_sent': true,
            'is_error': false,
          };

          setState(() {
            _messages.add(supportMessage);
            _isSending = false;
          });

          // Save support response locally
          await _saveMessageLocally(supportMessage);

          // Scroll to show new message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } else {
          // No support response from API, just stop sending indicator
          setState(() {
            _isSending = false;
          });
        }
        
      } else {
        print("⚠️ API send failed: ${result['message']}");
        
        // Mark as error
        if (messageIndex != -1) {
          final errorMessage = {
            ..._messages[messageIndex],
            'is_error': true,
            'error_message': result['message'] ?? 'Failed to send',
          };
          
          setState(() {
            _messages[messageIndex] = errorMessage;
            _isSending = false;
          });
          
          // Update in local storage
          await _updateMessageLocally(errorMessage);
        }
      }
    } catch (e) {
      print("❌ API send error: $e");
      
      // Mark as error
      if (messageIndex != -1) {
        final errorMessage = {
          ..._messages[messageIndex],
          'is_error': true,
          'error_message': 'Network error',
        };
        
        setState(() {
          _messages[messageIndex] = errorMessage;
          _isSending = false;
        });
        
        // Update in local storage
        await _updateMessageLocally(errorMessage);
      }
    }
  }

  String _getSupportResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('deposit') || lowerMessage.contains('recharge')) {
      return 'For deposits, please use the deposit section in the app. Minimum deposit is 10 Br. Would you like me to guide you through the process? 💰';
    } else if (lowerMessage.contains('balance')) {
      return 'You can check your current balance from the wallet section. Your funds are safe with us! 💳';
    } else if (lowerMessage.contains('help') || lowerMessage.contains('support')) {
      return 'I\'m here to help! Please describe your issue and I\'ll assist you immediately. 🤝';
    } else if (lowerMessage.contains('thank')) {
      return 'You\'re welcome! 😊 Is there anything else I can help you with today?';
    } else if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello! Welcome to our support chat. How can I assist you today? 👋';
    } else {
      return 'Thank you for your message. Our support team will review your query and get back to you shortly. In the meantime, you can check our FAQ section for quick answers. 📚';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      String? imageBase64;
      
      if (kIsWeb) {
        // For web, convert to base64
        final bytes = await image.readAsBytes();
        imageBase64 = base64Encode(bytes);
      } else {
        // For mobile, store the file path
        _imageFile = File(image.path);
      }
      
      // Create image message
      final messageId = DateTime.now().millisecondsSinceEpoch;
      final imageMessage = {
        'id': 'image_$messageId',
        'content': '📸 Image',
        'sender': 'user',
        'timestamp': DateTime.now(),
        'image_path': kIsWeb ? null : image.path,
        'image_base64': imageBase64,
        'type': 'image',
        'is_sent': false,
        'is_error': false,
      };

      setState(() {
        _messages.add(imageMessage); // Add to end (most recent)
      });

      // Save image message locally
      await _saveMessageLocally(imageMessage);

      // Scroll to show new message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      try {
        // Try to send image via REAL API
        final result = await ApiService.sendMessage(
          token: widget.token,
          message: '📸 Image', // You might need a different API endpoint for images
          sender: 'user',
        );

        if (result['success'] == true) {
          // Update message status to sent
          final messageIndex = _messages.indexWhere((msg) => msg['id'] == 'image_$messageId');
          if (messageIndex != -1) {
            final updatedMessage = {
              ..._messages[messageIndex],
              'is_sent': true,
            };
            
            setState(() {
              _messages[messageIndex] = updatedMessage;
            });
            
            await _updateMessageLocally(updatedMessage);
          }
        }
      } catch (e) {
        print("❌ Error sending image: $e");
      }
    }
  }

  // Add message deletion function
  Future<void> _deleteMessage(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('chat_messages_${widget.token}') ?? '[]';
      final List<dynamic> messages = json.decode(messagesJson);
      
      // Remove message from local storage
      messages.removeWhere((msg) => msg['id'] == messageId);
      
      await prefs.setString('chat_messages_${widget.token}', json.encode(messages));
      
      // Remove message from UI
      setState(() {
        _messages.removeWhere((msg) => msg['id'] == messageId);
      });
      
      print("🗑️ Message deleted: $messageId");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message deleted',
            style: GoogleFonts.poppins(), // FIXED
          ),
        ),
      );
    } catch (e) {
      print("❌ Error deleting message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting message: $e',
            style: GoogleFonts.poppins(), // FIXED
          ),
        ),
      );
    }
  }

  // Helper methods for local storage
  Future<void> _saveMessageLocally(Map<String, dynamic> message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('chat_messages_${widget.token}') ?? '[]';
      final List<dynamic> messages = json.decode(messagesJson);
      
      // Add new message
      messages.add({
        'id': message['id'],
        'content': message['content'],
        'sender': message['sender'],
        'timestamp': message['timestamp'] is DateTime
            ? message['timestamp'].toIso8601String()
            : DateTime.now().toIso8601String(),
        'image_path': message['image_path'],
        'image_base64': message['image_base64'],
        'type': message['type'] ?? 'text',
        'is_sent': message['is_sent'] ?? false,
        'is_error': message['is_error'] ?? false,
        'server_id': message['server_id'],
        'error_message': message['error_message'],
      });
      
      // Save back (limit to last 100 messages)
      final limitedMessages = messages.length > 100 ? messages.sublist(messages.length - 100) : messages;
      await prefs.setString('chat_messages_${widget.token}', json.encode(limitedMessages));
      print("💾 Message saved locally: ${message['id']}");
    } catch (e) {
      print("❌ Error saving message locally: $e");
    }
  }

  Future<void> _updateMessageLocally(Map<String, dynamic> message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('chat_messages_${widget.token}') ?? '[]';
      final List<dynamic> messages = json.decode(messagesJson);
      
      // Find and update the message
      final index = messages.indexWhere((msg) => msg['id'] == message['id']);
      if (index != -1) {
        messages[index] = {
          'id': message['id'],
          'content': message['content'],
          'sender': message['sender'],
          'timestamp': message['timestamp'] is DateTime
              ? message['timestamp'].toIso8601String()
              : DateTime.now().toIso8601String(),
          'image_path': message['image_path'],
          'image_base64': message['image_base64'],
          'type': message['type'] ?? 'text',
          'is_sent': message['is_sent'] ?? false,
          'is_error': message['is_error'] ?? false,
          'server_id': message['server_id'],
          'error_message': message['error_message'],
        };
        
        await prefs.setString('chat_messages_${widget.token}', json.encode(messages));
        print("🔄 Message updated locally: ${message['id']}");
      }
    } catch (e) {
      print("❌ Error updating message locally: $e");
    }
  }

  Future<void> _saveAllMessagesLocally(List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesToSave = messages.map((msg) {
        return {
          'id': msg['id'],
          'content': msg['content'],
          'sender': msg['sender'],
          'timestamp': msg['timestamp'] is DateTime
              ? msg['timestamp'].toIso8601String()
              : DateTime.now().toIso8601String(),
          'image_path': msg['image_path'],
          'image_base64': msg['image_base64'],
          'type': msg['type'] ?? 'text',
          'is_sent': msg['is_sent'] ?? true,
          'is_error': msg['is_error'] ?? false,
          'server_id': msg['server_id'],
          'error_message': msg['error_message'],
        };
      }).toList();
      
      // Limit to last 100 messages
      final limitedMessages = messagesToSave.length > 100 
          ? messagesToSave.sublist(messagesToSave.length - 100)
          : messagesToSave;
      
      await prefs.setString('chat_messages_${widget.token}', json.encode(limitedMessages));
      print("💾 Saved ${limitedMessages.length} messages to local storage");
    } catch (e) {
      print("❌ Error saving all messages: $e");
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUser) {
    final content = message['content']?.toString() ?? '';
    final timestamp = message['timestamp'] is DateTime 
        ? message['timestamp'] as DateTime
        : DateTime.parse(message['timestamp'].toString());
    final hasImage = message['type'] == 'image';
    final isSent = message['is_sent'] ?? true;
    final isError = message['is_error'] ?? false;
    final imagePath = message['image_path']?.toString();
    final imageBase64 = message['image_base64']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: GestureDetector(
        onLongPress: () {
          _showMessageOptions(message);
        },
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.headset_mic, color: Colors.white, size: 18),
                ),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFDCF8C6) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                      border: isError ? Border.all(color: Colors.red, width: 1) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Support Agent',
                              style: GoogleFonts.poppins( // FIXED
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        if (hasImage)
                          GestureDetector(
                            onTap: () {
                              _showImagePreview(message);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: _buildImageWidget(message),
                              ),
                            ),
                          )
                        else
                          Text(
                            content,
                            style: GoogleFonts.poppins(fontSize: 16), // FIXED
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('hh:mm a').format(timestamp),
                              style: GoogleFonts.poppins( // FIXED
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (isUser)
                              Row(
                                children: [
                                  if (isError)
                                    Tooltip(
                                      message: message['error_message'] ?? 'Failed to send',
                                      child: const Icon(Icons.error_outline, color: Colors.red, size: 12),
                                    ),
                                  if (!isError && !isSent)
                                    const Icon(Icons.access_time, color: Colors.grey, size: 12),
                                  if (!isError && isSent)
                                    const Icon(Icons.done_all, color: Colors.green, size: 12),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isUser) const SizedBox(width: 8),
            if (isUser)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0084FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(Map<String, dynamic> message) {
    final imagePath = message['image_path']?.toString();
    final imageBase64 = message['image_base64']?.toString();

    if (kIsWeb && imageBase64 != null) {
      // For web, use base64 image
      try {
        return Image.memory(
          base64Decode(imageBase64),
          width: 200,
          height: 150,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorWidget();
          },
        );
      } catch (e) {
        return _buildImageErrorWidget();
      }
    } else if (!kIsWeb && imagePath != null) {
      // For mobile, check if file exists first
      return FutureBuilder<bool>(
        future: _checkFileExists(imagePath),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              File(imagePath),
              width: 200,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImageErrorWidget();
              },
            );
          } else if (snapshot.hasError) {
            return _buildImageErrorWidget();
          } else {
            // Loading state
            return Container(
              width: 200,
              height: 150,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      );
    } else {
      return _buildImageErrorWidget();
    }
  }

  Future<bool> _checkFileExists(String path) async {
    if (kIsWeb) return false; // Web doesn't support file system
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Widget _buildImageErrorWidget() {
    return Container(
      width: 200,
      height: 150,
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: GoogleFonts.poppins( // FIXED
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(Map<String, dynamic> message) {
    final imagePath = message['image_path']?.toString();
    final imageBase64 = message['image_base64']?.toString();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kIsWeb && imageBase64 != null)
                    InteractiveViewer(
                      child: Image.memory(
                        base64Decode(imageBase64),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error, size: 50, color: Colors.red),
                                const SizedBox(height: 10),
                                Text(
                                  'Image not available',
                                  style: GoogleFonts.poppins(), // FIXED
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else if (!kIsWeb && imagePath != null)
                    FutureBuilder<bool>(
                      future: _checkFileExists(imagePath),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return InteractiveViewer(
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.contain,
                            ),
                          );
                        } else {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error, size: 50, color: Colors.red),
                                const SizedBox(height: 10),
                                Text(
                                  'Image not found',
                                  style: GoogleFonts.poppins(), // FIXED
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, size: 50, color: Colors.red),
                          const SizedBox(height: 10),
                          Text(
                            'Image not available',
                            style: GoogleFonts.poppins(), // FIXED
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    final messageId = message['id'];
    final hasImage = message['type'] == 'image';

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: Text(
                    'View Image',
                    style: GoogleFonts.poppins(), // FIXED
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showImagePreview(message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(
                  'Copy Text',
                  style: GoogleFonts.poppins(), // FIXED
                ),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message['content']?.toString() ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Copied to clipboard',
                        style: GoogleFonts.poppins(), // FIXED
                      ),
                    ),
                  );
                },
              ),
              if (isUser)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Delete Message',
                    style: GoogleFonts.poppins(color: Colors.red), // FIXED
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(messageId);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(), // FIXED
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Message',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold), // FIXED
        ),
        content: Text(
          'Are you sure you want to delete this message?',
          style: GoogleFonts.poppins(), // FIXED
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(), // FIXED
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red), // FIXED
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowerWaveBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: FlowerWavePainter(colors: _flowerColors),
          ),
        ),
        
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    if (!_isSupportTyping) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.headset_mic, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Agent',
                  style: GoogleFonts.poppins( // FIXED
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildTypingDot(0),
                    _buildTypingDot(1),
                    _buildTypingDot(2),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.green[400],
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildFlowerWaveBackground(),
          SafeArea(
            child: Column(
              children: [
                // App bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.headset_mic, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Support Center',
                              style: GoogleFonts.poppins( // FIXED
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Online - Usually replies instantly',
                              style: GoogleFonts.poppins( // FIXED
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.info),
                                      title: Text(
                                        'Chat Info',
                                        style: GoogleFonts.poppins(), // FIXED
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showChatInfo();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.notifications),
                                      title: Text(
                                        'Mute Notifications',
                                        style: GoogleFonts.poppins(), // FIXED
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Notifications muted',
                                              style: GoogleFonts.poppins(), // FIXED
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.clear_all),
                                      title: Text(
                                        'Clear Chat',
                                        style: GoogleFonts.poppins(), // FIXED
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _clearChat();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.report),
                                      title: Text(
                                        'Report Issue',
                                        style: GoogleFonts.poppins(), // FIXED
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _reportIssue();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Chat messages
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: SpinKitFadingCircle(
                            color: _flowerColors[0],
                            size: 50,
                          ),
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isUser = message['sender'] == 'user';
                                return _buildMessageBubble(message, isUser);
                              },
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: _buildTypingIndicator(),
                            ),
                          ],
                        ),
                ),

                // Input area
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_circle, color: _flowerColors[0]),
                        onPressed: _pickImage,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: GoogleFonts.poppins(), // FIXED
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isSending)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: SpinKitCircle(
                            color: _flowerColors[0],
                            size: 24,
                          ),
                        )
                      else
                        IconButton(
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_flowerColors[0], _flowerColors[1]],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                          onPressed: _sendMessage,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChatInfo() {
    final chatId = 'CHAT-${DateTime.now().millisecondsSinceEpoch}';
    final startedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Chat Information',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold), // FIXED
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Support Team: Available 24/7',
              style: GoogleFonts.poppins(), // FIXED
            ),
            Text(
              '• Average Response Time: < 2 minutes',
              style: GoogleFonts.poppins(), // FIXED
            ),
            Text(
              '• Chat ID: $chatId',
              style: GoogleFonts.poppins(), // FIXED
            ),
            Text(
              '• Started: $startedDate',
              style: GoogleFonts.poppins(), // FIXED
            ),
            const SizedBox(height: 8),
            Text(
              '• Messages: ${_messages.length}',
              style: GoogleFonts.poppins(), // FIXED
            ),
            Text(
              '• User: ${widget.userName}',
              style: GoogleFonts.poppins(), // FIXED
            ),
            Text(
              '• Images: ${_messages.where((msg) => msg['type'] == 'image').length}',
              style: GoogleFonts.poppins(), // FIXED
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(), // FIXED
            ),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold), // FIXED
        ),
        content: Text(
          'Are you sure you want to clear all chat messages? This cannot be undone.',
          style: GoogleFonts.poppins(), // FIXED
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(), // FIXED
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('chat_messages_${widget.token}');
                
                setState(() {
                  _messages.clear();
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Chat cleared',
                      style: GoogleFonts.poppins(), // FIXED
                    ),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error clearing chat: $e',
                      style: GoogleFonts.poppins(), // FIXED
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(color: Colors.red), // FIXED
            ),
          ),
        ],
      ),
    );
  }

  void _reportIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Report Issue',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold), // FIXED
        ),
        content: Text(
          'Please describe the issue you\'re experiencing:',
          style: GoogleFonts.poppins(), // FIXED
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(), // FIXED
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Issue reported successfully',
                    style: GoogleFonts.poppins(), // FIXED
                  ),
                ),
              );
            },
            child: Text(
              'Submit',
              style: GoogleFonts.poppins(), // FIXED
            ),
          ),
        ],
      ),
    );
  }
}

class FlowerWavePainter extends CustomPainter {
  final List<Color> colors;

  FlowerWavePainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors[0].withOpacity(0.05),
        colors[1].withOpacity(0.03),
        colors[2].withOpacity(0.02),
        colors[3].withOpacity(0.01),
      ],
    );

    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, size.height),
      Paint()..shader = gradient.createShader(
        Rect.fromLTRB(0, 0, size.width, size.height),
      ),
    );

    final random = Random(42);
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 2 + random.nextDouble() * 4;
      final colorIndex = random.nextInt(colors.length);
      final opacity = 0.1 + random.nextDouble() * 0.2;

      paint.color = colors[colorIndex].withOpacity(opacity);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
      
      for (int j = 0; j < 6; j++) {
        final angle = j * (2 * pi / 6);
        final petalX = x + cos(angle) * (radius * 1.5);
        final petalY = y + sin(angle) * (radius * 1.5);
        canvas.drawCircle(Offset(petalX, petalY), radius * 0.8, paint);
      }
    }

    paint.color = colors[0].withOpacity(0.08);
    final wavePath = Path();
    
    for (double i = 0; i < size.width; i += 20) {
      final waveHeight = sin(i / 50) * 15;
      if (i == 0) {
        wavePath.moveTo(i, size.height * 0.7 + waveHeight);
      } else {
        wavePath.lineTo(i, size.height * 0.7 + waveHeight);
      }
    }
    
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    
    canvas.drawPath(wavePath, paint);

    paint.color = colors[1].withOpacity(0.06);
    final wavePath2 = Path();
    
    for (double i = 0; i < size.width; i += 20) {
      final waveHeight = cos(i / 40 + pi/4) * 10;
      if (i == 0) {
        wavePath2.moveTo(i, size.height * 0.8 + waveHeight);
      } else {
        wavePath2.lineTo(i, size.height * 0.8 + waveHeight);
      }
    }
    
    wavePath2.lineTo(size.width, size.height);
    wavePath2.lineTo(0, size.height);
    wavePath2.close();
    
    canvas.drawPath(wavePath2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}