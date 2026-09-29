import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screen_protection.dart';

/// Mix into a sensitive screen's [State] to enable [ScreenProtection] on
/// enter and disable it on exit. Swallows [MissingPluginException] since
/// the native side isn't implemented yet (see `screen_protection.dart`) —
/// a screen must never crash because protection is unavailable, it should
/// just silently not be protected on that platform/build.
mixin ScreenProtectionMixin<T extends StatefulWidget> on State<T> {
  ScreenProtection get screenProtection => MethodChannelScreenProtection();

  @override
  void initState() {
    super.initState();
    _guard(screenProtection.enable);
  }

  @override
  void dispose() {
    _guard(screenProtection.disable);
    super.dispose();
  }

  void _guard(Future<void> Function() action) {
    action().catchError((Object _) {});
  }
}
