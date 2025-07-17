part of 'training_session_bloc.dart';

abstract class FlashcardTrainingEvent {}

class LoadTrainingSession extends FlashcardTrainingEvent {}

class SubmitCardRating extends FlashcardTrainingEvent {
  final int cardId;
  final Rating rating;

  SubmitCardRating({required this.cardId, required this.rating});
}

class TrainingCompleted extends FlashcardTrainingEvent {
  TrainingCompleted();
}
