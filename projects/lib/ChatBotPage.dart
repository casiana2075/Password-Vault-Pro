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
      '    * **Biometric Authentication:** For enhanced security and convenience, the app supports biometric authentication (e.g., fingerprint, face unlock) to quickly unmask sensitive information like passwords and credit card numbers within the app, and to facilitate quick login. This is handled by `authenticateUserBiometrically.dart` and integrated into `PasswordField.dart` and `EditCreditCardPage.dart`.\n'
      '2.  **Password Management (Main Section):**\n'
      '    * **Viewing Passwords:** The main screen (`Home Page`) displays a list of all saved passwords. Users can search and filter their passwords using the search bar.\n'
      '    * **Adding a Password:**\n'
      '        * Tap the **Floating Action Button (FAB)** with a `+` icon on the `Home Page` (the main password list screen).\n'
      '        * A modal sheet (`AddModal`) will appear.\n'
      '        * Users fill in the **Website**, **Username**, and **Password** fields.\n'
      '        * The **Password** field (`PasswordField`) offers a visibility toggle (which may require biometric authentication to reveal the password) and a button to **Generate a Strong Password** (`password_generator.dart`).\n'
      '        * As the user types the password, real-time **Password Strength Analysis** is provided, showing if the password is Very Weak, Weak, Fair, Good, Strong, or Very Strong.\n'
      '        * Users can also optionally provide a **Logo URL** for the website, or select from suggested logos fetched from the backend (`api_service.dart`).\n'
      '        * Tap the "Save" or "Add Password" button to securely store the new entry.\n'
      '    * **Editing a Password:**\n'
      '        * Tap on any password entry in the list on `Home Page`.\n'
      '        * This navigates to the `Edit Password Page`.\n'
      '        * Users can modify the Website, Username, Password, or Logo URL. The password field behaves similarly to the Add modal, with visibility toggle, generation, and strength analysis.\n'
      '        * There is also an option to **Open Website** and **Copy** password/username to clipboard.\n'
      '        * Tap "Save" to update or "Delete" to remove the password.\n'
      '    * **Security Recommendations (`Security Recommendations Page`):**\n'
      '        * Accessed from the navigation drawer.\n'
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
      '        * Tap the **Floating Action Button (FAB)** with a `+` icon on the `Credit Cards Page`.\n'
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
      '    * Accessed via the navigation drawer.\n'
      '    * Provides assistance and answers questions about how to use the "Password Vault Pro" application.\n'
      '\n\n'
      '**Technical Details (for advanced queries):**\n'
      '    * **Backend:** Node.js Express server (`index.js`) handling API requests.\n'
      '    * **Database:** PostgreSQL, managed by `node-postgres` pool. Data is structured for passwords and credit cards.\n'
      '    * **Encryption:** All sensitive user data (passwords, credit card numbers, CVVs) is encrypted using **AES-256 GCM** before being stored in the database. A unique AES key for each user is generated and stored in Firebase Firestore. This key is derived securely using PBKDF2 with the user\'s Firebase UID as a salt (`encryptionHelper.js`). Data is decrypted upon retrieval.\n'
      '    * **API Service:** `api_service.dart` handles all HTTP requests to the backend, including authentication tokens from Firebase.\n'
      '    * **Self-Signed Certificates:** The app\'s HTTP client (`api_service.dart`) is configured to accept self-signed SSL certificates for development purposes.\n'
      '    * **Logging out:** From `Home Page`, users can log out, which signs them out of Firebase and Google (if applicable) and redirects them to the `Login Page`.'
      'Answer to the user in the language he speaks to you';
  @override
  void initState() {
    super.initState();
    // Only add the user-facing greeting message
    _messages.add({'role': 'model', 'text': 'Hello! 👋 🤖 How can I help you today regarding your Password Vault Pro?'});
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _messageController.clear();
      _isLoading = true;
    });

    try {
      final gemini = Gemini.instance;

      // Build conversation history with system context
      String conversationHistory = _systemContext + '\n\n';

      // Add the conversation history
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

    } catch (e) {
      print('Error sending message to Gemini: $e');
      setState(() {
        _messages.add({'role': 'model', 'text': 'Error: Could not connect to the chatbot. Please try again.'});
      });
    } finally {
      setState(() {
        _isLoading = false;
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
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
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