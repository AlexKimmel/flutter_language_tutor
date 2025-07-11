import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_tutor/data/models/gramamr_card.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_bloc.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_event.dart';

class GrammarCardDetailPage extends StatelessWidget {
  final GrammarCard card;

  const GrammarCardDetailPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 24,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    card.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 24,
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 6.0),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted "${card.title}"'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    context.read<GrammarCardBloc>().add(
                      DeleteGrammarCard(card.id as int),
                    );
                  },
                  icon: Icon(
                    Icons.delete,
                    color: Colors.grey.shade600,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Example section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '"${card.example}"',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Explanation section
            Text(
              'Explanation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              card.explanation,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
            ),

            // Additional text section (if available)
            if (card.text.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              Text(
                'Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                card.text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
