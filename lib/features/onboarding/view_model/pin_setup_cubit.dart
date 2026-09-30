import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../../../core/vault/pin_controller.dart';
import '../../../core/vault/vault.dart';
import '../data/onboarding_pin_holder.dart';

part 'pin_setup_cubit.freezed.dart';

/// [verify] is the add-wallet step: the vault already has a PIN, so the
/// user proves it instead of creating a new one.
enum PinStep { create, confirm, verify }

enum PinSetupError { trivialPin, mismatch, wrongPin, lockedOut }

@freezed
sealed class PinSetupState with _$PinSetupState {
  const factory PinSetupState({
    @Default(0) int digitCount,
    @Default(6) int maxLength,
    PinSetupError? error,
    @Default(false) bool shake,
    @Default(0) int mismatchCount,
    @Default(false) bool completed,
    @Default(false) bool tooManyMismatches,

    /// A verify-step unlock attempt is in flight; keypad input is ignored.
    @Default(false) bool verifying,
  }) = _PinSetupState;
}

/// Drives both the Create Passcode and Confirm Passcode screens. Holds
/// the actual PIN digits only in a private [PinController] — [state]
/// (what the View/tests observe) carries just the digit count and UI
/// flags, per CLAUDE.md's Memory Hygiene rules.
class PinSetupCubit extends Cubit<PinSetupState> {
  PinSetupCubit({required this.step, required this.pinHolder, this.vault})
    : assert(
        step != PinStep.verify || vault != null,
        'the verify step needs a vault',
      ),
      _controller = PinController(),
      super(const PinSetupState());

  final PinStep step;
  final OnboardingPinHolder pinHolder;

  /// Only used by [PinStep.verify].
  final Vault? vault;
  PinController _controller;

  static const maxMismatches = 3;

  void addDigit(String digit) {
    if (state.verifying || state.digitCount >= state.maxLength) return;
    _controller.addDigit(digit);
    emit(
      state.copyWith(digitCount: _controller.length, error: null, shake: false),
    );
    if (_controller.isComplete) _handleComplete();
  }

  void removeDigit() {
    if (state.verifying || _controller.length == 0) return;
    _controller.removeLast();
    emit(state.copyWith(digitCount: _controller.length, error: null));
  }

  void _handleComplete() {
    switch (step) {
      case PinStep.create:
        _handleCreateComplete();
      case PinStep.confirm:
        _handleConfirmComplete();
      case PinStep.verify:
        _handleVerifyComplete();
    }
  }

  /// Checks the entered PIN against the vault (which also applies its
  /// lockout/backoff policy). On success the PIN buffer moves to the holder
  /// so the later create/import step can use it; nothing else keeps it.
  Future<void> _handleVerifyComplete() async {
    emit(state.copyWith(verifying: true));
    final pin = _controller.toPin();
    final Result<void> result;
    try {
      result = await vault!.unlock(pin);
    } finally {
      pin.dispose();
    }
    if (isClosed) return;

    if (result.isOk) {
      pinHolder.storeVerifiedPin(_controller);
      _controller = PinController();
      emit(state.copyWith(verifying: false, completed: true));
      return;
    }
    _controller.clear();
    emit(
      state.copyWith(
        verifying: false,
        digitCount: 0,
        error: result.failureOrNull is VaultLockedOutFailure
            ? PinSetupError.lockedOut
            : PinSetupError.wrongPin,
        shake: true,
      ),
    );
  }

  void _handleCreateComplete() {
    if (_controller.isTrivial()) {
      _controller.clear();
      emit(
        state.copyWith(
          digitCount: 0,
          error: PinSetupError.trivialPin,
          shake: true,
        ),
      );
      return;
    }
    pinHolder.storeFirstEntry(_controller);
    _controller = PinController();
    emit(state.copyWith(completed: true));
  }

  void _handleConfirmComplete() {
    final matched = pinHolder.confirmEntry(_controller);
    _controller = PinController();
    if (matched) {
      emit(state.copyWith(completed: true));
      return;
    }
    final mismatches = state.mismatchCount + 1;
    emit(
      state.copyWith(
        digitCount: 0,
        mismatchCount: mismatches,
        error: PinSetupError.mismatch,
        shake: true,
        tooManyMismatches: mismatches >= maxMismatches,
      ),
    );
  }

  /// Clears the shake flag once the View has played the animation, so a
  /// later identical error can re-trigger it.
  void acknowledgeShake() {
    if (state.shake) emit(state.copyWith(shake: false));
  }

  @override
  Future<void> close() {
    _controller.dispose();
    return super.close();
  }
}
