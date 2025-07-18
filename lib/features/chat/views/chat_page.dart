import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:language_tutor/data/models/chat_messages.dart';
import 'package:language_tutor/data/models/flashcard.dart';
import 'package:language_tutor/features/chat/bloc/chat_bloc.dart';
import 'package:language_tutor/features/chat/bloc/chat_event.dart';
import 'package:language_tutor/features/chat/bloc/chat_state.dart';
import 'package:language_tutor/features/chat/widgets/ai_chat_bubble.dart';
import 'package:language_tutor/features/chat/widgets/chat_date_bubble.dart';
import 'package:language_tutor/features/chat/widgets/laoding_chat_bubble.dart';
import 'package:language_tutor/features/chat/widgets/user_chat_bubbles.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_repository.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ScrollController _scrollController;
  final FlashcardRepository _flashcardRepository = FlashcardRepository();
  late List<Flashcard> _vocabulary = [];
  bool _showScrollDownButton = false;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
    context.read<ChatBloc>().add(LoadChatHistory());
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final threshold = 100.0;
      final currentScroll = _scrollController.position.pixels;
      final shouldShow = currentScroll > threshold;

      if (shouldShow != _showScrollDownButton) {
        setState(() {
          _showScrollDownButton = shouldShow;
        });
      }
    });
  }

  void _loadVocabulary() async {
    //final known = await _flashcardRepository.getKnownFlashcards();
    final learning = await _flashcardRepository.getNewFlashcards();
    setState(() {
      //_vocabulary = [...known, ...learning];
      _vocabulary = [...learning];
    });
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    context.read<ChatBloc>().add(SendUserMessage(text));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(ChatMessage message, {ChatMessage? previousMessage}) {
    if (message.text == '[LOADING]') {
      return LaodingChatBubble();
    }

    // Check if we need to show date bubble
    bool shouldShowDate = false;
    if (previousMessage != null) {
      shouldShowDate = !_isSameDay(
        message.timestamp,
        previousMessage.timestamp,
      );
    } else {
      // Show date for the first message in the conversation
      shouldShowDate = true;
    }

    Widget text = _buildText(message, knownWords: _vocabulary);

    return Column(
      children: [
        //if (shouldShowDate) ChatDateBubble(date: message.timestamp),
        if (message.isUser)
          UserChatBubble(text: message.text)
        else
          AiChatBubble(message: message, context: context, text: text),
      ],
    );
  }

  Widget _buildText(
    ChatMessage message, {
    List<Flashcard> knownWords = const [],
  }) {
    final flashcardPattern = RegExp(r'\[\*\*(.*?)\*\*\]\(flashcard:(.*?)\)');

    // Extract the actual words from flashcards (front side = Italian words)
    final wordStrings = knownWords.map((flashcard) => flashcard.front).toList();

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
                          (f) =>
                              f.front.toLowerCase() ==
                              matchedWord.toLowerCase(),
                          orElse: () => Flashcard(
                            front: matchedWord,
                            back: '',
                            context: '',
                            interval: 1,
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
                    borderRadius: BorderRadius.circular(500.0),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
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
                  // Add a small delay to ensure ListView has rendered new items
                  Future.delayed(const Duration(milliseconds: 50), () {
                    _scrollToBottom();
                  });
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
                      return Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              // Since we're using reverse, we need to reverse the index
                              final messageIndex =
                                  state.messages.length - 1 - index;
                              final message = state.messages[messageIndex];

                              // Get the previous message in UI order (the one rendered before this one)
                              // In a reversed ListView, this is the chronologically LATER message
                              ChatMessage? previousMessage;
                              if (messageIndex < state.messages.length - 1) {
                                previousMessage =
                                    state.messages[messageIndex + 1];
                              }

                              return _buildMessage(
                                message,
                                previousMessage: previousMessage,
                              );
                            },
                          ),

                          AnimatedPositioned(
                            bottom: _showScrollDownButton ? 10 : -100,
                            right: 4,
                            duration: const Duration(milliseconds: 150),
                            child: IconButton(
                              onPressed: () {
                                _scrollToBottom();
                              },
                              icon: CircleAvatar(
                                backgroundColor: Colors.blue.shade600,
                                child: const Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
