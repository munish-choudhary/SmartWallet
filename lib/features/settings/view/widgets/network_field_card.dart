import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings_palette.dart';

/// Translucent form card with an icon + label row on top. Static glass
/// (alpha fill, no live blur) since several of these sit in one scroll view.
class NetworkFieldCard extends StatelessWidget {
  const NetworkFieldCard({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.labelTrailing,
    this.errorText,
    this.footer,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? labelTrailing;

  /// Replaces [footer] and outlines the card in the error color.
  final String? errorText;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SettingsPalette.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? SettingsPalette.danger.withValues(alpha: 0.6)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: SettingsPalette.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.24,
                  ),
                ),
              ),
              if (labelTrailing != null) ...[
                const SizedBox(width: 8),
                labelTrailing!,
              ],
            ],
          ),
          const SizedBox(height: 6),
          child,
          if (hasError) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: SettingsPalette.danger,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
          ] else if (footer != null) ...[
            const SizedBox(height: 6),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Borderless text field that sits inside a [NetworkFieldCard].
class NetworkTextInput extends StatelessWidget {
  const NetworkTextInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onSubmitted,
    this.enabled = true,
    this.style = body,
  });

  static const body = TextStyle(
    color: SettingsPalette.textPrimary,
    fontSize: 14,
    letterSpacing: 0.07,
  );

  /// URLs: slightly tighter and heavier so long hosts stay legible.
  static const url = TextStyle(
    color: SettingsPalette.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.26,
  );

  /// Short values (chain ID, symbol) shown large.
  static const value = TextStyle(
    color: SettingsPalette.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.16,
  );

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        autocorrect: false,
        enableSuggestions: false,
        cursorColor: SettingsPalette.accent,
        style: style,
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: style.copyWith(
            color: SettingsPalette.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// Small icon + text line for the bottom of a [NetworkFieldCard].
class NetworkFieldNote extends StatelessWidget {
  const NetworkFieldNote({
    super.key,
    required this.text,
    this.icon,
    this.color = SettingsPalette.textSecondary,
  });

  final String text;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.07,
            ),
          ),
        ),
      ],
    );
  }
}
