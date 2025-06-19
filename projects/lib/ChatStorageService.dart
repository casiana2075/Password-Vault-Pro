class ChatStorageService {
  static final ChatStorageService _instance = ChatStorageService._internal();
  factory ChatStorageService() => _instance;
  ChatStorageService._internal();

  List<Map<String, dynamic>> _messages = [];
  bool _showFAQ = true;
  bool _isInitialized = false;

  // Getter for messages
  List<Map<String, dynamic>> get messages => List.from(_messages);

  // Getter for FAQ visibility
  bool get showFAQ => _showFAQ;

  // Getter for initialization status
  bool get isInitialized => _isInitialized;

  // Initialize chat with welcome message if not already initialized
  void initializeChat() {
    if (!_isInitialized) {
      _messages.clear();
      _messages.add({
        'role': 'model',
        'text': 'Hello! 👋 🤖 I\'m the Password Vault Pro virtual assistant. How can I help you today?\n\nYou can select one of the frequently asked questions below or ask me anything else about the app.'
      });
      _showFAQ = true;
      _isInitialized = true;
    }
  }

  // Add a message to the chat
  void addMessage(Map<String, dynamic> message) {
    _messages.add(message);
  }

  // Set FAQ visibility
  void setShowFAQ(bool show) {
    _showFAQ = show;
  }

  // Clear all chat data (called on logout)
  void clearChat() {
    _messages.clear();
    _showFAQ = true;
    _isInitialized = false;
  }

  // Start a new conversation (keeps user logged in but clears chat)
  void startNewConversation() {
    _messages.clear();
    _showFAQ = true;
    _isInitialized = false;
    initializeChat();
  }

  // Get conversation history for API calls
  String getConversationHistory(String systemContext) {
    String conversationHistory = systemContext + '\n\n';

    for (var msg in _messages) {
      if (msg['role'] == 'user') {
        conversationHistory += 'User: ${msg['text']}\n';
      } else if (msg['role'] == 'model') {
        conversationHistory += 'Assistant: ${msg['text']}\n';
      }
    }

    return conversationHistory;
  }
}