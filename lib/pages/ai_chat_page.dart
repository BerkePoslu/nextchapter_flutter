import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import '../main.dart';
import '../services/ai_service.dart';
import '../models/book.dart';
import '../services/database_service.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({Key? key}) : super(key: key);

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  List<Book> _userBooks = [];

  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadUserBooks();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserBooks() async {
    try {
      final books = await DatabaseService().getAllBooks();
      setState(() {
        _userBooks = books;
      });
    } catch (e) {
      print('Error loading books: $e');
    }
  }

  void _initializeChat() {
    final welcomeMessage = ChatMessage(
      text:
          "👋 Hallo! Ich bin Ihr persönlicher Bücher-KI-Assistent. Ich kann Ihnen helfen bei:\n\n"
          "📚 Buchempfehlungen basierend auf Ihren gelesenen Büchern\n"
          "💭 Diskussionen über Literatur und Bücher\n"
          "📖 Fragen zu Ihren aktuellen Büchern\n"
          "✨ Tipps zum besseren Lesen und Verstehen\n"
          "🎯 Auswahl des nächsten Buches\n\n"
          "Worüber möchten Sie sprechen?",
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final userMessage = ChatMessage(
      text: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final aiResponse = await _getAIResponse(messageText);

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text:
              "🚫 $e\n\nBitte stellen Sie sicher, dass Sie eine Internetverbindung haben und versuchen Sie es erneut.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  Future<String> _getAIResponse(String userMessage) async {
    try {
      // Context about user's books
      String booksContext = "";
      if (_userBooks.isNotEmpty) {
        final recentBooks = _userBooks.take(10).toList();
        booksContext = "Hier sind einige Bücher des Benutzers:\n";
        for (var book in recentBooks) {
          final progress = (book.progress * 100).round();
          booksContext +=
              "- ${book.title} von ${book.author} ($progress% gelesen)\n";
        }
        booksContext += "\n";
      }

      final prompt =
          """Sie sind ein hilfsreicher Bücher-KI-Assistent für eine Lese-App. 
      
$booksContext

Benutzer-Nachricht: $userMessage

Bitte antworten Sie hilfsreich, freundlich und auf Deutsch. Wenn der Benutzer nach Buchempfehlungen fragt, berücksichtigen Sie seine gelesenen Bücher. Geben Sie konkrete, praktische Ratschläge.""";

      // Use the existing AI service
      final response = await AIService().generateCustomResponse(prompt);

      // Check if response contains error
      if (response.contains('"error"')) {
        throw Exception('KI-Service nicht verfügbar');
      }

      return response;
    } catch (e) {
      throw Exception(
          '❌ KI-Chat-Antwort fehlgeschlagen: Internetverbindung prüfen');
    }
  }

  // REMOVED: Fallback response method - using only real AI now

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

  void _showQuickActions() {
    final quickActions = [
      "Buchempfehlungen für mich",
      "Was soll ich als nächstes lesen?",
      "Tipps zum besseren Lesen",
      "Wie kann ich mehr lesen?",
      "Erkläre mir dieses Genre",
      "Diskutiere mein aktuelles Buch",
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Schnelle Fragen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ...quickActions
                    .map((action) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _messageController.text = action;
                                _sendMessage();
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(action),
                            ),
                          ),
                        ))
                    .toList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KI-Chat'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: _showQuickActions,
              tooltip: 'Schnelle Fragen',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _messages.clear();
                });
                _initializeChat();
              },
              tooltip: 'Chat zurücksetzen',
            ),
          ],
        ),
        body: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),

            // Message input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Icon(
                Icons.psychology,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: message.isUser
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: Icon(
              Icons.psychology,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(right: i < 2 ? 4.0 : 0),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3 +
                                    (0.7 * _typingAnimation.value) *
                                        (i == 0
                                            ? 1.0
                                            : i == 1
                                                ? 0.7
                                                : 0.4)),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Fragen Sie mich etwas über Bücher...',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isTyping ? null : _sendMessage,
                icon: Icon(
                  _isTyping ? Icons.hourglass_empty : Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'gerade eben';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
