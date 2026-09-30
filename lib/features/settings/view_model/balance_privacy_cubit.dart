import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/security_settings_repository.dart';
import 'balance_privacy_state.dart';

class BalancePrivacyCubit extends Cubit<BalancePrivacyState> {
  BalancePrivacyCubit({required SecuritySettingsRepository repository})
      : _repository = repository,
        super(const BalancePrivacyState.loading()) {
    load();
  }

  final SecuritySettingsRepository _repository;

  Future<void> load() async {
    emit(const BalancePrivacyState.loading());
    final result = await _repository.getHideBalances();
    emit(switch (result) {
      Ok(:final value) => BalancePrivacyState.ready(hideBalances: value),
      Err(:final failure) => BalancePrivacyState.failure(failure),
    });
  }

  /// Applies immediately — a single switch needs no separate Save step.
  Future<void> setHideBalances(bool hide) async {
    final s = state;
    if (s is! BalancePrivacyReady || s.hideBalances == hide) return;
    emit(BalancePrivacyState.ready(hideBalances: hide));
    final result = await _repository.setHideBalances(hide);
    if (result is Err<void>) {
      emit(BalancePrivacyState.ready(hideBalances: s.hideBalances));
    }
  }
}
