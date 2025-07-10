abstract class ChatEvent {}

class LoadChatHistory extends ChatEvent {}

class SendUserMessage extends ChatEvent {
  final String message;
  SendUserMessage(this.message);
}
