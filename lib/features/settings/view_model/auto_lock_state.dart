import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../data/auto_lock_option.dart';

part 'auto_lock_state.freezed.dart';

@freezed
sealed class AutoLockState with _$AutoLockState {
  const factory AutoLockState.loading() = AutoLockLoading;
  const factory AutoLockState.ready({
    required AutoLockOption saved,
    required AutoLockOption selected,
    @Default(false) bool saving,
    @Default(false) bool justSaved,
  }) = AutoLockReady;
  const factory AutoLockState.failure(AppFailure failure) = AutoLockFailure;
}
