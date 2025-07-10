class GrammarCard {
  final int? id;
  final String title;
  final String example;
  final String explanation;
  final String text;

  GrammarCard({
    this.id,
    required this.title,
    required this.example,
    required this.explanation,
    required this.text,
  });

  factory GrammarCard.fromMap(Map<String, dynamic> json) {
    return GrammarCard(
      id: json['id'] as int?,
      title: json['title'] as String,
      example: json['example'] as String,
      explanation: json['explanation'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'example': example,
      'explanation': explanation,
      'text': text,
    };
  }
}
