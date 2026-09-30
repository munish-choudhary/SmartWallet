import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/models/wc_request.dart';

part 'request_review_state.freezed.dart';

/// One request is reviewed at a time; [queued] counts those waiting.
@freezed
sealed class RequestReviewState with _$RequestReviewState {
  const factory RequestReviewState.idle() = RequestReviewIdle;
  const factory RequestReviewState.reviewing(
    WcRequest request, {
    @Default(0) int queued,
  }) = RequestReviewReviewing;
  const factory RequestReviewState.submitting(WcRequest request) =
      RequestReviewSubmitting;
}
