import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/auto_lock_option.dart';
import '../data/security_settings_repository.dart';
import 'auto_lock_state.dart';

class AutoLockCubit extends Cubit<AutoLockState> {
  AutoLockCubit({required SecuritySettingsRepository repository})
      : _repository = repository,
        super(const AutoLockState.loading()) {
    load();
  }

  final SecuritySettingsRepository _repository;

  Future<void> load() async {
    emit(const AutoLockState.loading());
    final result = await _repository.getAutoLock();
    emit(switch (result) {
      Ok(:final value) => AutoLockState.ready(saved: value, selected: value),
      Err(:final failure) => AutoLockState.failure(failure),
    });
  }

  void select(AutoLockOption option) {
    final s = state;
    if (s is! AutoLockReady || s.saving) return;
    emit(s.copyWith(selected: option, justSaved: false));
  }

  Future<void> save() async {
    final s = state;
    if (s is! AutoLockReady || s.saving || s.selected == s.saved) return;
    emit(s.copyWith(saving: true));
    final result = await _repository.setAutoLock(s.selected);
    emit(switch (result) {
      Ok() => AutoLockState.ready(
          saved: s.selected,
          selected: s.selected,
          justSaved: true,
        ),
      Err(:final failure) => AutoLockState.failure(failure),
    });
  }
}
