import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/vault/pin_controller.dart';
import '../data/onboarding_pin_holder.dart';

part 'pin_setup_cubit.freezed.dart';

enum PinStep { create, confirm }

enum PinSetupError { trivialPin, mismatch }

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
  }) = _PinSetupState;
}

/// Drives both the Create Passcode and Confirm Passcode screens. Holds
/// the actual PIN digits only in a private [PinController] — [state]
/// (what the View/tests observe) carries just the digit count and UI
/// flags, per CLAUDE.md's Memory Hygiene rules.
class PinSetupCubit extends Cubit<PinSetupState> {
  PinSetupCubit({required this.step, required this.pinHolder})
    : _controller = PinController(),
      super(const PinSetupState());

  final PinStep step;
  final OnboardingPinHolder pinHolder;
  PinController _controller;

  static const maxMismatches = 3;

  void addDigit(String digit) {
    if (state.digitCount >= state.maxLength) return;
    _controller.addDigit(digit);
    emit(
      state.copyWith(digitCount: _controller.length, error: null, shake: false),
    );
    if (_controller.isComplete) _handleComplete();
  }

  void removeDigit() {
    if (_controller.length == 0) return;
    _controller.removeLast();
    emit(state.copyWith(digitCount: _controller.length, error: null));
  }

  void _handleComplete() {
    switch (step) {
      case PinStep.create:
        _handleCreateComplete();
      case PinStep.confirm:
        _handleConfirmComplete();
    }
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
