import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_event.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_repository.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_state.dart';

class GrammarCardBloc extends Bloc<GrammarEvent, GrammarState> {
  final GrammarRepository repository;

  GrammarCardBloc(this.repository) : super(GrammarInitial()) {
    on<LoadGrammarCards>(_onLoadGrammarCards);
    on<AddGrammarCard>(_onAddGrammarCard);
    on<UpdateGrammarCard>(_onUpdateGrammarCard);
    on<DeleteGrammarCard>(_onDeleteGrammarCard);
  }

  Future<void> _onLoadGrammarCards(
    LoadGrammarCards event,
    Emitter<GrammarState> emit,
  ) async {
    emit(GrammarLoading());
    try {
      final cards = await repository.getAllGrammarCards();
      emit(GrammarLoaded(cards));
    } catch (e) {
      emit(GrammarError('Failed to load grammar cards: ${e.toString()}'));
    }
  }

  Future<void> _onAddGrammarCard(
    AddGrammarCard event,
    Emitter<GrammarState> emit,
  ) async {
    try {
      await repository.addGrammarCard(event.grammarCard);
      add(LoadGrammarCards()); // Reload cards after adding
    } catch (e) {
      emit(GrammarError('Failed to add grammar card: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateGrammarCard(
    UpdateGrammarCard event,
    Emitter<GrammarState> emit,
  ) async {
    try {
      await repository.updateGrammarCard(event.grammarCard);
      add(LoadGrammarCards()); // Reload cards after updating
    } catch (e) {
      emit(GrammarError('Failed to update grammar card: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteGrammarCard(
    DeleteGrammarCard event,
    Emitter<GrammarState> emit,
  ) async {
    try {
      await repository.deleteGrammarCard(event.id);
      add(LoadGrammarCards()); // Reload cards after deleting
    } catch (e) {
      emit(GrammarError('Failed to delete grammar card: ${e.toString()}'));
    }
  }
}
