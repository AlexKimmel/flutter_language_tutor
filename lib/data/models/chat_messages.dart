import 'package:language_tutor/data/models/flashcard.dart';
import 'package:language_tutor/data/models/gramamr_card.dart';

class ChatMessage {
  final int? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  List<Flashcard> flashcards = [];
  List<GrammarCard> grammarNotes = [];

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.flashcards = const [],
    this.grammarNotes = const [],
  });

  factory ChatMessage.fromMap(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int?,
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
      grammarNotes: json['grammar_notes'] != null
          ? (json['grammar_notes'] as List<dynamic>)
                .map((e) => GrammarCard.fromMap(Map<String, dynamic>.from(e)))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatMessage &&
        other.id == id &&
        other.text == text &&
        other.isUser == isUser &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^ text.hashCode ^ isUser.hashCode ^ timestamp.hashCode;
  }
}
