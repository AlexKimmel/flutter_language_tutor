import 'package:language_tutor/data/models/gramamr_card.dart';

abstract class GrammarEvent {}

class LoadGrammarCards extends GrammarEvent {
  LoadGrammarCards();
}

class AddGrammarCard extends GrammarEvent {
  final GrammarCard grammarCard;

  AddGrammarCard(this.grammarCard);
}

class UpdateGrammarCard extends GrammarEvent {
  final GrammarCard grammarCard;

  UpdateGrammarCard(this.grammarCard);
}

class DeleteGrammarCard extends GrammarEvent {
  final int id;

  DeleteGrammarCard(this.id);
}
