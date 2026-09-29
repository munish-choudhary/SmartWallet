import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../../../core/vault/pin.dart';
import '../../../core/vault/vault.dart';

part 'verify_phrase_cubit.freezed.dart';

@freezed
sealed class VerifyPhraseState with _$VerifyPhraseState {
  const factory VerifyPhraseState({
    @Default(true) bool loading,
    @Default(<WordChallenge>[]) List<WordChallenge> challenges,
    @Default(0) int currentIndex,
    @Default(<String?>[]) List<String?> answers,
    @Default(false) bool submitting,
    @Default(false) bool shake,
    AppFailure? error,
    WalletId? completedWalletId,
  }) = _VerifyPhraseState;
}

/// Drives the Verify Phrase screen.
///
/// The `Vault` contract only exposes `verificationChallenge()` (shuffled
/// options, no answer key) and `confirmPendingWallet(answers, pin)`
/// (validates + persists together) — there is no way to check a single
/// tap's correctness without either leaking the mnemonic into this Cubit
/// or adding a vault method beyond what was specified. So this collects
/// all answers optimistically (advancing per tap, matching the Figma
/// flow) and validates the full set only on submit; a wrong set shakes
/// and re-fetches a fresh challenge for retry, rather than shaking a
/// single wrong chip immediately. See the onboarding delivery report for
/// the full rationale.
class VerifyPhraseCubit extends Cubit<VerifyPhraseState> {
  VerifyPhraseCubit({required this.vault}) : super(const VerifyPhraseState()) {
    _load();
  }

  final Vault vault;

  Future<void> _load() async {
    emit(state.copyWith(loading: true, shake: false, error: null));
    final result = await vault.verificationChallenge();
    result.when(
      ok: (challenge) => emit(
        VerifyPhraseState(
          loading: false,
          challenges: challenge.challenges,
          answers: List<String?>.filled(challenge.challenges.length, null),
        ),
      ),
      err: (failure) => emit(state.copyWith(loading: false, error: failure)),
    );
  }

  void selectOption(String option) {
    if (state.currentIndex >= state.challenges.length) return;
    final answers = [...state.answers];
    answers[state.currentIndex] = option;
    final nextIndex = (state.currentIndex + 1).clamp(
      0,
      state.challenges.length,
    );
    emit(state.copyWith(answers: answers, currentIndex: nextIndex));
  }

  bool get isReadyToSubmit =>
      state.answers.isNotEmpty && state.answers.every((a) => a != null);

  /// Submits the collected answers. On success, persists the wallet
  /// (and enables biometrics, if [alsoEnableBiometrics]) using [pin],
  /// which this method disposes once done either way.
  Future<void> submit({required Pin pin, required bool alsoEnableBiometrics}) async {
    if (!isReadyToSubmit) {
      pin.dispose();
      return;
    }
    emit(state.copyWith(submitting: true));
    try {
      final result = await vault.confirmPendingWallet(
        answers: state.answers.cast<String>(),
        pin: pin,
      );
      await result.when(
        ok: (walletId) async {
          if (alsoEnableBiometrics) {
            await vault.enableBiometrics(pin: pin);
          }
          emit(state.copyWith(submitting: false, completedWalletId: walletId));
        },
        err: (failure) async {
          if (failure is VerificationFailedFailure) {
            await _load();
            emit(state.copyWith(shake: true));
          } else {
            emit(state.copyWith(submitting: false, error: failure));
          }
        },
      );
    } finally {
      pin.dispose();
    }
  }

  void acknowledgeShake() {
    if (state.shake) emit(state.copyWith(shake: false));
  }

  void retryWithNewChallenge() => _load();
}
