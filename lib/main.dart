import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:language_tutor/app/app.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_bloc.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final flashcardRepository = FlashcardRepository();

  runApp(
    BlocProvider(
      create: (_) => FlashcardBloc(flashcardRepository),
      child: MaterialApp(home: const App()),
    ),
  );
}
