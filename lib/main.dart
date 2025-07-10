import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:language_tutor/app/app.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_bloc.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_repository.dart';
import 'package:language_tutor/features/chat/bloc/chat_bloc.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_bloc.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final flashcardRepository = FlashcardRepository();
  final grammarRepository = GrammarRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => FlashcardBloc(flashcardRepository)),
        BlocProvider(create: (_) => ChatBloc()),
        BlocProvider(create: (_) => GrammarCardBloc(grammarRepository)),
      ],
      child: MaterialApp(home: const App()),
    ),
  );
}
