import '../data/ai_message.dart';

sealed class AiChatState {
  const AiChatState();
}

/// Nothing sent yet — the AI Chat Home frame.
class AiChatEmpty extends AiChatState {
  const AiChatEmpty();
}

class AiChatActive extends AiChatState {
  const AiChatActive(this.messages);
  final List<AiMessage> messages;
}

/// A reply is pending; [messages] already ends with the user's prompt.
class AiChatResponding extends AiChatState {
  const AiChatResponding(this.messages);
  final List<AiMessage> messages;
}
