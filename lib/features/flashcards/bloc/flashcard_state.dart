import 'package:language_tutor/data/models/flashcard.dart';

abstract class FlashcardState {}

class FlashcardInitial extends FlashcardState {}

class FlashcardLoading extends FlashcardState {}

class FlashcardLoaded extends FlashcardState {
  final List<Flashcard> flashcards;
  FlashcardLoaded(this.flashcards);
}

class FlashcardError extends FlashcardState {
  final String message;
  FlashcardError(this.message);
}
