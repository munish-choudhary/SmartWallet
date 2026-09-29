import 'package:flutter/services.dart';

/// Enables/disables screen capture protection (`FLAG_SECURE` on Android, a
/// blur overlay in the iOS app switcher) per CLAUDE.md's Security
/// Checklist, for sensitive screens: recovery phrase, verify phrase,
/// import phrase, import private key, PIN screens.
///
/// Native implementation is a follow-up (mirrors `vault_keystore.dart`'s
/// pattern) — [MethodChannelScreenProtection] will throw
/// [MissingPluginException] on a real device until Android/iOS handlers
/// exist for the `screen_protection` channel (`enable`/`disable` methods,
/// no arguments, no return value). Widgets should not let that exception
/// propagate to the user — see [ScreenProtectionMixin].
abstract interface class ScreenProtection {
  Future<void> enable();
  Future<void> disable();
}

final class MethodChannelScreenProtection implements ScreenProtection {
  MethodChannelScreenProtection([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('screen_protection');

  final MethodChannel _channel;

  @override
  Future<void> enable() => _channel.invokeMethod<void>('enable');

  @override
  Future<void> disable() => _channel.invokeMethod<void>('disable');
}

/// No-op implementation for platforms/tests where screen protection isn't
/// applicable (e.g. widget tests, desktop/web builds).
final class NoopScreenProtection implements ScreenProtection {
  const NoopScreenProtection();

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}
