import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:http/http.dart' as http;
import 'package:language_tutor/data/models/chat_messages.dart';
import 'package:language_tutor/features/chat/widgets/chat_bubbles.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // OpenAI API configuration
  static String get _openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _openAiApiUrl =
      'https://api.openai.com/v1/chat/completions';

  // User's vocabulary lists (these could be loaded from a database)
  final List<String> _knownWords = [];

  final List<String> _currentlyLearning = [];

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
    });

    // Simulate AI response after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _simulateAIResponse(text);
    });

    _scrollToBottom();
  }

  void _simulateAIResponse(String userMessage) async {
    // Show typing indicator
    setState(() {
      _messages.add(
        ChatMessage(
          text: "Thinking...",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });

    try {
      ChatMessage response = await _generateResponse(userMessage);

      // Remove typing indicator and add actual response
      setState(() {
        _messages.removeLast(); // Remove "Thinking..." message
        _messages.add(response);
      });
    } catch (e) {
      // Remove typing indicator and show error
      setState(() {
        _messages.removeLast(); // Remove "Thinking..." message
        _messages.add(
          ChatMessage(
            text:
                "Mi dispiace, c'è stato un errore. (Sorry, there was an error.) Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }

    _scrollToBottom();
  }

  String _extractJsonBlock(String rawResponse) {
    final jsonStart = rawResponse.indexOf('{');
    final jsonEnd = rawResponse.lastIndexOf('}');
    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      return rawResponse.substring(jsonStart, jsonEnd + 1);
    }
    return rawResponse; // fallback
  }

  Future<ChatMessage> _generateResponse(String userMessage) async {
    if (_openAiApiKey.isEmpty || _openAiApiKey == 'your_openai_api_key_here') {
      // Fallback response when API key is not configured
      return ChatMessage(
        text: _getFallbackResponse(userMessage),
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    try {
      final systemPrompt = '''
    You are an AI language tutor helping a user learn Italian using English as a supporting language.

    The user has a growing vocabulary. You will be given two lists:
    - `known_words`: These are words the user already knows well. Use them freely in your responses.
    - `currently_learning`: These are words the user is actively practicing. Use them often and provide helpful reinforcement through examples and context.
    Do not introduce these words as new flashcards — the user already knows them.

    You may introduce **new words** sparingly (up to 2–3 per response), only if appropriate for the user's current level.
    When introducing a new word, you **must**:
    1. Embed it inline using **exactly this format**, no exceptions:
      [**italian_word**](flashcard:english_translation)

    ❗ Do NOT use: plain bold, parentheses, or italics. Only use the exact `[**word**](flashcard:meaning)` format so the app can recognize it.
    ❗ If the user asks for a new word return a new flashcard not a plain text response use the formatting that is given above.
    
    2. Then also include the same word in the `flashcards` list below, with context.

    This lets the app render the word as tappable text and store it for spaced repetition.
    ❗ So do use the inline format as if it was the actual word else you have the word doubled in the response.

    You can also provide grammar notes to help the user understand the context of the words used. In these grammar notes, explain the usage of the new words in sentences, their conjugation, or any relevant grammatical rules.
    1. To do this, use the following format: 
       [**italien_sentence**](grammar:english_explanation)
    2. Then also include the same sentence in the `grammar_notes` list below, with an explanation.

    This lets the app render a grammar note below your resonse and store it for later review.

    Each response must be returned as a JSON object with the following structure:
    {
      "reply": "Your response text here, mixing Italian and English, using [**italian_word**](flashcard:translation) syntax for new vocabulary.",
      "flashcards": [
        { "italian": "new_word", "english": "translation", "context": "Sentence where it was used" }
      ],
      "grammar_notes": [
        { "sentence": "Italian sentence", "explanation": "Short grammar explanation" }
      ]
    }

    Avoid translating or re-teaching `known_words` or `currently_learning` words keep them in italian and mark them as if there where a flashcard.
    Encourage natural conversation, offer corrections if needed, and always stay supportive and context-aware.
    Return only a valid JSON object, with no introduction, no markdown blocks, no explanation — only valid raw JSON like this:
''';

      final response = await http.post(
        Uri.parse(_openAiApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {
              'role': 'assistant',
              'content':
                  'known_words: [${_knownWords.join(', ')}], currently_learning: [${_currentlyLearning.join(', ')}]',
            },
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 250,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final raw = data['choices'][0]['message']['content'];
        print('Raw response: $raw');
        final cleaned = _extractJsonBlock(raw);
        final responseJson = jsonDecode(cleaned);
        return _formatResponse(responseJson);
      } else {
        throw Exception('API call failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling OpenAI API: $e');
      return ChatMessage(
        text: _getFallbackResponse(userMessage),
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  ChatMessage _formatResponse(Map<String, dynamic> data) {
    ChatMessage message = ChatMessage(
      text: data['reply'] ?? '',
      isUser: false,
      timestamp: DateTime.now(),
    );

    if (data['flashcards'] != null) {
      message.flashcards = data['flashcards'].map<Map<String, String>>((
        flashcard,
      ) {
        return Map<String, String>.from(flashcard);
      }).toList();
    }
    if (data['grammar_notes'] != null) {
      message.grammarNotes = data['grammar_notes'].map<Map<String, String>>((
        note,
      ) {
        return Map<String, String>.from(note);
      }).toList();
    }

    return message;
  }

  String _getFallbackResponse(String userMessage) {
    return '''There seem to be some issues with the OpenAI API key configuration.''';
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

  Widget _buildMessage(ChatMessage message) {
    if (message.isUser) {
      return userCatBubble(text: message.text);
    }
    Widget text = _buildText(message);
    return aiChatBubble(message: message, context: context, text: text);
  }

  Widget _buildText(ChatMessage message) {
    final pattern = RegExp(r'\[\*\*(.*?)\*\*\]\(flashcard:(.*?)\)');
    final matches = pattern.allMatches(message.text);

    int currentIndex = 0;
    List<Widget> widgets = [];

    for (final match in matches) {
      final matchStart = match.start;
      final matchEnd = match.end;

      if (currentIndex < matchStart) {
        final normalText = message.text.substring(currentIndex, matchStart);
        widgets.add(Text(normalText, style: const TextStyle(fontSize: 16)));
      }

      final word = match.group(1)!;
      final translation = match.group(2)!;

      widgets.add(
        CustomPopup(
          content: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(translation, style: const TextStyle(fontSize: 14)),
          ),
          child: GestureDetector(
            child: Text(
              word,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      currentIndex = matchEnd;
    }

    if (currentIndex < message.text.length) {
      widgets.add(
        Text(
          message.text.substring(currentIndex),
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return Wrap(spacing: 4, runSpacing: 4, children: widgets);
  }

  Widget _buildTextComposer() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, -1),
            blurRadius: 4,
            color: Colors.black12,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _handleSubmitted,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              FloatingActionButton(
                onPressed: () => _handleSubmitted(_textController.text),
                mini: true,
                backgroundColor: Colors.blue.shade600,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Tutor Chat'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask me anything about language learning',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
