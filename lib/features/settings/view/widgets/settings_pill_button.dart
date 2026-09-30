import 'package:flutter/material.dart';

import 'settings_palette.dart';

class SettingsPillButton extends StatelessWidget {
  const SettingsPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: enabled ? SettingsPalette.accent : SettingsPalette.chip,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? SettingsPalette.onAccent
                      : SettingsPalette.textSecondary,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: SettingsPalette.onAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
