import 'package:language_tutor/features/flashcards/flashcard.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  List<Flashcard> flashcards = [];
  List<Map<String, dynamic>> grammarNotes = [];

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.flashcards = const [],
    this.grammarNotes = const [],
  });

  factory ChatMessage.fromMap(Map<String, dynamic> json) {
    return ChatMessage(
      text: (json['text'] ?? json['reply'] ?? '') as String,
      isUser:
          json['is_user'] != null &&
          (json['is_user'] == 1 || json['is_user'] == true),
      timestamp: json['timestamp'] == null
          ? DateTime.now()
          : DateTime.parse(json['timestamp'] as String),
      flashcards: json['flashcards'] != null
          ? (json['flashcards'] as List<dynamic>)
                .map((e) => Flashcard.fromMap(Map<String, dynamic>.from(e)))
                .toList()
          : [],
      grammarNotes:
          (json['grammar_notes'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reply': text,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'flashcards': flashcards,
      'grammar_notes': grammarNotes,
    };
  }

  @override
  String toString() {
    return 'ChatMessage: ${isUser ? 'User' : 'AITutor'}: $text';
  }
}
