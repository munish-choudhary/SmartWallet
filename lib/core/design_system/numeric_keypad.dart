import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

const _keypadLetters = {
  '2': 'ABC',
  '3': 'DEF',
  '4': 'GHI',
  '5': 'JKL',
  '6': 'MNO',
  '7': 'PQRS',
  '8': 'TUV',
  '9': 'WXYZ',
};

/// The 3x4 numeric keypad used on PIN screens, with an optional biometric
/// shortcut key (bottom-left) and delete key (bottom-right).
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [for (final d in row) _DigitKey(digit: d, onTap: onDigit)],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _IconKey(
              icon: Icons.fingerprint,
              enabled: onBiometric != null,
              onTap: onBiometric,
            ),
            _DigitKey(digit: '0', onTap: onDigit),
            _IconKey(icon: Icons.backspace_outlined, onTap: onDelete),
          ],
        ),
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.digit, required this.onTap});

  final String digit;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return _KeyBase(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(digit);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(digit, style: AppTypography.headline),
          if (_keypadLetters[digit] != null)
            Text(
              _keypadLetters[digit]!,
              style: AppTypography.caption.copyWith(letterSpacing: 1.5),
            ),
        ],
      ),
    );
  }
}

class _IconKey extends StatelessWidget {
  const _IconKey({required this.icon, this.enabled = true, this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _KeyBase(
      onTap: enabled ? onTap : null,
      child: Icon(
        icon,
        color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
        size: 22,
      ),
    );
  }
}

class _KeyBase extends StatelessWidget {
  const _KeyBase({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 64,
      child: Material(
        color: AppColors.keyFill,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
