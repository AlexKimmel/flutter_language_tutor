import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: library_prefixes
import 'package:fsrs/fsrs.dart' as FSRS;
import 'package:flutter/material.dart';
import 'package:language_tutor/data/models/flashcard.dart';

import 'package:language_tutor/features/training_session/bloc/training_session_bloc.dart';

class TrainingSessionPage extends StatefulWidget {
  const TrainingSessionPage({super.key});

  @override
  State<TrainingSessionPage> createState() => _TrainingSessionPageState();
}

class _TrainingSessionPageState extends State<TrainingSessionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  bool _isFlipped = false;
  bool _showAnswer = false;
  final int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Load due flashcards when the page starts
    context.read<TrainingSessionBloc>().add(LoadTrainingSession());
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (!_isFlipped) {
      _flipController.forward();
      setState(() {
        _isFlipped = true;
        _showAnswer = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Test'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: BlocBuilder<TrainingSessionBloc, TrainingSessionState>(
          builder: (context, state) {
            if (state is TrainingSessionLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TrainingSessionError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is TrainingInProgress) {
              final session = state.session;
              final card = session.currentCard;
              final total = session.queue.length + session.completed.length;
              return Column(
                children: [
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Card ${_currentCardIndex + 1} of $total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${total > 0 ? ((_currentCardIndex + 1) / total * 100).round() : 0}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: total > 0
                              ? (_currentCardIndex + 1) / total
                              : 0.0,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Flashcard
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: _flipCard,
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final isShowingFront = _flipAnimation.value < 0.5;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(_flipAnimation.value * 3.14159),
                              child: Card(
                                margin: const EdgeInsets.all(20),
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isShowingFront
                                          ? [Colors.white, Colors.grey.shade50]
                                          : [
                                              Colors.blue.shade50,
                                              Colors.blue.shade100,
                                            ],
                                    ),
                                  ),
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..rotateY(isShowingFront ? 0 : 3.14159),
                                    child: _buildCardContent(
                                      isShowingFront,
                                      card!,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Instructions or difficulty buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: _showAnswer
                        ? _buildDifficultyButtons(card!)
                        : _buildInstructions(),
                  ),
                ],
              );
            } else if (state is TrainingComplet) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Training session completed!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Great job! Come back later for more practice.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('No training session in progress'));
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(bool isShowingFront, Flashcard card) {
    if (isShowingFront) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            card.front,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Tap to reveal answer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 40,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 20),
            Text(
              card.back,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (card.context.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  card.context,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildInstructions() {
    return GestureDetector(
      onTap: _flipCard,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, color: Colors.blue.shade600, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Tap the card to reveal the answer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButtons(Flashcard card) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDifficultyButton(
                'Again',
                Colors.red.shade600,
                Icons.refresh,
                () {
                  _emitCardRating(card, FSRS.Rating.again);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifficultyButton(
                'Hard',
                Colors.orange.shade600,
                Icons.warning,
                () {
                  _emitCardRating(card, FSRS.Rating.hard);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifficultyButton(
                'Good',
                Colors.green.shade600,
                Icons.check,
                () {
                  _emitCardRating(card, FSRS.Rating.good);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifficultyButton(
                'Easy',
                Colors.blue.shade600,
                Icons.done_all,
                () {
                  _emitCardRating(card, FSRS.Rating.easy);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _emitCardRating(Flashcard card, FSRS.Rating rating) {
    context.read<TrainingSessionBloc>().add(
      SubmitCardRating(cardId: card.id!, rating: rating),
    );
    _showAnswer = false; // Hide answer after rating
    _isFlipped = false; // Reset flip state
    _flipController.reset(); // Reset animation controller
  }

  Widget _buildDifficultyButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
