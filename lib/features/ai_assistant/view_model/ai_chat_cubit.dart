import 'package:flutter_bloc/flutter_bloc.dart';

import '../../portfolio/data/models/token_asset.dart';
import '../../../core/result/result.dart';
import '../data/ai_assistant_repository.dart';
import '../data/ai_message.dart';
import 'ai_chat_state.dart';

class AiChatCubit extends Cubit<AiChatState> {
  AiChatCubit({required AiAssistantRepository repository})
    : _repository = repository,
      super(const AiChatEmpty());

  final AiAssistantRepository _repository;

  List<AiMessage> get _messages => switch (state) {
    AiChatEmpty() => const [],
    AiChatActive(:final messages) => messages,
    AiChatResponding(:final messages) => messages,
  };

  Future<void> send(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || state is AiChatResponding) return;

    final withPrompt = [
      ..._messages,
      AiUserMessage(prompt, at: DateTime.now()),
    ];
    emit(AiChatResponding(withPrompt));

    final result = await _repository.respond(prompt);
    if (isClosed) return;
    final reply = switch (result) {
      Ok(:final value) => value,
      Err() => [
          AiTextMessage(
            'Something went wrong reaching the assistant. Please try again.',
            at: DateTime.now(),
          ),
        ],
    };
    emit(AiChatActive([...withPrompt, ...reply]));
  }

  Future<List<TokenAsset>> swapTokens() => _repository.swapTokens();

  void clear() => emit(const AiChatEmpty());
}
