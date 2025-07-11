import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_tutor/features/flashcards/widgets/flashcard_item.dart';
import '../bloc/flashcard_bloc.dart';
import '../bloc/flashcard_state.dart';
import '../bloc/flashcard_event.dart';

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  @override
  void initState() {
    super.initState();
    context.read<FlashcardBloc>().add(LoadFlashcards());
  }

  Widget _emptyFlashcardList() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('No flashcards available.'),
          Text('Create some to get started!'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: BlocBuilder<FlashcardBloc, FlashcardState>(
        builder: (context, state) {
          if (state is FlashcardLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FlashcardLoaded) {
            if (state.flashcards.isEmpty) return _emptyFlashcardList();
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: state.flashcards.length,
              itemBuilder: (context, index) {
                return FlashcardItem(flashcard: state.flashcards[index]);
              },
            );
          } else if (state is FlashcardError) {
            return Center(child: Text('Error: ${state.message}'));
          } else {
            return _emptyFlashcardList();
          }
        },
      ),
    );
  }
}
