import 'package:flutter/material.dart';

import '../../../../core/design_system/numeric_keypad.dart';
import '../../../../core/design_system/pin_dots.dart';
import '../../../../core/vault/pin.dart';
import '../../../../core/vault/pin_controller.dart';
import 'settings_palette.dart';

/// Manual PIN entry required before a secret is revealed (CLAUDE.md: reveal
/// phrase / export key never accept the biometric-retrieved PIN, so no
/// biometric key is offered here). The digits live only in a
/// [PinController] and are zeroized on completion and dispose.
class PinGate extends StatefulWidget {
  const PinGate({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSubmit,
  });

  final String title;
  final String subtitle;

  /// Returns `true` when the PIN was accepted. The [Pin] is disposed by the
  /// gate after this returns.
  final Future<bool> Function(Pin pin) onSubmit;

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  final _controller = PinController();
  bool _busy = false;
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = false;
    });
    final pin = _controller.toPin();
    bool ok;
    try {
      ok = await widget.onSubmit(pin);
    } finally {
      pin.dispose();
    }
    if (!mounted) return;
    _controller.clear();
    setState(() {
      _busy = false;
      _error = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SettingsPalette.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SettingsPalette.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          PinDots(
            length: _controller.maxLength,
            filled: _controller.length,
            error: _error,
            shake: _error,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 20,
            child: _error
                ? const Text(
                    'Incorrect PIN. Try again.',
                    style: TextStyle(
                      color: SettingsPalette.danger,
                      fontSize: 13,
                    ),
                  )
                : null,
          ),
          const Spacer(),
          IgnorePointer(
            ignoring: _busy,
            child: NumericKeypad(
              onDigit: (d) {
                _controller.addDigit(d);
                setState(() => _error = false);
                if (_controller.isComplete) _submit();
              },
              onDelete: () {
                _controller.removeLast();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
