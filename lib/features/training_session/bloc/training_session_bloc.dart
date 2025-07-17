import 'package:bloc/bloc.dart';
import 'package:fsrs/fsrs.dart';
import 'package:language_tutor/data/models/training_session.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_repository.dart';
import 'package:meta/meta.dart';

part 'training_session_event.dart';
part 'training_session_state.dart';

class TrainingSessionBloc
    extends Bloc<FlashcardTrainingEvent, TrainingSessionState> {
  final FlashcardRepository repository = FlashcardRepository();
  final Scheduler fsrs = Scheduler();

  TrainingSessionBloc() : super(TrainingSessionInitial()) {
    on<LoadTrainingSession>(_onLoadSession);
    on<SubmitCardRating>(_onSubmitRating);
    on<TrainingCompleted>(_onTrainingCompleted);
  }

  Future<void> _onLoadSession(LoadTrainingSession event, Emitter emit) async {
    final due = await repository.getDueFlashcards();
    final newCards = await repository.getNewFlashcards(limit: 10);

    final all = [...due, ...newCards];

    if (all.isEmpty) {
      emit(TrainingComplet());
      return;
    }

    final session = TrainingSession(
      queue: all.map((f) => f.id!).toList(),
      cards: {for (var f in all) f.id!: f},
    );

    emit(TrainingInProgress(session));
  }

  Future<void> _onSubmitRating(SubmitCardRating event, Emitter emit) async {
    final state = this.state;
    if (state is! TrainingInProgress) return;

    final session = state.session;
    final card = session.cards[event.cardId]!;

    // Run FSRS
    final fsrsCard = Card(cardId: card.id!)
      ..due = card.due.toUtc()
      ..stability = card.stability
      ..difficulty = card.difficulty;

    final result = fsrs.reviewCard(fsrsCard, event.rating);
    final updated = result.card;
    // Update DB
    final updatedModel = card.copyWith(
      due: updated.due.toLocal(),
      stability: updated.stability,
      difficulty: updated.difficulty,
      lastReviewed: DateTime.now(),
    );
    await repository.updateFlashcard(updatedModel);

    // Update session
    session.cards[event.cardId] = updatedModel;
    session.markCompleted(event.cardId);

    // Reinsert if user pressed "again"
    if (event.rating == Rating.again) {
      session.reinsertLater(event.cardId, 5); // 5 = insert after 5 more
    } else {
      session.advance();
    }

    if (session.isFinished) {
      emit(TrainingComplet());
    } else {
      emit(TrainingInProgress(session));
    }
  }

  Future<void> _onTrainingCompleted(
    TrainingCompleted event,
    Emitter emit,
  ) async {
    DateTime? nextSessionTime = await repository.getNextSessionTime();

    if (nextSessionTime != null) {
      emit(TrainingComplet(nextSessionAvailable: nextSessionTime));
    } else {
      emit(TrainingComplet());
    }

    emit(TrainingComplet());
  }
}
