import 'package:language_tutor/data/models/flashcard.dart';

class TrainingSession {
  final List<int> queue; // flashcard IDs in review order
  final Map<int, Flashcard> cards; // in-memory cache of cards
  Set<int> completed; // IDs already completed

  TrainingSession({
    required this.queue,
    required this.cards,
    Set<int>? completed,
  }) : completed = completed ?? <int>{};

  Flashcard? get currentCard => queue.isEmpty ? null : cards[queue.first];

  void markCompleted(int id) => completed.add(id);

  void reinsertLater(int id, int offset) {
    queue.remove(id);
    final insertAt = (offset < queue.length) ? offset : queue.length;
    queue.insert(insertAt, id);
  }

  void advance() {
    if (queue.isNotEmpty) queue.removeAt(0);
  }

  bool get isFinished => queue.isEmpty;
}
