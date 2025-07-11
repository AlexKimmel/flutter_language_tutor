// ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_repository.dart';
import 'flashcard_event.dart';
import 'flashcard_state.dart';

class FlashcardBloc extends Bloc<FlashcardEvent, FlashcardState> {
  final FlashcardRepository repository;

  FlashcardBloc(this.repository) : super(FlashcardInitial()) {
    on<LoadFlashcards>(_onLoad);
    on<AddFlashcard>(_onAdd);
    on<UpdateFlashcard>(_onUpdate);
    on<DeleteFlashcard>(_onDelete);
    on<ReviewFlashcard>(_onReview);
  }

  Future<void> _onLoad(
    LoadFlashcards event,
    Emitter<FlashcardState> emit,
  ) async {
    emit(FlashcardLoading());
    try {
      final cards = event.onlyDue
          ? await repository.getDueFlashcards()
          : await repository.getAllFlashcards();
      emit(FlashcardLoaded(cards));
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }

  Future<void> _onAdd(AddFlashcard event, Emitter<FlashcardState> emit) async {
    await repository.addFlashcard(event.flashcard);
    add(LoadFlashcards());
  }

  Future<void> _onUpdate(
    UpdateFlashcard event,
    Emitter<FlashcardState> emit,
  ) async {
    await repository.updateFlashcard(event.flashcard);
    add(LoadFlashcards());
  }

  Future<void> _onDelete(
    DeleteFlashcard event,
    Emitter<FlashcardState> emit,
  ) async {
    await repository.deleteFlashcard(event.id);
    add(LoadFlashcards());
  }

  Future<void> _onReview(
    ReviewFlashcard event,
    Emitter<FlashcardState> emit,
  ) async {
    final updated = repository.updateSRS(event.flashcard, event.quality);
    await repository.updateFlashcard(updated);
    add(LoadFlashcards(onlyDue: true));
  }
}
