import 'package:fsrs/fsrs.dart';
import 'package:language_tutor/data/models/flashcard.dart';

abstract class FlashcardEvent {}

class LoadFlashcards extends FlashcardEvent {
  final bool onlyDue;
  LoadFlashcards({this.onlyDue = false});
}

class AddFlashcard extends FlashcardEvent {
  final Flashcard flashcard;
  AddFlashcard(this.flashcard);
}

class UpdateFlashcard extends FlashcardEvent {
  final Flashcard flashcard;
  UpdateFlashcard(this.flashcard);
}

class DeleteFlashcard extends FlashcardEvent {
  final int id;
  DeleteFlashcard(this.id);
}

class ReviewFlashcard extends FlashcardEvent {
  final Flashcard flashcard;
  final Rating quality; // 1–5 for spaced repetition
  ReviewFlashcard({required this.flashcard, required this.quality});
}
