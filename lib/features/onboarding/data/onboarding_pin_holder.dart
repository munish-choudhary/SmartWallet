import '../../../core/vault/pin.dart';
import '../../../core/vault/pin_controller.dart';

/// Carries the user's PIN, as bytes only, between the Create/Confirm PIN
/// screens and whichever later screen actually commits it to the vault
/// (Verify Phrase's "Confirm & Complete" for the create flow, Importing
/// for the import flow — the create flow sets the PIN well before the
/// wallet is actually persisted). Provided once per onboarding flow
/// instance; never touches Cubit/Bloc state or route params.
final class OnboardingPinHolder {
  PinController? _pending;
  PinController? _confirmed;

  /// Called when the Create PIN screen collects a complete 6-digit PIN.
  /// Takes ownership of [controller] (disposes it later itself).
  void storeFirstEntry(PinController controller) {
    _pending?.dispose();
    _pending = controller;
  }

  /// Called when the Confirm PIN screen collects its 6 digits. Returns
  /// whether it matches the first entry; on a match, takes ownership of
  /// [controller] as the confirmed PIN and disposes the first-entry
  /// buffer (no longer needed). On a mismatch, disposes [controller]
  /// itself — caller should not also dispose it.
  bool confirmEntry(PinController controller) {
    final matches = _pending?.matches(controller) ?? false;
    if (matches) {
      _confirmed?.dispose();
      _confirmed = controller;
      _pending?.dispose();
      _pending = null;
    } else {
      controller.dispose();
    }
    return matches;
  }

  bool get hasConfirmedPin => _confirmed != null;

  /// Consumes the confirmed PIN, building a [Pin] from it. Can only be
  /// called once — the underlying buffer is zeroed immediately after.
  /// Caller owns the returned [Pin] and must dispose it after use.
  Pin? takeConfirmedPin() {
    final controller = _confirmed;
    if (controller == null) return null;
    final pin = controller.toPin();
    controller.dispose();
    _confirmed = null;
    return pin;
  }

  /// Discards everything — called when the flow is abandoned or reset.
  void discardAll() {
    _pending?.dispose();
    _pending = null;
    _confirmed?.dispose();
    _confirmed = null;
  }
}
