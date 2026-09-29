import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_failure.dart';

export 'app_failure.dart';

part 'result.freezed.dart';

/// Every repository/service call returns this instead of throwing across
/// layer boundaries, per CLAUDE.md's Error Handling rules.
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppFailure failure) = Err<T>;
}

// `when`/`map`/etc. are generated onto `Result` directly by freezed 3.x
// (see the `ResultPatterns` extension in result.freezed.dart) — use those
// for pattern matching. This extension only adds the extra shorthand
// getters freezed doesn't generate.
extension ResultX<T> on Result<T> {
  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  AppFailure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final failure) => failure,
      };
}
