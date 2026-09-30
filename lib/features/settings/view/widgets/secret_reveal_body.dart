import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/vault/pin.dart';
import 'settings_palette.dart';

/// Shared lifecycle for the reveal screens: PIN gate → revealed content,
/// with the secret held only in this State (never a Cubit/route), wiped on
/// dispose, and re-hidden when the app goes to the background.
abstract class SecretRevealState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
  Uint8List? _secret;

  bool get isUnlocked => _secret != null;

  /// Loads the secret bytes for [pin], or `null` on a wrong PIN.
  Future<Uint8List?> loadSecret(Pin pin);

  Future<bool> submitPin(Pin pin) async {
    final secret = await loadSecret(pin);
    if (!mounted) {
      if (secret != null) secret.fillRange(0, secret.length, 0);
      return false;
    }
    if (secret == null) return false;
    setState(() => _secret = secret);
    return true;
  }

  /// Read-only access for building the revealed view.
  Uint8List get secretBytes => _secret!;

  void wipe() {
    final s = _secret;
    if (s != null) s.fillRange(0, s.length, 0);
    _secret = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && isUnlocked) {
      setState(wipe);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    wipe();
    super.dispose();
  }
}

/// Copies [text] and clears the clipboard after 60s (CLAUDE.md security
/// checklist), only if it still holds the copied secret.
Future<void> copySecret(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied. Clipboard clears in 60s')),
    );
  }
  unawaited(
    Future.delayed(const Duration(seconds: 60), () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == text) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    }),
  );
}

class ShieldBadge extends StatelessWidget {
  const ShieldBadge({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: SettingsPalette.chip.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_rounded,
                  size: 14, color: SettingsPalette.danger),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class DangerCard extends StatelessWidget {
  const DangerCard({
    super.key,
    required this.title,
    required this.message,
    this.badge,
  });
  final String title;
  final String? badge;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(147, 0, 10, 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: SettingsPalette.danger.withValues(alpha: 0.2),
                child: const Icon(Icons.warning_amber_rounded,
                    size: 16, color: SettingsPalette.danger),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: SettingsPalette.dangerText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SettingsPalette.danger,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: SettingsPalette.dangerOnBadge,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: SettingsPalette.dangerText.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Titled card with bullet rows ("Security Protocols" / "Storage Protocols").
class ProtocolsCard extends StatelessWidget {
  const ProtocolsCard({super.key, required this.title, required this.items});
  final String title;
  final List<(IconData, Color, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SettingsPalette.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: SettingsPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (final (icon, color, text) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: SettingsPalette.textSecondary,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Grey pill action used for "Copy …" and "Done" style actions.
class SettingsSecondaryButton extends StatelessWidget {
  const SettingsSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = SettingsPalette.textPrimary,
    this.expand = true,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? color : SettingsPalette.textSecondary;
    return SizedBox(
      height: 48,
      width: expand ? double.infinity : null,
      child: Material(
        color: SettingsPalette.cardAlt,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
