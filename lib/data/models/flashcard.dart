class Flashcard {
  final int? id;
  final String front;
  final String back;
  final String context;

  double stability;
  double difficulty;
  int interval;
  DateTime due;
  DateTime? lastReviewed;

  Flashcard({
    this.id,
    required this.front,
    required this.back,
    required this.context,
    this.stability = 0.0,
    this.difficulty = 0.3,
    this.interval = 0,
    DateTime? due,
    this.lastReviewed,
  }) : due = due ?? DateTime.now();

  factory Flashcard.fromMap(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      front: json['front'],
      back: json['back'],
      context: json['context'],
      stability: (json['stability'] as num?)?.toDouble() ?? 0.0,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.3,
      interval: json['interval'] ?? 0,
      due: json['due'] != null ? DateTime.parse(json['due']) : DateTime.now(),
      lastReviewed: json['lastReviewed'] != null ? DateTime.parse(json['lastReviewed']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'context': context,
      'stability': stability,
      'difficulty': difficulty,
      'interval': interval,
      'due': due.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
    };
  }

  Flashcard copyWith({
    int? id,
    String? front,
    String? back,
    String? context,
    double? stability,
    double? difficulty,
    int? interval,
    DateTime? due,
    DateTime? lastReviewed,
  }) {
    return Flashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      context: context ?? this.context,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      interval: interval ?? this.interval,
      due: due ?? this.due,
      lastReviewed: lastReviewed ?? this.lastReviewed,
    );
  }
}
