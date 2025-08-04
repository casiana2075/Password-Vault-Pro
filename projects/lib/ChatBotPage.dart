import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:projects/ChatStorageService.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatStorageService _chatStorage = ChatStorageService();
  bool _isLoading = false;

  // Get messages from storage
  List<Map<String, dynamic>> get _messages => _chatStorage.messages;

  // Get FAQ visibility from storage
  bool get _showFAQ => _chatStorage.showFAQ;

  // Frequent questions
  final List<Map<String, String>> _frequentQuestions = [
    {
      'question': '🔐 How to add a new password?',
      'text': 'How do I add a new password to the app?'
    },
    {
      'question': '💳 How to save a credit card?',
      'text': 'How can I add and save credit card information?'
    },
    {
      'question': '🔒 What is biometric authentication?',
      'text': 'How does biometric authentication work in the app?'
    },
    {
      'question': '🛡️ How to check password security?',
      'text': 'Where can I find security recommendations for my passwords?'
    },
    {
      'question': '🔄 How to generate a strong password?',
      'text': 'How can I generate a secure and strong password?'
    },
    {
      'question': '📱 How to authenticate in the app?',
      'text': 'What authentication methods are available?'
    },
    {
      'question': '🔍 How to search saved passwords?',
      'text': 'How can I search and filter my saved passwords?'
    },
    {
      'question': '⚙️ How to edit saved information?',
      'text': 'How can I modify saved passwords or cards?'
    }
  ];

  // Parse markdown-style text to Flutter widgets
  List<TextSpan> _parseMarkdownText(String text) {
    List<TextSpan> spans = [];
    RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');

    int lastIndex = 0;

    for (Match match in boldRegex.allMatches(text)) {
      // Add text before bold
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ));
      }

      // Add bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(fontSize: 16, color: Colors.black87),
      ));
    }

    return spans;
  }

  // System context that will be used for AI but not displayed
  final String _systemContext = 'You are a helpful assistant for "Password Vault Pro," a secure mobile application '
      'designed to manage passwords and credit card information. '
      'Your goal is to guide users on how to use the app\'s features. '
      '\n\n'
      '**App Overview:**\n'
      'This app allows users to securely store, retrieve, manage, and audit their digital credentials. '
      'It focuses on strong security practices, including robust encryption and biometric authentication. '
      '\n\n'
      '**Key Features & How to Use Them:**\n'
      '1.  **Authentication:**\n'
      '    * **Login/Signup:** Users can create an account or log in using email/password via Firebase, or use Google Sign-In. The login page (`Login Page`) handles this. Users can also reset their password if forgotten. Firebase is used for authentication, while actual password/credit card data is stored securely in a custom backend.\n'
      '    * **Biometric Authentication:** For enhanced security and convenience, the app supports biometric authentication (e.g., fingerprint, face unlock) to quickly unmask sensitive information like passwords and credit card numbers within the app, and to facilitate quick login. This is handled by `authenticateUserBiometrically` and integrated into `PasswordField` and `EditCreditCardPage`.\n'
      '2.  **Password Management (Main Section):**\n'
      '    * **Viewing Passwords:** The main screen (`Home Page`) displays a list of all saved passwords. Users can search and filter their passwords using the search bar.\n'
      '    * **Adding a Password:**\n'
      '        * Tap the **Floating Action Button (FAB)** with a `+` icon on the `Home Page` in right top part of screen (the main password list screen).\n'
      '        * A modal sheet (`AddModal`) will appear.\n'
      '        * Users fill in the **Website**, **Username**, and **Password** fields.\n'
      '        * The **Password** field (`PasswordField`) offers a visibility toggle (which may require biometric authentication to reveal the password) and a button to **Generate a Strong Password** (`password_generator.dart`).\n'
      '        * As the user types the password, real-time **Password Strength Analysis** is provided, showing if the password is Very Weak, Weak, Fair, Good, Strong, or Very Strong.\n'
      '        * Users can select from suggested logos fetched from the backend which is displayed in frontend as a dropdown menu. If the user insert its own website link then the image is a default placeholder.(`api_service`).\n'
      '        * Tap the "Save" or "Add Password" button to securely store the new entry.\n'
      '    * **Editing a Password:**\n'
      '        * Tap on any password entry in the list on `Home Page`.\n'
      '        * This navigates to the `Edit Password Page`.\n'
      '        * Users can modify the Website, Username, Password. The password field behaves similarly to the Add modal, with visibility toggle, strong password generation, but without strength analysis.\n'
      '        * There is also an option to **Open Website** which redirect the user outside of the app to the website, but when coming bat a pop-up message appear in which the user is asked if he changed his password outside of the app.\n'
      '        * Tap "Save" to update or "Delete" to remove the password.\n'
      '    * **Security Recommendations (`Security Recommendations Page`):**\n'
      '        * Accessed from the designed section from home page.\n'
      '        * This section helps users identify and fix security weaknesses in their stored passwords.\n'
      '        * It flags:\n'
      '            * **Repeated Passwords:** Shows instances where the same password is used for different accounts.\n'
      '            * **Weak Passwords:** Identifies passwords that are deemed weak by the strength analyzer.\n'
      '            * **Pwned Passwords:** Indicates if a password has been compromised in a data breach (likely checks against a "Have I Been Pwned" like service, though specific API isn\'t in snippets, it\'s part of `password.dart` model).\n'
      '            * **Confusable Domains:** Points out websites with very similar names, which could be typos or phishing risks (uses Levenshtein distance).\n'
      '        * Users can tap on these recommendations to go directly to the `Edit Password Page` to rectify the issue.\n'
      '3.  **Credit Card Management (Accessed via Bottom Navigation Bar):**\n'
      '    * **Viewing Credit Cards:** On the `Home Page`, switch to the "Credit Cards" tab using the bottom navigation bar. This navigates to `Credit Cards Page`.\n'
      '    * **Adding a Credit Card:**\n'
      '        * Tap the **Floating Action Button (FAB)** with a `+` icon on the `Credit Cards Page` right bottom.\n'
      '        * A modal sheet (`AddCreditCardModal.dart`) will appear.\n'
      '        * Users input **Card Holder Name**, **Card Number**, **Expiry Date (MM/YY)**, **CVV**, and optional **Notes**.\n'
      '        * The app dynamically recognizes and allows selection of the **Card Type** (Visa, Mastercard, American Express, Discover, JCB, Diners Club, UnionPay).\n'
      '        * A `CreditCardPreview.dart` widget provides a visual representation of the card as details are entered.\n'
      '        * Input formatters assist with correct formatting for card number and expiry date.\n'
      '        * Tap "Add Card" to save.\n'
      '    * **Editing a Credit Card:**\n'
      '        * Tap on any credit card entry in the list on `Credit Cards Page`.\n'
      '        * This navigates to the `Edit Credit Card Page`.\n'
      '        * Users can modify all details. Card number and CVV can be toggled for visibility, typically requiring biometric authentication.\n'
      '        * Tap "Save Changes" to update or "Delete Card" to remove.\n'
      '4.  **Chatbot (`Chat Bot Page` - this page):**\n'
      '    * Accessed via the floating button from right bottom with chat icon from home page.\n'
      '    * Provides assistance and answers questions about how to use the "Password Vault Pro" application.\n'
      '    * Provides frequently asked questions and a persistent chat by keeping the chat history. Chat history will be deleted when user is going to log out.\n'
      '\n\n'
      '**Technical Details (for advanced queries):**\n'
      '    * **Backend:** Node.js Express server (`index.js`) handling API requests.\n'
      '    * **Database:** PostgreSQL, managed by `node-postgres` pool. Data is structured for passwords and credit cards.\n'
      '    * **Encryption:** All sensitive user data (passwords, credit card numbers, CVVs) is encrypted using **AES-256 GCM** before being stored in the database. A unique AES key for each user is generated and stored in Firebase Firestore. This key is derived securely using PBKDF2 with the user\'s Firebase UID as a salt (`encryptionHelper.js`). Data is decrypted upon retrieval.\n'
      '    * **API Service:** `api_service.dart` handles all HTTPS requests to the backend, including authentication tokens from Firebase.\n'
      '    * **Self-Signed Certificates:** The app\'s HTTPS client (`api_service.dart`) is configured to accept self-signed SSL certificates for development purposes.\n'
      '    * **Logging out:** From `Home Page`, users can log out, which signs them out of Firebase and Google (if applicable) and redirects them to the `Login Page`.'
      'Answer to the user in the language he speaks to you'
      'Respond only to questions directly related to information security, such as password managers, encryption, authentication, secure storage, or similar topics. For any question outside this scope, politely state: "I\'m sorry, I can only answer questions related to information security, such as password managers or similar tools. Please ask a relevant question.'
      'Respond to the user in list step, when he ask about directions within the app, such that he can see easily what he have to do. Otherwise respond normally in a text-structure like.';


  @override
  void initState() {
    super.initState();
    // Initialize chat storage
    _chatStorage.initializeChat();
  }

  void _sendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatStorage.addMessage({'role': 'user', 'text': text});
      if (predefinedText == null) {
        _messageController.clear();
      }
      _isLoading = true;
      _chatStorage.setShowFAQ(false); // Hide FAQ after first interaction
    });

    try {
      final gemini = Gemini.instance;

      // Build conversation history with system context using storage service
      String conversationHistory = _chatStorage.getConversationHistory(_systemContext);
      conversationHistory += 'User: $text\nAssistant: ';

      final response = await gemini.text(conversationHistory);

      setState(() {
        _chatStorage.addMessage({'role': 'model', 'text': response?.output ?? 'No response received'});
      });

    } catch (e) {
      print('Error sending message to Gemini: $e');
      setState(() {
        _chatStorage.addMessage({'role': 'model', 'text': 'Error: Could not connect to chatbot. Please try again.'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startNewConversation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start New Conversation'),
          content: Text('Are you sure you want to start a new conversation? This will clear all current messages.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _chatStorage.startNewConversation();
                  _isLoading = false;
                });
              },
              child: Text(
                'Start New',
                style: TextStyle(color: Color.fromARGB(255, 55, 114, 255)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFAQSection() {
    if (!_showFAQ) return SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
            ),
            itemCount: _frequentQuestions.length,
            itemBuilder: (context, index) {
              final faq = _frequentQuestions[index];
              return InkWell(
                onTap: () => _sendMessage(faq['text']),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 55, 114, 255).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color.fromARGB(255, 55, 114, 255).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      faq['question']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 55, 114, 255),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
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
        actions: [
          if (!_showFAQ && _messages.length > 1)
            IconButton(
              icon: Icon(Icons.help_outline),
              onPressed: () {
                setState(() {
                  _chatStorage.setShowFAQ(true);
                });
              },
              tooltip: 'Show frequently asked questions',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _startNewConversation,
            tooltip: 'Start new conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length + (_showFAQ ? 1 : 0),
              itemBuilder: (context, index) {
                // Show FAQ section at the bottom (top when reversed)
                if (_showFAQ && index == 0) {
                  return _buildFAQSection();
                }

                final messageIndex = _showFAQ ? index - 1 : index;
                final message = _messages[_messages.length - 1 - messageIndex];
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
                    child: RichText(
                      text: TextSpan(
                        children: _parseMarkdownText(message['text']),
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
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  color: Color.fromARGB(255, 55, 114, 255),
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
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