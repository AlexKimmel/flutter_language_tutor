import 'package:flutter/material.dart';

class UserChatBubble extends StatelessWidget {
  const UserChatBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(18.0),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Text(text, style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8.0),
          CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: Icon(Icons.person, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }
}
