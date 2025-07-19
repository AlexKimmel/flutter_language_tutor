import 'dart:async';
import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart' show Bloc, Emitter;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:language_tutor/data/models/chat_messages.dart';
import 'package:language_tutor/data/models/gramamr_card.dart';
import 'package:language_tutor/features/chat/bloc/chat_repository.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_repository.dart';
import 'package:language_tutor/data/models/flashcard.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ChatRepository _chatRepository = ChatRepository();
  final FlashcardRepository _flashcardRepository = FlashcardRepository();
  final GrammarRepository _grammarRepository = GrammarRepository();

  ChatBloc() : super(ChatLoading()) {
    //print('DEBUG: ChatBloc constructor called - new instance created');
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendUserMessage>(_onSendUserMessage);
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final chatHistory = await _chatRepository.getChatHistory(limit: 100);
      //print('DEBUG: Loaded ${chatHistory.length} messages from database');
      _messages.clear();

      for (var msg in chatHistory) {
        ChatMessage message = ChatMessage.fromMap(msg);
        // print(
        //   'DEBUG: Loading message: ${message.text.substring(0, math.min(50, message.text.length))}...',
        // );
        // Load grammar cards synchronously
        if (message.id != null) {
          final grammarCards = await _grammarRepository
              .getGrammarCardsByMessageId(message.id!);
          message.grammarNotes = grammarCards;
        }
        _messages.add(message);
      }

      //print('DEBUG: Final _messages count: ${_messages.length}');
      emit(ChatLoaded(List.from(_messages)));
    } catch (e) {
      //print('DEBUG: Error loading chat history: $e');
      emit(ChatError('Failed to load chat history: ${e.toString()}'));
    }
  }

  Future<void> _onSendUserMessage(
    SendUserMessage event,
    Emitter<ChatState> emit,
  ) async {
    textController.clear();
    final userMessage = ChatMessage(
      text: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);

    // Add message for loading state
    _messages.add(
      ChatMessage(text: '[LOADING]', isUser: false, timestamp: DateTime.now()),
    );
    emit(ChatLoaded(List.from(_messages)));

    // Save user message to repository
    final userMessageId = await _chatRepository.addMessage(
      userMessage.text,
      userMessage.isUser,
    );
    //print('DEBUG: Saved user message with ID: $userMessageId');
    final aiResponse = await _generateResponse(event.message);

    // Remove loading message
    _messages.removeWhere((msg) => msg.text == '[LOADING]');

    // Add AI response to messages
    _messages.add(aiResponse);

    emit(ChatLoaded(List.from(_messages)));

    // Save AI response to repository
    int messageId = await _chatRepository.addMessage(
      aiResponse.text,
      aiResponse.isUser,
    );
    //print('DEBUG: Saved AI response with ID: $messageId');

    if (aiResponse.flashcards.isNotEmpty) {
      for (var card in aiResponse.flashcards) {
        _flashcardRepository.addFlashcard(card);
      }
    }

    if (aiResponse.grammarNotes.isNotEmpty) {
      for (var note in aiResponse.grammarNotes) {
        note.messageId = messageId;
        _grammarRepository.addGrammarCard(note);
      }
    }
  }

  static String get _openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _openAiApiUrl =
      'https://api.openai.com/v1/chat/completions';
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
   AI Language Tutor Prompt for Italian Learning App

You are an AI language tutor helping a user learn Italian using English as a supporting language.

📥 Input Data

You will be given:
	•	A list of known_words: use them freely, do NOT include them in flashcards.
	•	A list of currently_learning words: use them often, reinforce through usage, but do NOT add them as new flashcards.
	•	A chat history: maintain conversation context from it.

⸻

🔤 Vocabulary Handling

When introducing a new Italian word that is not in known_words or currently_learning, do the following:
	1.	Use the exact format italian_word inline.
	2.	Add a corresponding entry in the flashcards list with:
	•	italian: the word
	•	english: the translation
	•	context: the sentence where the word appeared

❗️Rules:
	•	Never use plain bold, parentheses, or italics for new words.
	•	Always and only use [**word**](flashcard:meaning) format.

⸻

📘 Grammar Notes

Whenever a grammar rule or structure is used or helpful:
	1.	Mark the sentence inline using this format:
[**Italian sentence**](grammar:short_summary_of_grammar_point)
	2.	Add a grammar note in the grammar_notes list using this structure:

Each grammar note must have all of the following:
	•	"title": a concise title summarizing the grammar point (e.g., Present tense of essere)
	•	"example": a valid Italian sentence using the grammar rule
	•	"explanation": a clear explanation of the grammar concept
	•	"text": additional optional notes (can be empty)

❗ If you cannot produce a complete grammar note with all required fields, do not include it at all.
{
  "title": "Concise title of the grammar topic",
  "example": "Always include an example Italian sentence showing the rule",
  "explanation": "Clear and helpful explanation of the rule or structure",
  "text": "Optional extra notes (can be empty)"
}

❗️Rules:
	•	Every grammar note must have a title, example, and explanation.
	•	Do not include grammar explanations directly in the reply text.

⸻

📤 Output Format

Return only a valid JSON object with the following structure:

{
  "reply": "Message content here, using [**word**](flashcard:meaning) and [**sentence**](grammar:explanation)",
  "flashcards": [
    { "italian": "word", "english": "translation", "context": "Sentence" }
  ],
  "grammar_notes": [
    { "title": "...", "example": "...", "explanation": "...", "text": "..." }
  ],
  "history": [
    "User: ...",
    "AI: ..."
  ]
}

✅ Output Rules
	•	No markdown blocks.
	•	No additional explanations.
	•	Only return the JSON described above.

Example:
{
  "reply": "Here's an example: [**Io sono felice**](grammar:subject-verb agreement).",
  "flashcards": [
    { "italian": "felice", "english": "happy", "context": "Io sono felice." }
  ],
  "grammar_notes": [
    {
      "title": "Subject–Verb Agreement in Present Tense",
      "example": "Io sono felice.",
      "explanation": "In Italian, the verb must agree with the subject. 'Io' (I) uses 'sono' (am), the first person singular form of 'essere'.",
      "text": ""
    }
  ],
  "history": [
    "User: Can you give me an example using 'essere'?",
    "AI: Sure! Here's one..."
  ]
}

''';
      final List<Flashcard> knownWords = await _flashcardRepository
          .getDueFlashcards();
      final List<Flashcard> currentlyLearning = await _flashcardRepository
          .getNewFlashcards();

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
                  'known_words: [${knownWords.join(', ')}], currently_learning: [${currentlyLearning.join(', ')}]',
            },
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final raw = data['choices'][0]['message']['content'];
        final cleaned = _extractJsonBlock(raw);
        final responseJson = jsonDecode(cleaned);
        return _formatResponse(responseJson);
      } else {
        throw Exception('API call failed: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error calling OpenAI API: $e');
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
      message.flashcards = (data['flashcards'] as List<dynamic>)
          .map(
            (flashcard) => Flashcard(
              front: flashcard['italian'] ?? '',
              back: flashcard['english'] ?? '',
              context: flashcard['context'] ?? '',
            ),
          )
          .toList();
    }

    if (data['grammar_notes'] != null) {
      message.grammarNotes = (data['grammar_notes'] as List<dynamic>)
          .map(
            (grammarNote) => GrammarCard(
              title: grammarNote['sentence'] ?? 'Grammar Note',
              example: grammarNote['sentence'] ?? '',
              explanation: grammarNote['explanation'] ?? '',
              text: '',
            ),
          )
          .toList();
    }

    return message;
  }

  @override
  Future<void> close() {
    textController.dispose();
    return super.close();
  }
}

String _getFallbackResponse(String userMessage) {
  return '''There seem to be some issues with the OpenAI API key configuration.''';
}

String _extractJsonBlock(String rawResponse) {
  final jsonStart = rawResponse.indexOf('{');
  final jsonEnd = rawResponse.lastIndexOf('}');
  if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
    return rawResponse.substring(jsonStart, jsonEnd + 1);
  }
  return rawResponse; // fallback
}
