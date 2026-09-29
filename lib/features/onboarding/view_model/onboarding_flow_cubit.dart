import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/vault/vault.dart';

part 'onboarding_flow_cubit.freezed.dart';

enum OnboardingMode { create, import }

enum ImportKind { phrase, privateKey }

/// Tracks which onboarding flow is active and its step-independent
/// choices (create vs import, word count, import kind, whether
/// biometrics got enabled). Deliberately holds **no** secret material —
/// no mnemonic, no PIN, no private key. Those live only in
/// [OnboardingPinHolder] / screen-local state, per CLAUDE.md's Memory
/// Hygiene rules.
@freezed
sealed class OnboardingFlowState with _$OnboardingFlowState {
  const factory OnboardingFlowState({
    @Default(OnboardingMode.create) OnboardingMode mode,
    @Default(12) int wordCount,
    ImportKind? importKind,
    @Default(false) bool biometricsEnabled,
    WalletId? completedWalletId,
  }) = _OnboardingFlowState;
}

class OnboardingFlowCubit extends Cubit<OnboardingFlowState> {
  OnboardingFlowCubit() : super(const OnboardingFlowState());

  void selectCreate() => emit(state.copyWith(mode: OnboardingMode.create));

  void selectImport() => emit(state.copyWith(mode: OnboardingMode.import));

  void setWordCount(int words) {
    assert(words == 12 || words == 24, 'words must be 12 or 24');
    emit(state.copyWith(wordCount: words));
  }

  void setImportKind(ImportKind kind) =>
      emit(state.copyWith(importKind: kind));

  void setBiometricsEnabled(bool enabled) =>
      emit(state.copyWith(biometricsEnabled: enabled));

  void setCompletedWalletId(WalletId id) =>
      emit(state.copyWith(completedWalletId: id));

  /// Resets to a clean slate — called when the whole onboarding flow is
  /// abandoned (back-out confirm, or restarted after an app-kill mid-flow).
  void reset() => emit(const OnboardingFlowState());
}
