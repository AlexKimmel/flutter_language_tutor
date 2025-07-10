import 'package:language_tutor/data/models/gramamr_card.dart';

abstract class GrammarState {}

class GrammarLoading extends GrammarState {}

class GrammarInitial extends GrammarState {}

class GrammarLoaded extends GrammarState {
  final List<GrammarCard> grammarCards;
  GrammarLoaded(this.grammarCards);
}

class GrammarError extends GrammarState {
  final String error;
  GrammarError(this.error);
}
