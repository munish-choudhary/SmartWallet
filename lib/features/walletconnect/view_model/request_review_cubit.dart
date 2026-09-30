import 'dart:async';
import 'dart:collection';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/wc_request.dart';
import '../data/wallet_connect_repository.dart';
import 'request_review_state.dart';

/// Serialises incoming dApp requests so the user only ever reviews one at
/// a time. Every request is answered: approve and reject both go through
/// [WalletConnectRepository.respond], and dismissing a sheet counts as a
/// rejection — a request is never left hanging or auto-approved.
class RequestReviewCubit extends Cubit<RequestReviewState> {
  RequestReviewCubit({required WalletConnectRepository repository})
      : _repository = repository,
        super(const RequestReviewState.idle()) {
    _subscription = _repository.incomingRequests.listen(_onRequest);
  }

  final WalletConnectRepository _repository;
  final Queue<WcRequest> _queue = Queue();
  late final StreamSubscription<WcRequest> _subscription;

  void _onRequest(WcRequest request) {
    final current = state;
    switch (current) {
      case RequestReviewIdle():
        emit(RequestReviewState.reviewing(request));
      case RequestReviewReviewing():
        _queue.add(request);
        emit(current.copyWith(queued: _queue.length));
      case RequestReviewSubmitting():
        _queue.add(request);
    }
  }

  Future<void> approve({String? approvalCap}) =>
      _decide(WcRequestDecision.approve(approvalCap: approvalCap));

  Future<void> reject() => _decide(const WcRequestDecision.reject());

  Future<void> _decide(WcRequestDecision decision) async {
    final current = state;
    if (current is! RequestReviewReviewing) return;
    emit(RequestReviewState.submitting(current.request));
    await _repository.respond(current.request.id, decision);
    if (isClosed) return;
    if (_queue.isEmpty) {
      emit(const RequestReviewState.idle());
    } else {
      emit(RequestReviewState.reviewing(
        _queue.removeFirst(),
        queued: _queue.length,
      ));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
