import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_bloc.dart';
import 'package:language_tutor/features/flashcards/bloc/flashcard_event.dart';
import 'package:language_tutor/data/models/flashcard.dart';
import 'package:language_tutor/features/flashcards/widgets/flashcard_dialog.dart';

class FlashcardItem extends StatefulWidget {
  const FlashcardItem({super.key, required this.flashcard});
  final Flashcard flashcard;
  @override
  State<FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<FlashcardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showBack) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _showBack = !_showBack;
    });
  }

  @override
  Widget build(BuildContext context) {
    final flashcard = widget.flashcard;
    // Set a fixed height for the card to keep the size consistent

    return GestureDetector(
      onTap: _flipCard,
      onLongPress: () {
        // show dialog to edit or delete the flashcard
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Flashcard Options'),
              content: Text('What would you like to do with this flashcard?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) {
                        // Open the dialog to edit the flashcard

                        final frontController = TextEditingController();
                        final backController = TextEditingController();
                        final contextController = TextEditingController();
                        final formKey = GlobalKey<FormState>();
                        return FlashcardDialog(
                          flashcard: flashcard,
                          formKey: formKey,
                          frontController: frontController,
                          backController: backController,
                          contextController: contextController,
                        );
                      },
                    );
                  },
                  child: Text('Edit'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<FlashcardBloc>().add(
                      DeleteFlashcard(flashcard.id as int),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted "${flashcard.front}"'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: double.infinity,

          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value * 3.1415926535897932;
              final isBack = _animation.value >= 0.5;
              // For the back, flip the content so text is not mirrored
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: isBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..rotateY(3.1415926535897932),
                        child: _buildBack(context, flashcard),
                      )
                    : _buildFront(context, flashcard),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context, Flashcard flashcard) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          flashcard.front,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBack(BuildContext context, Flashcard flashcard) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            flashcard.back,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (flashcard.context.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: MarkdownBody(
                data: flashcard.context,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  strong: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  em: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: WrapAlignment.center,
                ),
                shrinkWrap: true,
                selectable: false,
              ),
            ),
        ],
      ),
    );
  }
}
