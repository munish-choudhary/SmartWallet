import 'dart:async';

import '../../../../core/result/result.dart';
import '../../../walletconnect/data/models/wc_dapp.dart';
import '../../../walletconnect/data/models/wc_request.dart';
import '../../../walletconnect/data/wallet_account_source.dart';

/// How the bridge asks the user for decisions. Implemented by
/// [DappPromptBroker]; the UI answers the prompts.
abstract interface class DappInteractionPrompter {
  Future<bool> confirmConnection(WcDapp dapp, WalletAccount account);
  Future<WcRequestDecision> review(WcRequest request);
  void notice(String message);
}

sealed class DappPrompt {
  const DappPrompt();
}

final class ConnectPrompt extends DappPrompt {
  ConnectPrompt(this.dapp, this.account);
  final WcDapp dapp;
  final WalletAccount account;
  final Completer<bool> _completer = Completer<bool>();

  Future<bool> get answer => _completer.future;
  void respond(bool approved) {
    if (!_completer.isCompleted) _completer.complete(approved);
  }
}

final class ReviewPrompt extends DappPrompt {
  ReviewPrompt(this.request);
  final WcRequest request;
  final Completer<WcRequestDecision> _completer =
      Completer<WcRequestDecision>();

  Future<WcRequestDecision> get answer => _completer.future;
  void respond(WcRequestDecision decision) {
    if (!_completer.isCompleted) _completer.complete(decision);
  }
}

final class NoticePrompt extends DappPrompt {
  const NoticePrompt(this.message);
  final String message;
}

/// Queues prompts so the user only ever sees one at a time, and fails
/// closed: with no UI attached (or once disposed) every prompt resolves as
/// a rejection — a request never hangs and never auto-approves.
final class DappPromptBroker implements DappInteractionPrompter {
  final _controller = StreamController<DappPrompt>.broadcast();
  final List<DappPrompt> _open = [];
  Future<void> _tail = Future.value();
  bool _disposed = false;

  Stream<DappPrompt> get prompts => _controller.stream;

  Future<T> _enqueue<T>(
    DappPrompt prompt,
    Future<T> Function() answer,
    T rejected,
  ) {
    if (_disposed || !_controller.hasListener) return Future.value(rejected);
    final done = Completer<T>();
    _tail = _tail.then((_) async {
      if (_disposed || !_controller.hasListener) {
        done.complete(rejected);
        return;
      }
      _open.add(prompt);
      _controller.add(prompt);
      try {
        done.complete(await answer());
      } finally {
        _open.remove(prompt);
      }
    });
    return done.future;
  }

  @override
  Future<bool> confirmConnection(WcDapp dapp, WalletAccount account) {
    final prompt = ConnectPrompt(dapp, account);
    return _enqueue(prompt, () => prompt.answer, false);
  }

  @override
  Future<WcRequestDecision> review(WcRequest request) {
    final prompt = ReviewPrompt(request);
    return _enqueue(
      prompt,
      () => prompt.answer,
      const WcRequestDecision.reject(),
    );
  }

  @override
  void notice(String message) {
    if (_disposed || !_controller.hasListener) return;
    _controller.add(NoticePrompt(message));
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final prompt in List.of(_open)) {
      switch (prompt) {
        case ConnectPrompt():
          prompt.respond(false);
        case ReviewPrompt():
          prompt.respond(const WcRequestDecision.reject());
        case NoticePrompt():
          break;
      }
    }
    unawaited(_controller.close());
  }
}

/// Executes an approved request: sign, and for transactions broadcast.
///
/// This is the seam to `core/signing` (validate → simulate → authenticate
/// → `Vault.sign()` → broadcast). Until that pipeline exists the default
/// is [UnavailableDappSigningGateway], which refuses — the browser never
/// fabricates a signature or a transaction hash.
abstract interface class DappSigningGateway {
  /// Returns the signature (messages) or transaction hash (transactions).
  Future<Result<String>> execute(WcRequest request, {String? approvalCap});
}

final class UnavailableDappSigningGateway implements DappSigningGateway {
  const UnavailableDappSigningGateway();

  @override
  Future<Result<String>> execute(
    WcRequest request, {
    String? approvalCap,
  }) async =>
      const Result.err(AppFailure.notImplemented());
}
