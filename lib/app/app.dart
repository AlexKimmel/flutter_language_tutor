import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:language_tutor/features/flashcards/views/flashcard_page.dart';
import 'package:language_tutor/features/chat/views/chat_page.dart';
import 'package:language_tutor/features/flashcards/widgets/flashcard_dialog.dart';
import 'package:language_tutor/features/grammar/views/grammar_page.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BottomBarController _bottomBarController;
  int _currentPage = 1;
  final List<Color> _colors = [
    Colors.blue.shade100,
    Colors.blue.shade200,
    Colors.blue.shade300,
    Colors.blue.shade400,
  ];

  @override
  void initState() {
    super.initState();
    _bottomBarController = BottomBarController();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPage == 0) {
      _bottomBarController.hideBar();
    } else {
      _bottomBarController.showBar();
    }

    return Scaffold(
      backgroundColor: _colors[_currentPage],
      body: BottomBar(
        controller: _bottomBarController,
        fit: StackFit.expand,
        icon: (width, height) => Center(
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: null,
            icon: Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: width,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(500),
        duration: const Duration(milliseconds: 150),
        curve: Curves.decelerate,
        showIcon: true,
        width: MediaQuery.of(context).size.width * 0.8,
        barColor: Colors.black,
        start: 2,
        end: 0,
        offset: 10,
        barAlignment: Alignment.bottomCenter,
        iconHeight: 30,
        iconWidth: 30,
        reverse: false,
        hideOnScroll: true,
        scrollOpposite: false,
        respectSafeArea: true,
        onBottomBarHidden: () {},
        onBottomBarShown: () {},
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            TabBar(
              controller: _tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: _colors[_currentPage], width: 4),
                insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              ),
              tabs: [
                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: _currentPage == 0
                          ? Colors.blue.shade300
                          : Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(
                    child: Icon(
                      Icons.style,
                      color: _currentPage == 1
                          ? Colors.blue.shade300
                          : Colors.white,
                    ),
                  ),
                ),

                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(
                    child: Icon(
                      Icons.biotech,
                      color: _currentPage == 2
                          ? Colors.blue.shade300
                          : Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(
                    child: Icon(
                      Icons.menu_book_outlined,
                      color: _currentPage == 3
                          ? Colors.blue.shade300
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.decelerate,
              top: _currentPage == 0 ? 0 : -25,
              child: Positioned(
                child: FloatingActionButton(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.blue.shade400,
                  onPressed: () {
                    final frontController = TextEditingController();
                    final backController = TextEditingController();
                    final contextController = TextEditingController();
                    final formKey = GlobalKey<FormState>();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return FlashcardDialog(
                          formKey: formKey,
                          frontController: frontController,
                          backController: backController,
                          contextController: contextController,
                        );
                      },
                    );
                  },
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        body: (context, controller) => TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: const [
            ChatPage(),
            FlashcardPage(),
            Placeholder(),
            GrammarPage(),
          ],
        ),
      ),
    );
  }
}
