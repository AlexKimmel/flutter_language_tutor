import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_bloc.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_event.dart';
import 'package:language_tutor/data/models/flashcard.dart';

class FlashcardDialog extends StatelessWidget {
  const FlashcardDialog({
    super.key,
    required this.formKey,
    required this.frontController,
    required this.backController,
    required this.contextController,
    this.flashcard,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController frontController;
  final TextEditingController backController;
  final TextEditingController contextController;
  final Flashcard? flashcard;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_card, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          const Text('Add Flashcard'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: frontController,
                decoration: InputDecoration(
                  labelText: 'Front (Italian)',
                  prefixIcon: const Icon(Icons.translate),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: backController,
                decoration: InputDecoration(
                  labelText: 'Back (English)',
                  prefixIcon: const Icon(Icons.language),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contextController,
                decoration: InputDecoration(
                  labelText: 'Context (optional)',
                  prefixIcon: const Icon(Icons.short_text),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                minLines: 1,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              if (flashcard != null) {
                // Update existing flashcard
                Flashcard updatedCard = flashcard!.copyWith(
                  front: frontController.text.trim(),
                  back: backController.text.trim(),
                  context: contextController.text.trim(),
                );
                context.read<FlashcardBloc>().add(UpdateFlashcard(updatedCard));
              } else {
                // Add new flashcard
                Flashcard newCard = Flashcard(
                  front: frontController.text.trim(),
                  back: backController.text.trim(),
                  context: contextController.text.trim(),
                  nextReview: DateTime.now(),
                  interval: 1,
                  easeFactor: 2.5,
                  repetitions: 0,
                );
                context.read<FlashcardBloc>().add(AddFlashcard(newCard));
              }
              Navigator.of(context).pop();
            }
          },
          child: Text(flashcard != null ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
