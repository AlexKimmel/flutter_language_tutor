import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:language_tutor/data/models/chat_messages.dart';
import 'package:language_tutor/data/models/flashcard.dart';
import 'package:language_tutor/features/chat/bloc/chat_bloc.dart';
import 'package:language_tutor/features/chat/bloc/chat_event.dart';
import 'package:language_tutor/features/chat/bloc/chat_state.dart';
import 'package:language_tutor/features/chat/widgets/ai_chat_bubble.dart';
import 'package:language_tutor/features/chat/widgets/user_chat_bubbles.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_repository.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final FlashcardRepository _flashcardRepository = FlashcardRepository();
  late List<Flashcard> _vocabulary = [];
  @override
  void initState() {
    super.initState();
    _loadVocabulary();
    context.read<ChatBloc>().add(LoadChatHistory());
  }

  void _loadVocabulary() async {
    final known = await _flashcardRepository.getKnownFlashcards();
    final learning = await _flashcardRepository
        .getCurrentlyLearningFlashcards();
    setState(() {
      _vocabulary = [...known, ...learning];
    });
    print(known);
    print('Loaded vocabulary: ${_vocabulary.map((f) => f.front).toList()}');
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    // Use the bloc to send the message
    context.read<ChatBloc>().add(SendUserMessage(text));
    _scrollToBottom();
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
      return UserCatBubble(text: message.text);
    }

    Widget text = _buildText(message, knownWords: _vocabulary);
    return AiChatBubble(message: message, context: context, text: text);
  }

  Widget _buildText(
    ChatMessage message, {
    List<Flashcard> knownWords = const [],
  }) {
    final flashcardPattern = RegExp(r'\[\*\*(.*?)\*\*\]\(flashcard:(.*?)\)');

    // Extract the actual words from flashcards (front side = Italian words)
    final wordStrings = knownWords.map((flashcard) => flashcard.front).toList();

    // Debug: Print the words being searched for
    if (wordStrings.isNotEmpty) {
      print('Searching for words: $wordStrings');
    }

    // Create regex pattern that matches Italian words (including accented characters)
    final wordPattern = wordStrings.isNotEmpty
        ? RegExp(
            r"\b(" +
                wordStrings.map((word) => RegExp.escape(word)).join('|') +
                r")\b",
            caseSensitive: false,
            unicode: true,
          )
        : null;

    List<InlineSpan> spans = [];
    int index = 0;

    while (index < message.text.length) {
      final flashMatch = flashcardPattern.matchAsPrefix(message.text, index);
      if (flashMatch != null) {
        if (index < flashMatch.start) {
          spans.add(
            TextSpan(text: message.text.substring(index, flashMatch.start)),
          );
        }

        final word = flashMatch.group(1)!;
        final translation = flashMatch.group(2)!;

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: CustomPopup(
              content: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(translation, style: const TextStyle(fontSize: 14)),
              ),
              child: GestureDetector(
                child: Text(
                  word,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        );

        index = flashMatch.end;
      } else if (wordPattern != null) {
        final wordMatch = wordPattern.matchAsPrefix(message.text, index);
        if (wordMatch != null) {
          if (index < wordMatch.start) {
            spans.add(
              TextSpan(text: message.text.substring(index, wordMatch.start)),
            );
          }

          final matchedWord = wordMatch.group(0)!;

          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: CustomPopup(
                content: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    knownWords
                        .firstWhere(
                          (f) => f.front == matchedWord,
                          orElse: () => Flashcard(
                            front: matchedWord,
                            back: '',
                            context: '',
                            nextReview: DateTime.now(),
                            interval: 1,
                            repetitions: 0,
                            easeFactor: 2.5,
                          ),
                        )
                        .back,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                child: GestureDetector(
                  child: Text(
                    matchedWord,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ),
          );

          index = wordMatch.end;
        } else {
          spans.add(TextSpan(text: message.text[index]));
          index++;
        }
      } else {
        spans.add(TextSpan(text: message.text[index]));
        index++;
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: spans,
      ),
    );
  }

  Widget _buildTextComposer() {
    final chatBloc = context.read<ChatBloc>();

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
                    controller: chatBloc.textController,
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
                onPressed: () => _handleSubmitted(chatBloc.textController.text),
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
            child: BlocListener<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatLoaded) {
                  // Auto-scroll to bottom when new messages are loaded
                  _scrollToBottom();
                }
              },
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ChatError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.error,
                            style: TextStyle(color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ChatBloc>().add(LoadChatHistory());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is ChatLoaded) {
                    if (state.messages.isEmpty) {
                      return Center(
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
                      );
                    } else {
                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessage(state.messages[index]);
                        },
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
