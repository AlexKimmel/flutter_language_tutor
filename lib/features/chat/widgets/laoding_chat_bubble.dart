import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LaodingChatBubble extends StatefulWidget {
  const LaodingChatBubble({super.key});

  @override
  State<LaodingChatBubble> createState() => _LaodingChatBubbleState();
}

class _LaodingChatBubbleState extends State<LaodingChatBubble> {
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
                  child: LoadingAnimationWidget.waveDots(
                    color: Colors.grey.shade800,
                    size: 34.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
