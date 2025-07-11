import 'package:flutter/material.dart';
import 'package:language_tutor/data/models/chat_messages.dart';
import 'package:language_tutor/data/models/gramamr_card.dart';

class AiChatBubble extends StatelessWidget {
  const AiChatBubble({
    super.key,
    required this.context,
    required this.text,
    required this.message,
  });

  final BuildContext context;
  final Widget text;
  final ChatMessage message;

  Widget _buildGrammarNotes(GrammarCard notes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    notes.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2.0),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    children: [
                      if (notes.example.isNotEmpty)
                        TextSpan(
                          text: '"${notes.example}"\n',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      if (notes.explanation.isNotEmpty)
                        TextSpan(
                          text: "${notes.explanation}\n",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      if (notes.text.isNotEmpty)
                        TextSpan(text: '\n${notes.text}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.smart_toy, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: text,
                ),
              ),
            ],
          ),
          if (message.grammarNotes.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            ...message.grammarNotes.map((notes) => _buildGrammarNotes(notes)),
          ],
        ],
      ),
    );
  }
}
