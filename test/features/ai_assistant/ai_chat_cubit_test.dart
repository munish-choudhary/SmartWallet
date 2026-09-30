import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/ai_assistant/data/ai_assistant_repository.dart';
import 'package:smart_wallet/features/ai_assistant/data/ai_message.dart';
import 'package:smart_wallet/features/ai_assistant/view_model/ai_chat_cubit.dart';
import 'package:smart_wallet/features/ai_assistant/view_model/ai_chat_state.dart';

class _MockRepo extends Mock implements AiAssistantRepository {}

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  blocTest<AiChatCubit, AiChatState>(
    'send emits responding then active with the reply',
    build: () {
      when(() => repo.respond(any())).thenAnswer(
        (_) async => Result.ok([AiTextMessage('hi', at: DateTime(2026))]),
      );
      return AiChatCubit(repository: repo);
    },
    act: (c) => c.send('hello'),
    expect: () => [isA<AiChatResponding>(), isA<AiChatActive>()],
  );

  blocTest<AiChatCubit, AiChatState>(
    'blank prompt is ignored',
    build: () => AiChatCubit(repository: repo),
    act: (c) => c.send('   '),
    expect: () => <AiChatState>[],
  );

  blocTest<AiChatCubit, AiChatState>(
    'failure becomes an assistant text message',
    build: () {
      when(() => repo.respond(any()))
          .thenAnswer((_) async => const Result.err(AppFailure.network('x')));
      return AiChatCubit(repository: repo);
    },
    act: (c) => c.send('hello'),
    expect: () => [isA<AiChatResponding>(), isA<AiChatActive>()],
  );
}
