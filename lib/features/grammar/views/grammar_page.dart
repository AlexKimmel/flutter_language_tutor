import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:language_tutor/data/models/gramamr_card.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_bloc.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_event.dart';
import 'package:language_tutor/features/grammar/bloc/grammar_state.dart';
import 'package:language_tutor/features/grammar/widgets/grammar_detail_popup.dart';

class GrammarPage extends StatefulWidget {
  const GrammarPage({super.key});

  @override
  State<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends State<GrammarPage> {
  @override
  void initState() {
    super.initState();
    // Load grammar cards when the page is initialized
    context.read<GrammarCardBloc>().add(LoadGrammarCards());
  }

  void _showGrammarCardDetail(GrammarCard card) {
    // Navigator.of(context).push(
    //   PageRouteBuilder(
    //     pageBuilder: (context, animation, secondaryAnimation) =>
    //         GrammarCardDetailPage(card: card),
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       const begin = Offset(0.0, 1.0);
    //       const end = Offset.zero;
    //       const curve = Curves.easeInOutCubic;

    //       var tween = Tween(
    //         begin: begin,
    //         end: end,
    //       ).chain(CurveTween(curve: curve));

    //       return SlideTransition(
    //         position: animation.drive(tween),
    //         child: child,
    //       );
    //     },
    //     transitionDuration: const Duration(milliseconds: 300),
    //   ),
    // );
  }

  Widget _buildCompactGrammarCard(GrammarCard card) {
    return CustomPopup(
      content: GrammarCardDetailPage(card: card),
      child: Container(
        margin: const EdgeInsets.all(4.0),
        padding: const EdgeInsets.all(12.0),
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
                // Icon(
                //   Icons.lightbulb_outline,
                //   size: 24,
                //   color: Colors.blue.shade700,
                // ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    card.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 24,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              '"${card.example}"',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade900),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // const SizedBox(height: 4.0),
            // Text(
            //   card.explanation,
            //   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            //   maxLines: 2,
            //   overflow: TextOverflow.ellipsis,
            // ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammar Notes'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: BlocBuilder<GrammarCardBloc, GrammarState>(
        builder: (context, state) {
          if (state is GrammarLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GrammarError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: TextStyle(fontSize: 18, color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error,
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<GrammarCardBloc>().add(LoadGrammarCards());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is GrammarLoaded) {
            if (state.grammarCards.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No grammar notes yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start chatting to collect grammar notes!',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemCount: state.grammarCards.length,
                  itemBuilder: (context, index) {
                    return _buildCompactGrammarCard(state.grammarCards[index]);
                  },
                ),
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
