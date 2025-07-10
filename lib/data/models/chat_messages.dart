class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  List<Map<String, String>> flashcards = [];
  List<Map<String, String>> grammarNotes = [];

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.flashcards = const [],
    this.grammarNotes = const [],
  });

  @override
  String toString() {
    return 'ChatMessage(text: $text, isUser: $isUser, timestamp: $timestamp, flashcards: $flashcards, grammarNotes: $grammarNotes)';
  }
}
