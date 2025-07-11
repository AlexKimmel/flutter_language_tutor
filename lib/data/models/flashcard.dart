class Flashcard {
  final int? id;
  final String front;
  final String back;
  final String context;

  final DateTime nextReview;
  final int interval;
  final double easeFactor;
  final int repetitions;

  Flashcard({
    this.id,
    required this.front,
    required this.back,
    required this.context,

    required this.nextReview,
    required this.interval,
    required this.easeFactor,
    required this.repetitions,
  });

  factory Flashcard.fromMap(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      front: json['front'],
      back: json['back'],
      context: json['context'],

      nextReview: DateTime.parse(json['nextReview']),
      interval: json['interval'],
      easeFactor: (json['easeFactor'] as num).toDouble(),
      repetitions: json['repetitions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'context': context,
      'nextReview': nextReview.toIso8601String(),
      'interval': interval,
      'easeFactor': easeFactor,
      'repetitions': repetitions,
    };
  }

  Flashcard copyWith({
    int? id,
    String? front,
    String? back,
    String? context,
    DateTime? nextReview,
    int? interval,
    double? easeFactor,
    int? repetitions,
  }) {
    return Flashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      context: context ?? this.context,
      nextReview: nextReview ?? this.nextReview,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
    );
  }
}
