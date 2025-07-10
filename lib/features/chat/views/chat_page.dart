import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:language_tutor/data/models/chat_messages.dart';
import 'package:language_tutor/features/chat/bloc/chat_bloc.dart';
import 'package:language_tutor/features/chat/bloc/chat_event.dart';
import 'package:language_tutor/features/chat/bloc/chat_state.dart';
import 'package:language_tutor/features/chat/widgets/chat_bubbles.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load chat history when the page is initialized
    context.read<ChatBloc>().add(LoadChatHistory());
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
