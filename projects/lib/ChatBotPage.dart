import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // Store messages {role: 'user'/'model', text: 'message'}
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add an initial greeting from the bot
    _messages.add({'role': 'model', 'text': 'Hello! 👋 🤖 How can I help you today regarding your password manager?'});
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _messageController.clear();
      _isLoading = true; // Show loading indicator
    });

    try {
      final gemini = Gemini.instance;

      // Method 1: Simple text generation (recommended for basic chat)
      final response = await gemini.text(text);

      setState(() {
        _messages.add({'role': 'model', 'text': response?.output ?? 'No response'});
      });

      // Alternative Method 2: If you need chat history context, try this instead:
      /*
      // Build conversation history as a single string
      String conversationHistory = '';
      for (var msg in _messages) {
        if (msg['role'] == 'user') {
          conversationHistory += 'User: ${msg['text']}\n';
        } else if (msg['role'] == 'model') {
          conversationHistory += 'Assistant: ${msg['text']}\n';
        }
      }
      conversationHistory += 'User: $text\nAssistant: ';

      final response = await gemini.text(conversationHistory);

      setState(() {
        _messages.add({'role': 'model', 'text': response?.output ?? 'No response'});
      });
      */

    } catch (e) {
      print('Error sending message to Gemini: $e');
      setState(() {
        _messages.add({'role': 'model', 'text': 'Error: Could not connect to the chatbot. Please try again.'});
      });
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Vault Pro Chatbot'),
        backgroundColor: Color.fromARGB(255, 55, 114, 255),
        foregroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 1,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true, // Show latest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index]; // Display in correct order
                final isUser = message['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      message['text'],
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 10),
                  Text('Thinking...'),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null, // Allow multiple lines
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  color: Color.fromARGB(255, 55, 114, 255),
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage, // Disable when loading
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}