import 'package:flutter/material.dart';

class ChatDateBubble extends StatelessWidget {
  const ChatDateBubble({super.key, required this.date});
  final DateTime date;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(18.0),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          "${date.day}.${date.month}.${date.year}",
          style: TextStyle(color: Colors.grey.shade900, fontSize: 12.0),
        ),
      ),
    );
  }
}
