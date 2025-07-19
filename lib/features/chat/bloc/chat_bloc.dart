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
    
    You will also be given a chat history, which you should use to maintain context and continuity in the conversation.
    
    Each response must be returned as a JSON object with the following structure:
    {
      "reply": "Your response text here, mixing Italian and English, using [**italian_word**](flashcard:translation) syntax for new vocabulary.",
      "flashcards": [
        { "italian": "new_word", "english": "translation", "context": "Sentence where it was used" }
      ],
      "grammar_notes": [
        { "title": "the title of the grammar card", "example": "Italian sentence", "explanation": "Short grammar explanation", "text": "some not nessecary additional text" }
      ]
      "histroy" : [
      "User: user text is marked with User and AI for AI responses",
      "AI: AI response is marked with AI"]
    }

    Avoid translating or re-teaching `known_words` or `currently_learning` words keep them in italian and mark them as if there where a flashcard.
    Encourage natural conversation, offer corrections if needed, and always stay supportive and context-aware.
    Return only a valid JSON object, with no introduction, no markdown blocks, no explanation — only valid raw JSON like this:
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
