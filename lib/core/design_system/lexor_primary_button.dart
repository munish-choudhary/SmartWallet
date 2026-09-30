import 'package:flutter/material.dart';

import 'lexor_palette.dart';

/// 52px lime pill CTA with the soft lime glow used on the Lexor frames.
/// Disabled (null [onPressed]) or [loading] renders the muted state.
class LexorPrimaryButton extends StatelessWidget {
  const LexorPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final foreground = enabled
        ? LexorPalette.onAccentDark
        : LexorPalette.textDisabled;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color.fromRGBO(212, 238, 107, 0.2),
                  blurRadius: 15,
                  offset: Offset(0, 10),
                  spreadRadius: -3,
                ),
              ]
            : null,
      ),
      child: Material(
        color: enabled ? LexorPalette.accent : LexorPalette.chipMuted,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: 52,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(foreground),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, size: 18, color: foreground),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
